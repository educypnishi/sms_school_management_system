import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exam_model.dart';
import '../services/firebase_exam_service.dart';
import '../theme/app_theme.dart';

class StudentTakeExamScreen extends StatefulWidget {
  final String examId;
  
  const StudentTakeExamScreen({super.key, required this.examId});

  @override
  State<StudentTakeExamScreen> createState() => _StudentTakeExamScreenState();
}

class _StudentTakeExamScreenState extends State<StudentTakeExamScreen> {
  ExamModel? _exam;
  int _currentQuestionIndex = 0;
  Map<String, dynamic> _answers = {};
  Duration _timeRemaining = Duration.zero;
  bool _isLoading = true;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadExam();
  }

  Future<void> _loadExam() async {
    try {
      final exam = await FirebaseExamService.getExamById(widget.examId);
      if (exam != null) {
        setState(() {
          _exam = exam;
          _timeRemaining = exam.duration;
          _isLoading = false;
        });
        _startTimer();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exam: $e')),
        );
      }
    }
  }

  void _startTimer() {
    // Simple timer simulation - in real app, use proper timer
    // This is just for UI demonstration
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_exam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam Not Found')),
        body: const Center(
          child: Text('The requested exam could not be found.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_exam!.title),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, color: Colors.red, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${_timeRemaining.inHours.toString().padLeft(2, '0')}:${(_timeRemaining.inMinutes % 60).toString().padLeft(2, '0')}:${(_timeRemaining.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isSubmitted ? _buildSubmittedView() : _buildExamView(),
      bottomNavigationBar: _isSubmitted ? null : _buildNavigationBar(),
    );
  }

  Widget _buildExamView() {
    if (_exam!.questions.isEmpty) {
      return const Center(
        child: Text('No questions available for this exam.'),
      );
    }

    final question = _exam!.questions[_currentQuestionIndex];
    
    return Column(
      children: [
        // Progress indicator
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${_exam!.questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${question.points} points',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _exam!.questions.length,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ],
          ),
        ),
        
        // Question content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.question,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (question.imageUrl != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text('Image would be displayed here'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Answer options
                _buildAnswerSection(question),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerSection(ExamQuestion question) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceOptions(question);
      case QuestionType.trueFalse:
        return _buildTrueFalseOptions(question);
      case QuestionType.shortAnswer:
      case QuestionType.essay:
        return _buildTextAnswer(question);
      case QuestionType.fillInTheBlank:
        return _buildFillInBlankAnswer(question);
      default:
        return const Text('Question type not supported');
    }
  }

  Widget _buildMultipleChoiceOptions(ExamQuestion question) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select the correct answer:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final optionLetter = String.fromCharCode(65 + index); // A, B, C, D
              
              return RadioListTile<String>(
                title: Text('$optionLetter. $option'),
                value: optionLetter,
                groupValue: _answers[question.id],
                onChanged: (value) {
                  setState(() {
                    _answers[question.id] = value;
                  });
                },
                activeColor: AppTheme.primaryColor,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrueFalseOptions(ExamQuestion question) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select True or False:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            RadioListTile<String>(
              title: const Text('True'),
              value: 'True',
              groupValue: _answers[question.id],
              onChanged: (value) {
                setState(() {
                  _answers[question.id] = value;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
            RadioListTile<String>(
              title: const Text('False'),
              value: 'False',
              groupValue: _answers[question.id],
              onChanged: (value) {
                setState(() {
                  _answers[question.id] = value;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextAnswer(ExamQuestion question) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.type == QuestionType.essay ? 'Write your essay:' : 'Enter your answer:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              maxLines: question.type == QuestionType.essay ? 8 : 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type your answer here...',
              ),
              onChanged: (value) {
                _answers[question.id] = value;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFillInBlankAnswer(ExamQuestion question) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fill in the blank:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your answer...',
              ),
              onChanged: (value) {
                _answers[question.id] = value;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _previousQuestion,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          
          if (_currentQuestionIndex > 0) const SizedBox(width: 16),
          
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _currentQuestionIndex < _exam!.questions.length - 1
                  ? _nextQuestion
                  : _submitExam,
              icon: Icon(_currentQuestionIndex < _exam!.questions.length - 1
                  ? Icons.arrow_forward
                  : Icons.check),
              label: Text(_currentQuestionIndex < _exam!.questions.length - 1
                  ? 'Next'
                  : 'Submit Exam'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentQuestionIndex < _exam!.questions.length - 1
                    ? AppTheme.primaryColor
                    : Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            const Text(
              'Exam Submitted Successfully!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your answers have been submitted for "${_exam!.title}". You will be notified when results are available.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.home),
              label: const Text('Return to Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _exam!.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _submitExam() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Exam'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to submit your exam?'),
            const SizedBox(height: 16),
            Text('Answered: ${_answers.length} of ${_exam!.questions.length} questions'),
            const SizedBox(height: 8),
            const Text(
              'Once submitted, you cannot make changes.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
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
              _performSubmit();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _performSubmit() {
    setState(() {
      _isSubmitted = true;
    });
    
    // In real app, submit to Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exam submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
