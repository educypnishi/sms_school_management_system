import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuizBuilderScreen extends StatefulWidget {
  const QuizBuilderScreen({super.key});

  @override
  State<QuizBuilderScreen> createState() => _QuizBuilderScreenState();
}

class _QuizBuilderScreenState extends State<QuizBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedClass = 'Class 9-A';
  String _selectedSubject = 'Mathematics';
  int _timeLimit = 30;
  bool _randomizeQuestions = true;
  bool _showResults = true;
  List<Map<String, dynamic>> _questions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Builder'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _previewQuiz,
            child: const Text('Preview', style: TextStyle(color: Colors.white)),
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
              // Quiz Settings
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quiz Settings', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Quiz Title *',
                          border: OutlineInputBorder(),
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
                              items: ['Mathematics', 'Physics', 'Chemistry', 'Biology']
                                  .map((subject) => DropdownMenuItem(value: subject, child: Text(subject)))
                                  .toList(),
                              onChanged: (value) => setState(() => _selectedSubject = value!),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: _timeLimit.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Time Limit (minutes)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _timeLimit = int.tryParse(value) ?? 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                SwitchListTile(
                                  title: const Text('Randomize Questions'),
                                  value: _randomizeQuestions,
                                  onChanged: (value) => setState(() => _randomizeQuestions = value),
                                ),
                                SwitchListTile(
                                  title: const Text('Show Results'),
                                  value: _showResults,
                                  onChanged: (value) => setState(() => _showResults = value),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Questions Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Questions (${_questions.length})', 
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(
                            onPressed: _addQuestion,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Question'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      if (_questions.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.quiz, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No questions added yet'),
                              Text('Click "Add Question" to start building your quiz'),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _questions.length,
                          itemBuilder: (context, index) {
                            final question = _questions[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryColor,
                                  child: Text('${index + 1}', 
                                      style: const TextStyle(color: Colors.white)),
                                ),
                                title: Text(question['question'] ?? 'Question ${index + 1}'),
                                subtitle: Text('Type: ${question['type']} • Points: ${question['points']}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editQuestion(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteQuestion(index),
                                    ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Question: ${question['question']}'),
                                        const SizedBox(height: 8),
                                        if (question['type'] == 'Multiple Choice')
                                          ...List.generate(
                                            (question['options'] as List).length,
                                            (optionIndex) => Padding(
                                              padding: const EdgeInsets.only(left: 16, top: 4),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    optionIndex == question['correctAnswer']
                                                        ? Icons.radio_button_checked
                                                        : Icons.radio_button_unchecked,
                                                    color: optionIndex == question['correctAnswer']
                                                        ? Colors.green
                                                        : Colors.grey,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(question['options'][optionIndex]),
                                                ],
                                              ),
                                            ),
                                          ),
                                        if (question['type'] == 'True/False')
                                          Padding(
                                            padding: const EdgeInsets.only(left: 16),
                                            child: Text('Correct Answer: ${question['correctAnswer']}'),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
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
                      onPressed: _createQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Create Quiz'),
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

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) => _QuestionDialog(
        onSave: (question) {
          setState(() {
            _questions.add(question);
          });
        },
      ),
    );
  }

  void _editQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => _QuestionDialog(
        question: _questions[index],
        onSave: (question) {
          setState(() {
            _questions[index] = question;
          });
        },
      ),
    );
  }

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  void _previewQuiz() {
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one question to preview')),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quiz preview will be implemented')),
    );
  }

  void _createQuiz() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one question')),
        );
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quiz created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}

class _QuestionDialog extends StatefulWidget {
  final Map<String, dynamic>? question;
  final Function(Map<String, dynamic>) onSave;

  const _QuestionDialog({
    this.question,
    required this.onSave,
  });

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  final _questionController = TextEditingController();
  String _questionType = 'Multiple Choice';
  int _points = 1;
  List<String> _options = ['', '', '', ''];
  int _correctAnswer = 0;
  bool _trueFalseAnswer = true;

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      _questionController.text = widget.question!['question'] ?? '';
      _questionType = widget.question!['type'] ?? 'Multiple Choice';
      _points = widget.question!['points'] ?? 1;
      if (widget.question!['options'] != null) {
        _options = List<String>.from(widget.question!['options']);
      }
      _correctAnswer = widget.question!['correctAnswer'] ?? 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.question == null ? 'Add Question' : 'Edit Question'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question Text',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _questionType,
                    decoration: const InputDecoration(
                      labelText: 'Question Type',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Multiple Choice', 'True/False', 'Short Answer']
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) => setState(() => _questionType = value!),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 100,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Points',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _points = int.tryParse(value) ?? 1,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_questionType == 'Multiple Choice') ...[
              const Text('Options:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...List.generate(4, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Radio<int>(
                      value: index,
                      groupValue: _correctAnswer,
                      onChanged: (value) => setState(() => _correctAnswer = value!),
                    ),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Option ${String.fromCharCode(65 + index)}',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => _options[index] = value,
                      ),
                    ),
                  ],
                ),
              )),
            ] else if (_questionType == 'True/False') ...[
              const Text('Correct Answer:', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: _trueFalseAnswer,
                    onChanged: (value) => setState(() => _trueFalseAnswer = value!),
                  ),
                  const Text('True'),
                  Radio<bool>(
                    value: false,
                    groupValue: _trueFalseAnswer,
                    onChanged: (value) => setState(() => _trueFalseAnswer = value!),
                  ),
                  const Text('False'),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveQuestion,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _saveQuestion() {
    if (_questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question')),
      );
      return;
    }

    final question = {
      'question': _questionController.text,
      'type': _questionType,
      'points': _points,
    };

    if (_questionType == 'Multiple Choice') {
      question['options'] = _options;
      question['correctAnswer'] = _correctAnswer;
    } else if (_questionType == 'True/False') {
      question['correctAnswer'] = _trueFalseAnswer;
    }

    widget.onSave(question);
    Navigator.pop(context);
  }
}
