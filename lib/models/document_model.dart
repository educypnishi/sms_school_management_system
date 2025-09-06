import 'package:flutter/material.dart';

/// Represents the type of document
enum DocumentType {
  transcript,
  certificate,
  idCard,
  passport,
  cv,
  motivationLetter,
  recommendationLetter,
  other
}

/// Represents the verification status of a document
enum DocumentVerificationStatus {
  pending,
  verified,
  rejected
}

/// Model for a document in the system
class DocumentModel {
  final String id;
  final String userId;
  final String applicationId;
  final String title;
  final String description;
  final DocumentType type;
  final String fileUrl;
  final String fileName;
  final int fileSize; // in bytes
  final String fileType; // mime type
  final DateTime uploadDate;
  final DocumentVerificationStatus verificationStatus;
  final String? verifiedBy;
  final DateTime? verificationDate;
  final String? rejectionReason;
  final bool isRequired;

  DocumentModel({
    required this.id,
    required this.userId,
    required this.applicationId,
    required this.title,
    required this.description,
    required this.type,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    required this.uploadDate,
    required this.verificationStatus,
    this.verifiedBy,
    this.verificationDate,
    this.rejectionReason,
    required this.isRequired,
  });

  /// Create a copy of this document with updated fields
  DocumentModel copyWith({
    String? id,
    String? userId,
    String? applicationId,
    String? title,
    String? description,
    DocumentType? type,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? fileType,
    DateTime? uploadDate,
    DocumentVerificationStatus? verificationStatus,
    String? verifiedBy,
    DateTime? verificationDate,
    String? rejectionReason,
    bool? isRequired,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      applicationId: applicationId ?? this.applicationId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileType: fileType ?? this.fileType,
      uploadDate: uploadDate ?? this.uploadDate,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verificationDate: verificationDate ?? this.verificationDate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isRequired: isRequired ?? this.isRequired,
    );
  }

  /// Get a human-readable file size
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Get the icon for this document type
  IconData get typeIcon {
    switch (type) {
      case DocumentType.transcript:
        return Icons.school;
      case DocumentType.certificate:
        return Icons.card_membership;
      case DocumentType.idCard:
        return Icons.badge;
      case DocumentType.passport:
        return Icons.book;
      case DocumentType.cv:
        return Icons.description;
      case DocumentType.motivationLetter:
        return Icons.edit_note;
      case DocumentType.recommendationLetter:
        return Icons.recommend;
      case DocumentType.other:
        return Icons.insert_drive_file;
    }
  }

  /// Get the color for this document's verification status
  Color get statusColor {
    switch (verificationStatus) {
      case DocumentVerificationStatus.pending:
        return Colors.orange;
      case DocumentVerificationStatus.verified:
        return Colors.green;
      case DocumentVerificationStatus.rejected:
        return Colors.red;
    }
  }

  /// Get a human-readable verification status
  String get statusText {
    switch (verificationStatus) {
      case DocumentVerificationStatus.pending:
        return 'Pending Verification';
      case DocumentVerificationStatus.verified:
        return 'Verified';
      case DocumentVerificationStatus.rejected:
        return 'Rejected';
    }
  }

  /// Get a human-readable document type
  String get typeText {
    switch (type) {
      case DocumentType.transcript:
        return 'Academic Transcript';
      case DocumentType.certificate:
        return 'Certificate';
      case DocumentType.idCard:
        return 'ID Card';
      case DocumentType.passport:
        return 'Passport';
      case DocumentType.cv:
        return 'Curriculum Vitae';
      case DocumentType.motivationLetter:
        return 'Motivation Letter';
      case DocumentType.recommendationLetter:
        return 'Recommendation Letter';
      case DocumentType.other:
        return 'Other Document';
    }
  }
}
