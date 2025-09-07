import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/document_verification_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class DocumentVerificationService {
  // Shared Preferences key prefixes
  static const String _documentVerificationPrefix = 'document_verification_';
  static const String _pendingVerificationPrefix = 'pending_verification_';
  static const String _userDocumentsPrefix = 'user_documents_';
  static const String _applicationDocumentsPrefix = 'application_documents_';
  
  // Notification service for sending notifications
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  
  // Get all documents pending verification
  Future<List<DocumentVerificationModel>> getPendingVerifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all pending verification IDs
      final pendingIds = prefs.getStringList(_pendingVerificationPrefix) ?? [];
      
      // Get document verification models
      final documents = <DocumentVerificationModel>[];
      for (final id in pendingIds) {
        final document = await getDocumentVerification(id);
        if (document != null) {
          documents.add(document);
        }
      }
      
      // Sort by upload date (newest first)
      documents.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      
      return documents;
    } catch (e) {
      debugPrint('Error getting pending verifications: $e');
      return [];
    }
  }
  
  // Get document verification by ID
  Future<DocumentVerificationModel?> getDocumentVerification(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get document verification from SharedPreferences
      final documentJson = prefs.getString('${_documentVerificationPrefix}$id');
      if (documentJson == null) {
        return null;
      }
      
      // Parse document verification
      final documentMap = jsonDecode(documentJson) as Map<String, dynamic>;
      return DocumentVerificationModel.fromMap(documentMap, id);
    } catch (e) {
      debugPrint('Error getting document verification: $e');
      return null;
    }
  }
  
  // Get all documents for a user
  Future<List<DocumentVerificationModel>> getUserDocuments(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all document IDs for the user
      final documentIds = prefs.getStringList('${_userDocumentsPrefix}$userId') ?? [];
      
      // Get document verification models
      final documents = <DocumentVerificationModel>[];
      for (final id in documentIds) {
        final document = await getDocumentVerification(id);
        if (document != null) {
          documents.add(document);
        }
      }
      
      // Sort by upload date (newest first)
      documents.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      
      return documents;
    } catch (e) {
      debugPrint('Error getting user documents: $e');
      return [];
    }
  }
  
  // Get all documents for an application
  Future<List<DocumentVerificationModel>> getApplicationDocuments(String applicationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all document IDs for the application
      final documentIds = prefs.getStringList('${_applicationDocumentsPrefix}$applicationId') ?? [];
      
      // Get document verification models
      final documents = <DocumentVerificationModel>[];
      for (final id in documentIds) {
        final document = await getDocumentVerification(id);
        if (document != null) {
          documents.add(document);
        }
      }
      
      // Sort by document type
      documents.sort((a, b) => a.documentType.compareTo(b.documentType));
      
      return documents;
    } catch (e) {
      debugPrint('Error getting application documents: $e');
      return [];
    }
  }
  
  // Submit a document for verification
  Future<DocumentVerificationModel> submitDocument({
    required String documentId,
    required String applicationId,
    required String userId,
    required String documentType,
    required String documentUrl,
    String? previousVersionId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generate a new verification ID
      final verificationId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Determine version number
      int version = 1;
      if (previousVersionId != null) {
        final previousDocument = await getDocumentVerification(previousVersionId);
        if (previousDocument != null) {
          version = previousDocument.version + 1;
        }
      }
      
      // Create document verification model
      final documentVerification = DocumentVerificationModel(
        id: verificationId,
        documentId: documentId,
        applicationId: applicationId,
        userId: userId,
        documentType: documentType,
        documentUrl: documentUrl,
        status: VerificationStatus.pending,
        uploadedAt: DateTime.now(),
        feedbackHistory: [],
        version: version,
        previousVersionId: previousVersionId,
      );
      
      // Save document verification to SharedPreferences
      await prefs.setString(
        '${_documentVerificationPrefix}$verificationId', 
        jsonEncode(documentVerification.toMap())
      );
      
      // Add to pending verifications list
      final pendingIds = prefs.getStringList(_pendingVerificationPrefix) ?? [];
      if (!pendingIds.contains(verificationId)) {
        pendingIds.add(verificationId);
        await prefs.setStringList(_pendingVerificationPrefix, pendingIds);
      }
      
      // Add to user documents list
      final userDocumentIds = prefs.getStringList('${_userDocumentsPrefix}$userId') ?? [];
      if (!userDocumentIds.contains(verificationId)) {
        userDocumentIds.add(verificationId);
        await prefs.setStringList('${_userDocumentsPrefix}$userId', userDocumentIds);
      }
      
      // Add to application documents list
      final applicationDocumentIds = prefs.getStringList('${_applicationDocumentsPrefix}$applicationId') ?? [];
      if (!applicationDocumentIds.contains(verificationId)) {
        applicationDocumentIds.add(verificationId);
        await prefs.setStringList('${_applicationDocumentsPrefix}$applicationId', applicationDocumentIds);
      }
      
      // Send notification to admins about new document
      await _notificationService.createNotification(
        userId: 'admin', // Send to all admins
        title: 'New Document Submitted',
        message: 'A new $documentType document has been submitted for verification.',
        type: 'document',
        data: {
          'documentId': verificationId,
          'userId': userId,
        },
      );
      
      return documentVerification;
    } catch (e) {
      debugPrint('Error submitting document: $e');
      rethrow;
    }
  }
  
  // Assign a document to a verifier
  Future<DocumentVerificationModel> assignDocument(String documentId, String verifierId) async {
    try {
      // Get document verification
      final document = await getDocumentVerification(documentId);
      if (document == null) {
        throw Exception('Document not found');
      }
      
      // Update document with assigned verifier
      final updatedDocument = document.copyWith(
        assignedVerifierId: verifierId,
      );
      
      // Save updated document
      await _saveDocument(updatedDocument);
      
      // Send notification to verifier
      await _notificationService.createNotification(
        userId: verifierId,
        title: 'Document Assigned',
        message: 'A ${document.documentType} document has been assigned to you for verification.',
        type: 'document',
        data: {
          'documentId': documentId,
          'senderId': 'system',
        },
      );
      
      return updatedDocument;
    } catch (e) {
      debugPrint('Error assigning document: $e');
      rethrow;
    }
  }
  
  // Update document verification status
  Future<DocumentVerificationModel> updateDocumentStatus({
    required String documentId,
    required VerificationStatus status,
    required String comment,
  }) async {
    try {
      // Get current user (verifier)
      final verifier = await _authService.getCurrentUser();
      if (verifier == null) {
        throw Exception('User not logged in');
      }
      
      // Get document verification
      final document = await getDocumentVerification(documentId);
      if (document == null) {
        throw Exception('Document not found');
      }
      
      // Update document status
      final updatedDocument = document.updateStatus(
        status,
        verifier.id,
        verifier.name,
        comment,
      );
      
      // Save updated document
      await _saveDocument(updatedDocument);
      
      // If status is no longer pending, remove from pending list
      if (status != VerificationStatus.pending) {
        await _removeFromPendingList(documentId);
      }
      
      // Send notification to document owner
      String statusMessage;
      switch (status) {
        case VerificationStatus.verified:
          statusMessage = 'Your ${document.documentType} document has been verified.';
          break;
        case VerificationStatus.rejected:
          statusMessage = 'Your ${document.documentType} document has been rejected. Please check the feedback and resubmit.';
          break;
        case VerificationStatus.needsClarification:
          statusMessage = 'Your ${document.documentType} document needs clarification. Please check the feedback.';
          break;
        default:
          statusMessage = 'Your ${document.documentType} document status has been updated.';
      }
      
      await _notificationService.createNotification(
        userId: document.userId,
        title: 'Document Status Updated',
        message: statusMessage,
        type: 'document',
        data: {
          'documentId': documentId,
          'senderId': verifier.id,
        },
      );
      
      return updatedDocument;
    } catch (e) {
      debugPrint('Error updating document status: $e');
      rethrow;
    }
  }
  
  // Add feedback to a document
  Future<DocumentVerificationModel> addFeedback({
    required String documentId,
    required String comment,
  }) async {
    try {
      // Get current user (verifier)
      final verifier = await _authService.getCurrentUser();
      if (verifier == null) {
        throw Exception('User not logged in');
      }
      
      // Get document verification
      final document = await getDocumentVerification(documentId);
      if (document == null) {
        throw Exception('Document not found');
      }
      
      // Create feedback
      final feedback = VerificationFeedback(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        verifierId: verifier.id,
        verifierName: verifier.name,
        comment: comment,
        timestamp: DateTime.now(),
      );
      
      // Add feedback to document
      final updatedDocument = document.addFeedback(feedback);
      
      // Save updated document
      await _saveDocument(updatedDocument);
      
      // Send notification to document owner
      await _notificationService.createNotification(
        userId: document.userId,
        title: 'New Document Feedback',
        message: 'You have received new feedback on your ${document.documentType} document.',
        type: 'document',
        data: {
          'documentId': documentId,
          'senderId': verifier.id,
        },
      );
      
      return updatedDocument;
    } catch (e) {
      debugPrint('Error adding feedback: $e');
      rethrow;
    }
  }
  
  // Save document verification to SharedPreferences
  Future<void> _saveDocument(DocumentVerificationModel document) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save document verification to SharedPreferences
      await prefs.setString(
        '${_documentVerificationPrefix}${document.id}', 
        jsonEncode(document.toMap())
      );
    } catch (e) {
      debugPrint('Error saving document: $e');
      rethrow;
    }
  }
  
  // Remove document from pending list
  Future<void> _removeFromPendingList(String documentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get pending verification IDs
      final pendingIds = prefs.getStringList(_pendingVerificationPrefix) ?? [];
      
      // Remove document ID from pending list
      pendingIds.remove(documentId);
      
      // Save updated pending list
      await prefs.setStringList(_pendingVerificationPrefix, pendingIds);
    } catch (e) {
      debugPrint('Error removing document from pending list: $e');
      rethrow;
    }
  }
  
  // Generate sample documents for testing
  Future<void> generateSampleDocuments(String userId, String applicationId) async {
    try {
      // Sample document URLs (in a real app, these would be actual file URLs)
      const passportUrl = 'https://example.com/passport.pdf';
      const transcriptUrl = 'https://example.com/transcript.pdf';
      const financialUrl = 'https://example.com/financial.pdf';
      
      // Submit sample documents
      await submitDocument(
        documentId: 'doc_passport_$userId',
        applicationId: applicationId,
        userId: userId,
        documentType: 'Passport',
        documentUrl: passportUrl,
      );
      
      await submitDocument(
        documentId: 'doc_transcript_$userId',
        applicationId: applicationId,
        userId: userId,
        documentType: 'Academic Transcript',
        documentUrl: transcriptUrl,
      );
      
      await submitDocument(
        documentId: 'doc_financial_$userId',
        applicationId: applicationId,
        userId: userId,
        documentType: 'Financial Statement',
        documentUrl: financialUrl,
      );
    } catch (e) {
      debugPrint('Error generating sample documents: $e');
    }
  }
}
