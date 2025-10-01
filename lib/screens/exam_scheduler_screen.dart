import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ExamSchedulerScreen extends StatefulWidget {
  const ExamSchedulerScreen({super.key});

  @override
  State<ExamSchedulerScreen> createState() => _ExamSchedulerScreenState();
}

class _ExamSchedulerScreenState extends State<ExamSchedulerScreen> {
  String _selectedExamType = 'Mid Term';
  String _selectedClass = 'Class 9-A';
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Scheduler'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exam Configuration
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Exam Configuration', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedExamType,
                      decoration: const InputDecoration(
                        labelText: 'Exam Type',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Mid Term', 'Final Term', 'Monthly Test', 'Quiz']
                          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedExamType = value!),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedClass,
                      decoration: const InputDecoration(
                        labelText: 'Class',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Class 9-A', 'Class 9-B', 'Class 10-A', 'Class 10-B']
                          .map((cls) => DropdownMenuItem(value: cls, child: Text(cls)))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedClass = value!),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Exam Schedule
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Exam Schedule', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        final subjects = ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'English', 'Urdu'];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryColor,
                              child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(subjects[index]),
                            subtitle: Text('Date: ${_startDate.add(Duration(days: index)).day}/${_startDate.add(Duration(days: index)).month}'),
                            trailing: const Text('9:00 AM - 12:00 PM'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exam schedule created successfully!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Create Exam Schedule'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
