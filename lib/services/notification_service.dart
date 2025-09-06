import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../services/auth_service.dart';

class NotificationService {
  // Notification prefix for SharedPreferences keys
  static const String _notificationPrefix = 'notification_';
  
  // Notification types
  static const String typeGeneral = 'general';
  static const String typeApplication = 'application';
  static const String typeProgram = 'program';
  static const String typeMessage = 'message';
  
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
  
  // Create sample notifications for testing
  Future<void> _createSampleNotifications(String userId) async {
    try {
      // Create sample notifications
      await createNotification(
        userId: userId,
        title: 'Welcome to EduCyp',
        message: 'Thank you for joining EduCyp. We\'re excited to help you find the perfect educational program in Cyprus.',
        type: typeGeneral,
      );
      
      await createNotification(
        userId: userId,
        title: 'New Programs Available',
        message: 'Check out the new educational programs that have been added to our platform.',
        type: typeProgram,
        data: {
          'programId': '1',
        },
      );
      
      await createNotification(
        userId: userId,
        title: 'Application Status Updated',
        message: 'Your application status has been updated. Click to view details.',
        type: typeApplication,
        data: {
          'applicationId': '1',
        },
      );
      
      await createNotification(
        userId: userId,
        title: 'New Message',
        message: 'You have received a new message from the admissions team.',
        type: typeMessage,
        data: {
          'conversationId': '1',
        },
      );
    } catch (e) {
      debugPrint('Error creating sample notifications: $e');
    }
  }
}
