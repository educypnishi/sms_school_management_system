import 'package:flutter/material.dart';

/// Represents the possible statuses of a student application
enum ApplicationStatusType {
  submitted,
  reviewing,
  documentVerification,
  interview,
  decision,
  completed
}

/// Represents a milestone in the application process
class ApplicationMilestone {
  final String title;
  final String description;
  final DateTime? date;
  final bool isCompleted;
  final IconData icon;

  ApplicationMilestone({
    required this.title,
    required this.description,
    this.date,
    required this.isCompleted,
    required this.icon,
  });
}

/// Model for tracking the status of a student application
class ApplicationStatus {
  final String applicationId;
  final ApplicationStatusType currentStatus;
  final List<ApplicationMilestone> milestones;
  final DateTime submissionDate;
  final DateTime? estimatedCompletionDate;
  final String? assignedTo;
  final String? feedback;

  ApplicationStatus({
    required this.applicationId,
    required this.currentStatus,
    required this.milestones,
    required this.submissionDate,
    this.estimatedCompletionDate,
    this.assignedTo,
    this.feedback,
  });

  /// Calculate the progress percentage based on completed milestones
  double get progressPercentage {
    if (milestones.isEmpty) return 0.0;
    
    int completedCount = milestones.where((m) => m.isCompleted).length;
    return completedCount / milestones.length;
  }

  /// Get the next pending milestone
  ApplicationMilestone? get nextMilestone {
    for (var milestone in milestones) {
      if (!milestone.isCompleted) {
        return milestone;
      }
    }
    return null;
  }

  /// Create a copy of this status with updated fields
  ApplicationStatus copyWith({
    String? applicationId,
    ApplicationStatusType? currentStatus,
    List<ApplicationMilestone>? milestones,
    DateTime? submissionDate,
    DateTime? estimatedCompletionDate,
    String? assignedTo,
    String? feedback,
  }) {
    return ApplicationStatus(
      applicationId: applicationId ?? this.applicationId,
      currentStatus: currentStatus ?? this.currentStatus,
      milestones: milestones ?? this.milestones,
      submissionDate: submissionDate ?? this.submissionDate,
      estimatedCompletionDate: estimatedCompletionDate ?? this.estimatedCompletionDate,
      assignedTo: assignedTo ?? this.assignedTo,
      feedback: feedback ?? this.feedback,
    );
  }

  /// Get a human-readable status text
  String get statusText {
    switch (currentStatus) {
      case ApplicationStatusType.submitted:
        return 'Application Submitted';
      case ApplicationStatusType.reviewing:
        return 'Under Review';
      case ApplicationStatusType.documentVerification:
        return 'Document Verification';
      case ApplicationStatusType.interview:
        return 'Interview Stage';
      case ApplicationStatusType.decision:
        return 'Decision Pending';
      case ApplicationStatusType.completed:
        return 'Application Completed';
    }
  }

  /// Get the color associated with the current status
  Color get statusColor {
    switch (currentStatus) {
      case ApplicationStatusType.submitted:
        return Colors.blue;
      case ApplicationStatusType.reviewing:
        return Colors.amber;
      case ApplicationStatusType.documentVerification:
        return Colors.orange;
      case ApplicationStatusType.interview:
        return Colors.purple;
      case ApplicationStatusType.decision:
        return Colors.deepOrange;
      case ApplicationStatusType.completed:
        return Colors.green;
    }
  }
}
