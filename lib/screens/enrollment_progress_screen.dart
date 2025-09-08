import 'package:flutter/material.dart';
import '../models/application_status_model.dart';
import '../services/application_status_service.dart';
import '../widgets/application_progress_tracker.dart';
import '../theme/app_theme.dart';

class EnrollmentProgressScreen extends StatefulWidget {
  final String enrollmentId;

  const EnrollmentProgressScreen({
    super.key,
    required this.enrollmentId,
  });

  @override
  State<EnrollmentProgressScreen> createState() => _EnrollmentProgressScreenState();
}

class _EnrollmentProgressScreenState extends State<EnrollmentProgressScreen> {
  final ApplicationStatusService _statusService = ApplicationStatusService();
  bool _isLoading = true;
  ApplicationStatus? _status;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEnrollmentStatus();
  }

  Future<void> _loadEnrollmentStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // For demo purposes, generate sample data if it doesn't exist
      await _statusService.generateSampleData();
      
      final status = await _statusService.getApplicationStatus(widget.enrollmentId);
      
      setState(() {
        _status = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load enrollment status: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enrollment Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadEnrollmentStatus,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_status == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off,
                color: AppTheme.lightTextColor,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'Enrollment Not Found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'We couldn\'t find the enrollment you\'re looking for.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEnrollmentStatus,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enrollment ID and submission date
            _buildEnrollmentHeader(),
            const SizedBox(height: 16),
            
            // Progress tracker
            ApplicationProgressTracker(
              status: _status!,
              onRefresh: _loadEnrollmentStatus,
            ),
            const SizedBox(height: 24),
            
            // Additional information
            _buildAdditionalInfo(),
            const SizedBox(height: 16),
            
            // Contact section
            _buildContactSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrollmentHeader() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enrollment ID',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  _status!.applicationId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Submitted on'),
                Text(
                  _formatDate(_status!.submissionDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (_status!.assignedTo != null) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Assigned to'),
                  Text(
                    _status!.assignedTo!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What\'s Next?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_status!.nextMilestone != null)
              Text(
                'Your enrollment is currently at the "${_status!.nextMilestone!.title}" stage. ${_status!.nextMilestone!.description}',
              )
            else
              const Text(
                'Your enrollment process is complete. No further action is required.',
              ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Need to Update Your Enrollment?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'If you need to update any information or documents in your enrollment, please contact our support team.',
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This feature will be available in future updates'),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_document),
                label: const Text('Request Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need Help?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'If you have any questions about your enrollment or need assistance, our support team is here to help.',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email support will be available in future updates'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.email),
                  label: const Text('Email'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chat support will be available in future updates'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enrollment Progress Tracker'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to use this screen:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• View your current enrollment status and progress'),
              Text('• Track each milestone in the enrollment process'),
              Text('• See feedback from reviewers'),
              Text('• Find out what\'s next in your enrollment journey'),
              SizedBox(height: 16),
              Text(
                'Need to update your enrollment?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Use the "Request Changes" button to contact our team if you need to update any information in your enrollment.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
