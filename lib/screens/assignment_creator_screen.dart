import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/assignment_service.dart';
import '../models/assignment_model.dart';

class AssignmentCreatorScreen extends StatefulWidget {
  const AssignmentCreatorScreen({super.key});

  @override
  State<AssignmentCreatorScreen> createState() => _AssignmentCreatorScreenState();
}

class _AssignmentCreatorScreenState extends State<AssignmentCreatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final AssignmentService _assignmentService = AssignmentService();
  
  String _selectedClass = 'Class 9-A';
  String _selectedSubject = 'Mathematics';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _dueTime = const TimeOfDay(hour: 23, minute: 59);
  bool _allowLateSubmission = true;
  int _maxMarks = 100;
  bool _isCreating = false;
  List<String> _attachments = [];
  List<Map<String, dynamic>> _rubricCriteria = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Assignment'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveAsDraft,
            child: const Text('Save Draft', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Assignment Details', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Assignment Title *',
                          border: OutlineInputBorder(),
                          hintText: 'Enter assignment title',
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Title is required' : null,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
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
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedSubject,
                              decoration: const InputDecoration(
                                labelText: 'Subject',
                                border: OutlineInputBorder(),
                              ),
                              items: ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'English']
                                  .map((subject) => DropdownMenuItem(value: subject, child: Text(subject)))
                                  .toList(),
                              onChanged: (value) => setState(() => _selectedSubject = value!),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          hintText: 'Assignment instructions and description',
                        ),
                        maxLines: 4,
                        validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Due Date & Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Submission Settings', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: const Text('Due Date'),
                              subtitle: Text('${_dueDate.day}/${_dueDate.month}/${_dueDate.year}'),
                              leading: const Icon(Icons.calendar_today),
                              onTap: _selectDueDate,
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: const Text('Due Time'),
                              subtitle: Text('${_dueTime.format(context)}'),
                              leading: const Icon(Icons.access_time),
                              onTap: _selectDueTime,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _maxMarks.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Maximum Marks',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _maxMarks = int.tryParse(value) ?? 100,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SwitchListTile(
                              title: const Text('Allow Late Submission'),
                              value: _allowLateSubmission,
                              onChanged: (value) => setState(() => _allowLateSubmission = value),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // File Attachments
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Attachments', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: _addAttachment,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Click to upload files'),
                              Text('PDF, DOC, Images supported', 
                                  style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Attached Files List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 2, // Sample attachments
                        itemBuilder: (context, index) {
                          final files = ['assignment_instructions.pdf', 'reference_material.docx'];
                          return ListTile(
                            leading: const Icon(Icons.attach_file),
                            title: Text(files[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                // Remove attachment
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Grading Rubric
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Grading Rubric', 
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            onPressed: _addRubricCriteria,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Criteria'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 3, // Sample criteria
                        itemBuilder: (context, index) {
                          final criteria = [
                            {'name': 'Content Quality', 'marks': 40},
                            {'name': 'Presentation', 'marks': 30},
                            {'name': 'Timeliness', 'marks': 30},
                          ];
                          
                          final criterion = criteria[index];
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(criterion['name'] as String),
                              subtitle: Text('${criterion['marks']} marks'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editRubricCriteria(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteRubricCriteria(index),
                                  ),
                                ],
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
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createAssignment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isCreating
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 12),
                                Text('Creating...'),
                              ],
                            )
                          : const Text('Create Assignment'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  void _selectDueTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );
    if (time != null) {
      setState(() => _dueTime = time);
    }
  }

  void _addAttachment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File picker will be implemented')),
    );
  }

  void _addRubricCriteria() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Grading Criteria'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Criteria Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Maximum Marks',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editRubricCriteria(int index) {
    // Edit rubric criteria logic
  }

  void _deleteRubricCriteria(int index) {
    // Delete rubric criteria logic
  }

  void _saveAsDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Assignment saved as draft'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _createAssignment() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isCreating = true);
      
      try {
        await _assignmentService.createAssignment(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          className: _selectedClass,
          subject: _selectedSubject,
          teacherId: 'teacher_${DateTime.now().millisecondsSinceEpoch}', // Mock teacher ID
          teacherName: 'Current Teacher', // Mock teacher name
          dueDate: _dueDate,
          dueTime: _dueTime,
          maxMarks: _maxMarks,
          allowLateSubmission: _allowLateSubmission,
          attachments: _attachments,
          rubricCriteria: _rubricCriteria,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assignment created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating assignment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isCreating = false);
        }
      }
    }
  }
}
