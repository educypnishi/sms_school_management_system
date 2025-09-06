import 'package:flutter/material.dart';
import '../utils/toast_util.dart';
import '../models/application_model.dart';
import '../services/application_service.dart';
import '../theme/app_theme.dart';

class PartnerApplicationsScreen extends StatefulWidget {
  const PartnerApplicationsScreen({super.key});

  @override
  State<PartnerApplicationsScreen> createState() => _PartnerApplicationsScreenState();
}

class _PartnerApplicationsScreenState extends State<PartnerApplicationsScreen> {
  final ApplicationService _applicationService = ApplicationService();
  List<ApplicationModel> _applications = [];
  bool _isLoading = true;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }
  
  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // For Phase 5, we'll get assigned applications for the partner
      final applications = await _applicationService.getPartnerApplications();
      
      // Debug output to help diagnose issues
      debugPrint('Partner applications loaded: ${applications.length}');
      for (var app in applications) {
        debugPrint('Application ID: ${app.id}, Status: ${app.status}, AssignedTo: ${app.assignedPartnerId}');
      }
      
      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading applications: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ToastUtil.showToast(
      context: context,
      message: 'Error loading applications: $e',
    );
    }
  }

  Future<void> _addFeedback(String applicationId) async {
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
                  await _applicationService.addApplicationFeedback(
                    applicationId,
                    _feedbackController.text.trim(),
                  );
                  
                  // Refresh applications list
                  await _loadApplications();
                  
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

  Future<void> _viewFeedback(String applicationId) async {
    try {
      final feedback = await _applicationService.getApplicationFeedback(applicationId);
      
      if (!mounted) return;
      
      // Show feedback dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Application Feedback'),
          content: feedback.isEmpty
              ? const Text('No feedback available for this application.')
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
        title: const Text('Assigned Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
              ? const Center(
                  child: Text(
                    'No applications assigned to you',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _applications.length,
                  itemBuilder: (context, index) {
                    final application = _applications[index];
                    return _buildApplicationCard(application);
                  },
                ),
    );
  }

  Widget _buildApplicationCard(ApplicationModel application) {
    // Determine status color
    Color statusColor;
    switch (application.status) {
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
            // Application ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: ${application.id.substring(0, 8)}...',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTextColor,
                  ),
                ),
                Chip(
                  label: Text(
                    application.status.toUpperCase(),
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
            
            // Applicant Details
            Text(
              application.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              application.email,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.lightTextColor,
              ),
            ),
            Text(
              application.phone,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.lightTextColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Timestamps
            Text(
              'Submitted: ${application.submittedAt?.toString().substring(0, 16) ?? 'Not submitted'}',
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
                  onPressed: () => _viewFeedback(application.id),
                  icon: const Icon(Icons.comment),
                  label: const Text('View Feedback'),
                ),
                const SizedBox(width: 8),
                
                // Add Feedback Button
                ElevatedButton.icon(
                  onPressed: () => _addFeedback(application.id),
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
