import 'package:flutter/material.dart';

/// Represents the status of a visa application
enum VisaApplicationStatus {
  notStarted,
  preparing,
  submitted,
  underReview,
  additionalDocumentsRequested,
  approved,
  rejected,
  appealing,
}

/// Represents the type of visa
enum VisaType {
  student,
  tourist,
  work,
  family,
  other,
}

/// Represents a milestone in the visa application process
class VisaMilestone {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final DateTime? completedDate;
  final bool isCompleted;
  final bool isRequired;
  final int order;

  VisaMilestone({
    required this.id,
    required this.title,
    required this.description,
    this.dueDate,
    this.completedDate,
    required this.isCompleted,
    required this.isRequired,
    required this.order,
  });

  /// Create a copy of this milestone with updated fields
  VisaMilestone copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? completedDate,
    bool? isCompleted,
    bool? isRequired,
    int? order,
  }) {
    return VisaMilestone(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      completedDate: completedDate ?? this.completedDate,
      isCompleted: isCompleted ?? this.isCompleted,
      isRequired: isRequired ?? this.isRequired,
      order: order ?? this.order,
    );
  }

  /// Create a VisaMilestone from a map
  factory VisaMilestone.fromMap(Map<String, dynamic> map) {
    return VisaMilestone(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      completedDate: map['completedDate'] != null ? DateTime.parse(map['completedDate']) : null,
      isCompleted: map['isCompleted'] ?? false,
      isRequired: map['isRequired'] ?? true,
      order: map['order'] ?? 0,
    );
  }

  /// Convert VisaMilestone to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'isRequired': isRequired,
      'order': order,
    };
  }
}

/// Represents a required document for a visa application
class VisaDocument {
  final String id;
  final String name;
  final String description;
  final bool isSubmitted;
  final bool isApproved;
  final bool isRejected;
  final String? rejectionReason;
  final DateTime? submissionDate;
  final DateTime? approvalDate;
  final DateTime? rejectionDate;
  final bool isRequired;
  final String? fileUrl;

  VisaDocument({
    required this.id,
    required this.name,
    required this.description,
    required this.isSubmitted,
    required this.isApproved,
    required this.isRejected,
    this.rejectionReason,
    this.submissionDate,
    this.approvalDate,
    this.rejectionDate,
    required this.isRequired,
    this.fileUrl,
  });

  /// Create a copy of this document with updated fields
  VisaDocument copyWith({
    String? id,
    String? name,
    String? description,
    bool? isSubmitted,
    bool? isApproved,
    bool? isRejected,
    String? rejectionReason,
    DateTime? submissionDate,
    DateTime? approvalDate,
    DateTime? rejectionDate,
    bool? isRequired,
    String? fileUrl,
  }) {
    return VisaDocument(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      isApproved: isApproved ?? this.isApproved,
      isRejected: isRejected ?? this.isRejected,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      submissionDate: submissionDate ?? this.submissionDate,
      approvalDate: approvalDate ?? this.approvalDate,
      rejectionDate: rejectionDate ?? this.rejectionDate,
      isRequired: isRequired ?? this.isRequired,
      fileUrl: fileUrl ?? this.fileUrl,
    );
  }

  /// Get the status of the document
  String get status {
    if (isRejected) return 'Rejected';
    if (isApproved) return 'Approved';
    if (isSubmitted) return 'Submitted';
    return 'Not Submitted';
  }

  /// Get the color associated with the document status
  Color get statusColor {
    if (isRejected) return Colors.red;
    if (isApproved) return Colors.green;
    if (isSubmitted) return Colors.orange;
    return Colors.grey;
  }

  /// Create a VisaDocument from a map
  factory VisaDocument.fromMap(Map<String, dynamic> map) {
    return VisaDocument(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      isSubmitted: map['isSubmitted'] ?? false,
      isApproved: map['isApproved'] ?? false,
      isRejected: map['isRejected'] ?? false,
      rejectionReason: map['rejectionReason'],
      submissionDate: map['submissionDate'] != null ? DateTime.parse(map['submissionDate']) : null,
      approvalDate: map['approvalDate'] != null ? DateTime.parse(map['approvalDate']) : null,
      rejectionDate: map['rejectionDate'] != null ? DateTime.parse(map['rejectionDate']) : null,
      isRequired: map['isRequired'] ?? true,
      fileUrl: map['fileUrl'],
    );
  }

  /// Convert VisaDocument to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isSubmitted': isSubmitted,
      'isApproved': isApproved,
      'isRejected': isRejected,
      'rejectionReason': rejectionReason,
      'submissionDate': submissionDate?.toIso8601String(),
      'approvalDate': approvalDate?.toIso8601String(),
      'rejectionDate': rejectionDate?.toIso8601String(),
      'isRequired': isRequired,
      'fileUrl': fileUrl,
    };
  }
}

/// Represents a note or comment on a visa application
class VisaNote {
  final String id;
  final String content;
  final DateTime createdAt;
  final String createdBy;
  final bool isImportant;

  VisaNote({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.createdBy,
    required this.isImportant,
  });

  /// Create a copy of this note with updated fields
  VisaNote copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    String? createdBy,
    bool? isImportant,
  }) {
    return VisaNote(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isImportant: isImportant ?? this.isImportant,
    );
  }

  /// Create a VisaNote from a map
  factory VisaNote.fromMap(Map<String, dynamic> map) {
    return VisaNote(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      isImportant: map['isImportant'] ?? false,
    );
  }

  /// Convert VisaNote to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'isImportant': isImportant,
    };
  }
}

/// Represents an appointment related to a visa application
class VisaAppointment {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final bool isCompleted;
  final String? notes;
  final bool isReminded;

  VisaAppointment({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.isCompleted,
    this.notes,
    required this.isReminded,
  });

  /// Create a copy of this appointment with updated fields
  VisaAppointment copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    String? location,
    bool? isCompleted,
    String? notes,
    bool? isReminded,
  }) {
    return VisaAppointment(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      isReminded: isReminded ?? this.isReminded,
    );
  }

  /// Create a VisaAppointment from a map
  factory VisaAppointment.fromMap(Map<String, dynamic> map) {
    return VisaAppointment(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dateTime: map['dateTime'] != null ? DateTime.parse(map['dateTime']) : DateTime.now(),
      location: map['location'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      notes: map['notes'],
      isReminded: map['isReminded'] ?? false,
    );
  }

  /// Convert VisaAppointment to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'isCompleted': isCompleted,
      'notes': notes,
      'isReminded': isReminded,
    };
  }
}

/// Extension on VisaApplicationStatus to provide helper methods
extension VisaApplicationStatusExtension on VisaApplicationStatus {
  /// Get a display name for this status
  String get displayName {
    switch (this) {
      case VisaApplicationStatus.notStarted:
        return 'Not Started';
      case VisaApplicationStatus.preparing:
        return 'Preparing';
      case VisaApplicationStatus.submitted:
        return 'Submitted';
      case VisaApplicationStatus.underReview:
        return 'Under Review';
      case VisaApplicationStatus.additionalDocumentsRequested:
        return 'Additional Documents Requested';
      case VisaApplicationStatus.approved:
        return 'Approved';
      case VisaApplicationStatus.rejected:
        return 'Rejected';
      case VisaApplicationStatus.appealing:
        return 'Appealing';
    }
  }

  /// Get a color for this status
  Color get color {
    switch (this) {
      case VisaApplicationStatus.notStarted:
        return Colors.grey;
      case VisaApplicationStatus.preparing:
        return Colors.blue;
      case VisaApplicationStatus.submitted:
        return Colors.orange;
      case VisaApplicationStatus.underReview:
        return Colors.purple;
      case VisaApplicationStatus.additionalDocumentsRequested:
        return Colors.amber;
      case VisaApplicationStatus.approved:
        return Colors.green;
      case VisaApplicationStatus.rejected:
        return Colors.red;
      case VisaApplicationStatus.appealing:
        return Colors.deepOrange;
    }
  }

  /// Get an icon for this status
  IconData get icon {
    switch (this) {
      case VisaApplicationStatus.notStarted:
        return Icons.hourglass_empty;
      case VisaApplicationStatus.preparing:
        return Icons.edit_document;
      case VisaApplicationStatus.submitted:
        return Icons.send;
      case VisaApplicationStatus.underReview:
        return Icons.search;
      case VisaApplicationStatus.additionalDocumentsRequested:
        return Icons.file_present;
      case VisaApplicationStatus.approved:
        return Icons.check_circle;
      case VisaApplicationStatus.rejected:
        return Icons.cancel;
      case VisaApplicationStatus.appealing:
        return Icons.gavel;
    }
  }
}

/// Extension on VisaType to provide helper methods
extension VisaTypeExtension on VisaType {
  /// Get a display name for this visa type
  String get displayName {
    switch (this) {
      case VisaType.student:
        return 'Student Visa';
      case VisaType.tourist:
        return 'Tourist Visa';
      case VisaType.work:
        return 'Work Visa';
      case VisaType.family:
        return 'Family Visa';
      case VisaType.other:
        return 'Other Visa';
    }
  }
}

/// Model for a visa application
class VisaApplicationModel {
  final String id;
  final String userId;
  final String applicationId;
  final VisaType visaType;
  final VisaApplicationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final String country;
  final String embassy;
  final String? referenceNumber;
  final List<VisaMilestone> milestones;
  final List<VisaDocument> documents;
  final List<VisaNote> notes;
  final List<VisaAppointment> appointments;
  final double completionPercentage;

  VisaApplicationModel({
    required this.id,
    required this.userId,
    required this.applicationId,
    required this.visaType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.submittedAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
    required this.country,
    required this.embassy,
    this.referenceNumber,
    required this.milestones,
    required this.documents,
    required this.notes,
    required this.appointments,
    required this.completionPercentage,
  });

  /// Create a copy of this visa application with updated fields
  VisaApplicationModel copyWith({
    String? id,
    String? userId,
    String? applicationId,
    VisaType? visaType,
    VisaApplicationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
    DateTime? approvedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
    String? country,
    String? embassy,
    String? referenceNumber,
    List<VisaMilestone>? milestones,
    List<VisaDocument>? documents,
    List<VisaNote>? notes,
    List<VisaAppointment>? appointments,
    double? completionPercentage,
  }) {
    return VisaApplicationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      applicationId: applicationId ?? this.applicationId,
      visaType: visaType ?? this.visaType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      country: country ?? this.country,
      embassy: embassy ?? this.embassy,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      milestones: milestones ?? this.milestones,
      documents: documents ?? this.documents,
      notes: notes ?? this.notes,
      appointments: appointments ?? this.appointments,
      completionPercentage: completionPercentage ?? this.completionPercentage,
    );
  }

  /// Get the next milestone that needs to be completed
  VisaMilestone? get nextMilestone {
    final incompleteMilestones = milestones.where((m) => !m.isCompleted).toList();
    incompleteMilestones.sort((a, b) => a.order.compareTo(b.order));
    return incompleteMilestones.isNotEmpty ? incompleteMilestones.first : null;
  }

  /// Get the number of completed milestones
  int get completedMilestonesCount => milestones.where((m) => m.isCompleted).length;

  /// Get the number of completed required documents
  int get completedDocumentsCount => documents.where((d) => d.isSubmitted).length;

  /// Get the number of required documents
  int get requiredDocumentsCount => documents.where((d) => d.isRequired).length;

  /// Get the next appointment
  VisaAppointment? get nextAppointment {
    final futureAppointments = appointments
        .where((a) => !a.isCompleted && a.dateTime.isAfter(DateTime.now()))
        .toList();
    futureAppointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return futureAppointments.isNotEmpty ? futureAppointments.first : null;
  }

  /// Create a VisaApplicationModel from a map
  factory VisaApplicationModel.fromMap(Map<String, dynamic> map) {
    // Parse milestones
    final milestonesList = <VisaMilestone>[];
    if (map['milestones'] != null) {
      for (final milestone in map['milestones']) {
        milestonesList.add(VisaMilestone.fromMap(milestone));
      }
    }
    
    // Parse documents
    final documentsList = <VisaDocument>[];
    if (map['documents'] != null) {
      for (final document in map['documents']) {
        documentsList.add(VisaDocument.fromMap(document));
      }
    }
    
    // Parse notes
    final notesList = <VisaNote>[];
    if (map['notes'] != null) {
      for (final note in map['notes']) {
        notesList.add(VisaNote.fromMap(note));
      }
    }
    
    // Parse appointments
    final appointmentsList = <VisaAppointment>[];
    if (map['appointments'] != null) {
      for (final appointment in map['appointments']) {
        appointmentsList.add(VisaAppointment.fromMap(appointment));
      }
    }
    
    return VisaApplicationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      applicationId: map['applicationId'] ?? '',
      visaType: _parseVisaType(map['visaType']),
      status: _parseVisaApplicationStatus(map['status']),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
      submittedAt: map['submittedAt'] != null ? DateTime.parse(map['submittedAt']) : null,
      approvedAt: map['approvedAt'] != null ? DateTime.parse(map['approvedAt']) : null,
      rejectedAt: map['rejectedAt'] != null ? DateTime.parse(map['rejectedAt']) : null,
      rejectionReason: map['rejectionReason'],
      country: map['country'] ?? '',
      embassy: map['embassy'] ?? '',
      referenceNumber: map['referenceNumber'],
      milestones: milestonesList,
      documents: documentsList,
      notes: notesList,
      appointments: appointmentsList,
      completionPercentage: map['completionPercentage']?.toDouble() ?? 0.0,
    );
  }

  /// Convert VisaApplicationModel to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'applicationId': applicationId,
      'visaType': visaType.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'submittedAt': submittedAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'country': country,
      'embassy': embassy,
      'referenceNumber': referenceNumber,
      'milestones': milestones.map((m) => m.toMap()).toList(),
      'documents': documents.map((d) => d.toMap()).toList(),
      'notes': notes.map((n) => n.toMap()).toList(),
      'appointments': appointments.map((a) => a.toMap()).toList(),
      'completionPercentage': completionPercentage,
    };
  }

  /// Parse VisaType from string
  static VisaType _parseVisaType(String? value) {
    if (value == null) return VisaType.student;
    
    switch (value.toLowerCase()) {
      case 'tourist':
        return VisaType.tourist;
      case 'work':
        return VisaType.work;
      case 'family':
        return VisaType.family;
      case 'other':
        return VisaType.other;
      case 'student':
      default:
        return VisaType.student;
    }
  }

  /// Parse VisaApplicationStatus from string
  static VisaApplicationStatus _parseVisaApplicationStatus(String? value) {
    if (value == null) return VisaApplicationStatus.notStarted;
    
    switch (value.toLowerCase()) {
      case 'preparing':
        return VisaApplicationStatus.preparing;
      case 'submitted':
        return VisaApplicationStatus.submitted;
      case 'underreview':
        return VisaApplicationStatus.underReview;
      case 'additionaldocumentsrequested':
        return VisaApplicationStatus.additionalDocumentsRequested;
      case 'approved':
        return VisaApplicationStatus.approved;
      case 'rejected':
        return VisaApplicationStatus.rejected;
      case 'appealing':
        return VisaApplicationStatus.appealing;
      case 'notstarted':
      default:
        return VisaApplicationStatus.notStarted;
    }
  }
}
