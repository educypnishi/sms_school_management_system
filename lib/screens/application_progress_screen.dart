import 'package:flutter/material.dart';
import '../models/application_status_model.dart';
import '../services/application_status_service.dart';
import '../widgets/application_progress_tracker.dart';
import '../theme/app_theme.dart';

class ApplicationProgressScreen extends StatefulWidget {
  final String applicationId;

  const ApplicationProgressScreen({
    super.key,
    required this.applicationId,
  });

  @override
  State<ApplicationProgressScreen> createState() => _ApplicationProgressScreenState();
}

class _ApplicationProgressScreenState extends State<ApplicationProgressScreen> {
  final ApplicationStatusService _statusService = ApplicationStatusService();
  bool _isLoading = true;
  ApplicationStatus? _status;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadApplicationStatus();
  }

  Future<void> _loadApplicationStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // For demo purposes, generate sample data if it doesn't exist
      await _statusService.generateSampleData();
      
      final status = await _statusService.getApplicationStatus(widget.applicationId);
      
      setState(() {
        _status = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load application status: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Progress'),
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
                onPressed: _loadApplicationStatus,
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
                'Application Not Found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'We couldn\'t find the application you\'re looking for.',
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
      onRefresh: _loadApplicationStatus,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Application ID and submission date
            _buildApplicationHeader(),
            const SizedBox(height: 16),
            
            // Progress tracker
            ApplicationProgressTracker(
              status: _status!,
              onRefresh: _loadApplicationStatus,
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

  Widget _buildApplicationHeader() {
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
                  'Application ID',
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
                'Your application is currently at the "${_status!.nextMilestone!.title}" stage. ${_status!.nextMilestone!.description}',
              )
            else
              const Text(
                'Your application process is complete. No further action is required.',
              ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Need to Update Your Application?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'If you need to update any information or documents in your application, please contact our support team.',
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
              'If you have any questions about your application or need assistance, our support team is here to help.',
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
        title: const Text('Application Progress Tracker'),
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
              Text('• View your current application status and progress'),
              Text('• Track each milestone in the application process'),
              Text('• See feedback from reviewers'),
              Text('• Find out what\'s next in your application journey'),
              SizedBox(height: 16),
              Text(
                'Need to update your application?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Use the "Request Changes" button to contact our team if you need to update any information in your application.'),
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
