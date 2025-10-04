import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firebase_timetable_service.dart';
import '../services/firebase_class_service.dart';
import '../services/firebase_auth_service.dart';
import '../models/timetable_model.dart';
import '../models/class_model.dart';
import '../theme/app_theme.dart';

class TimetableManagementScreen extends StatefulWidget {
  const TimetableManagementScreen({super.key});

  @override
  State<TimetableManagementScreen> createState() => _TimetableManagementScreenState();
}

class _TimetableManagementScreenState extends State<TimetableManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EnhancedTimetableModel> _timetables = [];
  List<ClassScheduleModel> _schedules = [];
  EnhancedTimetableModel? _selectedTimetable;
  bool _isLoading = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTimetables();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTimetables() async {
    setState(() => _isLoading = true);
    try {
      final timetables = await FirebaseTimetableService.getAllTimetables();
      setState(() {
        _timetables = timetables.cast<EnhancedTimetableModel>();
        if (_timetables.isNotEmpty) {
          _selectedTimetable = _timetables.first;
          _loadSchedules();
        }
      });
    } catch (e) {
      _showErrorSnackBar('Error loading timetables: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSchedules() async {
    if (_selectedTimetable == null) return;
    
    try {
      final schedules = await FirebaseTimetableService.getClassSchedules(_selectedTimetable!.id);
      setState(() => _schedules = schedules);
    } catch (e) {
      _showErrorSnackBar('Error loading schedules: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.schedule), text: 'Timetables'),
            Tab(icon: Icon(Icons.view_week), text: 'Schedule View'),
            Tab(icon: Icon(Icons.auto_awesome), text: 'AI Generator'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateTimetableDialog,
            tooltip: 'Create New Timetable',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTimetables,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTimetablesTab(),
                _buildScheduleViewTab(),
                _buildAIGeneratorTab(),
              ],
            ),
    );
  }

  Widget _buildTimetablesTab() {
    return Column(
      children: [
        // Timetable selector
        if (_timetables.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<EnhancedTimetableModel>(
              value: _selectedTimetable,
              decoration: const InputDecoration(
                labelText: 'Select Timetable',
                border: OutlineInputBorder(),
              ),
              items: _timetables.map((timetable) {
                return DropdownMenuItem(
                  value: timetable,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timetable.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${timetable.academicYear} - ${timetable.semester}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (timetable) {
                setState(() => _selectedTimetable = timetable);
                _loadSchedules();
              },
            ),
          ),

        // Timetable list
        Expanded(
          child: _timetables.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _timetables.length,
                  itemBuilder: (context, index) {
                    final timetable = _timetables[index];
                    return _buildTimetableCard(timetable);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTimetableCard(EnhancedTimetableModel timetable) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: timetable.isActive ? Colors.green : Colors.grey,
          child: Icon(
            timetable.isActive ? Icons.check : Icons.schedule,
            color: Colors.white,
          ),
        ),
        title: Text(
          timetable.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${timetable.academicYear} - ${timetable.semester}'),
            Text(
              'Status: ${timetable.status.toUpperCase()}',
              style: TextStyle(
                color: _getStatusColor(timetable.status),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (timetable.conflicts.isNotEmpty)
              Text(
                '⚠️ ${timetable.conflicts.length} conflicts',
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('View Details'),
              onTap: () => _showTimetableDetails(timetable),
            ),
            PopupMenuItem(
              child: const Text('Add Schedule'),
              onTap: () => _showAddScheduleDialog(timetable),
            ),
            if (!timetable.isActive)
              PopupMenuItem(
                child: const Text('Activate'),
                onTap: () => _activateTimetable(timetable.id),
              ),
            PopupMenuItem(
              child: const Text('Generate Report'),
              onTap: () => _generateTimetableReport(timetable),
            ),
          ],
        ),
        onTap: () {
          setState(() => _selectedTimetable = timetable);
          _loadSchedules();
        },
      ),
    );
  }

  Widget _buildScheduleViewTab() {
    if (_selectedTimetable == null) {
      return const Center(
        child: Text('Please select a timetable first'),
      );
    }

    return Column(
      children: [
        // Schedule header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedTimetable!.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Chip(
                label: Text(_selectedTimetable!.status.toUpperCase()),
                backgroundColor: _getStatusColor(_selectedTimetable!.status),
                labelStyle: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),

        // Schedule grid
        Expanded(
          child: _schedules.isEmpty
              ? const Center(child: Text('No schedules found'))
              : _buildScheduleGrid(),
        ),
      ],
    );
  }

  Widget _buildScheduleGrid() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    final timeSlots = _selectedTimetable!.timeSlots.keys.toList()..sort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Time')),
            ...days.map((day) => DataColumn(label: Text(day))),
          ],
          rows: timeSlots.map((slot) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    _selectedTimetable!.timeSlots[slot] ?? slot,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ...days.map((day) {
                  final schedule = _schedules.firstWhere(
                    (s) => s.day == day && s.timeSlot == slot,
                    orElse: () => ClassScheduleModel(
                      id: '',
                      timetableId: '',
                      classId: '',
                      className: '',
                      subjectId: '',
                      subjectName: '',
                      teacherId: '',
                      teacherName: '',
                      roomId: '',
                      roomName: '',
                      day: day,
                      timeSlot: slot,
                      startTime: '',
                      endTime: '',
                    ),
                  );

                  return DataCell(
                    schedule.id.isEmpty
                        ? const SizedBox.shrink()
                        : _buildScheduleCell(schedule),
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildScheduleCell(ClassScheduleModel schedule) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: schedule.hasConflicts ? Colors.red[100] : Colors.blue[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: schedule.hasConflicts ? Colors.red : Colors.blue,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            schedule.subjectName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            schedule.className,
            style: const TextStyle(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            schedule.teacherName,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            schedule.roomName,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (schedule.hasConflicts)
            const Icon(
              Icons.warning,
              size: 12,
              color: Colors.red,
            ),
        ],
      ),
    );
  }

  Widget _buildAIGeneratorTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.purple[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.purple[700]),
                      const SizedBox(width: 8),
                      Text(
                        'AI Timetable Generator',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate optimal timetables automatically using AI algorithms. '
                    'The system will consider teacher availability, room capacity, '
                    'subject requirements, and conflict avoidance.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // AI Generation Options
          const Text(
            'Generation Options',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Timetable Name',
                      hintText: 'e.g., Fall 2024 Timetable',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Academic Year',
                      hintText: 'e.g., 2024-2025',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Classes Count',
                            hintText: '10',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Teachers Count',
                            hintText: '25',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateAITimetable,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isGenerating ? 'Generating...' : 'Generate AI Timetable'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // AI Features
          const Text(
            'AI Features',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _buildFeatureCard(
            'Conflict Detection',
            'Automatically detects and resolves scheduling conflicts',
            Icons.warning_amber,
            Colors.orange,
          ),
          _buildFeatureCard(
            'Optimal Distribution',
            'Evenly distributes subjects across the week',
            Icons.balance,
            Colors.green,
          ),
          _buildFeatureCard(
            'Resource Optimization',
            'Maximizes room and teacher utilization',
            Icons.trending_up,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Timetables Found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first timetable to get started',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateTimetableDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Timetable'),
          ),
        ],
      ),
    );
  }

  void _showCreateTimetableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Timetable'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Timetable Name',
                  hintText: 'e.g., Fall 2024 Timetable',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Academic Year',
                  hintText: 'e.g., 2024-2025',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Semester',
                  hintText: 'e.g., Fall, Spring',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createTimetable();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddScheduleDialog(EnhancedTimetableModel timetable) {
    // Implementation for adding individual schedules
    _showInfoSnackBar('Add Schedule dialog - Implementation pending');
  }

  void _showTimetableDetails(EnhancedTimetableModel timetable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(timetable.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Academic Year', timetable.academicYear),
            _buildDetailRow('Semester', timetable.semester),
            _buildDetailRow('Status', timetable.status.toUpperCase()),
            _buildDetailRow('Working Days', timetable.workingDays.join(', ')),
            _buildDetailRow('Time Slots', '${timetable.timeSlots.length} slots'),
            _buildDetailRow('Schedules', '${timetable.schedules.length} classes'),
            if (timetable.conflicts.isNotEmpty)
              _buildDetailRow('Conflicts', '${timetable.conflicts.length} issues'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _createTimetable() async {
    try {
      await FirebaseTimetableService.createTimetable(
        name: 'New Timetable',
        academicYear: '2024-2025',
        semester: 'Fall',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 120)),
        workingDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
        timeSlots: {
          'slot1': '08:00-08:50',
          'slot2': '08:50-09:40',
          'slot3': '09:40-10:30',
          'slot4': '10:50-11:40',
          'slot5': '11:40-12:30',
          'slot6': '12:30-13:20',
          'slot7': '14:00-14:50',
          'slot8': '14:50-15:40',
        },
        description: 'Manually created timetable',
      );
      _showSuccessSnackBar('Timetable created successfully!');
      _loadTimetables();
    } catch (e) {
      _showErrorSnackBar('Error creating timetable: $e');
    }
  }

  Future<void> _generateAITimetable() async {
    setState(() => _isGenerating = true);
    try {
      // Load classes for AI generation
      final classes = await FirebaseClassService.getAllClasses();
      
      final timetableId = await FirebaseTimetableService.generateOptimalTimetable(
        name: 'AI Generated Timetable ${DateTime.now().millisecondsSinceEpoch}',
        academicYear: '2024-2025',
        classes: classes,
        teachers: [], // Would load from teacher service
        rooms: [], // Would load from room service
        subjectHours: {}, // Would configure subject hours
      );
      
      _showSuccessSnackBar('AI Timetable generated successfully!');
      _loadTimetables();
    } catch (e) {
      _showErrorSnackBar('Error generating AI timetable: $e');
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _activateTimetable(String timetableId) async {
    try {
      await FirebaseTimetableService.activateTimetable(timetableId);
      _showSuccessSnackBar('Timetable activated successfully!');
      _loadTimetables();
    } catch (e) {
      _showErrorSnackBar('Error activating timetable: $e');
    }
  }

  void _generateTimetableReport(EnhancedTimetableModel timetable) {
    _showInfoSnackBar('Timetable report generation - Implementation pending');
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
