import 'package:flutter/material.dart';
import '../utils/toast_util.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'application_form_screen.dart';
import 'program_detail_screen.dart';
import 'notification_settings_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  List<NotificationModel> _filteredNotifications = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  late TabController _tabController;
  
  // Filter options
  final List<String> _filterOptions = [
    'All',
    'Unread',
    'Application',
    'Program',
    'Message',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filterOptions.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadNotifications();
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedFilter = _filterOptions[_tabController.index];
        _filterNotifications();
      });
    }
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
        _filterNotifications();
      });
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ToastUtil.showToast(
      context: context,
      message: 'Error loading notifications: $e',
    );
    }
  }
  
  void _filterNotifications() {
    switch (_selectedFilter) {
      case 'Unread':
        _filteredNotifications = _notifications.where((n) => !n.isRead).toList();
        break;
      case 'Application':
        _filteredNotifications = _notifications.where((n) => n.type == NotificationService.typeApplication).toList();
        break;
      case 'Program':
        _filteredNotifications = _notifications.where((n) => n.type == NotificationService.typeProgram).toList();
        break;
      case 'Message':
        _filteredNotifications = _notifications.where((n) => n.type == NotificationService.typeMessage).toList();
        break;
      case 'General':
        _filteredNotifications = _notifications.where((n) => n.type == NotificationService.typeGeneral).toList();
        break;
      case 'All':
      default:
        _filteredNotifications = List.from(_notifications);
        break;
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final authService = await _notificationService.markAllAsRead(_notifications.first.userId);
      
      // Refresh notifications
      await _loadNotifications();
      
      // Show success message
      ToastUtil.showToast(
      context: context,
      message: 'All notifications marked as read',
    );
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      
      // Show error message
      ToastUtil.showToast(
      context: context,
      message: 'Error marking all notifications as read: $e',
    );
    }
  }
  
  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      
      // Update notification in list
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
  
  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      
      // Remove notification from list
      setState(() {
        _notifications.removeWhere((n) => n.id == notificationId);
      });
      
      // Show success message
      ToastUtil.showToast(
      context: context,
      message: 'Notification deleted',
    );
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      
      // Show error message
      ToastUtil.showToast(
      context: context,
      message: 'Error deleting notification: $e',
    );
    }
  }
  
  void _openNotificationSettings() {
    // Navigate to notification settings screen
    if (_notifications.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationSettingsScreen(
            userId: _notifications.first.userId,
          ),
        ),
      );
    } else {
      // If no notifications, use a sample user ID
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NotificationSettingsScreen(
            userId: 'user123',
          ),
        ),
      );
    }
  }

  void _handleNotificationTap(NotificationModel notification) async {
    // Mark notification as read
    await _markAsRead(notification.id);
    
    // Handle navigation based on notification type
    switch (notification.type) {
      case NotificationService.typeApplication:
        if (notification.data != null && notification.data!['applicationId'] != null) {
          // Navigate to application details
          if (!mounted) return;
          Navigator.pushNamed(context, AppConstants.enrollmentFormRoute);
        }
        break;
      case NotificationService.typeProgram:
        if (notification.data != null && notification.data!['programId'] != null) {
          // Navigate to program details
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProgramDetailScreen(
                programId: notification.data!['programId'],
              ),
            ),
          );
        }
        break;
      case NotificationService.typeMessage:
        // Navigate to messages
        if (!mounted) return;
        ToastUtil.showToast(
      context: context,
      message: 'Messages will be available in future phases',
    );
        break;
      default:
        // Do nothing for general notifications
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: 'Mark all as read',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openNotificationSettings,
            tooltip: 'Notification Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _filterOptions.map((filter) => Tab(text: filter)).toList(),
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredNotifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedFilter == 'All'
                            ? 'No notifications'
                            : 'No ${_selectedFilter.toLowerCase()} notifications',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = _filteredNotifications[index];
                    return _buildNotificationCard(notification);
                  },
                ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    // Determine icon based on notification type
    IconData icon;
    Color iconColor;
    
    switch (notification.type) {
      case NotificationService.typeApplication:
        icon = Icons.assignment;
        iconColor = Colors.orange;
        break;
      case NotificationService.typeProgram:
        icon = Icons.school;
        iconColor = Colors.blue;
        break;
      case NotificationService.typeMessage:
        icon = Icons.message;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.notifications;
        iconColor = AppTheme.primaryColor;
        break;
    }
    
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
        _deleteNotification(notification.id);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: notification.isRead ? null : Colors.blue.shade50,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Notification Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Message
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: notification.isRead ? AppTheme.lightTextColor : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Timestamp
                      Text(
                        _formatDateTime(notification.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.lightTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Read/Unread Indicator
                if (!notification.isRead)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}
