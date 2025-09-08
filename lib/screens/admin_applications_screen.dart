import 'package:flutter/material.dart';
import '../utils/toast_util.dart';
import '../models/enrollment_model.dart';
import '../models/user_model.dart';
import '../services/enrollment_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  State<AdminApplicationsScreen> createState() => _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
  final EnrollmentService _enrollmentService = EnrollmentService();
  final AuthService _authService = AuthService();
  List<EnrollmentModel> _enrollments = [];
  List<UserModel> _teachers = [];
  bool _isLoading = true;
  String? _selectedTeacherId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    await Future.wait([
      _loadEnrollments(),
      _loadTeachers(),
    ]);
  }

  Future<void> _loadEnrollments() async {
    try {
      // Get all enrollments
      // In a real app, this would filter by status, date, etc.
      final enrollments = await _enrollmentService.getAllEnrollments();
      
      setState(() {
        _enrollments = enrollments;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading enrollments: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ToastUtil.showToast(
      context: context,
      message: 'Error loading enrollments: $e',
    );
    }
  }
  
  Future<void> _loadTeachers() async {
    try {
      // Simulate getting teachers
      // In a real app, this would get teachers from Firestore
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Create dummy teacher users
      final teachers = [
        UserModel(
          id: 'teacher1',
          name: 'Teacher Smith',
          email: 'teacher1@school.edu',
          role: 'teacher',
          createdAt: DateTime.now(),
        ),
        UserModel(
          id: 'teacher2',
          name: 'Teacher Johnson',
          email: 'teacher2@school.edu',
          role: 'teacher',
          createdAt: DateTime.now(),
        ),
      ];
      
      setState(() {
        _teachers = teachers;
      });
    } catch (e) {
      debugPrint('Error loading teachers: $e');
    }
  }

  Future<void> _updateEnrollmentStatus(String enrollmentId, String newStatus) async {
    try {
      await _enrollmentService.updateEnrollmentStatus(enrollmentId, newStatus);
      
      // Refresh enrollments list
      await _loadEnrollments();
      
      // Show success message
      ToastUtil.showToast(
      context: context,
      message: 'Enrollment status updated',
    );
    } catch (e) {
      debugPrint('Error updating enrollment status: $e');
      
      // Show error message
      ToastUtil.showToast(
      context: context,
      message: 'Error updating enrollment status: $e',
    );
    }
  }
  
  Future<void> _assignToTeacher(String enrollmentId) async {
    // Reset selected teacher
    _selectedTeacherId = null;
    
    // Show teacher selection dialog
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign to Teacher'),
        content: _teachers.isEmpty
            ? const Text('No teachers available')
            : DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Teacher',
                  border: OutlineInputBorder(),
                ),
                items: _teachers.map((teacher) {
                  return DropdownMenuItem<String>(
                    value: teacher.id,
                    child: Text(teacher.name),
                  );
                }).toList(),
                onChanged: (value) {
                  _selectedTeacherId = value;
                },
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_selectedTeacherId != null) {
                Navigator.pop(context);
                
                try {
                  await _enrollmentService.assignEnrollmentToTeacher(
                    enrollmentId,
                    _selectedTeacherId!,
                  );
                  
                  // Refresh enrollments list
                  await _loadEnrollments();
                  
                  // Show success message
                  ToastUtil.showToast(
      context: context,
      message: 'Enrollment assigned to teacher',
    );
                } catch (e) {
                  debugPrint('Error assigning enrollment: $e');
                  
                  // Show error message
                  ToastUtil.showToast(
      context: context,
      message: 'Error assigning enrollment: $e',
    );
                }
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Enrollments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEnrollments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _enrollments.isEmpty
              ? const Center(
                  child: Text(
                    'No enrollments found',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _enrollments.length,
                  itemBuilder: (context, index) {
                    final enrollment = _enrollments[index];
                    return _buildEnrollmentCard(enrollment);
                  },
                ),
    );
  }

  Widget _buildEnrollmentCard(EnrollmentModel enrollment) {
    // Determine status color
    Color statusColor;
    switch (enrollment.status) {
      case 'submitted':
        statusColor = Colors.blue;
        break;
      case 'in_review':
        statusColor = Colors.orange;
        break;
      case 'accepted':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enrollment ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: ${enrollment.id.substring(0, 8)}...',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTextColor,
                  ),
                ),
                Chip(
                  label: Text(
                    enrollment.status.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Student Details
            Text(
              enrollment.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              enrollment.email,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.lightTextColor,
              ),
            ),
            Text(
              enrollment.phone,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.lightTextColor,
              ),
            ),
            
            // Teacher Assignment Info
            if (enrollment.assignedTeacherId != null) ...[  
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.school,
                    size: 16,
                    color: AppTheme.secondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned to Teacher: ${_teachers.firstWhere(
                      (t) => t.id == enrollment.assignedTeacherId,
                      orElse: () => UserModel(
                        id: '',
                        name: 'Unknown',
                        email: '',
                        role: '',
                        createdAt: DateTime.now(),
                      ),
                    ).name}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            
            // Timestamps
            Text(
              'Submitted: ${enrollment.submittedAt?.toString().substring(0, 16) ?? 'Not submitted'}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.lightTextColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // In Review Button
                if (enrollment.status == 'submitted')
                  ElevatedButton(
                    onPressed: () => _updateEnrollmentStatus(enrollment.id, 'in_review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Mark In Review'),
                  ),
                  
                // Assign to Teacher Button
                if (enrollment.status == 'submitted' && enrollment.assignedTeacherId == null)
                  ElevatedButton(
                    onPressed: () => _assignToTeacher(enrollment.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('Assign to Teacher'),
                  ),
                  
                // Accept/Reject Buttons
                if (enrollment.status == 'in_review') ...[
                  ElevatedButton(
                    onPressed: () => _updateEnrollmentStatus(enrollment.id, 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Accept'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _updateEnrollmentStatus(enrollment.id, 'rejected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Reject'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
