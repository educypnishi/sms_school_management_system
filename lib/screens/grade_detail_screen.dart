import 'package:flutter/material.dart';
import '../models/grade_model.dart';
import '../services/grade_service.dart';
import '../theme/app_theme.dart';

class GradeDetailScreen extends StatefulWidget {
  final String gradeId;
  final bool isTeacher;

  const GradeDetailScreen({
    super.key,
    required this.gradeId,
    this.isTeacher = false,
  });

  @override
  State<GradeDetailScreen> createState() => _GradeDetailScreenState();
}

class _GradeDetailScreenState extends State<GradeDetailScreen> {
  final GradeService _gradeService = GradeService();
  bool _isLoading = true;
  GradeModel? _grade;
  bool _isEditing = false;
  
  // Controllers for editing
  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGrade();
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _loadGrade() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final grade = await _gradeService.getGradeById(widget.gradeId);
      
      setState(() {
        _grade = grade;
        _scoreController.text = grade?.score.toString() ?? '0.0';
        _commentsController.text = grade?.comments ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading grade: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateGrade() async {
    if (_grade == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final score = double.tryParse(_scoreController.text) ?? _grade!.score;
      final comments = _commentsController.text.trim();
      
      await _gradeService.updateGrade(
        id: _grade!.id,
        score: score,
        comments: comments.isEmpty ? null : comments,
      );
      
      await _loadGrade();
      
      setState(() {
        _isEditing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grade updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating grade: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grade Details'),
        actions: [
          if (widget.isTeacher && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'Edit Grade',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _grade == null
              ? const Center(child: Text('Grade not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Grade Card
                      _buildGradeCard(),
                      const SizedBox(height: 24),
                      
                      // Student and Course Info
                      _buildInfoCard(),
                      const SizedBox(height: 24),
                      
                      // Edit Form (if in edit mode)
                      if (_isEditing) _buildEditForm(),
                      
                      // Comments Section
                      if (!_isEditing) _buildCommentsSection(),
                    ],
                  ),
                ),
      bottomNavigationBar: _isEditing
          ? BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _scoreController.text = _grade!.score.toString();
                          _commentsController.text = _grade!.comments ?? '';
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _updateGrade,
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildGradeCard() {
    if (_grade == null) return const SizedBox.shrink();
    
    final letterGrade = _grade!.letterGrade;
    final percentage = _grade!.score / (_grade!.maxScore > 0 ? _grade!.maxScore : 100.0) * 100;
    final color = _getGradeColor(letterGrade);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _grade!.assessmentType.toUpperCase(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Letter Grade
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                    border: Border.all(
                      color: color,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      letterGrade,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                
                // Score
                Column(
                  children: [
                    Text(
                      '${_grade!.score.toStringAsFixed(1)} / ${_grade!.maxScore.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 18,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    if (_grade == null) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Info
            const Text(
              'Course Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Course', _grade!.courseName),
            _buildInfoRow('Assignment', _grade!.assessmentType),
            const Divider(),
            
            // Student Info
            const Text(
              'Student Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Student', _grade!.studentName),
            _buildInfoRow('Student ID', _grade!.studentId),
            const Divider(),
            
            // Dates
            const Text(
              'Dates',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Graded Date', _formatDate(_grade!.gradedDate)),
            _buildInfoRow('Graded By', _grade!.teacherName),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    if (_grade == null) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teacher Comments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_grade!.comments != null && _grade!.comments!.isNotEmpty)
              Text(_grade!.comments!)
            else
              const Text(
                'No comments provided',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppTheme.lightTextColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Grade',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Score Field
            TextField(
              controller: _scoreController,
              decoration: InputDecoration(
                labelText: 'Score (max: ${_grade?.maxScore != null ? _grade!.maxScore.toStringAsFixed(1) : '100.0'})',
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            
            // Comments Field
            TextField(
              controller: _commentsController,
              decoration: const InputDecoration(
                labelText: 'Comments',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.lightTextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getGradeColor(String letterGrade) {
    switch (letterGrade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
