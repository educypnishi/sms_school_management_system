import 'package:flutter/material.dart';
import '../utils/toast_util.dart';
import '../models/enrollment_model.dart';
import '../services/enrollment_service.dart';
import '../theme/app_theme.dart';

class TeacherClassesScreen extends StatefulWidget {
  const TeacherClassesScreen({super.key});

  @override
  State<TeacherClassesScreen> createState() => _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends State<TeacherClassesScreen> {
  final EnrollmentService _enrollmentService = EnrollmentService();
  List<EnrollmentModel> _enrollments = [];
  bool _isLoading = true;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEnrollments();
  }
  
  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadEnrollments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get enrollments assigned to the teacher
      final enrollments = await _enrollmentService.getTeacherEnrollments();
      
      // Debug output to help diagnose issues
      debugPrint('Teacher enrollments loaded: ${enrollments.length}');
      for (var enrollment in enrollments) {
        debugPrint('Enrollment ID: ${enrollment.id}, Status: ${enrollment.status}, AssignedTo: ${enrollment.assignedTeacherId}');
      }
      
      setState(() {
        _enrollments = enrollments;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading enrollments: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ToastUtil.showToast(
      context: context,
      message: 'Error loading enrollments: $e',
    );
    }
  }

  Future<void> _addFeedback(String enrollmentId) async {
    // Reset feedback controller
    _feedbackController.clear();
    
    // Show feedback dialog
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Feedback'),
        content: TextField(
          controller: _feedbackController,
          decoration: const InputDecoration(
            hintText: 'Enter your feedback here',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_feedbackController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                
                try {
                  await _enrollmentService.addEnrollmentFeedback(
                    enrollmentId,
                    _feedbackController.text.trim(),
                  );
                  
                  // Refresh enrollments list
                  await _loadEnrollments();
                  
                  // Show success message
                  ToastUtil.showToast(
      context: context,
      message: 'Feedback added successfully',
    );
                } catch (e) {
                  debugPrint('Error adding feedback: $e');
                  
                  // Show error message
                  ToastUtil.showToast(
      context: context,
      message: 'Error adding feedback: $e',
    );
                }
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _viewFeedback(String enrollmentId) async {
    try {
      final feedback = await _enrollmentService.getEnrollmentFeedback(enrollmentId);
      
      if (!mounted) return;
      
      // Show feedback dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Student Feedback'),
          content: feedback.isEmpty
              ? const Text('No feedback available for this student.')
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: feedback.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.date,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppTheme.lightTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(item.text),
                            const Divider(),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error getting feedback: $e');
      
      // Show error message
      ToastUtil.showToast(
      context: context,
      message: 'Error getting feedback: $e',
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEnrollments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _enrollments.isEmpty
              ? const Center(
                  child: Text(
                    'No students assigned to your classes',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _enrollments.length,
                  itemBuilder: (context, index) {
                    final enrollment = _enrollments[index];
                    return _buildEnrollmentCard(enrollment);
                  },
                ),
    );
  }

  Widget _buildEnrollmentCard(EnrollmentModel enrollment) {
    // Determine status color
    Color statusColor;
    switch (enrollment.status) {
      case 'submitted':
        statusColor = Colors.blue;
        break;
      case 'in_review':
        statusColor = Colors.orange;
        break;
      case 'accepted':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enrollment ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: ${enrollment.id.substring(0, 8)}...',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTextColor,
                  ),
                ),
                Chip(
                  label: Text(
                    enrollment.status.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Student Details
            Text(
              enrollment.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              enrollment.email,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.lightTextColor,
              ),
            ),
            Text(
              enrollment.phone,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.lightTextColor,
              ),
            ),
            const SizedBox(height: 8),
            
            // Class Information
            if (enrollment.desiredClass != null && enrollment.desiredGrade != null)
              Text(
                'Class: ${enrollment.desiredClass} - Grade: ${enrollment.desiredGrade}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryColor,
                ),
              ),
            const SizedBox(height: 16),
            
            // Timestamps
            Text(
              'Enrolled: ${enrollment.submittedAt?.toString().substring(0, 16) ?? 'Not submitted'}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.lightTextColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // View Feedback Button
                OutlinedButton.icon(
                  onPressed: () => _viewFeedback(enrollment.id),
                  icon: const Icon(Icons.comment),
                  label: const Text('View Feedback'),
                ),
                const SizedBox(width: 8),
                
                // Add Feedback Button
                ElevatedButton.icon(
                  onPressed: () => _addFeedback(enrollment.id),
                  icon: const Icon(Icons.add_comment),
                  label: const Text('Add Feedback'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
