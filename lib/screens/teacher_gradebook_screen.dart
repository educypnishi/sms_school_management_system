import 'package:flutter/material.dart';
import '../models/gradebook_model.dart';
import '../services/gradebook_service.dart';
import '../theme/app_theme.dart';

class TeacherGradebookScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const TeacherGradebookScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<TeacherGradebookScreen> createState() => _TeacherGradebookScreenState();
}

class _TeacherGradebookScreenState extends State<TeacherGradebookScreen> with SingleTickerProviderStateMixin {
  final GradebookService _gradebookService = GradebookService();
  bool _isLoading = true;
  List<AssignmentModel> _assignments = [];
  List<StudentGradeSummary> _studentSummaries = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final assignments = await _gradebookService.getAssignmentsForCourse(widget.courseId);
      final studentSummaries = await _gradebookService.getAllStudentGradeSummariesForCourse(widget.courseId);

      setState(() {
        _assignments = assignments;
        _studentSummaries = studentSummaries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading gradebook data: $e'),
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
        title: Text('Gradebook: ${widget.courseName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Assignments'),
            Tab(text: 'Students'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAssignmentsTab(),
                _buildStudentsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddAssignmentDialog();
          } else {
            _showGradeAllDialog();
          }
        },
        child: Icon(_tabController.index == 0 ? Icons.add : Icons.edit),
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    return _assignments.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.assignment,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No assignments yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your first assignment by clicking the + button',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showAddAssignmentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Assignment'),
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: _assignments.length,
            itemBuilder: (context, index) {
              final assignment = _assignments[index];
              return _buildAssignmentCard(assignment);
            },
          );
  }

  Widget _buildAssignmentCard(AssignmentModel assignment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToAssignmentDetail(assignment),
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
                      assignment.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildAssignmentStatusChip(assignment),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Type: ${assignment.type.toUpperCase()}',
                style: TextStyle(
                  color: AppTheme.secondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Max Score: ${assignment.maxScore.toStringAsFixed(1)} points',
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Due: ${_formatDate(assignment.dueDate)}',
                    style: TextStyle(
                      color: assignment.isOverdue()
                          ? Colors.red
                          : AppTheme.lightTextColor,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditAssignmentDialog(assignment),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _showDeleteAssignmentDialog(assignment),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentStatusChip(AssignmentModel assignment) {
    if (!assignment.isPublished) {
      return Chip(
        label: const Text('Draft'),
        backgroundColor: Colors.grey[300],
        labelStyle: const TextStyle(color: Colors.black),
      );
    } else if (assignment.isOverdue()) {
      return const Chip(
        label: Text('Past Due'),
        backgroundColor: Colors.red,
        labelStyle: TextStyle(color: Colors.white),
      );
    } else {
      return Chip(
        label: Text('Due in ${assignment.daysRemaining} days'),
        backgroundColor: AppTheme.primaryColor,
        labelStyle: const TextStyle(color: Colors.white),
      );
    }
  }

  Widget _buildStudentsTab() {
    return _studentSummaries.isEmpty
        ? const Center(
            child: Text('No student data available'),
          )
        : ListView.builder(
            itemCount: _studentSummaries.length,
            itemBuilder: (context, index) {
              final summary = _studentSummaries[index];
              return _buildStudentGradeCard(summary);
            },
          );
  }

  Widget _buildStudentGradeCard(StudentGradeSummary summary) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToStudentDetail(summary),
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
                      summary.studentName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildGradeChip(summary.overallLetterGrade, summary.overallPercentage),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Assignments Completed: ${summary.grades.length}/${_assignments.length}',
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: summary.overallPercentage / 100,
                backgroundColor: Colors.grey[300],
                color: _getGradeColor(summary.overallPercentage),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeChip(String letterGrade, double percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getGradeColor(percentage),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$letterGrade (${percentage.toStringAsFixed(1)}%)',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _navigateToAssignmentDetail(AssignmentModel assignment) {
    // Navigate to assignment detail screen
    // This would be implemented in a real app
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing ${assignment.title}'),
      ),
    );
  }

  void _navigateToStudentDetail(StudentGradeSummary summary) {
    // Navigate to student detail screen
    // This would be implemented in a real app
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing grades for ${summary.studentName}'),
      ),
    );
  }

  void _showAddAssignmentDialog() {
    // Show dialog to add a new assignment
    // This would be implemented in a real app
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add Assignment dialog would appear here'),
      ),
    );
  }

  void _showEditAssignmentDialog(AssignmentModel assignment) {
    // Show dialog to edit an assignment
    // This would be implemented in a real app
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit ${assignment.title} dialog would appear here'),
      ),
    );
  }

  void _showDeleteAssignmentDialog(AssignmentModel assignment) {
    // Show dialog to confirm deletion of an assignment
    // This would be implemented in a real app
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Delete ${assignment.title} dialog would appear here'),
      ),
    );
  }

  void _showGradeAllDialog() {
    // Show dialog to grade all students for an assignment
    // This would be implemented in a real app
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Grade All Students dialog would appear here'),
      ),
    );
  }
}
