import 'dart:io';
import 'package:flutter/material.dart';
import '../models/document_model.dart';

/// Service to manage documents in the system
class DocumentService {
  // In a real app, this would be stored in Firebase or another database
  // For now, we'll use an in-memory map for demo purposes
  final Map<String, DocumentModel> _documents = {};
  
  // Required documents for school enrollment
  final List<Map<String, dynamic>> _requiredDocuments = [
    {
      'type': 'birth certificate',
      'title': 'Birth Certificate',
      'description': 'Official birth certificate of the student',
      'required': true,
    },
    {
      'type': 'id card',
      'title': 'ID Card',
      'description': 'Valid identification document of the student',
      'required': true,
    },
    {
      'type': 'report card',
      'title': 'Report Card',
      'description': 'Previous school report card or academic records',
      'required': true,
    },
    {
      'type': 'medical record',
      'title': 'Medical Record',
      'description': 'Medical history and health information',
      'required': true,
    },
    {
      'type': 'immunization record',
      'title': 'Immunization Record',
      'description': 'Record of vaccinations and immunizations',
      'required': true,
    },
    {
      'type': 'parent consent',
      'title': 'Parent Consent Form',
      'description': 'Signed consent form from parent or guardian',
      'required': true,
    },
    {
      'type': 'previous school record',
      'title': 'Previous School Record',
      'description': 'Transfer certificate or records from previous school',
      'required': false,
    },
  ];

  /// Get all documents for a user
  Future<List<DocumentModel>> getUserDocuments(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _documents.values.where((doc) => doc.userId == userId).toList();
  }

  /// Get all documents for an application
  Future<List<DocumentModel>> getApplicationDocuments(String applicationId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _documents.values.where((doc) => doc.applicationId == applicationId).toList();
  }

  /// Get a specific document
  Future<DocumentModel?> getDocument(String documentId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _documents[documentId];
  }

  /// Upload a new document
  Future<DocumentModel> uploadDocument({
    required String userId,
    required String applicationId,
    required DocumentType documentType,
    required File file,
    String? title,
    String? description,
    bool isRequired = true,
  }) async {
    // Simulate network delay and file upload
    await Future.delayed(const Duration(seconds: 1));
    
    // In a real app, we would upload the file to storage and get a URL
    // For now, we'll just use a placeholder URL
    final String fileUrl = 'https://example.com/files/${file.path.split('/').last}';
    
    // Create a new document
    final document = DocumentModel(
      id: 'DOC${_documents.length + 1}',
      userId: userId,
      applicationId: applicationId,
      title: title ?? _getDefaultTitle(documentType),
      description: description ?? _getDefaultDescription(documentType),
      type: documentType,
      fileUrl: fileUrl,
      fileName: file.path.split('/').last,
      fileSize: await file.length(),
      fileType: _getFileType(file.path),
      uploadDate: DateTime.now(),
      verificationStatus: DocumentVerificationStatus.pending,
      isRequired: isRequired,
    );
    
    // Add the document to the map
    _documents[document.id] = document;
    
    return document;
  }

  /// Update a document's verification status
  Future<DocumentModel> updateDocumentStatus({
    required String documentId,
    required DocumentVerificationStatus status,
    String? verifiedBy,
    String? reason,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    final document = _documents[documentId];
    if (document == null) {
      throw Exception('Document not found');
    }
    
    final updatedDocument = document.copyWith(
      verificationStatus: status,
      verifiedBy: verifiedBy,
      verificationDate: DateTime.now(),
      rejectionReason: reason,
    );
    
    _documents[documentId] = updatedDocument;
    
    return updatedDocument;
  }

  /// Delete a document
  Future<void> deleteDocument(String documentId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    _documents.remove(documentId);
  }

  /// Get the list of required documents for an application
  List<Map<String, dynamic>> getRequiredDocuments() {
    return _requiredDocuments;
  }

  /// Check if all required documents are uploaded and verified for an application
  Future<bool> areAllRequiredDocumentsVerified(String applicationId) async {
    final documents = await getApplicationDocuments(applicationId);
    
    // Check if all required document types are present and verified
    for (final requiredDoc in _requiredDocuments) {
      final docType = requiredDoc['type'] as DocumentType;
      
      final hasVerifiedDoc = documents.any((doc) => 
        doc.type == docType && 
        doc.isRequired &&
        doc.verificationStatus == DocumentVerificationStatus.verified
      );
      
      if (!hasVerifiedDoc) {
        return false;
      }
    }
    
    return true;
  }

  /// Get missing required documents for an application
  Future<List<Map<String, dynamic>>> getMissingRequiredDocuments(String applicationId) async {
    final documents = await getApplicationDocuments(applicationId);
    final missingDocs = <Map<String, dynamic>>[];
    
    for (final requiredDoc in _requiredDocuments) {
      final docType = requiredDoc['type'] as DocumentType;
      
      final hasDoc = documents.any((doc) => 
        doc.type == docType && 
        doc.isRequired
      );
      
      if (!hasDoc) {
        missingDocs.add(requiredDoc);
      }
    }
    
    return missingDocs;
  }

  /// Generate sample documents for demo purposes
  Future<void> generateSampleDocuments(String userId, String enrollmentId) async {
    // Sample document 1 - Verified birth certificate
    final doc1 = DocumentModel(
      id: 'DOC001',
      userId: userId,
      applicationId: enrollmentId,
      title: 'Birth Certificate',
      description: 'Official birth certificate of the student',
      type: DocumentType.birthCertificate,
      fileUrl: 'https://example.com/files/birth_certificate.pdf',
      fileName: 'birth_certificate.pdf',
      fileSize: 1024 * 1024 * 2, // 2 MB
      fileType: 'application/pdf',
      uploadDate: DateTime.now().subtract(const Duration(days: 10)),
      verificationStatus: DocumentVerificationStatus.verified,
      verifiedBy: 'Admin',
      verificationDate: DateTime.now().subtract(const Duration(days: 5)),
      isRequired: true,
    );
    
    // Sample document 2 - Pending report card
    final doc2 = DocumentModel(
      id: 'DOC002',
      userId: userId,
      applicationId: enrollmentId,
      title: 'Report Card',
      description: 'Previous school report card',
      type: DocumentType.reportCard,
      fileUrl: 'https://example.com/files/report_card.jpg',
      fileName: 'report_card.jpg',
      fileSize: 1024 * 500, // 500 KB
      fileType: 'image/jpeg',
      uploadDate: DateTime.now().subtract(const Duration(days: 3)),
      verificationStatus: DocumentVerificationStatus.pending,
      isRequired: true,
    );
    
    // Sample document 3 - Rejected medical record (needs update)
    final doc3 = DocumentModel(
      id: 'DOC003',
      userId: userId,
      applicationId: enrollmentId,
      title: 'Medical Record',
      description: 'Medical history and health information',
      type: DocumentType.medicalRecord,
      fileUrl: 'https://example.com/files/medical_record.pdf',
      fileName: 'medical_record.pdf',
      fileSize: 1024 * 300, // 300 KB
      fileType: 'application/pdf',
      uploadDate: DateTime.now().subtract(const Duration(days: 7)),
      verificationStatus: DocumentVerificationStatus.rejected,
      verifiedBy: 'Admin',
      verificationDate: DateTime.now().subtract(const Duration(days: 2)),
      rejectionReason: 'Please provide updated immunization records',
      isRequired: true,
    );
    
    // Add the sample documents to the map
    _documents[doc1.id] = doc1;
    _documents[doc2.id] = doc2;
    _documents[doc3.id] = doc3;
  }
  
  /// Get the file type based on file extension
  String _getFileType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
  
  /// Get default title for document type
  String _getDefaultTitle(DocumentType type) {
    switch (type) {
      case DocumentType.reportCard:
        return 'Report Card';
      case DocumentType.certificate:
        return 'Certificate';
      case DocumentType.idCard:
        return 'ID Card';
      case DocumentType.birthCertificate:
        return 'Birth Certificate';
      case DocumentType.medicalRecord:
        return 'Medical Record';
      case DocumentType.parentConsent:
        return 'Parent Consent Form';
      case DocumentType.previousSchoolRecord:
        return 'Previous School Record';
      case DocumentType.immunizationRecord:
        return 'Immunization Record';
      case DocumentType.other:
        return 'Other Document';
    }
  }
  
  /// Get default description for document type
  String _getDefaultDescription(DocumentType type) {
    switch (type) {
      case DocumentType.reportCard:
        return 'Previous school report card or academic records';
      case DocumentType.certificate:
        return 'Certificate of completion or achievement';
      case DocumentType.idCard:
        return 'Valid identification card of the student';
      case DocumentType.birthCertificate:
        return 'Official birth certificate of the student';
      case DocumentType.medicalRecord:
        return 'Medical history and health information';
      case DocumentType.parentConsent:
        return 'Signed consent form from parent or guardian';
      case DocumentType.previousSchoolRecord:
        return 'Transfer certificate or records from previous school';
      case DocumentType.immunizationRecord:
        return 'Record of vaccinations and immunizations';
      case DocumentType.other:
        return 'Additional supporting document';
    }
  }
}
