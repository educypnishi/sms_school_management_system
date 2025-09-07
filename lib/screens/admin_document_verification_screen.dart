import 'package:flutter/material.dart';
import '../models/document_verification_model.dart';
import '../services/document_verification_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/toast_util.dart';

class AdminDocumentVerificationScreen extends StatefulWidget {
  const AdminDocumentVerificationScreen({super.key});

  @override
  State<AdminDocumentVerificationScreen> createState() => _AdminDocumentVerificationScreenState();
}

class _AdminDocumentVerificationScreenState extends State<AdminDocumentVerificationScreen> {
  final DocumentVerificationService _documentVerificationService = DocumentVerificationService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = true;
  List<DocumentVerificationModel> _pendingDocuments = [];
  DocumentVerificationModel? _selectedDocument;
  final TextEditingController _feedbackController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadPendingDocuments();
  }
  
  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPendingDocuments() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final documents = await _documentVerificationService.getPendingVerifications();
      
      setState(() {
        _pendingDocuments = documents;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading pending documents: $e');
      
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
  
  Future<void> _updateDocumentStatus(VerificationStatus status) async {
    if (_selectedDocument == null) {
      ToastUtil.showToast(
        context: context,
        message: 'No document selected',
      );
      return;
    }
    
    if (_feedbackController.text.isEmpty) {
      ToastUtil.showToast(
        context: context,
        message: 'Please provide feedback',
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _documentVerificationService.updateDocumentStatus(
        documentId: _selectedDocument!.id,
        status: status,
        comment: _feedbackController.text.trim(),
      );
      
      // Clear feedback and selected document
      _feedbackController.clear();
      
      // Reload documents
      await _loadPendingDocuments();
      
      setState(() {
        _selectedDocument = null;
      });
      
      if (mounted) {
        ToastUtil.showToast(
          context: context,
          message: 'Document status updated successfully',
        );
      }
    } catch (e) {
      debugPrint('Error updating document status: $e');
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ToastUtil.showToast(
          context: context,
          message: 'Error updating document status: $e',
        );
      }
    }
  }
  
  void _selectDocument(DocumentVerificationModel document) {
    setState(() {
      _selectedDocument = document;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingDocuments,
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
                    child: _pendingDocuments.isEmpty
                        ? const Center(
                            child: Text('No pending documents'),
                          )
                        : ListView.builder(
                            itemCount: _pendingDocuments.length,
                            itemBuilder: (context, index) {
                              final document = _pendingDocuments[index];
                              return Card(
                                margin: const EdgeInsets.all(8),
                                child: ListTile(
                                  leading: Icon(
                                    _getDocumentTypeIcon(document.documentType),
                                    color: AppTheme.primaryColor,
                                  ),
                                  title: Text(document.documentType),
                                  subtitle: Text(
                                    'Uploaded: ${_formatDate(document.uploadedAt)}',
                                  ),
                                  selected: _selectedDocument?.id == document.id,
                                  selectedTileColor: Colors.blue[50],
                                  onTap: () => _selectDocument(document),
                                ),
                              );
                            },
                          ),
                  ),
                ),
                
                // Document Preview and Actions (Right Panel)
                Expanded(
                  flex: 2,
                  child: _selectedDocument == null
                      ? const Center(
                          child: Text('Select a document to verify'),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Document Info
                              Text(
                                _selectedDocument!.documentType,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Application ID: ${_selectedDocument!.applicationId}',
                                style: const TextStyle(
                                  color: AppTheme.lightTextColor,
                                ),
                              ),
                              Text(
                                'Uploaded: ${_formatDate(_selectedDocument!.uploadedAt)}',
                                style: const TextStyle(
                                  color: AppTheme.lightTextColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Document Preview
                              Expanded(
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
                              
                              // Feedback Input
                              TextField(
                                controller: _feedbackController,
                                decoration: const InputDecoration(
                                  labelText: 'Feedback',
                                  hintText: 'Enter your feedback or comments',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              
                              // Action Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _updateDocumentStatus(VerificationStatus.verified),
                                    icon: const Icon(Icons.check_circle),
                                    label: const Text('Verify'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _updateDocumentStatus(VerificationStatus.needsClarification),
                                    icon: const Icon(Icons.help),
                                    label: const Text('Need Clarification'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _updateDocumentStatus(VerificationStatus.rejected),
                                    icon: const Icon(Icons.cancel),
                                    label: const Text('Reject'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                  ),
                                ],
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
