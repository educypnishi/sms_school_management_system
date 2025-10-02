import 'dart:convert';
import 'package:flutter/material.dart';

enum AssignmentStatus {
  draft,
  active,
  closed,
  archived,
}

enum SubmissionStatus {
  notSubmitted,
  submitted,
  graded,
  returned,
}

class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final String className;
  final String subject;
  final String teacherId;
  final String teacherName;
  final DateTime dueDate;
  final int maxMarks;
  final bool allowLateSubmission;
  final List<String> attachments;
  final List<Map<String, dynamic>> rubricCriteria;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final AssignmentStatus status;
  final String? instructions;
  final Map<String, dynamic>? settings;

  AssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.className,
    required this.subject,
    required this.teacherId,
    required this.teacherName,
    required this.dueDate,
    required this.maxMarks,
    this.allowLateSubmission = true,
    this.attachments = const [],
    this.rubricCriteria = const [],
    required this.createdAt,
    this.updatedAt,
    this.status = AssignmentStatus.active,
    this.instructions,
    this.settings,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'className': className,
      'subject': subject,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'dueDate': dueDate.toIso8601String(),
      'maxMarks': maxMarks,
      'allowLateSubmission': allowLateSubmission,
      'attachments': attachments,
      'rubricCriteria': rubricCriteria,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'status': status.name,
      'instructions': instructions,
      'settings': settings,
    };
  }

  factory AssignmentModel.fromMap(Map<String, dynamic> map) {
    return AssignmentModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      className: map['className'] ?? '',
      subject: map['subject'] ?? '',
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      dueDate: map['dueDate'] != null 
          ? DateTime.parse(map['dueDate']) 
          : DateTime.now(),
      maxMarks: map['maxMarks'] ?? 0,
      allowLateSubmission: map['allowLateSubmission'] ?? true,
      attachments: List<String>.from(map['attachments'] ?? []),
      rubricCriteria: List<Map<String, dynamic>>.from(map['rubricCriteria'] ?? []),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
      status: AssignmentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AssignmentStatus.active,
      ),
      instructions: map['instructions'],
      settings: map['settings'],
    );
  }

  String toJsonString() {
    return jsonEncode(toMap());
  }

  factory AssignmentModel.fromJsonString(String jsonString) {
    return AssignmentModel.fromMap(jsonDecode(jsonString));
  }

  AssignmentModel copyWith({
    String? id,
    String? title,
    String? description,
    String? className,
    String? subject,
    String? teacherId,
    String? teacherName,
    DateTime? dueDate,
    int? maxMarks,
    bool? allowLateSubmission,
    List<String>? attachments,
    List<Map<String, dynamic>>? rubricCriteria,
    DateTime? createdAt,
    DateTime? updatedAt,
    AssignmentStatus? status,
    String? instructions,
    Map<String, dynamic>? settings,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      className: className ?? this.className,
      subject: subject ?? this.subject,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      dueDate: dueDate ?? this.dueDate,
      maxMarks: maxMarks ?? this.maxMarks,
      allowLateSubmission: allowLateSubmission ?? this.allowLateSubmission,
      attachments: attachments ?? this.attachments,
      rubricCriteria: rubricCriteria ?? this.rubricCriteria,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      instructions: instructions ?? this.instructions,
      settings: settings ?? this.settings,
    );
  }

  // Helper methods
  bool get isOverdue => DateTime.now().isAfter(dueDate);
  bool get isActive => status == AssignmentStatus.active;
  bool get isDraft => status == AssignmentStatus.draft;
  
  String get statusDisplayName {
    switch (status) {
      case AssignmentStatus.draft:
        return 'Draft';
      case AssignmentStatus.active:
        return 'Active';
      case AssignmentStatus.closed:
        return 'Closed';
      case AssignmentStatus.archived:
        return 'Archived';
    }
  }

  Color get statusColor {
    switch (status) {
      case AssignmentStatus.draft:
        return Colors.grey;
      case AssignmentStatus.active:
        return isOverdue ? Colors.red : Colors.green;
      case AssignmentStatus.closed:
        return Colors.orange;
      case AssignmentStatus.archived:
        return Colors.grey;
    }
  }

  String get dueDateFormatted {
    final now = DateTime.now();
    final difference = dueDate.difference(now);
    
    if (difference.isNegative) {
      return 'Overdue by ${difference.inDays.abs()} days';
    } else if (difference.inDays == 0) {
      return 'Due today';
    } else if (difference.inDays == 1) {
      return 'Due tomorrow';
    } else {
      return 'Due in ${difference.inDays} days';
    }
  }

  int get totalRubricMarks {
    return rubricCriteria.fold(0, (sum, criteria) => sum + (criteria['marks'] as int? ?? 0));
  }
}

class AssignmentSubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String submissionText;
  final List<String> attachments;
  final DateTime submittedAt;
  final bool isLate;
  final SubmissionStatus status;
  final double? marks;
  final String? feedback;
  final DateTime? gradedAt;
  final String? gradedBy;
  final Map<String, dynamic>? rubricGrades;

  AssignmentSubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.submissionText,
    this.attachments = const [],
    required this.submittedAt,
    this.isLate = false,
    this.status = SubmissionStatus.submitted,
    this.marks,
    this.feedback,
    this.gradedAt,
    this.gradedBy,
    this.rubricGrades,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'submissionText': submissionText,
      'attachments': attachments,
      'submittedAt': submittedAt.toIso8601String(),
      'isLate': isLate,
      'status': status.name,
      'marks': marks,
      'feedback': feedback,
      'gradedAt': gradedAt?.toIso8601String(),
      'gradedBy': gradedBy,
      'rubricGrades': rubricGrades,
    };
  }

  factory AssignmentSubmissionModel.fromMap(Map<String, dynamic> map) {
    return AssignmentSubmissionModel(
      id: map['id'] ?? '',
      assignmentId: map['assignmentId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      submissionText: map['submissionText'] ?? '',
      attachments: List<String>.from(map['attachments'] ?? []),
      submittedAt: map['submittedAt'] != null 
          ? DateTime.parse(map['submittedAt']) 
          : DateTime.now(),
      isLate: map['isLate'] ?? false,
      status: SubmissionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SubmissionStatus.submitted,
      ),
      marks: map['marks']?.toDouble(),
      feedback: map['feedback'],
      gradedAt: map['gradedAt'] != null 
          ? DateTime.parse(map['gradedAt']) 
          : null,
      gradedBy: map['gradedBy'],
      rubricGrades: map['rubricGrades'],
    );
  }

  String toJsonString() {
    return jsonEncode(toMap());
  }

  factory AssignmentSubmissionModel.fromJsonString(String jsonString) {
    return AssignmentSubmissionModel.fromMap(jsonDecode(jsonString));
  }

  AssignmentSubmissionModel copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    String? studentName,
    String? submissionText,
    List<String>? attachments,
    DateTime? submittedAt,
    bool? isLate,
    SubmissionStatus? status,
    double? marks,
    String? feedback,
    DateTime? gradedAt,
    String? gradedBy,
    Map<String, dynamic>? rubricGrades,
  }) {
    return AssignmentSubmissionModel(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      submissionText: submissionText ?? this.submissionText,
      attachments: attachments ?? this.attachments,
      submittedAt: submittedAt ?? this.submittedAt,
      isLate: isLate ?? this.isLate,
      status: status ?? this.status,
      marks: marks ?? this.marks,
      feedback: feedback ?? this.feedback,
      gradedAt: gradedAt ?? this.gradedAt,
      gradedBy: gradedBy ?? this.gradedBy,
      rubricGrades: rubricGrades ?? this.rubricGrades,
    );
  }

  // Helper methods
  bool get isGraded => status == SubmissionStatus.graded;
  bool get isPending => status == SubmissionStatus.submitted;
  
  String get statusDisplayName {
    switch (status) {
      case SubmissionStatus.notSubmitted:
        return 'Not Submitted';
      case SubmissionStatus.submitted:
        return 'Submitted';
      case SubmissionStatus.graded:
        return 'Graded';
      case SubmissionStatus.returned:
        return 'Returned';
    }
  }

  Color get statusColor {
    switch (status) {
      case SubmissionStatus.notSubmitted:
        return Colors.grey;
      case SubmissionStatus.submitted:
        return isLate ? Colors.orange : Colors.blue;
      case SubmissionStatus.graded:
        return Colors.green;
      case SubmissionStatus.returned:
        return Colors.purple;
    }
  }

  String? get gradePercentage {
    if (marks == null) return null;
    // Assuming max marks is available from assignment
    return '${(marks! * 100 / 100).toStringAsFixed(1)}%';
  }

  String get submissionTimeFormatted {
    final now = DateTime.now();
    final difference = now.difference(submittedAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
