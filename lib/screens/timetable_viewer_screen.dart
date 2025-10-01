import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TimetableViewerScreen extends StatefulWidget {
  const TimetableViewerScreen({super.key});

  @override
  State<TimetableViewerScreen> createState() => _TimetableViewerScreenState();
}

class _TimetableViewerScreenState extends State<TimetableViewerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedView = 'Class View';
  String _selectedClass = 'Class 9-A';
  String _selectedTeacher = 'Dr. Ahmad Ali';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Viewer'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportTimetable();
                  break;
                case 'print':
                  _printTimetable();
                  break;
                case 'share':
                  _shareTimetable();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print),
                    SizedBox(width: 8),
                    Text('Print'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Class View', icon: Icon(Icons.class_)),
            Tab(text: 'Teacher View', icon: Icon(Icons.person)),
            Tab(text: 'Room View', icon: Icon(Icons.room)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: _buildFilterSection(),
          ),
          
          // Timetable Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildClassView(),
                _buildTeacherView(),
                _buildRoomView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    switch (_tabController.index) {
      case 0: // Class View
        return Row(
          children: [
            const Text('Class: ', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: DropdownButton<String>(
                value: _selectedClass,
                isExpanded: true,
                items: [
                  'Class 9-A', 'Class 9-B', 'Class 10-A', 'Class 10-B',
                  'Class 11-A', 'Class 11-B', 'Class 12-A', 'Class 12-B'
                ].map((cls) => DropdownMenuItem(
                  value: cls,
                  child: Text(cls),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClass = value!;
                  });
                },
              ),
            ),
          ],
        );
      case 1: // Teacher View
        return Row(
          children: [
            const Text('Teacher: ', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: DropdownButton<String>(
                value: _selectedTeacher,
                isExpanded: true,
                items: [
                  'Dr. Ahmad Ali', 'Prof. Zara Ahmed', 'Dr. Hassan Khan',
                  'Ms. Fatima Sheikh', 'Mr. Ali Raza', 'Ms. Sana Malik',
                  'Maulana Abdul Rahman', 'Mr. Usman Shah'
                ].map((teacher) => DropdownMenuItem(
                  value: teacher,
                  child: Text(teacher),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTeacher = value!;
                  });
                },
              ),
            ),
          ],
        );
      default: // Room View
        return Row(
          children: [
            const Text('Room: ', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: DropdownButton<String>(
                value: 'Room A-101',
                isExpanded: true,
                items: [
                  'Room A-101', 'Room A-102', 'Room B-201', 'Room B-202',
                  'Lab-1', 'Lab-2', 'Library', 'Auditorium'
                ].map((room) => DropdownMenuItem(
                  value: room,
                  child: Text(room),
                )).toList(),
                onChanged: (value) {},
              ),
            ),
          ],
        );
    }
  }

  Widget _buildClassView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor,
                    child: const Icon(Icons.class_, size: 30, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedClass,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('Students: 35 | Room: A-101'),
                        const Text('Class Teacher: Dr. Ahmad Ali'),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _buildInfoChip('Total Periods', '32'),
                      const SizedBox(height: 4),
                      _buildInfoChip('Weekly Hours', '28'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Weekly Timetable
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Timetable',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildTimetableTable(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Subject Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subject Distribution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 8,
                    itemBuilder: (context, index) {
                      final subjects = [
                        {'name': 'Mathematics', 'periods': 6, 'teacher': 'Dr. Ahmad Ali', 'color': Colors.blue},
                        {'name': 'Physics', 'periods': 5, 'teacher': 'Prof. Zara Ahmed', 'color': Colors.green},
                        {'name': 'Chemistry', 'periods': 5, 'teacher': 'Dr. Hassan Khan', 'color': Colors.orange},
                        {'name': 'Biology', 'periods': 4, 'teacher': 'Ms. Fatima Sheikh', 'color': Colors.purple},
                        {'name': 'English', 'periods': 4, 'teacher': 'Mr. Ali Raza', 'color': Colors.red},
                        {'name': 'Urdu', 'periods': 3, 'teacher': 'Ms. Sana Malik', 'color': Colors.teal},
                        {'name': 'Islamic Studies', 'periods': 2, 'teacher': 'Maulana Abdul Rahman', 'color': Colors.indigo},
                        {'name': 'Computer Science', 'periods': 3, 'teacher': 'Mr. Usman Shah', 'color': Colors.brown},
                      ];
                      
                      final subject = subjects[index];
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: subject['color'] as Color,
                          child: Text(
                            '${subject['periods']}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(subject['name'] as String),
                        subtitle: Text('Teacher: ${subject['teacher']}'),
                        trailing: Text(
                          '${subject['periods']} periods/week',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teacher Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor,
                    child: const Icon(Icons.person, size: 30, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedTeacher,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('Subject: Mathematics'),
                        const Text('Department: Science'),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _buildInfoChip('Classes', '4'),
                      const SizedBox(height: 4),
                      _buildInfoChip('Periods', '24'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Teacher's Weekly Schedule
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Schedule',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildTeacherTimetableTable(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Class Assignments
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Class Assignments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      final classes = [
                        {'name': 'Class 9-A', 'subject': 'Mathematics', 'periods': 6, 'room': 'A-101'},
                        {'name': 'Class 10-B', 'subject': 'Mathematics', 'periods': 6, 'room': 'A-102'},
                        {'name': 'Class 11-A', 'subject': 'Mathematics', 'periods': 6, 'room': 'B-201'},
                        {'name': 'Class 12-A', 'subject': 'Mathematics', 'periods': 6, 'room': 'B-202'},
                      ];
                      
                      final classInfo = classes[index];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              '${classInfo['periods']}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(classInfo['name'] as String),
                          subtitle: Text('Subject: ${classInfo['subject']} | Room: ${classInfo['room']}'),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // Navigate to class details
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.primaryColor,
                    child: const Icon(Icons.room, size: 30, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Room A-101',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('Capacity: 40 students'),
                        const Text('Type: Regular Classroom'),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _buildInfoChip('Utilization', '85%'),
                      const SizedBox(height: 4),
                      _buildInfoChip('Free Periods', '8'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Room Schedule
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Room Schedule',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildRoomTimetableTable(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Room Utilization
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Utilization',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
                      final utilization = [85, 90, 80, 95, 75];
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getUtilizationColor(utilization[index]),
                          child: Text(
                            '${utilization[index]}%',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                        title: Text(days[index]),
                        subtitle: Text('${utilization[index]}% utilized'),
                        trailing: LinearProgressIndicator(
                          value: utilization[index] / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getUtilizationColor(utilization[index]),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableTable() {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Monday', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Tuesday', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Wednesday', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Thursday', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Friday', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: [
        _buildDataRow('8:00-8:45', ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'English']),
        _buildDataRow('8:45-9:30', ['Physics', 'Mathematics', 'English', 'Chemistry', 'Urdu']),
        _buildDataRow('9:30-9:45', ['BREAK', 'BREAK', 'BREAK', 'BREAK', 'BREAK']),
        _buildDataRow('9:45-10:30', ['Chemistry', 'Biology', 'Mathematics', 'Physics', 'Computer Science']),
        _buildDataRow('10:30-11:15', ['English', 'Urdu', 'Physics', 'Mathematics', 'Islamic Studies']),
        _buildDataRow('11:15-12:00', ['Biology', 'Chemistry', 'Computer Science', 'English', 'Mathematics']),
        _buildDataRow('12:00-1:00', ['LUNCH', 'LUNCH', 'LUNCH', 'LUNCH', 'LUNCH']),
        _buildDataRow('1:00-1:45', ['Urdu', 'Islamic Studies', 'Biology', 'Computer Science', 'Physics']),
        _buildDataRow('1:45-2:30', ['Islamic Studies', 'Computer Science', 'Urdu', 'Urdu', 'Chemistry']),
      ],
    );
  }

  Widget _buildTeacherTimetableTable() {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Monday', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Tuesday', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Wednesday', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Thursday', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Friday', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: [
        _buildDataRow('8:00-8:45', ['Class 9-A', 'FREE', 'FREE', 'Class 11-A', 'Class 12-A']),
        _buildDataRow('8:45-9:30', ['FREE', 'Class 10-B', 'Class 9-A', 'FREE', 'FREE']),
        _buildDataRow('9:30-9:45', ['BREAK', 'BREAK', 'BREAK', 'BREAK', 'BREAK']),
        _buildDataRow('9:45-10:30', ['Class 12-A', 'FREE', 'Class 11-A', 'Class 10-B', 'FREE']),
        _buildDataRow('10:30-11:15', ['FREE', 'Class 11-A', 'FREE', 'Class 9-A', 'Class 10-B']),
        _buildDataRow('11:15-12:00', ['Class 10-B', 'FREE', 'Class 12-A', 'FREE', 'Class 11-A']),
        _buildDataRow('12:00-1:00', ['LUNCH', 'LUNCH', 'LUNCH', 'LUNCH', 'LUNCH']),
        _buildDataRow('1:00-1:45', ['FREE', 'Class 9-A', 'FREE', 'Class 12-A', 'FREE']),
        _buildDataRow('1:45-2:30', ['Class 11-A', 'Class 12-A', 'Class 10-B', 'FREE', 'Class 9-A']),
      ],
    );
  }

  Widget _buildRoomTimetableTable() {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Monday', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Tuesday', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Wednesday', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Thursday', style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text('Friday', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
      rows: [
        _buildDataRow('8:00-8:45', ['Class 9-A\nMath', 'Class 10-A\nPhysics', 'Class 9-A\nChemistry', 'Class 11-A\nBiology', 'Class 12-A\nEnglish']),
        _buildDataRow('8:45-9:30', ['Class 10-A\nPhysics', 'Class 9-A\nMath', 'Class 11-A\nEnglish', 'Class 12-A\nChemistry', 'Class 10-A\nUrdu']),
        _buildDataRow('9:30-9:45', ['BREAK', 'BREAK', 'BREAK', 'BREAK', 'BREAK']),
        _buildDataRow('9:45-10:30', ['Class 11-A\nChemistry', 'Class 12-A\nBiology', 'Class 10-A\nMath', 'Class 9-A\nPhysics', 'FREE']),
        _buildDataRow('10:30-11:15', ['Class 12-A\nEnglish', 'Class 11-A\nUrdu', 'Class 9-A\nPhysics', 'Class 10-A\nMath', 'Class 11-A\nIslamic Studies']),
        _buildDataRow('11:15-12:00', ['Class 9-A\nBiology', 'FREE', 'Class 12-A\nComputer Science', 'Class 11-A\nEnglish', 'Class 10-A\nMath']),
        _buildDataRow('12:00-1:00', ['LUNCH', 'LUNCH', 'LUNCH', 'LUNCH', 'LUNCH']),
        _buildDataRow('1:00-1:45', ['Class 10-A\nUrdu', 'Class 9-A\nIslamic Studies', 'Class 11-A\nBiology', 'FREE', 'Class 12-A\nPhysics']),
        _buildDataRow('1:45-2:30', ['FREE', 'Class 12-A\nComputer Science', 'Class 10-A\nUrdu', 'Class 9-A\nUrdu', 'Class 11-A\nChemistry']),
      ],
    );
  }

  DataRow _buildDataRow(String time, List<String> subjects) {
    return DataRow(
      cells: [
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              time,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        ...subjects.map((subject) => DataCell(
          Container(
            width: 100,
            padding: const EdgeInsets.all(4),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getSubjectColor(subject),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _getSubjectBorderColor(subject),
                ),
              ),
              child: Text(
                subject,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _getSubjectTextColor(subject),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    if (subject == 'BREAK' || subject == 'LUNCH') return Colors.grey[200]!;
    if (subject == 'FREE') return Colors.green[100]!;
    return AppTheme.primaryColor.withOpacity(0.1);
  }

  Color _getSubjectBorderColor(String subject) {
    if (subject == 'BREAK' || subject == 'LUNCH') return Colors.grey[400]!;
    if (subject == 'FREE') return Colors.green[300]!;
    return AppTheme.primaryColor.withOpacity(0.3);
  }

  Color _getSubjectTextColor(String subject) {
    if (subject == 'BREAK' || subject == 'LUNCH') return Colors.grey[600]!;
    if (subject == 'FREE') return Colors.green[700]!;
    return Colors.black;
  }

  Color _getUtilizationColor(int percentage) {
    if (percentage >= 90) return Colors.red;
    if (percentage >= 75) return Colors.orange;
    if (percentage >= 50) return Colors.green;
    return Colors.blue;
  }

  void _exportTimetable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting timetable to PDF...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _printTimetable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sending timetable to printer...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _shareTimetable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing timetable...'),
        backgroundColor: Colors.purple,
      ),
    );
  }
}
