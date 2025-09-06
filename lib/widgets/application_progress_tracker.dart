import 'package:flutter/material.dart';
import '../models/application_status_model.dart';
import '../theme/app_theme.dart';

/// A widget that displays the application progress as a timeline
class ApplicationProgressTracker extends StatelessWidget {
  final ApplicationStatus status;
  final VoidCallback? onRefresh;

  const ApplicationProgressTracker({
    super.key,
    required this.status,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and progress
            _buildHeader(context),
            const SizedBox(height: 16),
            
            // Progress bar
            _buildProgressBar(),
            const SizedBox(height: 24),
            
            // Timeline of milestones
            _buildTimeline(context),
            
            // Feedback section if available
            if (status.feedback != null && status.feedback!.isNotEmpty)
              _buildFeedbackSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Application Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: status.statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  status.statusText,
                  style: TextStyle(
                    color: status.statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
            tooltip: 'Refresh status',
          ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress: ${(status.progressPercentage * 100).toInt()}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Submitted: ${_formatDate(status.submissionDate)}',
              style: const TextStyle(color: AppTheme.lightTextColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: status.progressPercentage,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(status.statusColor),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        if (status.estimatedCompletionDate != null)
          Text(
            'Estimated completion: ${_formatDate(status.estimatedCompletionDate!)}',
            style: const TextStyle(color: AppTheme.lightTextColor, fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildTimeline(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Application Timeline',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: status.milestones.length,
          itemBuilder: (context, index) {
            final milestone = status.milestones[index];
            return _buildTimelineItem(context, milestone, index);
          },
        ),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, ApplicationMilestone milestone, int index) {
    final isLast = index == status.milestones.length - 1;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: milestone.isCompleted ? status.statusColor : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Icon(
                milestone.isCompleted ? Icons.check : milestone.icon,
                color: milestone.isCompleted ? Colors.white : Colors.grey[600],
                size: 16,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: milestone.isCompleted ? status.statusColor : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                milestone.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: milestone.isCompleted ? status.statusColor : Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                milestone.description,
                style: TextStyle(
                  color: milestone.isCompleted ? Colors.black87 : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              if (milestone.date != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatDate(milestone.date!),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Feedback',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            status.feedback!,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
