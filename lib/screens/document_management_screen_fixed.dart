import 'dart:io';
import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../models/document_verification_model.dart';
import '../services/document_service.dart';
import '../services/document_verification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/document_card.dart';
import '../widgets/document_upload_card.dart';
import '../screens/student_document_status_screen.dart';
import '../screens/admin_document_verification_screen.dart';

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
  final DocumentVerificationService _verificationService = DocumentVerificationService();
  bool _isLoading = true;
  List<DocumentModel> _documents = [];
  List<Map<String, dynamic>> _missingDocuments = [];
  List<DocumentVerificationModel> _verificationDocuments = [];
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
      // Load verification documents
      final verificationDocs = await _verificationService.getApplicationDocuments(widget.applicationId);
      
      // For demo purposes, generate sample data if it doesn't exist
      await _documentService.generateSampleDocuments(widget.userId, widget.applicationId);
      
      // Get documents for this application
      final documents = await _documentService.getApplicationDocuments(widget.applicationId);
      
      // Get missing required documents
      final missingDocs = await _documentService.getMissingRequiredDocuments(widget.applicationId);
      
      setState(() {
        _documents = documents;
        _missingDocuments = missingDocs;
        _verificationDocuments = verificationDocs;
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
  
  Future<void> _uploadDocument(String documentType) async {
    // In a real app, this would open a file picker
    // For demo purposes, we'll simulate uploading a document
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _documentService.uploadDocument(
        userId: widget.userId,
        applicationId: widget.applicationId,
        documentType: documentType,
        file: File(''), // This would be the actual file in a real app
      );
      
      // Reload documents
      await _loadDocuments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _deleteDocument(String documentId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _documentService.deleteDocument(documentId);
      
      // Reload documents
      await _loadDocuments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
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
  
  Future<void> _updateDocumentStatus(String documentId, String status, String reason) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _documentService.updateDocumentStatus(documentId, status, reason);
      
      // Reload documents
      await _loadDocuments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
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
    // In a real app, this would open the document viewer
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Viewing ${document.name}'),
        content: SingleChildScrollView(
          child: Column(
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
  
  void _navigateToVerificationScreen(DocumentModel document) {
    if (widget.isAdmin) {
      // Navigate to admin verification screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminDocumentVerificationScreen(),
        ),
      ).then((_) => _loadDocuments());
    } else {
      // Navigate to student verification status screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudentDocumentStatusScreen(
            applicationId: widget.applicationId,
          ),
        ),
      ).then((_) => _loadDocuments());
    }
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
            Tab(text: 'Required Documents'),
          ],
        ),
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
          return Column(
            children: [
              DocumentCard(
                document: document,
                onView: () => _viewDocument(document),
                onDelete: widget.isAdmin ? null : () => _deleteDocument(document.id),
                onUpdateStatus: widget.isAdmin ? (status, reason) => _updateDocumentStatus(document.id, status, reason) : null,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _navigateToVerificationScreen(document),
                icon: const Icon(Icons.verified),
                label: Text(widget.isAdmin ? 'Verify Document' : 'Check Verification Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
            ],
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
        const Text(
          'Required Documents',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please upload the following required documents for your application',
          style: TextStyle(
            color: AppTheme.lightTextColor,
          ),
        ),
        const SizedBox(height: 16),
        
        // Required documents
        ..._missingDocuments.map((document) => _buildMissingDocumentCard(document)),
        
        const SizedBox(height: 32),
        
        // Optional documents
        const Text(
          'Optional Documents',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'These documents are optional but may help with your application',
          style: TextStyle(
            color: AppTheme.lightTextColor,
          ),
        ),
        const SizedBox(height: 16),
        
        // Optional document cards
        ...requiredDocuments
            .where((doc) => doc['required'] == false)
            .map((document) => _buildMissingDocumentCard(document)),
      ],
    );
  }

  Widget _buildMissingDocumentCard(Map<String, dynamic> document) {
    return DocumentUploadCard(
      documentType: document['type'],
      description: document['description'],
      onUpload: () => _uploadDocument(document['type']),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
