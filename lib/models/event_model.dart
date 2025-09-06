import 'package:flutter/material.dart';

/// Represents the type of event
enum EventType {
  applicationDeadline,
  documentDeadline,
  interview,
  orientation,
  registration,
  exam,
  result,
  other
}

/// Represents the priority level of an event
enum EventPriority {
  low,
  medium,
  high,
  urgent
}

/// Model for an event in the calendar system
class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isAllDay;
  final EventType type;
  final EventPriority priority;
  final String? location;
  final String? applicationId;
  final String? programId;
  final bool isCompleted;
  final String? userId;
  final bool hasReminder;
  final Duration? reminderBefore;
  final List<String>? attendees;
  final Map<String, dynamic>? additionalInfo;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    this.isAllDay = false,
    required this.type,
    required this.priority,
    this.location,
    this.applicationId,
    this.programId,
    this.isCompleted = false,
    this.userId,
    this.hasReminder = true,
    this.reminderBefore = const Duration(days: 1),
    this.attendees,
    this.additionalInfo,
  });

  /// Create a copy of this event with updated fields
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAllDay,
    EventType? type,
    EventPriority? priority,
    String? location,
    String? applicationId,
    String? programId,
    bool? isCompleted,
    String? userId,
    bool? hasReminder,
    Duration? reminderBefore,
    List<String>? attendees,
    Map<String, dynamic>? additionalInfo,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isAllDay: isAllDay ?? this.isAllDay,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      location: location ?? this.location,
      applicationId: applicationId ?? this.applicationId,
      programId: programId ?? this.programId,
      isCompleted: isCompleted ?? this.isCompleted,
      userId: userId ?? this.userId,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderBefore: reminderBefore ?? this.reminderBefore,
      attendees: attendees ?? this.attendees,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  /// Get the icon for this event type
  IconData get typeIcon {
    switch (type) {
      case EventType.applicationDeadline:
        return Icons.assignment_late;
      case EventType.documentDeadline:
        return Icons.description;
      case EventType.interview:
        return Icons.people;
      case EventType.orientation:
        return Icons.school;
      case EventType.registration:
        return Icons.app_registration;
      case EventType.exam:
        return Icons.quiz;
      case EventType.result:
        return Icons.grading;
      case EventType.other:
        return Icons.event;
    }
  }

  /// Get the color for this event's priority
  Color get priorityColor {
    switch (priority) {
      case EventPriority.low:
        return Colors.green;
      case EventPriority.medium:
        return Colors.blue;
      case EventPriority.high:
        return Colors.orange;
      case EventPriority.urgent:
        return Colors.red;
    }
  }

  /// Get a human-readable priority text
  String get priorityText {
    switch (priority) {
      case EventPriority.low:
        return 'Low Priority';
      case EventPriority.medium:
        return 'Medium Priority';
      case EventPriority.high:
        return 'High Priority';
      case EventPriority.urgent:
        return 'Urgent';
    }
  }

  /// Get a human-readable event type
  String get typeText {
    switch (type) {
      case EventType.applicationDeadline:
        return 'Application Deadline';
      case EventType.documentDeadline:
        return 'Document Deadline';
      case EventType.interview:
        return 'Interview';
      case EventType.orientation:
        return 'Orientation';
      case EventType.registration:
        return 'Registration';
      case EventType.exam:
        return 'Exam';
      case EventType.result:
        return 'Result';
      case EventType.other:
        return 'Other Event';
    }
  }

  /// Check if the event is due soon (within the next 3 days)
  bool get isDueSoon {
    final now = DateTime.now();
    final difference = startDate.difference(now).inDays;
    return difference >= 0 && difference <= 3;
  }

  /// Check if the event is overdue
  bool get isOverdue {
    final now = DateTime.now();
    return startDate.isBefore(now) && !isCompleted;
  }

  /// Format the event date for display
  String get formattedDate {
    if (isAllDay) {
      return '${startDate.day}/${startDate.month}/${startDate.year} (All day)';
    }
    
    if (endDate != null) {
      return '${startDate.day}/${startDate.month}/${startDate.year} ${startDate.hour}:${startDate.minute.toString().padLeft(2, '0')} - '
          '${endDate!.hour}:${endDate!.minute.toString().padLeft(2, '0')}';
    }
    
    return '${startDate.day}/${startDate.month}/${startDate.year} ${startDate.hour}:${startDate.minute.toString().padLeft(2, '0')}';
  }

  /// Get the reminder time
  DateTime? get reminderTime {
    if (!hasReminder || reminderBefore == null) return null;
    return startDate.subtract(reminderBefore!);
  }
}
