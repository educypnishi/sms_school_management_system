import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_active,
                    size: 48,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Real-time Notifications System',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Stay updated with assignments, grades, and school announcements',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Sample Notifications
            Expanded(
              child: ListView(
                children: [
                  _buildNotificationCard(
                    'New Assignment Posted',
                    'Mathematics Assignment #3 has been posted. Due date: March 15, 2025',
                    Icons.assignment,
                    Colors.blue,
                    '2 hours ago',
                    false,
                  ),
                  _buildNotificationCard(
                    'Grade Updated',
                    'Your Physics Quiz grade has been updated: A- (87%)',
                    Icons.grade,
                    Colors.green,
                    '1 day ago',
                    true,
                  ),
                  _buildNotificationCard(
                    'Fee Payment Reminder',
                    'Monthly fee payment is due on March 10, 2025. Amount: PKR 15,000',
                    Icons.payment,
                    Colors.orange,
                    '2 days ago',
                    true,
                  ),
                  _buildNotificationCard(
                    'Timetable Updated',
                    'Class 9-A timetable has been updated. Chemistry lab moved to Friday.',
                    Icons.schedule,
                    AppTheme.primaryColor,
                    '3 days ago',
                    true,
                  ),
                  _buildNotificationCard(
                    'School Announcement',
                    'Parent-Teacher meeting scheduled for March 20, 2025 at 2:00 PM',
                    Icons.campaign,
                    Colors.purple,
                    '1 week ago',
                    true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    String title,
    String message,
    IconData icon,
    Color color,
    String time,
    bool isRead,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 3,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
        isThreeLine: true,
        onTap: () {
          // Handle notification tap
        },
      ),
    );
  }
}
