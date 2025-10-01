import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TimetableGeneratorScreen extends StatefulWidget {
  const TimetableGeneratorScreen({super.key});

  @override
  State<TimetableGeneratorScreen> createState() => _TimetableGeneratorScreenState();
}

class _TimetableGeneratorScreenState extends State<TimetableGeneratorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGenerating = false;
  String _selectedClass = 'Class 9-A';
  String _selectedTerm = 'Spring 2025';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Timetable Generator'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Auto Generate', icon: Icon(Icons.auto_awesome)),
            Tab(text: 'Manual Setup', icon: Icon(Icons.edit_calendar)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAutoGenerateTab(),
          _buildManualSetupTab(),
        ],
      ),
    );
  }

  Widget _buildAutoGenerateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Configuration Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Timetable Configuration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Class Selection
                  DropdownButtonFormField<String>(
                    value: _selectedClass,
                    decoration: const InputDecoration(
                      labelText: 'Select Class',
                      border: OutlineInputBorder(),
                    ),
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
                  
                  const SizedBox(height: 16),
                  
                  // Term Selection
                  DropdownButtonFormField<String>(
                    value: _selectedTerm,
                    decoration: const InputDecoration(
                      labelText: 'Academic Term',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'Spring 2025', 'Summer 2025', 'Fall 2025'
                    ].map((term) => DropdownMenuItem(
                      value: term,
                      child: Text(term),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTerm = value!;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Time Slots Configuration
                  const Text('Time Slots Configuration:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Start Time',
                            hintText: '8:00 AM',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'End Time',
                            hintText: '3:00 PM',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Period Duration (minutes)',
                            hintText: '45',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Break Duration (minutes)',
                            hintText: '15',
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
          
          const SizedBox(height: 16),
          
          // Constraints Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Generation Constraints',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  CheckboxListTile(
                    title: const Text('Avoid consecutive same subjects'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  
                  CheckboxListTile(
                    title: const Text('Prioritize core subjects in morning'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  
                  CheckboxListTile(
                    title: const Text('Consider teacher availability'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  
                  CheckboxListTile(
                    title: const Text('Balance workload across days'),
                    value: false,
                    onChanged: (value) {},
                  ),
                  
                  CheckboxListTile(
                    title: const Text('Include lab sessions'),
                    value: true,
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Subject Allocation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subject Allocation',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 8,
                    itemBuilder: (context, index) {
                      final subjects = [
                        {'name': 'Mathematics', 'periods': 6, 'teacher': 'Dr. Ahmad Ali'},
                        {'name': 'Physics', 'periods': 5, 'teacher': 'Prof. Zara Ahmed'},
                        {'name': 'Chemistry', 'periods': 5, 'teacher': 'Dr. Hassan Khan'},
                        {'name': 'Biology', 'periods': 4, 'teacher': 'Ms. Fatima Sheikh'},
                        {'name': 'English', 'periods': 4, 'teacher': 'Mr. Ali Raza'},
                        {'name': 'Urdu', 'periods': 3, 'teacher': 'Ms. Sana Malik'},
                        {'name': 'Islamic Studies', 'periods': 2, 'teacher': 'Maulana Abdul Rahman'},
                        {'name': 'Computer Science', 'periods': 3, 'teacher': 'Mr. Usman Shah'},
                      ];
                      
                      final subject = subjects[index];
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          child: Text('${subject['periods']}', style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(subject['name'] as String),
                        subtitle: Text('Teacher: ${subject['teacher']}'),
                        trailing: SizedBox(
                          width: 80,
                          child: TextFormField(
                            initialValue: '${subject['periods']}',
                            decoration: const InputDecoration(
                              labelText: 'Periods/Week',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateTimetable,
              icon: _isGenerating 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isGenerating ? 'Generating...' : 'Generate Timetable'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualSetupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class and Day Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedClass,
                      decoration: const InputDecoration(
                        labelText: 'Select Class',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'Class 9-A', 'Class 9-B', 'Class 10-A', 'Class 10-B'
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
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAddPeriodDialog();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Period'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Weekly Timetable Grid
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
                  
                  // Timetable Table
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Time')),
                        DataColumn(label: Text('Monday')),
                        DataColumn(label: Text('Tuesday')),
                        DataColumn(label: Text('Wednesday')),
                        DataColumn(label: Text('Thursday')),
                        DataColumn(label: Text('Friday')),
                      ],
                      rows: [
                        _buildTimetableRow('8:00-8:45', [
                          'Mathematics\nDr. Ahmad Ali',
                          'Physics\nProf. Zara Ahmed',
                          'Chemistry\nDr. Hassan Khan',
                          'Biology\nMs. Fatima Sheikh',
                          'English\nMr. Ali Raza'
                        ]),
                        _buildTimetableRow('8:45-9:30', [
                          'Physics\nProf. Zara Ahmed',
                          'Mathematics\nDr. Ahmad Ali',
                          'English\nMr. Ali Raza',
                          'Chemistry\nDr. Hassan Khan',
                          'Urdu\nMs. Sana Malik'
                        ]),
                        _buildTimetableRow('9:30-9:45', [
                          'BREAK', 'BREAK', 'BREAK', 'BREAK', 'BREAK'
                        ]),
                        _buildTimetableRow('9:45-10:30', [
                          'Chemistry\nDr. Hassan Khan',
                          'Biology\nMs. Fatima Sheikh',
                          'Mathematics\nDr. Ahmad Ali',
                          'Physics\nProf. Zara Ahmed',
                          'Computer Science\nMr. Usman Shah'
                        ]),
                        _buildTimetableRow('10:30-11:15', [
                          'English\nMr. Ali Raza',
                          'Urdu\nMs. Sana Malik',
                          'Physics\nProf. Zara Ahmed',
                          'Mathematics\nDr. Ahmad Ali',
                          'Islamic Studies\nMaulana Abdul Rahman'
                        ]),
                        _buildTimetableRow('11:15-12:00', [
                          'Biology\nMs. Fatima Sheikh',
                          'Chemistry\nDr. Hassan Khan',
                          'Computer Science\nMr. Usman Shah',
                          'English\nMr. Ali Raza',
                          'Mathematics\nDr. Ahmad Ali'
                        ]),
                        _buildTimetableRow('12:00-1:00', [
                          'LUNCH BREAK', 'LUNCH BREAK', 'LUNCH BREAK', 'LUNCH BREAK', 'LUNCH BREAK'
                        ]),
                        _buildTimetableRow('1:00-1:45', [
                          'Urdu\nMs. Sana Malik',
                          'Islamic Studies\nMaulana Abdul Rahman',
                          'Biology\nMs. Fatima Sheikh',
                          'Computer Science\nMr. Usman Shah',
                          'Physics\nProf. Zara Ahmed'
                        ]),
                        _buildTimetableRow('1:45-2:30', [
                          'Islamic Studies\nMaulana Abdul Rahman',
                          'Computer Science\nMr. Usman Shah',
                          'Urdu\nMs. Sana Malik',
                          'Urdu\nMs. Sana Malik',
                          'Chemistry\nDr. Hassan Khan'
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Save timetable
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Timetable'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Preview timetable
                  },
                  icon: const Icon(Icons.preview),
                  label: const Text('Preview'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Export timetable
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DataRow _buildTimetableRow(String time, List<String> subjects) {
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
            width: 120,
            padding: const EdgeInsets.all(4),
            child: InkWell(
              onTap: () {
                if (subject != 'BREAK' && subject != 'LUNCH BREAK') {
                  _showEditPeriodDialog(subject);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: subject == 'BREAK' || subject == 'LUNCH BREAK' 
                      ? Colors.grey[200] 
                      : AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: subject == 'BREAK' || subject == 'LUNCH BREAK' 
                        ? Colors.grey[400]! 
                        : AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  subject,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: subject == 'BREAK' || subject == 'LUNCH BREAK' 
                        ? Colors.grey[600] 
                        : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        )).toList(),
      ],
    );
  }

  void _generateTimetable() async {
    setState(() {
      _isGenerating = true;
    });
    
    // Simulate timetable generation
    await Future.delayed(const Duration(seconds: 3));
    
    setState(() {
      _isGenerating = false;
    });
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Timetable Generated'),
          content: const Text('Timetable has been successfully generated for the selected class. You can now review and make adjustments if needed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _tabController.animateTo(1); // Switch to manual tab
              },
              child: const Text('Review & Edit'),
            ),
          ],
        ),
      );
    }
  }

  void _showAddPeriodDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
              items: [
                'Mathematics', 'Physics', 'Chemistry', 'Biology', 
                'English', 'Urdu', 'Islamic Studies', 'Computer Science'
              ].map((subject) => DropdownMenuItem(
                value: subject,
                child: Text(subject),
              )).toList(),
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Teacher',
                border: OutlineInputBorder(),
              ),
              items: [
                'Dr. Ahmad Ali', 'Prof. Zara Ahmed', 'Dr. Hassan Khan',
                'Ms. Fatima Sheikh', 'Mr. Ali Raza', 'Ms. Sana Malik'
              ].map((teacher) => DropdownMenuItem(
                value: teacher,
                child: Text(teacher),
              )).toList(),
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Day',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'
                    ].map((day) => DropdownMenuItem(
                      value: day,
                      child: Text(day),
                    )).toList(),
                    onChanged: (value) {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      '8:00-8:45', '8:45-9:30', '9:45-10:30', '10:30-11:15',
                      '11:15-12:00', '1:00-1:45', '1:45-2:30'
                    ].map((time) => DropdownMenuItem(
                      value: time,
                      child: Text(time),
                    )).toList(),
                    onChanged: (value) {},
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Add period logic
            },
            child: const Text('Add Period'),
          ),
        ],
      ),
    );
  }

  void _showEditPeriodDialog(String currentSubject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current: $currentSubject'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Change Subject',
                border: OutlineInputBorder(),
              ),
              items: [
                'Mathematics', 'Physics', 'Chemistry', 'Biology', 
                'English', 'Urdu', 'Islamic Studies', 'Computer Science'
              ].map((subject) => DropdownMenuItem(
                value: subject,
                child: Text(subject),
              )).toList(),
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Change Teacher',
                border: OutlineInputBorder(),
              ),
              items: [
                'Dr. Ahmad Ali', 'Prof. Zara Ahmed', 'Dr. Hassan Khan',
                'Ms. Fatima Sheikh', 'Mr. Ali Raza', 'Ms. Sana Malik'
              ].map((teacher) => DropdownMenuItem(
                value: teacher,
                child: Text(teacher),
              )).toList(),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Delete period logic
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Update period logic
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
