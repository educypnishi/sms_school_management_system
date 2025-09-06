import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/calendar_service.dart';
import '../services/notification_service.dart';

/// Service to manage calendar event notifications
class CalendarNotificationService {
  final CalendarService _calendarService = CalendarService();
  final NotificationService _notificationService = NotificationService();
  
  // Notification types for calendar events
  static const String typeDeadline = 'deadline';
  static const String typeReminder = 'reminder';
  static const String typeEventUpdate = 'event_update';
  
  /// Check for events that need reminders and create notifications
  Future<void> checkAndCreateReminders(String userId) async {
    try {
      // Get events that need reminders
      final events = await _calendarService.getEventsNeedingReminders();
      
      // Create notifications for each event
      for (final event in events) {
        await _createReminderNotification(userId, event);
      }
    } catch (e) {
      debugPrint('Error checking for reminders: $e');
    }
  }
  
  /// Create a reminder notification for an event
  Future<void> _createReminderNotification(String userId, EventModel event) async {
    try {
      // Create notification
      await _notificationService.createNotification(
        userId: userId,
        title: 'Reminder: ${event.title}',
        message: _getReminderMessage(event),
        type: typeReminder,
        data: {
          'eventId': event.id,
          'eventType': event.type.toString(),
          'startDate': event.startDate.toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error creating reminder notification: $e');
    }
  }
  
  /// Create a deadline notification for an event
  Future<void> createDeadlineNotification(String userId, EventModel event) async {
    try {
      // Create notification
      await _notificationService.createNotification(
        userId: userId,
        title: 'Deadline: ${event.title}',
        message: _getDeadlineMessage(event),
        type: typeDeadline,
        data: {
          'eventId': event.id,
          'eventType': event.type.toString(),
          'startDate': event.startDate.toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error creating deadline notification: $e');
    }
  }
  
  /// Create an event update notification
  Future<void> createEventUpdateNotification(String userId, EventModel event, String updateType) async {
    try {
      // Create notification
      await _notificationService.createNotification(
        userId: userId,
        title: 'Event Update: ${event.title}',
        message: _getEventUpdateMessage(event, updateType),
        type: typeEventUpdate,
        data: {
          'eventId': event.id,
          'eventType': event.type.toString(),
          'startDate': event.startDate.toIso8601String(),
          'updateType': updateType,
        },
      );
    } catch (e) {
      debugPrint('Error creating event update notification: $e');
    }
  }
  
  /// Get the reminder message for an event
  String _getReminderMessage(EventModel event) {
    final formattedDate = _formatDate(event.startDate);
    
    switch (event.type) {
      case EventType.applicationDeadline:
        return 'Your application deadline is approaching on $formattedDate. Don\'t forget to submit your application!';
      case EventType.documentDeadline:
        return 'Your document submission deadline is approaching on $formattedDate. Make sure to upload all required documents.';
      case EventType.interview:
        return 'You have an interview scheduled on $formattedDate. Make sure to prepare!';
      case EventType.orientation:
        return 'Orientation is scheduled on $formattedDate. Don\'t miss it!';
      case EventType.registration:
        return 'Course registration deadline is approaching on $formattedDate. Make sure to register for your courses.';
      case EventType.exam:
        return 'You have an exam scheduled on $formattedDate. Good luck!';
      case EventType.result:
        return 'Results will be announced on $formattedDate. Stay tuned!';
      case EventType.other:
        return 'You have an upcoming event on $formattedDate: ${event.title}';
    }
  }
  
  /// Get the deadline message for an event
  String _getDeadlineMessage(EventModel event) {
    final formattedDate = _formatDate(event.startDate);
    
    switch (event.type) {
      case EventType.applicationDeadline:
        return 'Today is the deadline for your application! Make sure to submit before the end of the day.';
      case EventType.documentDeadline:
        return 'Today is the deadline for document submission! Make sure to upload all required documents.';
      case EventType.interview:
        return 'Your interview is today at ${_formatTime(event.startDate)}. Don\'t be late!';
      case EventType.orientation:
        return 'Orientation is today at ${_formatTime(event.startDate)}. Don\'t miss it!';
      case EventType.registration:
        return 'Today is the course registration deadline! Make sure to register before the end of the day.';
      case EventType.exam:
        return 'Your exam is today at ${_formatTime(event.startDate)}. Good luck!';
      case EventType.result:
        return 'Results will be announced today at ${_formatTime(event.startDate)}. Stay tuned!';
      case EventType.other:
        return 'Your event "${event.title}" is today at ${_formatTime(event.startDate)}.';
    }
  }
  
  /// Get the event update message
  String _getEventUpdateMessage(EventModel event, String updateType) {
    final formattedDate = _formatDate(event.startDate);
    
    switch (updateType) {
      case 'rescheduled':
        return 'Your event "${event.title}" has been rescheduled to $formattedDate.';
      case 'cancelled':
        return 'Your event "${event.title}" scheduled for $formattedDate has been cancelled.';
      case 'location_changed':
        return 'The location for your event "${event.title}" on $formattedDate has been changed to ${event.location}.';
      case 'completed':
        return 'Your event "${event.title}" has been marked as completed.';
      default:
        return 'Your event "${event.title}" scheduled for $formattedDate has been updated.';
    }
  }
  
  /// Format a date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  /// Format a time for display
  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
