import 'dart:io';
import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../services/document_service.dart';
import '../theme/app_theme.dart';
import '../widgets/document_card.dart';
import '../widgets/document_upload_card.dart';

class DocumentManagementScreen extends StatefulWidget {
  final String userId;
  final String applicationId;
  final bool isAdmin;

  const DocumentManagementScreen({
    super.key,
    required this.userId,
    required this.applicationId,
    this.isAdmin = false,
  });

  @override
  State<DocumentManagementScreen> createState() => _DocumentManagementScreenState();
}

class _DocumentManagementScreenState extends State<DocumentManagementScreen> with SingleTickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();
  bool _isLoading = true;
  List<DocumentModel> _documents = [];
  List<Map<String, dynamic>> _missingDocuments = [];
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDocuments();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // For demo purposes, generate sample data if it doesn't exist
      await _documentService.generateSampleDocuments(widget.userId, widget.applicationId);
      
      // Get documents for this application
      final documents = await _documentService.getApplicationDocuments(widget.applicationId);
      
      // Get missing required documents
      final missingDocs = await _documentService.getMissingRequiredDocuments(widget.applicationId);
      
      setState(() {
        _documents = documents;
        _missingDocuments = missingDocs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading documents: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadDocument(File file, DocumentType type, String title, String description) async {
    try {
      final document = await _documentService.uploadDocument(
        userId: widget.userId,
        applicationId: widget.applicationId,
        title: title,
        description: description,
        type: type,
        file: file,
      );
      
      setState(() {
        _documents.add(document);
        
        // Remove from missing documents if applicable
        _missingDocuments.removeWhere((doc) => doc['type'] == type);
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _deleteDocument(String documentId) async {
    try {
      await _documentService.deleteDocument(documentId);
      
      setState(() {
        _documents.removeWhere((doc) => doc.id == documentId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateDocumentStatus(String documentId, DocumentVerificationStatus status, String? reason) async {
    try {
      final updatedDocument = await _documentService.updateDocumentStatus(
        documentId: documentId,
        status: status,
        verifiedBy: 'Admin',
        rejectionReason: reason,
      );
      
      setState(() {
        final index = _documents.indexWhere((doc) => doc.id == documentId);
        if (index != -1) {
          _documents[index] = updatedDocument;
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == DocumentVerificationStatus.verified
                  ? 'Document verified successfully'
                  : 'Document rejected',
            ),
            backgroundColor: status == DocumentVerificationStatus.verified ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating document status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewDocument(DocumentModel document) {
    // In a real app, we would open the document for viewing
    // For this demo, we'll just show a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(document.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Document Preview (Simulated)'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.insert_drive_file,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('File Name: ${document.fileName}'),
            Text('File Size: ${document.formattedFileSize}'),
            Text('Upload Date: ${_formatDate(document.uploadDate)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document downloaded (simulated)'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Documents'),
            Tab(text: 'Upload Documents'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocuments,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDocumentsTab(),
                _buildUploadTab(),
              ],
            ),
    );
  }

  Widget _buildDocumentsTab() {
    if (_documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.folder_open,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Documents Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload your documents using the Upload tab',
              style: TextStyle(color: AppTheme.lightTextColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _tabController.animateTo(1);
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Documents'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _documents.length,
        itemBuilder: (context, index) {
          final document = _documents[index];
          return DocumentCard(
            document: document,
            onView: () => _viewDocument(document),
            onDelete: widget.isAdmin ? null : () => _deleteDocument(document.id),
            onUpdateStatus: widget.isAdmin ? (status, reason) => _updateDocumentStatus(document.id, status, reason) : null,
          );
        },
      ),
    );
  }

  Widget _buildUploadTab() {
    final requiredDocuments = _documentService.getRequiredDocuments();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Missing required documents section
        if (_missingDocuments.isNotEmpty) ...[
          const Text(
            'Required Documents',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please upload the following required documents:',
            style: TextStyle(color: AppTheme.lightTextColor),
          ),
          const SizedBox(height: 16),
          
          // List of missing required documents
          ..._missingDocuments.map((doc) => DocumentUploadCard(
            documentType: doc['type'] as DocumentType,
            title: doc['title'] as String,
            description: doc['description'] as String,
            isRequired: true,
            onUpload: _uploadDocument,
          )),
          
          const Divider(height: 32),
        ],
        
        // Upload additional documents section
        const Text(
          'Additional Documents',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'You can upload additional documents to support your application:',
          style: TextStyle(color: AppTheme.lightTextColor),
        ),
        const SizedBox(height: 16),
        
        // Additional document types
        DocumentUploadCard(
          documentType: DocumentType.recommendationLetter,
          title: 'Recommendation Letter',
          description: 'Letter of recommendation from a teacher or employer',
          isRequired: false,
          onUpload: _uploadDocument,
        ),
        DocumentUploadCard(
          documentType: DocumentType.certificate,
          title: 'Additional Certificate',
          description: 'Any additional certificates or qualifications',
          isRequired: false,
          onUpload: _uploadDocument,
        ),
        DocumentUploadCard(
          documentType: DocumentType.other,
          title: 'Other Document',
          description: 'Any other supporting document for your application',
          isRequired: false,
          onUpload: _uploadDocument,
        ),
      ],
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document Management Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to use Document Management:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• View your uploaded documents in the "My Documents" tab'),
              Text('• Upload required and additional documents in the "Upload Documents" tab'),
              Text('• Required documents are marked with a "Required" badge'),
              Text('• You can view, download, or delete your documents'),
              Text('• Document verification status is shown on each document'),
              SizedBox(height: 16),
              Text(
                'Document Status:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Pending: Document is awaiting verification'),
              Text('• Verified: Document has been verified by our team'),
              Text('• Rejected: Document was rejected (see rejection reason)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
