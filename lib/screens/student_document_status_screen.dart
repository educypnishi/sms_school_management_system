import 'package:flutter/material.dart';
import '../models/document_verification_model.dart';
import '../services/document_verification_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/toast_util.dart';

class StudentDocumentStatusScreen extends StatefulWidget {
  final String applicationId;
  
  const StudentDocumentStatusScreen({
    super.key,
    required this.applicationId,
  });

  @override
  State<StudentDocumentStatusScreen> createState() => _StudentDocumentStatusScreenState();
}

class _StudentDocumentStatusScreenState extends State<StudentDocumentStatusScreen> {
  final DocumentVerificationService _documentVerificationService = DocumentVerificationService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = true;
  List<DocumentVerificationModel> _documents = [];
  DocumentVerificationModel? _selectedDocument;
  String _userId = '';
  
  @override
  void initState() {
    super.initState();
    _loadUserDocuments();
  }
  
  Future<void> _loadUserDocuments() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get current user
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      _userId = currentUser.id;
      
      // Get documents for this application
      final documents = await _documentVerificationService.getApplicationDocuments(widget.applicationId);
      
      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading documents: $e');
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ToastUtil.showToast(
          context: context,
          message: 'Error loading documents: $e',
        );
      }
    }
  }
  
  void _selectDocument(DocumentVerificationModel document) {
    setState(() {
      _selectedDocument = document;
    });
  }
  
  Future<void> _uploadNewVersion() async {
    if (_selectedDocument == null) {
      ToastUtil.showToast(
        context: context,
        message: 'No document selected',
      );
      return;
    }
    
    // In a real app, this would open a file picker
    // For now, we'll simulate uploading a new version
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Simulate a new document URL
      final newDocumentUrl = '${_selectedDocument!.documentUrl}?v=${DateTime.now().millisecondsSinceEpoch}';
      
      // Submit new version
      await _documentVerificationService.submitDocument(
        documentId: '${_selectedDocument!.documentId}_v${_selectedDocument!.version + 1}',
        applicationId: widget.applicationId,
        userId: _userId,
        documentType: _selectedDocument!.documentType,
        documentUrl: newDocumentUrl,
        previousVersionId: _selectedDocument!.id,
      );
      
      // Reload documents
      await _loadUserDocuments();
      
      if (mounted) {
        ToastUtil.showToast(
          context: context,
          message: 'New version uploaded successfully',
        );
      }
    } catch (e) {
      debugPrint('Error uploading new version: $e');
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ToastUtil.showToast(
          context: context,
          message: 'Error uploading new version: $e',
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserDocuments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Document List (Left Panel)
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.grey[100],
                    child: _documents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('No documents found'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    // In a real app, this would navigate to document upload screen
                                    ToastUtil.showToast(
                                      context: context,
                                      message: 'Document upload will be implemented in the next phase',
                                    );
                                  },
                                  child: const Text('Upload Documents'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _documents.length,
                            itemBuilder: (context, index) {
                              final document = _documents[index];
                              return Card(
                                margin: const EdgeInsets.all(8),
                                child: ListTile(
                                  leading: Icon(
                                    _getDocumentTypeIcon(document.documentType),
                                    color: document.getStatusColor(),
                                  ),
                                  title: Text(document.documentType),
                                  subtitle: Text(
                                    'Status: ${document.getStatusText()}',
                                    style: TextStyle(
                                      color: document.getStatusColor(),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: document.version > 1
                                      ? Chip(
                                          label: Text('v${document.version}'),
                                          backgroundColor: Colors.grey[200],
                                        )
                                      : null,
                                  selected: _selectedDocument?.id == document.id,
                                  selectedTileColor: Colors.blue[50],
                                  onTap: () => _selectDocument(document),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                
                // Document Details (Right Panel)
                Expanded(
                  flex: 2,
                  child: _selectedDocument == null
                      ? const Center(
                          child: Text('Select a document to view details'),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Document Info
                              Row(
                                children: [
                                  Icon(
                                    _selectedDocument!.getStatusIcon(),
                                    color: _selectedDocument!.getStatusColor(),
                                    size: 32,
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedDocument!.documentType,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Status: ${_selectedDocument!.getStatusText()}',
                                        style: TextStyle(
                                          color: _selectedDocument!.getStatusColor(),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Uploaded: ${_formatDate(_selectedDocument!.uploadedAt)}',
                                style: const TextStyle(
                                  color: AppTheme.lightTextColor,
                                ),
                              ),
                              if (_selectedDocument!.verifiedAt != null)
                                Text(
                                  'Verified: ${_formatDate(_selectedDocument!.verifiedAt!)}',
                                  style: const TextStyle(
                                    color: AppTheme.lightTextColor,
                                  ),
                                ),
                              Text(
                                'Version: ${_selectedDocument!.version}',
                                style: const TextStyle(
                                  color: AppTheme.lightTextColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Document Preview
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.description,
                                          size: 64,
                                          color: AppTheme.primaryColor,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Document URL: ${_selectedDocument!.documentUrl}',
                                          style: const TextStyle(
                                            color: AppTheme.lightTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            // In a real app, this would open the document
                                            ToastUtil.showToast(
                                              context: context,
                                              message: 'Document viewer will be implemented in the next phase',
                                            );
                                          },
                                          child: const Text('View Document'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Feedback History
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Feedback History',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: _selectedDocument!.feedbackHistory.isEmpty
                                          ? const Center(
                                              child: Text('No feedback yet'),
                                            )
                                          : ListView.builder(
                                              itemCount: _selectedDocument!.feedbackHistory.length,
                                              itemBuilder: (context, index) {
                                                final feedback = _selectedDocument!.feedbackHistory[index];
                                                return Card(
                                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                                  child: ListTile(
                                                    title: Text(feedback.comment),
                                                    subtitle: Text(
                                                      '${feedback.verifierName} - ${_formatDate(feedback.timestamp)}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Action Buttons
                              if (_selectedDocument!.status == VerificationStatus.rejected ||
                                  _selectedDocument!.status == VerificationStatus.needsClarification)
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: _uploadNewVersion,
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text('Upload New Version'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
    );
  }
  
  IconData _getDocumentTypeIcon(String documentType) {
    switch (documentType.toLowerCase()) {
      case 'passport':
        return Icons.credit_card;
      case 'academic transcript':
        return Icons.school;
      case 'financial statement':
        return Icons.account_balance_wallet;
      case 'photo':
        return Icons.photo;
      case 'motivation letter':
        return Icons.description;
      case 'recommendation letter':
        return Icons.recommend;
      default:
        return Icons.description;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
