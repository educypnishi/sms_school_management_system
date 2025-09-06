import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../theme/app_theme.dart';

/// A widget to display an event card with actions
class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onComplete;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.onDelete,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getBorderColor(),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event title and priority badge
              Row(
                children: [
                  Icon(
                    event.typeIcon,
                    color: event.priorityColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _buildPriorityBadge(),
                ],
              ),
              const SizedBox(height: 8),
              
              // Event description
              Text(
                event.description,
                style: const TextStyle(color: AppTheme.lightTextColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Event details
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppTheme.lightTextColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    event.formattedDate,
                    style: const TextStyle(
                      color: AppTheme.lightTextColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              
              if (event.location != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppTheme.lightTextColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location!,
                        style: const TextStyle(
                          color: AppTheme.lightTextColor,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onComplete != null && !event.isCompleted) ...[
                    TextButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Mark Complete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (onDelete != null) ...[
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete',
                      color: Colors.red,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: event.priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPriorityIcon(),
            size: 12,
            color: event.priorityColor,
          ),
          const SizedBox(width: 4),
          Text(
            event.priorityText,
            style: TextStyle(
              fontSize: 12,
              color: event.priorityColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPriorityIcon() {
    switch (event.priority) {
      case EventPriority.low:
        return Icons.arrow_downward;
      case EventPriority.medium:
        return Icons.remove;
      case EventPriority.high:
        return Icons.arrow_upward;
      case EventPriority.urgent:
        return Icons.priority_high;
    }
  }

  Color _getBorderColor() {
    if (event.isCompleted) {
      return Colors.green;
    }
    
    if (event.isOverdue) {
      return Colors.red;
    }
    
    if (event.isDueSoon) {
      return Colors.orange;
    }
    
    return Colors.grey.shade300;
  }
}
