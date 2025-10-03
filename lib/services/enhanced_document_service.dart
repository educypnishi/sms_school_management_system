import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../models/document_model.dart';
import '../services/auth_service.dart';

class EnhancedDocumentService {
  static const String _documentsKey = 'documents';
  static const String _versionsKey = 'document_versions';
  static const String _templatesKey = 'document_templates';
  static const String _workflowsKey = 'approval_workflows';
  
  // Document Management with Versioning
  
  // Upload document with versioning support
  Future<DocumentModel> uploadDocument({
    required String fileName,
    required String filePath,
    required String userId,
    required String category,
    String? description,
    Map<String, dynamic>? metadata,
    String? parentDocumentId, // For versioning
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Generate document ID
      final documentId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Calculate file hash for integrity check
      final file = File(filePath);
      final fileBytes = await file.readAsBytes();
      final fileHash = sha256.convert(fileBytes).toString();
      
      // Get file size
      final fileSize = await file.length();
      
      // Copy file to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final documentsDir = Directory('${appDir.path}/documents');
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }
      
      final newFilePath = '${documentsDir.path}/$documentId-$fileName';
      await file.copy(newFilePath);
      
      // Determine version number
      int versionNumber = 1;
      if (parentDocumentId != null) {
        final versions = await getDocumentVersions(parentDocumentId);
        versionNumber = versions.length + 1;
      }
      
      // Create document model
      final document = DocumentModel(
        id: documentId,
        fileName: fileName,
        filePath: newFilePath,
        fileSize: fileSize,
        fileHash: fileHash,
        mimeType: _getMimeType(fileName),
        uploadedBy: currentUser.id,
        uploadedByName: currentUser.name,
        uploadedAt: DateTime.now(),
        category: category,
        description: description,
        metadata: metadata ?? {},
        status: DocumentStatus.pending,
        versionNumber: versionNumber,
        parentDocumentId: parentDocumentId,
        isLatestVersion: true,
      );
      
      // Save document
      await _saveDocument(document);
      
      // If this is a new version, update the previous version
      if (parentDocumentId != null) {
        await _updatePreviousVersions(parentDocumentId);
      }
      
      // Create approval workflow if required
      if (_requiresApproval(category)) {
        await _createApprovalWorkflow(documentId, category);
      }
      
      return document;
    } catch (e) {
      debugPrint('Error uploading document: $e');
      rethrow;
    }
  }
  
  // Get document by ID
  Future<DocumentModel?> getDocumentById(String documentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final documentJson = prefs.getString('document_$documentId');
      
      if (documentJson == null) {
        return null;
      }
      
      final documentMap = jsonDecode(documentJson) as Map<String, dynamic>;
      return DocumentModel.fromMap(documentMap, documentId);
    } catch (e) {
      debugPrint('Error getting document: $e');
      return null;
    }
  }
  
  // Get document versions
  Future<List<DocumentModel>> getDocumentVersions(String documentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final documentKeys = allKeys.where((key) => key.startsWith('document_')).toList();
      
      final versions = <DocumentModel>[];
      
      for (final key in documentKeys) {
        final docJson = prefs.getString(key);
        if (docJson != null) {
          final docMap = jsonDecode(docJson) as Map<String, dynamic>;
          final doc = DocumentModel.fromMap(docMap, key.substring('document_'.length));
          
          // Check if this document is a version of the requested document
          if (doc.id == documentId || doc.parentDocumentId == documentId) {
            versions.add(doc);
          }
        }
      }
      
      // Sort by version number
      versions.sort((a, b) => b.versionNumber.compareTo(a.versionNumber));
      
      return versions;
    } catch (e) {
      debugPrint('Error getting document versions: $e');
      return [];
    }
  }
  
  // Create new version of document
  Future<DocumentModel> createNewVersion({
    required String parentDocumentId,
    required String fileName,
    required String filePath,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final parentDoc = await getDocumentById(parentDocumentId);
      if (parentDoc == null) {
        throw Exception('Parent document not found');
      }
      
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      return await uploadDocument(
        fileName: fileName,
        filePath: filePath,
        userId: currentUser.id,
        category: parentDoc.category,
        description: description,
        metadata: metadata,
        parentDocumentId: parentDocumentId,
      );
    } catch (e) {
      debugPrint('Error creating new version: $e');
      rethrow;
    }
  }
  
  // Approve document
  Future<void> approveDocument({
    required String documentId,
    String? approvalNotes,
  }) async {
    try {
      final document = await getDocumentById(documentId);
      if (document == null) {
        throw Exception('Document not found');
      }
      
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Update document status
      final updatedDocument = document.copyWith(
        status: DocumentStatus.approved,
        approvedBy: currentUser.id,
        approvedByName: currentUser.name,
        approvedAt: DateTime.now(),
        approvalNotes: approvalNotes,
      );
      
      await _saveDocument(updatedDocument);
      
      // Update workflow status
      await _updateWorkflowStatus(documentId, WorkflowStatus.approved);
      
    } catch (e) {
      debugPrint('Error approving document: $e');
      rethrow;
    }
  }
  
  // Reject document
  Future<void> rejectDocument({
    required String documentId,
    required String rejectionReason,
  }) async {
    try {
      final document = await getDocumentById(documentId);
      if (document == null) {
        throw Exception('Document not found');
      }
      
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Update document status
      final updatedDocument = document.copyWith(
        status: DocumentStatus.rejected,
        rejectedBy: currentUser.id,
        rejectedByName: currentUser.name,
        rejectedAt: DateTime.now(),
        rejectionReason: rejectionReason,
      );
      
      await _saveDocument(updatedDocument);
      
      // Update workflow status
      await _updateWorkflowStatus(documentId, WorkflowStatus.rejected);
      
    } catch (e) {
      debugPrint('Error rejecting document: $e');
      rethrow;
    }
  }
  
  // Search documents
  Future<List<DocumentModel>> searchDocuments({
    String? query,
    String? category,
    DocumentStatus? status,
    String? uploadedBy,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final allDocuments = await getAllDocuments();
      
      return allDocuments.where((doc) {
        // Text search
        if (query != null && query.isNotEmpty) {
          final searchText = query.toLowerCase();
          if (!doc.fileName.toLowerCase().contains(searchText) &&
              !(doc.description?.toLowerCase().contains(searchText) ?? false)) {
            return false;
          }
        }
        
        // Category filter
        if (category != null && doc.category != category) {
          return false;
        }
        
        // Status filter
        if (status != null && doc.status != status) {
          return false;
        }
        
        // Uploaded by filter
        if (uploadedBy != null && doc.uploadedBy != uploadedBy) {
          return false;
        }
        
        // Date range filter
        if (fromDate != null && doc.uploadedAt.isBefore(fromDate)) {
          return false;
        }
        
        if (toDate != null && doc.uploadedAt.isAfter(toDate)) {
          return false;
        }
        
        return true;
      }).toList();
    } catch (e) {
      debugPrint('Error searching documents: $e');
      return [];
    }
  }
  
  // Get all documents
  Future<List<DocumentModel>> getAllDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final documentKeys = allKeys.where((key) => key.startsWith('document_')).toList();
      
      final documents = <DocumentModel>[];
      
      for (final key in documentKeys) {
        final docJson = prefs.getString(key);
        if (docJson != null) {
          final docMap = jsonDecode(docJson) as Map<String, dynamic>;
          final doc = DocumentModel.fromMap(docMap, key.substring('document_'.length));
          documents.add(doc);
        }
      }
      
      // Sort by upload date (newest first)
      documents.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      
      return documents;
    } catch (e) {
      debugPrint('Error getting all documents: $e');
      return [];
    }
  }
  
  // Delete document
  Future<void> deleteDocument(String documentId) async {
    try {
      final document = await getDocumentById(documentId);
      if (document == null) {
        return;
      }
      
      // Delete physical file
      final file = File(document.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      
      // Remove from storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('document_$documentId');
      
      // Delete associated workflow
      await prefs.remove('workflow_$documentId');
      
    } catch (e) {
      debugPrint('Error deleting document: $e');
      rethrow;
    }
  }
  
  // Document Templates
  
  // Create document template
  Future<DocumentTemplate> createDocumentTemplate({
    required String name,
    required String category,
    required Map<String, dynamic> fields,
    String? description,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templateId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final template = DocumentTemplate(
        id: templateId,
        name: name,
        category: category,
        fields: fields,
        description: description,
        createdAt: DateTime.now(),
        isActive: true,
      );
      
      await prefs.setString('template_$templateId', jsonEncode(template.toMap()));
      
      return template;
    } catch (e) {
      debugPrint('Error creating document template: $e');
      rethrow;
    }
  }
  
  // Get document templates
  Future<List<DocumentTemplate>> getDocumentTemplates({String? category}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final templateKeys = allKeys.where((key) => key.startsWith('template_')).toList();
      
      final templates = <DocumentTemplate>[];
      
      for (final key in templateKeys) {
        final templateJson = prefs.getString(key);
        if (templateJson != null) {
          final templateMap = jsonDecode(templateJson) as Map<String, dynamic>;
          final template = DocumentTemplate.fromMap(templateMap, key.substring('template_'.length));
          
          if (category == null || template.category == category) {
            templates.add(template);
          }
        }
      }
      
      return templates;
    } catch (e) {
      debugPrint('Error getting document templates: $e');
      return [];
    }
  }
  
  // Helper methods
  
  Future<void> _saveDocument(DocumentModel document) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('document_${document.id}', jsonEncode(document.toMap()));
  }
  
  Future<void> _updatePreviousVersions(String parentDocumentId) async {
    final versions = await getDocumentVersions(parentDocumentId);
    
    for (final version in versions) {
      if (version.isLatestVersion && version.id != parentDocumentId) {
        final updatedVersion = version.copyWith(isLatestVersion: false);
        await _saveDocument(updatedVersion);
      }
    }
  }
  
  bool _requiresApproval(String category) {
    // Define categories that require approval
    const approvalCategories = [
      'academic_records',
      'financial_documents',
      'legal_documents',
      'certificates',
    ];
    
    return approvalCategories.contains(category);
  }
  
  Future<void> _createApprovalWorkflow(String documentId, String category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final workflow = ApprovalWorkflow(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        documentId: documentId,
        category: category,
        status: WorkflowStatus.pending,
        createdAt: DateTime.now(),
        requiredApprovers: _getRequiredApprovers(category),
        currentStep: 0,
      );
      
      await prefs.setString('workflow_$documentId', jsonEncode(workflow.toMap()));
    } catch (e) {
      debugPrint('Error creating approval workflow: $e');
    }
  }
  
  Future<void> _updateWorkflowStatus(String documentId, WorkflowStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workflowJson = prefs.getString('workflow_$documentId');
      
      if (workflowJson != null) {
        final workflowMap = jsonDecode(workflowJson) as Map<String, dynamic>;
        workflowMap['status'] = status.toString().split('.').last;
        workflowMap['completedAt'] = DateTime.now().toIso8601String();
        
        await prefs.setString('workflow_$documentId', jsonEncode(workflowMap));
      }
    } catch (e) {
      debugPrint('Error updating workflow status: $e');
    }
  }
  
  List<String> _getRequiredApprovers(String category) {
    // Define required approvers based on category
    switch (category) {
      case 'academic_records':
        return ['academic_admin', 'principal'];
      case 'financial_documents':
        return ['finance_admin', 'accountant'];
      case 'legal_documents':
        return ['legal_admin', 'principal'];
      default:
        return ['admin'];
    }
  }
  
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}

// Document Model Extensions
class DocumentModel {
  final String id;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String fileHash;
  final String mimeType;
  final String uploadedBy;
  final String uploadedByName;
  final DateTime uploadedAt;
  final String category;
  final String? description;
  final Map<String, dynamic> metadata;
  final DocumentStatus status;
  final int versionNumber;
  final String? parentDocumentId;
  final bool isLatestVersion;
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? approvalNotes;
  final String? rejectedBy;
  final String? rejectedByName;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  
  DocumentModel({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.fileHash,
    required this.mimeType,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.uploadedAt,
    required this.category,
    this.description,
    required this.metadata,
    required this.status,
    required this.versionNumber,
    this.parentDocumentId,
    required this.isLatestVersion,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.approvalNotes,
    this.rejectedBy,
    this.rejectedByName,
    this.rejectedAt,
    this.rejectionReason,
  });
  
  factory DocumentModel.fromMap(Map<String, dynamic> map, String id) {
    return DocumentModel(
      id: id,
      fileName: map['fileName'] ?? '',
      filePath: map['filePath'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      fileHash: map['fileHash'] ?? '',
      mimeType: map['mimeType'] ?? '',
      uploadedBy: map['uploadedBy'] ?? '',
      uploadedByName: map['uploadedByName'] ?? '',
      uploadedAt: DateTime.parse(map['uploadedAt']),
      category: map['category'] ?? '',
      description: map['description'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      status: DocumentStatus.values.firstWhere(
        (s) => s.toString().split('.').last == map['status'],
        orElse: () => DocumentStatus.pending,
      ),
      versionNumber: map['versionNumber'] ?? 1,
      parentDocumentId: map['parentDocumentId'],
      isLatestVersion: map['isLatestVersion'] ?? true,
      approvedBy: map['approvedBy'],
      approvedByName: map['approvedByName'],
      approvedAt: map['approvedAt'] != null ? DateTime.parse(map['approvedAt']) : null,
      approvalNotes: map['approvalNotes'],
      rejectedBy: map['rejectedBy'],
      rejectedByName: map['rejectedByName'],
      rejectedAt: map['rejectedAt'] != null ? DateTime.parse(map['rejectedAt']) : null,
      rejectionReason: map['rejectionReason'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
      'fileHash': fileHash,
      'mimeType': mimeType,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
      'uploadedAt': uploadedAt.toIso8601String(),
      'category': category,
      'description': description,
      'metadata': metadata,
      'status': status.toString().split('.').last,
      'versionNumber': versionNumber,
      'parentDocumentId': parentDocumentId,
      'isLatestVersion': isLatestVersion,
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'approvedAt': approvedAt?.toIso8601String(),
      'approvalNotes': approvalNotes,
      'rejectedBy': rejectedBy,
      'rejectedByName': rejectedByName,
      'rejectedAt': rejectedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }
  
  DocumentModel copyWith({
    String? fileName,
    String? filePath,
    int? fileSize,
    String? fileHash,
    String? mimeType,
    String? uploadedBy,
    String? uploadedByName,
    DateTime? uploadedAt,
    String? category,
    String? description,
    Map<String, dynamic>? metadata,
    DocumentStatus? status,
    int? versionNumber,
    String? parentDocumentId,
    bool? isLatestVersion,
    String? approvedBy,
    String? approvedByName,
    DateTime? approvedAt,
    String? approvalNotes,
    String? rejectedBy,
    String? rejectedByName,
    DateTime? rejectedAt,
    String? rejectionReason,
  }) {
    return DocumentModel(
      id: id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      fileHash: fileHash ?? this.fileHash,
      mimeType: mimeType ?? this.mimeType,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedByName: uploadedByName ?? this.uploadedByName,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      category: category ?? this.category,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      versionNumber: versionNumber ?? this.versionNumber,
      parentDocumentId: parentDocumentId ?? this.parentDocumentId,
      isLatestVersion: isLatestVersion ?? this.isLatestVersion,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      approvalNotes: approvalNotes ?? this.approvalNotes,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectedByName: rejectedByName ?? this.rejectedByName,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

enum DocumentStatus {
  pending,
  approved,
  rejected,
  archived,
}

class DocumentTemplate {
  final String id;
  final String name;
  final String category;
  final Map<String, dynamic> fields;
  final String? description;
  final DateTime createdAt;
  final bool isActive;
  
  DocumentTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.fields,
    this.description,
    required this.createdAt,
    required this.isActive,
  });
  
  factory DocumentTemplate.fromMap(Map<String, dynamic> map, String id) {
    return DocumentTemplate(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      fields: Map<String, dynamic>.from(map['fields'] ?? {}),
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      isActive: map['isActive'] ?? true,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'fields': fields,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}

class ApprovalWorkflow {
  final String id;
  final String documentId;
  final String category;
  final WorkflowStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<String> requiredApprovers;
  final int currentStep;
  
  ApprovalWorkflow({
    required this.id,
    required this.documentId,
    required this.category,
    required this.status,
    required this.createdAt,
    this.completedAt,
    required this.requiredApprovers,
    required this.currentStep,
  });
  
  factory ApprovalWorkflow.fromMap(Map<String, dynamic> map, String id) {
    return ApprovalWorkflow(
      id: id,
      documentId: map['documentId'] ?? '',
      category: map['category'] ?? '',
      status: WorkflowStatus.values.firstWhere(
        (s) => s.toString().split('.').last == map['status'],
        orElse: () => WorkflowStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      requiredApprovers: List<String>.from(map['requiredApprovers'] ?? []),
      currentStep: map['currentStep'] ?? 0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'category': category,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'requiredApprovers': requiredApprovers,
      'currentStep': currentStep,
    };
  }
}

enum WorkflowStatus {
  pending,
  approved,
  rejected,
}
