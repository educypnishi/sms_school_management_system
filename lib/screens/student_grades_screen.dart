import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/gradebook_model.dart';
import '../services/gradebook_service.dart';
import '../theme/app_theme.dart';

class StudentGradesScreen extends StatefulWidget {
  final String studentId;

  const StudentGradesScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<StudentGradesScreen> createState() => _StudentGradesScreenState();
}

class _StudentGradesScreenState extends State<StudentGradesScreen> {
  final GradebookService _gradebookService = GradebookService();
  bool _isLoading = true;
  List<GradeModel> _grades = [];
  Map<String, StudentGradeSummary> _courseSummaries = {};
  String? _selectedCourseId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final grades = await _gradebookService.getGradesForStudent(widget.studentId);
      
      // Group grades by course
      final courseGrades = <String, List<GradeModel>>{};
      for (final grade in grades) {
        if (!courseGrades.containsKey(grade.courseId)) {
          courseGrades[grade.courseId] = [];
        }
        courseGrades[grade.courseId]!.add(grade);
      }
      
      // Create summaries for each course
      final summaries = <String, StudentGradeSummary>{};
      courseGrades.forEach((courseId, courseGrades) {
        if (courseGrades.isNotEmpty) {
          summaries[courseId] = StudentGradeSummary(
            studentId: widget.studentId,
            studentName: courseGrades.first.studentName,
            courseId: courseId,
            courseName: courseGrades.first.courseName,
            grades: courseGrades,
          );
        }
      });

      setState(() {
        _grades = grades;
        _courseSummaries = summaries;
        _selectedCourseId = summaries.isNotEmpty ? summaries.keys.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading grades: $e'),
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
        title: const Text('My Grades'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _grades.isEmpty
              ? _buildEmptyState()
              : _buildGradesContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.grading,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No grades available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your grades will appear here once your assignments are graded',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildGradesContent() {
    return Column(
      children: [
        // Course selector
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.primaryColor.withOpacity(0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Course:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                value: _selectedCourseId,
                items: _courseSummaries.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value.courseName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCourseId = value;
                  });
                },
              ),
            ],
          ),
        ),
        
        // Grade summary
        if (_selectedCourseId != null) ...[
          _buildCourseSummary(_courseSummaries[_selectedCourseId]!),
          
          // Grade details
          Expanded(
            child: _buildGradesList(_courseSummaries[_selectedCourseId]!.grades),
          ),
        ],
      ],
    );
  }

  Widget _buildCourseSummary(StudentGradeSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.courseName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Grade: ${summary.overallLetterGrade}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: summary.overallPercentage / 100,
                      backgroundColor: Colors.grey[300],
                      color: _getGradeColor(summary.overallPercentage),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${summary.overallPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: _getGradeColor(summary.overallPercentage),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _buildGradeChart(summary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildGradeChart(StudentGradeSummary summary) {
    final averagesByType = summary.getAverageByType();
    
    if (averagesByType.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return SizedBox(
      height: 100,
      child: PieChart(
        PieChartData(
          sections: averagesByType.entries.map((entry) {
            return PieChartSectionData(
              color: _getAssignmentTypeColor(entry.key),
              value: entry.value,
              title: '',
              radius: 30,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
          centerSpaceRadius: 20,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildGradesList(List<GradeModel> grades) {
    // Sort grades by date (newest first)
    final sortedGrades = List<GradeModel>.from(grades)
      ..sort((a, b) => b.gradedDate.compareTo(a.gradedDate));
    
    return ListView.builder(
      itemCount: sortedGrades.length,
      itemBuilder: (context, index) {
        final grade = sortedGrades[index];
        return _buildGradeCard(grade);
      },
    );
  }

  Widget _buildGradeCard(GradeModel grade) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    grade.assignmentName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getGradeColor(grade.percentageScore),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${grade.score.toStringAsFixed(1)}/${grade.maxScore.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAssignmentTypeColor(grade.assignmentType).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    grade.assignmentType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getAssignmentTypeColor(grade.assignmentType),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Graded: ${_formatDate(grade.gradedDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            if (grade.feedback != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 4),
              Text(
                'Feedback:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                grade.feedback!,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.lightGreen;
    if (percentage >= 70) return Colors.amber;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getAssignmentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'quiz':
        return Colors.blue;
      case 'exam':
        return Colors.purple;
      case 'homework':
        return Colors.teal;
      case 'project':
        return Colors.orange;
      case 'participation':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
