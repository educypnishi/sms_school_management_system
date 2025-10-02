import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await _notificationService.getUserNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<NotificationModel> get _filteredNotifications {
    if (_selectedFilter == 'all') {
      return _notifications;
    } else if (_selectedFilter == 'unread') {
      return _notifications.where((n) => !n.isRead).toList();
    } else {
      return _notifications.where((n) => n.type == _selectedFilter).toList();
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await _notificationService.markAsRead(notification.id);
      await _loadNotifications(); // Refresh the list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking notification as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser != null) {
        await _notificationService.markAllAsRead(currentUser.id);
        await _loadNotifications(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications marked as read'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking all as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    try {
      await _notificationService.deleteNotification(notification.id);
      await _loadNotifications(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case NotificationService.typeAssignment:
        return Icons.assignment;
      case NotificationService.typeGrade:
        return Icons.grade;
      case NotificationService.typeAttendance:
        return Icons.fact_check;
      case NotificationService.typeFee:
        return Icons.payment;
      case NotificationService.typeTimetable:
        return Icons.schedule;
      case NotificationService.typeAnnouncement:
        return Icons.campaign;
      case NotificationService.typeExam:
        return Icons.quiz;
      case NotificationService.typeEmergency:
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case NotificationService.typeAssignment:
        return Colors.blue;
      case NotificationService.typeGrade:
        return Colors.green;
      case NotificationService.typeAttendance:
        return Colors.orange;
      case NotificationService.typeFee:
        return Colors.purple;
      case NotificationService.typeTimetable:
        return AppTheme.primaryColor;
      case NotificationService.typeAnnouncement:
        return Colors.teal;
      case NotificationService.typeExam:
        return Colors.red;
      case NotificationService.typeEmergency:
        return Colors.red[700]!;
      default:
        return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _notifications.any((n) => !n.isRead) ? _markAllAsRead : null,
            tooltip: 'Mark all as read',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All', Icons.notifications),
                  const SizedBox(width: 8),
                  _buildFilterChip('unread', 'Unread', Icons.mark_email_unread),
                  const SizedBox(width: 8),
                  _buildFilterChip(NotificationService.typeAssignment, 'Assignments', Icons.assignment),
                  const SizedBox(width: 8),
                  _buildFilterChip(NotificationService.typeGrade, 'Grades', Icons.grade),
                  const SizedBox(width: 8),
                  _buildFilterChip(NotificationService.typeFee, 'Fees', Icons.payment),
                  const SizedBox(width: 8),
                  _buildFilterChip(NotificationService.typeAnnouncement, 'Announcements', Icons.campaign),
                ],
              ),
            ),
          ),
          
          // Notifications List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.builder(
                          itemCount: _filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = _filteredNotifications[index];
                            return _buildNotificationItem(notification);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all' 
                ? 'No notifications yet'
                : 'No ${_selectedFilter == 'unread' ? 'unread' : _selectedFilter} notifications',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You\'ll see notifications here when they arrive',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: notification.isRead ? 1 : 3,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getNotificationColor(notification.type).withOpacity(0.1),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: _getNotificationColor(notification.type),
              size: 20,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _getTimeAgo(notification.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          trailing: notification.isRead
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
          onTap: () => _markAsRead(notification),
          isThreeLine: true,
        ),
      ),
    );
  }
}
