import 'package:flutter/material.dart';

/// Represents the type of calendar event
enum EventType {
  application,
  program,
  academic,
  personal
}

/// Represents the priority of calendar event
enum EventPriority {
  low,
  medium,
  high
}

/// Model for a calendar event
class CalendarEventModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isAllDay;
  final EventType type;
  final EventPriority priority;
  final String userId;
  final String? relatedItemId;
  final bool isCompleted;
  final Color? color;
  final bool hasReminder;
  final int reminderMinutesBefore;

  CalendarEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    this.isAllDay = false,
    required this.type,
    this.priority = EventPriority.medium,
    required this.userId,
    this.relatedItemId,
    this.isCompleted = false,
    this.color,
    this.hasReminder = false,
    this.reminderMinutesBefore = 60,
  });

  /// Create a CalendarEventModel from a map
  factory CalendarEventModel.fromMap(Map<String, dynamic> map, String id) {
    return CalendarEventModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startDate: map['startDate'] != null 
          ? DateTime.parse(map['startDate']) 
          : DateTime.now(),
      endDate: map['endDate'] != null 
          ? DateTime.parse(map['endDate']) 
          : null,
      isAllDay: map['isAllDay'] ?? false,
      type: _parseEventType(map['type']),
      priority: _parseEventPriority(map['priority']),
      userId: map['userId'] ?? '',
      relatedItemId: map['relatedItemId'],
      isCompleted: map['isCompleted'] ?? false,
      color: map['color'] != null ? Color(map['color']) : null,
      hasReminder: map['hasReminder'] ?? false,
      reminderMinutesBefore: map['reminderMinutesBefore'] ?? 60,
    );
  }

  /// Convert CalendarEventModel to a map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isAllDay': isAllDay,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'userId': userId,
      'relatedItemId': relatedItemId,
      'isCompleted': isCompleted,
      'color': color?.value,
      'hasReminder': hasReminder,
      'reminderMinutesBefore': reminderMinutesBefore,
    };
  }

  /// Create a copy of CalendarEventModel with some fields changed
  CalendarEventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isAllDay,
    EventType? type,
    EventPriority? priority,
    String? userId,
    String? relatedItemId,
    bool? isCompleted,
    Color? color,
    bool? hasReminder,
    int? reminderMinutesBefore,
  }) {
    return CalendarEventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isAllDay: isAllDay ?? this.isAllDay,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId,
      relatedItemId: relatedItemId ?? this.relatedItemId,
      isCompleted: isCompleted ?? this.isCompleted,
      color: color ?? this.color,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
    );
  }

  /// Parse EventType from string
  static EventType _parseEventType(String? value) {
    if (value == null) return EventType.personal;
    
    switch (value.toLowerCase()) {
      case 'application':
        return EventType.application;
      case 'program':
        return EventType.program;
      case 'academic':
        return EventType.academic;
      case 'personal':
      default:
        return EventType.personal;
    }
  }

  /// Parse EventPriority from string
  static EventPriority _parseEventPriority(String? value) {
    if (value == null) return EventPriority.medium;
    
    switch (value.toLowerCase()) {
      case 'high':
        return EventPriority.high;
      case 'low':
        return EventPriority.low;
      case 'medium':
      default:
        return EventPriority.medium;
    }
  }

  /// Get color based on event type
  Color getEventTypeColor() {
    if (color != null) return color!;
    
    switch (type) {
      case EventType.application:
        return Colors.blue;
      case EventType.program:
        return Colors.green;
      case EventType.academic:
        return Colors.orange;
      case EventType.personal:
        return Colors.purple;
    }
  }

  /// Get color based on event priority
  Color getEventPriorityColor() {
    switch (priority) {
      case EventPriority.high:
        return Colors.red;
      case EventPriority.low:
        return Colors.green;
      case EventPriority.medium:
        return Colors.orange;
    }
  }

  /// Format date range for display
  String getFormattedDateRange() {
    if (isAllDay && endDate == null) {
      return '${startDate.day}/${startDate.month}/${startDate.year} (All day)';
    } else if (isAllDay && endDate != null) {
      return '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate!.day}/${endDate!.month}/${endDate!.year} (All day)';
    } else if (endDate == null) {
      return '${startDate.day}/${startDate.month}/${startDate.year} ${startDate.hour}:${startDate.minute.toString().padLeft(2, '0')}';
    } else {
      return '${startDate.day}/${startDate.month}/${startDate.year} ${startDate.hour}:${startDate.minute.toString().padLeft(2, '0')} - ${endDate!.day}/${endDate!.month}/${endDate!.year} ${endDate!.hour}:${endDate!.minute.toString().padLeft(2, '0')}';
    }
  }
}
