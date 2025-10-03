import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class PushNotificationService {
  static const String _notificationsKey = 'notifications';
  static const String _settingsKey = 'notification_settings';
  static const String _tokensKey = 'device_tokens';
  
  // Initialize notification service
  Future<void> initialize() async {
    try {
      // In a real app, this would initialize Firebase Cloud Messaging
      // For now, we'll simulate with local storage
      await _initializeLocalNotifications();
      await _loadNotificationSettings();
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }
  
  // Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    NotificationType type = NotificationType.general,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        title: title,
        body: body,
        imageUrl: imageUrl,
        data: data ?? {},
        type: type,
        priority: priority,
        createdAt: DateTime.now(),
        isRead: false,
        isDelivered: false,
      );
      
      await _saveNotification(notification);
      await _simulateNotificationDelivery(notification);
      
    } catch (e) {
      debugPrint('Error sending notification to user: $e');
    }
  }
  
  // Send notification to multiple users
  Future<void> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    NotificationType type = NotificationType.general,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      for (final userId in userIds) {
        await sendNotificationToUser(
          userId: userId,
          title: title,
          body: body,
          imageUrl: imageUrl,
          data: data,
          type: type,
          priority: priority,
        );
      }
    } catch (e) {
      debugPrint('Error sending notification to users: $e');
    }
  }
  
  // Send notification to all users with specific role
  Future<void> sendNotificationToRole({
    required String role,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    NotificationType type = NotificationType.general,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      final userIds = await _getUserIdsByRole(role);
      await sendNotificationToUsers(
        userIds: userIds,
        title: title,
        body: body,
        imageUrl: imageUrl,
        data: data,
        type: type,
        priority: priority,
      );
    } catch (e) {
      debugPrint('Error sending notification to role: $e');
    }
  }
  
  // Send broadcast notification to all users
  Future<void> sendBroadcastNotification({
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
    NotificationType type = NotificationType.announcement,
    NotificationPriority priority = NotificationPriority.high,
  }) async {
    try {
      final allUserIds = await _getAllUserIds();
      await sendNotificationToUsers(
        userIds: allUserIds,
        title: title,
        body: body,
        imageUrl: imageUrl,
        data: data,
        type: type,
        priority: priority,
      );
    } catch (e) {
      debugPrint('Error sending broadcast notification: $e');
    }
  }
  
  // Get notifications for current user
  Future<List<NotificationModel>> getUserNotifications({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    try {
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        return [];
      }
      
      return await getNotificationsForUser(
        userId: currentUser.id,
        limit: limit,
        unreadOnly: unreadOnly,
      );
    } catch (e) {
      debugPrint('Error getting user notifications: $e');
      return [];
    }
  }
  
  // Get notifications for specific user
  Future<List<NotificationModel>> getNotificationsForUser({
    required String userId,
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final notificationKeys = allKeys.where((key) => key.startsWith('notification_')).toList();
      
      final notifications = <NotificationModel>[];
      
      for (final key in notificationKeys) {
        final notificationJson = prefs.getString(key);
        if (notificationJson != null) {
          final notificationMap = jsonDecode(notificationJson) as Map<String, dynamic>;
          final notification = NotificationModel.fromMap(
            notificationMap,
            key.substring('notification_'.length),
          );
          
          if (notification.userId == userId) {
            if (!unreadOnly || !notification.isRead) {
              notifications.add(notification);
            }
          }
        }
      }
      
      // Sort by creation date (newest first)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Apply limit
      if (notifications.length > limit) {
        return notifications.sublist(0, limit);
      }
      
      return notifications;
    } catch (e) {
      debugPrint('Error getting notifications for user: $e');
      return [];
    }
  }
  
  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final notification = await _getNotificationById(notificationId);
      if (notification != null) {
        final updatedNotification = notification.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        await _saveNotification(updatedNotification);
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
  
  // Mark all notifications as read for user
  Future<void> markAllNotificationsAsRead() async {
    try {
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        return;
      }
      
      final notifications = await getNotificationsForUser(
        userId: currentUser.id,
        unreadOnly: true,
      );
      
      for (final notification in notifications) {
        await markNotificationAsRead(notification.id);
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
  
  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notification_$notificationId');
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }
  
  // Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        return 0;
      }
      
      final unreadNotifications = await getNotificationsForUser(
        userId: currentUser.id,
        unreadOnly: true,
      );
      
      return unreadNotifications.length;
    } catch (e) {
      debugPrint('Error getting unread notification count: $e');
      return 0;
    }
  }
  
  // Notification Settings Management
  
  // Get notification settings for current user
  Future<NotificationSettings> getNotificationSettings() async {
    try {
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        return NotificationSettings.defaultSettings();
      }
      
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('notification_settings_${currentUser.id}');
      
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        return NotificationSettings.fromMap(settingsMap);
      }
      
      return NotificationSettings.defaultSettings();
    } catch (e) {
      debugPrint('Error getting notification settings: $e');
      return NotificationSettings.defaultSettings();
    }
  }
  
  // Update notification settings
  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    try {
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'notification_settings_${currentUser.id}',
        jsonEncode(settings.toMap()),
      );
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
    }
  }
  
  // Automated Notifications
  
  // Send fee due reminder
  Future<void> sendFeeDueReminder({
    required String studentId,
    required String studentName,
    required String feeTitle,
    required double amount,
    required DateTime dueDate,
  }) async {
    try {
      final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
      String title, body;
      
      if (daysUntilDue > 0) {
        title = 'Fee Payment Reminder';
        body = '$feeTitle of PKR ${amount.toStringAsFixed(0)} is due in $daysUntilDue days';
      } else if (daysUntilDue == 0) {
        title = 'Fee Payment Due Today';
        body = '$feeTitle of PKR ${amount.toStringAsFixed(0)} is due today';
      } else {
        title = 'Overdue Fee Payment';
        body = '$feeTitle of PKR ${amount.toStringAsFixed(0)} is ${-daysUntilDue} days overdue';
      }
      
      await sendNotificationToUser(
        userId: studentId,
        title: title,
        body: body,
        type: NotificationType.feeReminder,
        priority: daysUntilDue <= 0 ? NotificationPriority.high : NotificationPriority.normal,
        data: {
          'feeTitle': feeTitle,
          'amount': amount,
          'dueDate': dueDate.toIso8601String(),
          'studentName': studentName,
        },
      );
    } catch (e) {
      debugPrint('Error sending fee due reminder: $e');
    }
  }
  
  // Send exam reminder
  Future<void> sendExamReminder({
    required String studentId,
    required String examTitle,
    required DateTime examDate,
    required String subject,
  }) async {
    try {
      final daysUntilExam = examDate.difference(DateTime.now()).inDays;
      
      await sendNotificationToUser(
        userId: studentId,
        title: 'Exam Reminder',
        body: '$subject exam ($examTitle) is scheduled in $daysUntilExam days',
        type: NotificationType.examReminder,
        priority: NotificationPriority.normal,
        data: {
          'examTitle': examTitle,
          'examDate': examDate.toIso8601String(),
          'subject': subject,
        },
      );
    } catch (e) {
      debugPrint('Error sending exam reminder: $e');
    }
  }
  
  // Send assignment reminder
  Future<void> sendAssignmentReminder({
    required String studentId,
    required String assignmentTitle,
    required DateTime dueDate,
    required String subject,
  }) async {
    try {
      final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
      
      await sendNotificationToUser(
        userId: studentId,
        title: 'Assignment Due Soon',
        body: '$subject assignment "$assignmentTitle" is due in $daysUntilDue days',
        type: NotificationType.assignmentReminder,
        priority: NotificationPriority.normal,
        data: {
          'assignmentTitle': assignmentTitle,
          'dueDate': dueDate.toIso8601String(),
          'subject': subject,
        },
      );
    } catch (e) {
      debugPrint('Error sending assignment reminder: $e');
    }
  }
  
  // Helper Methods
  
  Future<void> _initializeLocalNotifications() async {
    // Initialize local notification system
    // In a real app, this would set up Firebase Cloud Messaging
  }
  
  Future<void> _loadNotificationSettings() async {
    // Load notification settings
  }
  
  Future<void> _saveNotification(NotificationModel notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'notification_${notification.id}',
        jsonEncode(notification.toMap()),
      );
    } catch (e) {
      debugPrint('Error saving notification: $e');
    }
  }
  
  Future<NotificationModel?> _getNotificationById(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationJson = prefs.getString('notification_$notificationId');
      
      if (notificationJson != null) {
        final notificationMap = jsonDecode(notificationJson) as Map<String, dynamic>;
        return NotificationModel.fromMap(notificationMap, notificationId);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting notification by ID: $e');
      return null;
    }
  }
  
  Future<void> _simulateNotificationDelivery(NotificationModel notification) async {
    // Simulate notification delivery
    // In a real app, this would send via FCM
    
    // Update delivery status
    final updatedNotification = notification.copyWith(
      isDelivered: true,
      deliveredAt: DateTime.now(),
    );
    
    await _saveNotification(updatedNotification);
  }
  
  Future<List<String>> _getUserIdsByRole(String role) async {
    // In a real app, this would query the user database
    // For now, return demo user IDs
    switch (role) {
      case 'student':
        return ['student_1', 'student_2', 'student_3'];
      case 'teacher':
        return ['teacher_1', 'teacher_2'];
      case 'admin':
        return ['admin_1'];
      default:
        return [];
    }
  }
  
  Future<List<String>> _getAllUserIds() async {
    // In a real app, this would get all user IDs from database
    return ['student_1', 'student_2', 'student_3', 'teacher_1', 'teacher_2', 'admin_1'];
  }
  
  // Cleanup old notifications
  Future<void> cleanupOldNotifications({int daysToKeep = 30}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final notificationKeys = allKeys.where((key) => key.startsWith('notification_')).toList();
      
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      for (final key in notificationKeys) {
        final notificationJson = prefs.getString(key);
        if (notificationJson != null) {
          final notificationMap = jsonDecode(notificationJson) as Map<String, dynamic>;
          final createdAt = DateTime.parse(notificationMap['createdAt']);
          
          if (createdAt.isBefore(cutoffDate)) {
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old notifications: $e');
    }
  }
}

// Notification Model
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;
  final bool isDelivered;
  final DateTime? deliveredAt;
  
  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.data,
    required this.type,
    required this.priority,
    required this.createdAt,
    required this.isRead,
    this.readAt,
    required this.isDelivered,
    this.deliveredAt,
  });
  
  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      imageUrl: map['imageUrl'],
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      type: NotificationType.values.firstWhere(
        (t) => t.toString().split('.').last == map['type'],
        orElse: () => NotificationType.general,
      ),
      priority: NotificationPriority.values.firstWhere(
        (p) => p.toString().split('.').last == map['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      isRead: map['isRead'] ?? false,
      readAt: map['readAt'] != null ? DateTime.parse(map['readAt']) : null,
      isDelivered: map['isDelivered'] ?? false,
      deliveredAt: map['deliveredAt'] != null ? DateTime.parse(map['deliveredAt']) : null,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'isDelivered': isDelivered,
      'deliveredAt': deliveredAt?.toIso8601String(),
    };
  }
  
  NotificationModel copyWith({
    String? userId,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? createdAt,
    bool? isRead,
    DateTime? readAt,
    bool? isDelivered,
    DateTime? deliveredAt,
  }) {
    return NotificationModel(
      id: id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      isDelivered: isDelivered ?? this.isDelivered,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}

// Notification Settings
class NotificationSettings {
  final bool enablePushNotifications;
  final bool enableEmailNotifications;
  final bool enableSMSNotifications;
  final bool enableFeeReminders;
  final bool enableExamReminders;
  final bool enableAssignmentReminders;
  final bool enableAnnouncementNotifications;
  final bool enableGradeNotifications;
  final bool enableAttendanceNotifications;
  final String quietHoursStart;
  final String quietHoursEnd;
  final bool enableQuietHours;
  
  NotificationSettings({
    required this.enablePushNotifications,
    required this.enableEmailNotifications,
    required this.enableSMSNotifications,
    required this.enableFeeReminders,
    required this.enableExamReminders,
    required this.enableAssignmentReminders,
    required this.enableAnnouncementNotifications,
    required this.enableGradeNotifications,
    required this.enableAttendanceNotifications,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.enableQuietHours,
  });
  
  factory NotificationSettings.defaultSettings() {
    return NotificationSettings(
      enablePushNotifications: true,
      enableEmailNotifications: true,
      enableSMSNotifications: false,
      enableFeeReminders: true,
      enableExamReminders: true,
      enableAssignmentReminders: true,
      enableAnnouncementNotifications: true,
      enableGradeNotifications: true,
      enableAttendanceNotifications: true,
      quietHoursStart: '22:00',
      quietHoursEnd: '08:00',
      enableQuietHours: true,
    );
  }
  
  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      enablePushNotifications: map['enablePushNotifications'] ?? true,
      enableEmailNotifications: map['enableEmailNotifications'] ?? true,
      enableSMSNotifications: map['enableSMSNotifications'] ?? false,
      enableFeeReminders: map['enableFeeReminders'] ?? true,
      enableExamReminders: map['enableExamReminders'] ?? true,
      enableAssignmentReminders: map['enableAssignmentReminders'] ?? true,
      enableAnnouncementNotifications: map['enableAnnouncementNotifications'] ?? true,
      enableGradeNotifications: map['enableGradeNotifications'] ?? true,
      enableAttendanceNotifications: map['enableAttendanceNotifications'] ?? true,
      quietHoursStart: map['quietHoursStart'] ?? '22:00',
      quietHoursEnd: map['quietHoursEnd'] ?? '08:00',
      enableQuietHours: map['enableQuietHours'] ?? true,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'enablePushNotifications': enablePushNotifications,
      'enableEmailNotifications': enableEmailNotifications,
      'enableSMSNotifications': enableSMSNotifications,
      'enableFeeReminders': enableFeeReminders,
      'enableExamReminders': enableExamReminders,
      'enableAssignmentReminders': enableAssignmentReminders,
      'enableAnnouncementNotifications': enableAnnouncementNotifications,
      'enableGradeNotifications': enableGradeNotifications,
      'enableAttendanceNotifications': enableAttendanceNotifications,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'enableQuietHours': enableQuietHours,
    };
  }
}

enum NotificationType {
  general,
  announcement,
  feeReminder,
  examReminder,
  assignmentReminder,
  gradeUpdate,
  attendanceAlert,
  emergencyAlert,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}
