import 'package:flutter/material.dart';
import '../models/application_status_model.dart';

/// Service to manage application statuses and progress tracking
class ApplicationStatusService {
  // In a real app, this would be stored in Firebase or another database
  // For now, we'll use an in-memory map for demo purposes
  final Map<String, ApplicationStatus> _applicationStatuses = {};

  /// Get the status for a specific application
  Future<ApplicationStatus?> getApplicationStatus(String applicationId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _applicationStatuses[applicationId];
  }

  /// Get all application statuses
  Future<List<ApplicationStatus>> getAllApplicationStatuses() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _applicationStatuses.values.toList();
  }

  /// Update the status of an application
  Future<void> updateApplicationStatus(ApplicationStatus status) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    _applicationStatuses[status.applicationId] = status;
  }

  /// Create default milestones for a new application
  List<ApplicationMilestone> createDefaultMilestones() {
    return [
      ApplicationMilestone(
        title: 'Application Submitted',
        description: 'Your application has been received by our team.',
        date: DateTime.now(),
        isCompleted: true,
        icon: Icons.check_circle,
      ),
      ApplicationMilestone(
        title: 'Document Review',
        description: 'We are reviewing your submitted documents.',
        isCompleted: false,
        icon: Icons.description,
      ),
      ApplicationMilestone(
        title: 'Document Verification',
        description: 'Verifying the authenticity of your documents.',
        isCompleted: false,
        icon: Icons.verified,
      ),
      ApplicationMilestone(
        title: 'Interview',
        description: 'You will be contacted for an interview.',
        isCompleted: false,
        icon: Icons.people,
      ),
      ApplicationMilestone(
        title: 'Final Decision',
        description: 'Final decision on your application.',
        isCompleted: false,
        icon: Icons.gavel,
      ),
      ApplicationMilestone(
        title: 'Application Complete',
        description: 'Your application process is complete.',
        isCompleted: false,
        icon: Icons.celebration,
      ),
    ];
  }

  /// Create a new application status
  Future<ApplicationStatus> createApplicationStatus(String applicationId) async {
    final status = ApplicationStatus(
      applicationId: applicationId,
      currentStatus: ApplicationStatusType.submitted,
      milestones: createDefaultMilestones(),
      submissionDate: DateTime.now(),
      estimatedCompletionDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    await updateApplicationStatus(status);
    return status;
  }

  /// Update a milestone in the application status
  Future<ApplicationStatus> updateMilestone(
    String applicationId,
    int milestoneIndex,
    {
      bool? isCompleted,
      DateTime? date,
      String? description,
    }
  ) async {
    final status = _applicationStatuses[applicationId];
    if (status == null) {
      throw Exception('Application status not found');
    }

    final milestones = List<ApplicationMilestone>.from(status.milestones);
    final oldMilestone = milestones[milestoneIndex];
    
    milestones[milestoneIndex] = ApplicationMilestone(
      title: oldMilestone.title,
      description: description ?? oldMilestone.description,
      date: date ?? oldMilestone.date,
      isCompleted: isCompleted ?? oldMilestone.isCompleted,
      icon: oldMilestone.icon,
    );

    // Update the current status based on the milestone
    ApplicationStatusType newStatus = status.currentStatus;
    if (isCompleted == true) {
      switch (milestoneIndex) {
        case 0:
          newStatus = ApplicationStatusType.submitted;
          break;
        case 1:
          newStatus = ApplicationStatusType.reviewing;
          break;
        case 2:
          newStatus = ApplicationStatusType.documentVerification;
          break;
        case 3:
          newStatus = ApplicationStatusType.interview;
          break;
        case 4:
          newStatus = ApplicationStatusType.decision;
          break;
        case 5:
          newStatus = ApplicationStatusType.completed;
          break;
      }
    }

    final updatedStatus = status.copyWith(
      milestones: milestones,
      currentStatus: newStatus,
    );

    await updateApplicationStatus(updatedStatus);
    return updatedStatus;
  }

  /// Add feedback to an application
  Future<ApplicationStatus> addFeedback(
    String applicationId,
    String feedback,
  ) async {
    final status = _applicationStatuses[applicationId];
    if (status == null) {
      throw Exception('Application status not found');
    }

    final updatedStatus = status.copyWith(
      feedback: feedback,
    );

    await updateApplicationStatus(updatedStatus);
    return updatedStatus;
  }

  /// Assign an application to a partner or admin
  Future<ApplicationStatus> assignApplication(
    String applicationId,
    String assignedTo,
  ) async {
    final status = _applicationStatuses[applicationId];
    if (status == null) {
      throw Exception('Application status not found');
    }

    final updatedStatus = status.copyWith(
      assignedTo: assignedTo,
    );

    await updateApplicationStatus(updatedStatus);
    return updatedStatus;
  }

  /// Generate sample application statuses for demo purposes
  Future<void> generateSampleData() async {
    // Sample application 1 - In progress
    final app1 = ApplicationStatus(
      applicationId: 'APP001',
      currentStatus: ApplicationStatusType.reviewing,
      milestones: [
        ApplicationMilestone(
          title: 'Application Submitted',
          description: 'Your application has been received by our team.',
          date: DateTime.now().subtract(const Duration(days: 5)),
          isCompleted: true,
          icon: Icons.check_circle,
        ),
        ApplicationMilestone(
          title: 'Document Review',
          description: 'We are reviewing your submitted documents.',
          date: DateTime.now().subtract(const Duration(days: 2)),
          isCompleted: true,
          icon: Icons.description,
        ),
        ApplicationMilestone(
          title: 'Document Verification',
          description: 'Verifying the authenticity of your documents.',
          isCompleted: false,
          icon: Icons.verified,
        ),
        ApplicationMilestone(
          title: 'Interview',
          description: 'You will be contacted for an interview.',
          isCompleted: false,
          icon: Icons.people,
        ),
        ApplicationMilestone(
          title: 'Final Decision',
          description: 'Final decision on your application.',
          isCompleted: false,
          icon: Icons.gavel,
        ),
        ApplicationMilestone(
          title: 'Application Complete',
          description: 'Your application process is complete.',
          isCompleted: false,
          icon: Icons.celebration,
        ),
      ],
      submissionDate: DateTime.now().subtract(const Duration(days: 5)),
      estimatedCompletionDate: DateTime.now().add(const Duration(days: 25)),
      assignedTo: 'Partner University',
      feedback: 'Your application is being processed. We will contact you for an interview soon.',
    );
    
    // Sample application 2 - Just started
    final app2 = ApplicationStatus(
      applicationId: 'APP002',
      currentStatus: ApplicationStatusType.submitted,
      milestones: [
        ApplicationMilestone(
          title: 'Application Submitted',
          description: 'Your application has been received by our team.',
          date: DateTime.now().subtract(const Duration(days: 1)),
          isCompleted: true,
          icon: Icons.check_circle,
        ),
        ApplicationMilestone(
          title: 'Document Review',
          description: 'We are reviewing your submitted documents.',
          isCompleted: false,
          icon: Icons.description,
        ),
        ApplicationMilestone(
          title: 'Document Verification',
          description: 'Verifying the authenticity of your documents.',
          isCompleted: false,
          icon: Icons.verified,
        ),
        ApplicationMilestone(
          title: 'Interview',
          description: 'You will be contacted for an interview.',
          isCompleted: false,
          icon: Icons.people,
        ),
        ApplicationMilestone(
          title: 'Final Decision',
          description: 'Final decision on your application.',
          isCompleted: false,
          icon: Icons.gavel,
        ),
        ApplicationMilestone(
          title: 'Application Complete',
          description: 'Your application process is complete.',
          isCompleted: false,
          icon: Icons.celebration,
        ),
      ],
      submissionDate: DateTime.now().subtract(const Duration(days: 1)),
      estimatedCompletionDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    // Sample application 3 - Completed
    final app3 = ApplicationStatus(
      applicationId: 'APP003',
      currentStatus: ApplicationStatusType.completed,
      milestones: [
        ApplicationMilestone(
          title: 'Application Submitted',
          description: 'Your application has been received by our team.',
          date: DateTime.now().subtract(const Duration(days: 30)),
          isCompleted: true,
          icon: Icons.check_circle,
        ),
        ApplicationMilestone(
          title: 'Document Review',
          description: 'We are reviewing your submitted documents.',
          date: DateTime.now().subtract(const Duration(days: 25)),
          isCompleted: true,
          icon: Icons.description,
        ),
        ApplicationMilestone(
          title: 'Document Verification',
          description: 'Verifying the authenticity of your documents.',
          date: DateTime.now().subtract(const Duration(days: 20)),
          isCompleted: true,
          icon: Icons.verified,
        ),
        ApplicationMilestone(
          title: 'Interview',
          description: 'You will be contacted for an interview.',
          date: DateTime.now().subtract(const Duration(days: 15)),
          isCompleted: true,
          icon: Icons.people,
        ),
        ApplicationMilestone(
          title: 'Final Decision',
          description: 'Final decision on your application.',
          date: DateTime.now().subtract(const Duration(days: 5)),
          isCompleted: true,
          icon: Icons.gavel,
        ),
        ApplicationMilestone(
          title: 'Application Complete',
          description: 'Your application process is complete.',
          date: DateTime.now().subtract(const Duration(days: 2)),
          isCompleted: true,
          icon: Icons.celebration,
        ),
      ],
      submissionDate: DateTime.now().subtract(const Duration(days: 30)),
      estimatedCompletionDate: DateTime.now().subtract(const Duration(days: 2)),
      assignedTo: 'Cyprus University',
      feedback: 'Congratulations! Your application has been accepted.',
    );

    // Add the sample applications to the map
    _applicationStatuses['APP001'] = app1;
    _applicationStatuses['APP002'] = app2;
    _applicationStatuses['APP003'] = app3;
  }
}
