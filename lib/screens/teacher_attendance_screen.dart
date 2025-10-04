import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_attendance_service.dart';
import '../services/firebase_class_service.dart';
import '../services/firebase_auth_service.dart';
import '../models/class_model.dart';
import '../models/attendance_model.dart';
import '../theme/app_theme.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  bool _isLoading = true;
  List<ClassModel> _teacherClasses = [];
  ClassModel? _selectedClass;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _classStudents = [];
  List<AttendanceModel> _existingAttendance = [];
  Map<String, String> _attendanceStatus = {};
  Map<String, String> _attendanceReasons = {};
  Map<String, String> _attendanceNotes = {};

  final _subjectController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTeacherClasses();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherClasses() async {
    setState(() => _isLoading = true);
    
    try {
      final teacherId = FirebaseAuthService.currentUserId!;
      final classes = await FirebaseClassService.getClassesByTeacher(teacherId);
      
      setState(() {
        _teacherClasses = classes;
        if (classes.isNotEmpty) {
          _selectedClass = classes.first;
          _subjectController.text = classes.first.subject;
        }
        _isLoading = false;
      });

      if (_selectedClass != null) {
        await _loadClassStudents();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading classes: $e');
    }
  }

  Future<void> _loadClassStudents() async {
    if (_selectedClass == null) return;

    try {
      final students = await FirebaseClassService.getClassStudents(_selectedClass!.id);
      final existingAttendance = await FirebaseAttendanceService.getClassAttendance(
        classId: _selectedClass!.id,
        date: _selectedDate,
      );

      setState(() {
        _classStudents = students;
        _existingAttendance = existingAttendance;
        
        // Initialize attendance status
        _attendanceStatus.clear();
        _attendanceReasons.clear();
        _attendanceNotes.clear();

        for (final student in students) {
          final studentId = student['studentId'];
          final existingRecord = existingAttendance
              .where((a) => a.studentId == studentId)
              .firstOrNull;

          _attendanceStatus[studentId] = existingRecord?.status ?? 'present';
          _attendanceReasons[studentId] = existingRecord?.reason ?? '';
          _attendanceNotes[studentId] = existingRecord?.notes ?? '';
        }
      });
    } catch (e) {
      _showErrorSnackBar('Error loading students: $e');
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedClass == null || _classStudents.isEmpty) return;

    try {
      setState(() => _isLoading = true);

      final teacherId = FirebaseAuthService.currentUserId!;
      final teacherName = FirebaseAuthService.currentUser?.displayName ?? 'Teacher';

      final attendanceList = _classStudents.map((student) {
        final studentId = student['studentId'];
        return {
          'studentId': studentId,
          'studentName': student['studentName'],
          'status': _attendanceStatus[studentId] ?? 'present',
          'reason': _attendanceReasons[studentId],
          'notes': _attendanceNotes[studentId],
        };
      }).toList();

      await FirebaseAttendanceService.markClassAttendance(
        classId: _selectedClass!.id,
        className: _selectedClass!.name,
        teacherId: teacherId,
        teacherName: teacherName,
        subject: _subjectController.text.trim(),
        date: _selectedDate,
        attendanceList: attendanceList,
      );

      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Attendance saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error saving attendance: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_classStudents.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveAttendance,
              tooltip: 'Save Attendance',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAttendanceForm(),
    );
  }

  Widget _buildAttendanceForm() {
    return Column(
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Column(
            children: [
              // Class Selection
              Row(
                children: [
                  const Icon(Icons.class_, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  const Text('Class: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: DropdownButton<ClassModel>(
                      value: _selectedClass,
                      isExpanded: true,
                      items: _teacherClasses.map((classModel) {
                        return DropdownMenuItem(
                          value: classModel,
                          child: Text('${classModel.name} - ${classModel.subject}'),
                        );
                      }).toList(),
                      onChanged: (ClassModel? newClass) {
                        setState(() {
                          _selectedClass = newClass;
                          _subjectController.text = newClass?.subject ?? '';
                        });
                        if (newClass != null) {
                          _loadClassStudents();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Date Selection
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  const Text('Date: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                          _loadClassStudents();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Subject Field
              Row(
                children: [
                  const Icon(Icons.subject, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  const Text('Subject: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: TextField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        hintText: 'Enter subject name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Quick Actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _markAllAs('present'),
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  label: const Text('All Present'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[50],
                    foregroundColor: Colors.green[700],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _markAllAs('absent'),
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text('All Absent'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Students List
        Expanded(
          child: _classStudents.isEmpty
              ? const Center(
                  child: Text(
                    'No students found in this class',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _classStudents.length,
                  itemBuilder: (context, index) {
                    final student = _classStudents[index];
                    final studentId = student['studentId'];
                    final studentName = student['studentName'];
                    
                    return _buildStudentAttendanceCard(studentId, studentName);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStudentAttendanceCard(String studentId, String studentName) {
    final status = _attendanceStatus[studentId] ?? 'present';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Name and Status
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getStatusColor(status),
                  child: Text(
                    studentName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    studentName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                _buildStatusChips(studentId),
              ],
            ),
            
            // Reason and Notes (if absent or late)
            if (status == 'absent' || status == 'late' || status == 'excused') ...[
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) => _attendanceReasons[studentId] = value,
                controller: TextEditingController(text: _attendanceReasons[studentId]),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) => _attendanceNotes[studentId] = value,
                controller: TextEditingController(text: _attendanceNotes[studentId]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChips(String studentId) {
    final statuses = ['present', 'absent', 'late', 'excused'];
    final currentStatus = _attendanceStatus[studentId] ?? 'present';
    
    return Wrap(
      spacing: 4,
      children: statuses.map((status) {
        final isSelected = currentStatus == status;
        return FilterChip(
          label: Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white : _getStatusColor(status),
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _attendanceStatus[studentId] = status);
            }
          },
          backgroundColor: Colors.grey[200],
          selectedColor: _getStatusColor(status),
          checkmarkColor: Colors.white,
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'excused':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _markAllAs(String status) {
    setState(() {
      for (final student in _classStudents) {
        _attendanceStatus[student['studentId']] = status;
      }
    });
  }
}

extension FirstWhereOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
