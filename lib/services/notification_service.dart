import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../services/auth_service.dart';

class NotificationService {
  // Notification prefix for SharedPreferences keys
  static const String _notificationPrefix = 'notification_';
  
  // School-specific notification types
  static const String typeGeneral = 'general';
  static const String typeAssignment = 'assignment';
  static const String typeGrade = 'grade';
  static const String typeAttendance = 'attendance';
  static const String typeFee = 'fee';
  static const String typeTimetable = 'timetable';
  static const String typeAnnouncement = 'announcement';
  static const String typeExam = 'exam';
  static const String typeEmergency = 'emergency';
  
  // Get all notifications for current user
  Future<List<NotificationModel>> getUserNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Check if we have any notifications stored
      final notificationsJson = prefs.getString('${_notificationPrefix}${currentUser.id}_list');
      
      // If no notifications exist, create sample notifications
      if (notificationsJson == null) {
        await _createSampleNotifications(currentUser.id);
      }
      
      // Get all notification IDs for current user
      final notificationIds = prefs.getStringList('${_notificationPrefix}${currentUser.id}_list') ?? [];
      
      // Get notifications
      final notifications = <NotificationModel>[];
      for (final id in notificationIds) {
        final notification = await getNotificationById(id);
        if (notification != null) {
          notifications.add(notification);
        }
      }
      
      // Sort by creation date (newest first)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return notifications;
    } catch (e) {
      debugPrint('Error getting user notifications: $e');
      return [];
    }
  }
  
  // Get notification by ID
  Future<NotificationModel?> getNotificationById(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get notification from SharedPreferences
      final notificationJson = prefs.getString('${_notificationPrefix}$notificationId');
      if (notificationJson == null) {
        return null;
      }
      
      // Parse notification
      final notificationMap = jsonDecode(notificationJson) as Map<String, dynamic>;
      return NotificationModel.fromMap(notificationMap, notificationId);
    } catch (e) {
      debugPrint('Error getting notification: $e');
      return null;
    }
  }
  
  // Create a new notification
  Future<NotificationModel> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generate a new notification ID
      final notificationId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create notification model
      final notification = NotificationModel(
        id: notificationId,
        userId: userId,
        title: title,
        message: message,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
        data: data,
      );
      
      // Save notification to SharedPreferences
      await prefs.setString('${_notificationPrefix}$notificationId', jsonEncode(notification.toMap()));
      
      // Add notification ID to user's notification list
      final notificationIds = prefs.getStringList('${_notificationPrefix}${userId}_list') ?? [];
      notificationIds.add(notificationId);
      await prefs.setStringList('${_notificationPrefix}${userId}_list', notificationIds);
      
      return notification;
    } catch (e) {
      debugPrint('Error creating notification: $e');
      rethrow;
    }
  }
  
  // Mark notification as read
  Future<NotificationModel> markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get notification from SharedPreferences
      final notificationJson = prefs.getString('${_notificationPrefix}$notificationId');
      if (notificationJson == null) {
        throw Exception('Notification not found');
      }
      
      // Parse notification
      final notificationMap = jsonDecode(notificationJson) as Map<String, dynamic>;
      final notification = NotificationModel.fromMap(notificationMap, notificationId);
      
      // Update notification
      final updatedNotification = notification.copyWith(
        isRead: true,
      );
      
      // Save updated notification to SharedPreferences
      await prefs.setString('${_notificationPrefix}$notificationId', jsonEncode(updatedNotification.toMap()));
      
      return updatedNotification;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all notification IDs for user
      final notificationIds = prefs.getStringList('${_notificationPrefix}${userId}_list') ?? [];
      
      // Mark each notification as read
      for (final id in notificationIds) {
        await markAsRead(id);
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }
  
  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get notification from SharedPreferences
      final notificationJson = prefs.getString('${_notificationPrefix}$notificationId');
      if (notificationJson == null) {
        return;
      }
      
      // Parse notification
      final notificationMap = jsonDecode(notificationJson) as Map<String, dynamic>;
      final notification = NotificationModel.fromMap(notificationMap, notificationId);
      
      // Remove notification from SharedPreferences
      await prefs.remove('${_notificationPrefix}$notificationId');
      
      // Remove notification ID from user's notification list
      final notificationIds = prefs.getStringList('${_notificationPrefix}${notification.userId}_list') ?? [];
      notificationIds.remove(notificationId);
      await prefs.setStringList('${_notificationPrefix}${notification.userId}_list', notificationIds);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }
  
  // Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final notifications = await getUserNotifications();
      return notifications.where((notification) => !notification.isRead).length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }
  
  // Create sample school notifications for testing
  Future<void> _createSampleNotifications(String userId) async {
    try {
      // Create sample school notifications
      await createNotification(
        userId: userId,
        title: 'New Assignment Posted',
        message: 'Mathematics Assignment #3 has been posted. Due date: March 15, 2025',
        type: typeAssignment,
        data: {
          'assignmentId': 'math_003',
          'subject': 'Mathematics',
          'dueDate': '2025-03-15',
        },
      );
      
      await createNotification(
        userId: userId,
        title: 'Grade Updated',
        message: 'Your Physics Quiz grade has been updated: A- (87%)',
        type: typeGrade,
        data: {
          'subject': 'Physics',
          'grade': 'A-',
          'percentage': 87,
        },
      );
      
      await createNotification(
        userId: userId,
        title: 'Attendance Alert',
        message: 'Your attendance is below 75%. Please contact your class teacher.',
        type: typeAttendance,
        data: {
          'attendancePercentage': 72,
        },
      );
      
      await createNotification(
        userId: userId,
        title: 'Fee Payment Reminder',
        message: 'Monthly fee payment is due on March 10, 2025. Amount: PKR 15,000',
        type: typeFee,
        data: {
          'amount': 15000,
          'dueDate': '2025-03-10',
          'currency': 'PKR',
        },
      );
      
      await createNotification(
        userId: userId,
        title: 'Timetable Updated',
        message: 'Class 9-A timetable has been updated. Chemistry lab moved to Friday.',
        type: typeTimetable,
        data: {
          'className': 'Class 9-A',
          'changes': 'Chemistry lab moved to Friday',
        },
      );
      
      await createNotification(
        userId: userId,
        title: 'School Announcement',
        message: 'Parent-Teacher meeting scheduled for March 20, 2025 at 2:00 PM',
        type: typeAnnouncement,
        data: {
          'eventDate': '2025-03-20',
          'eventTime': '14:00',
        },
      );
    } catch (e) {
      debugPrint('Error creating sample notifications: $e');
    }
  }
  
  // Helper methods for creating specific notification types
  Future<NotificationModel> createAssignmentNotification({
    required String userId,
    required String assignmentTitle,
    required String subject,
    required DateTime dueDate,
    String? assignmentId,
  }) async {
    return await createNotification(
      userId: userId,
      title: 'New Assignment: $assignmentTitle',
      message: '$subject assignment posted. Due: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
      type: typeAssignment,
      data: {
        'assignmentId': assignmentId,
        'subject': subject,
        'dueDate': dueDate.toIso8601String(),
      },
    );
  }
  
  Future<NotificationModel> createGradeNotification({
    required String userId,
    required String subject,
    required String grade,
    required double percentage,
    String? assessmentType,
  }) async {
    return await createNotification(
      userId: userId,
      title: 'Grade Posted: $subject',
      message: '${assessmentType ?? 'Assessment'} grade: $grade (${percentage.toStringAsFixed(1)}%)',
      type: typeGrade,
      data: {
        'subject': subject,
        'grade': grade,
        'percentage': percentage,
        'assessmentType': assessmentType,
      },
    );
  }
  
  Future<NotificationModel> createFeeReminderNotification({
    required String userId,
    required double amount,
    required DateTime dueDate,
    String feeType = 'Monthly Fee',
  }) async {
    return await createNotification(
      userId: userId,
      title: 'Fee Payment Reminder',
      message: '$feeType payment due: PKR ${amount.toStringAsFixed(0)} by ${dueDate.day}/${dueDate.month}/${dueDate.year}',
      type: typeFee,
      data: {
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'feeType': feeType,
        'currency': 'PKR',
      },
    );
  }
  
  Future<NotificationModel> createAnnouncementNotification({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? eventData,
  }) async {
    return await createNotification(
      userId: userId,
      title: title,
      message: message,
      type: typeAnnouncement,
      data: eventData,
    );
  }
}
