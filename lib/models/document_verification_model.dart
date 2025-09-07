import 'package:flutter/material.dart';

/// Represents the verification status of a document
enum VerificationStatus {
  pending,
  verified,
  rejected,
  needsClarification
}

/// Represents a document verification feedback entry
class VerificationFeedback {
  final String id;
  final String verifierId;
  final String verifierName;
  final String comment;
  final DateTime timestamp;

  VerificationFeedback({
    required this.id,
    required this.verifierId,
    required this.verifierName,
    required this.comment,
    required this.timestamp,
  });

  /// Create a VerificationFeedback from a map
  factory VerificationFeedback.fromMap(Map<String, dynamic> map, String id) {
    return VerificationFeedback(
      id: id,
      verifierId: map['verifierId'] ?? '',
      verifierName: map['verifierName'] ?? '',
      comment: map['comment'] ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp']) 
          : DateTime.now(),
    );
  }

  /// Convert VerificationFeedback to a map
  Map<String, dynamic> toMap() {
    return {
      'verifierId': verifierId,
      'verifierName': verifierName,
      'comment': comment,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Model for document verification
class DocumentVerificationModel {
  final String id;
  final String documentId;
  final String applicationId;
  final String userId;
  final String documentType;
  final String documentUrl;
  final VerificationStatus status;
  final String? assignedVerifierId;
  final DateTime uploadedAt;
  final DateTime? verifiedAt;
  final List<VerificationFeedback> feedbackHistory;
  final int version;
  final String? previousVersionId;

  DocumentVerificationModel({
    required this.id,
    required this.documentId,
    required this.applicationId,
    required this.userId,
    required this.documentType,
    required this.documentUrl,
    required this.status,
    this.assignedVerifierId,
    required this.uploadedAt,
    this.verifiedAt,
    required this.feedbackHistory,
    required this.version,
    this.previousVersionId,
  });

  /// Create a DocumentVerificationModel from a map
  factory DocumentVerificationModel.fromMap(Map<String, dynamic> map, String id) {
    // Parse feedback history
    final List<VerificationFeedback> feedbackList = [];
    if (map['feedbackHistory'] != null) {
      for (var item in map['feedbackHistory']) {
        feedbackList.add(VerificationFeedback.fromMap(
          item, 
          item['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()
        ));
      }
    }

    return DocumentVerificationModel(
      id: id,
      documentId: map['documentId'] ?? '',
      applicationId: map['applicationId'] ?? '',
      userId: map['userId'] ?? '',
      documentType: map['documentType'] ?? '',
      documentUrl: map['documentUrl'] ?? '',
      status: _parseVerificationStatus(map['status']),
      assignedVerifierId: map['assignedVerifierId'],
      uploadedAt: map['uploadedAt'] != null 
          ? DateTime.parse(map['uploadedAt']) 
          : DateTime.now(),
      verifiedAt: map['verifiedAt'] != null 
          ? DateTime.parse(map['verifiedAt']) 
          : null,
      feedbackHistory: feedbackList,
      version: map['version'] ?? 1,
      previousVersionId: map['previousVersionId'],
    );
  }

  /// Convert DocumentVerificationModel to a map
  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'applicationId': applicationId,
      'userId': userId,
      'documentType': documentType,
      'documentUrl': documentUrl,
      'status': status.toString().split('.').last,
      'assignedVerifierId': assignedVerifierId,
      'uploadedAt': uploadedAt.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
      'feedbackHistory': feedbackHistory.map((feedback) => feedback.toMap()).toList(),
      'version': version,
      'previousVersionId': previousVersionId,
    };
  }

  /// Create a copy of DocumentVerificationModel with some fields changed
  DocumentVerificationModel copyWith({
    String? id,
    String? documentId,
    String? applicationId,
    String? userId,
    String? documentType,
    String? documentUrl,
    VerificationStatus? status,
    String? assignedVerifierId,
    DateTime? uploadedAt,
    DateTime? verifiedAt,
    List<VerificationFeedback>? feedbackHistory,
    int? version,
    String? previousVersionId,
  }) {
    return DocumentVerificationModel(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      applicationId: applicationId ?? this.applicationId,
      userId: userId ?? this.userId,
      documentType: documentType ?? this.documentType,
      documentUrl: documentUrl ?? this.documentUrl,
      status: status ?? this.status,
      assignedVerifierId: assignedVerifierId ?? this.assignedVerifierId,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      feedbackHistory: feedbackHistory ?? this.feedbackHistory,
      version: version ?? this.version,
      previousVersionId: previousVersionId ?? this.previousVersionId,
    );
  }

  /// Add feedback to the document
  DocumentVerificationModel addFeedback(VerificationFeedback feedback) {
    final updatedFeedbackHistory = List<VerificationFeedback>.from(feedbackHistory)
      ..add(feedback);
    
    return copyWith(
      feedbackHistory: updatedFeedbackHistory,
    );
  }

  /// Update verification status
  DocumentVerificationModel updateStatus(
    VerificationStatus newStatus, 
    String verifierId,
    String verifierName,
    String comment,
  ) {
    final feedback = VerificationFeedback(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      verifierId: verifierId,
      verifierName: verifierName,
      comment: comment,
      timestamp: DateTime.now(),
    );
    
    final updatedFeedbackHistory = List<VerificationFeedback>.from(feedbackHistory)
      ..add(feedback);
    
    return copyWith(
      status: newStatus,
      verifiedAt: newStatus == VerificationStatus.verified ? DateTime.now() : verifiedAt,
      feedbackHistory: updatedFeedbackHistory,
    );
  }

  /// Get the latest feedback
  VerificationFeedback? get latestFeedback {
    if (feedbackHistory.isEmpty) return null;
    return feedbackHistory.last;
  }

  /// Get color based on verification status
  Color getStatusColor() {
    switch (status) {
      case VerificationStatus.pending:
        return Colors.orange;
      case VerificationStatus.verified:
        return Colors.green;
      case VerificationStatus.rejected:
        return Colors.red;
      case VerificationStatus.needsClarification:
        return Colors.amber;
    }
  }

  /// Get icon based on verification status
  IconData getStatusIcon() {
    switch (status) {
      case VerificationStatus.pending:
        return Icons.pending;
      case VerificationStatus.verified:
        return Icons.check_circle;
      case VerificationStatus.rejected:
        return Icons.cancel;
      case VerificationStatus.needsClarification:
        return Icons.help;
    }
  }

  /// Get text based on verification status
  String getStatusText() {
    switch (status) {
      case VerificationStatus.pending:
        return 'Pending Verification';
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.needsClarification:
        return 'Needs Clarification';
    }
  }

  /// Parse VerificationStatus from string
  static VerificationStatus _parseVerificationStatus(String? value) {
    if (value == null) return VerificationStatus.pending;
    
    switch (value.toLowerCase()) {
      case 'verified':
        return VerificationStatus.verified;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'needsclarification':
        return VerificationStatus.needsClarification;
      case 'pending':
      default:
        return VerificationStatus.pending;
    }
  }
}
