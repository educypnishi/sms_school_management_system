import 'dart:io';
import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../theme/app_theme.dart';

/// A widget for uploading documents
class DocumentUploadCard extends StatefulWidget {
  final DocumentType documentType;
  final String title;
  final String description;
  final bool isRequired;
  final Function(File file, DocumentType type, String title, String description) onUpload;

  const DocumentUploadCard({
    super.key,
    required this.documentType,
    required this.title,
    required this.description,
    required this.isRequired,
    required this.onUpload,
  });

  @override
  State<DocumentUploadCard> createState() => _DocumentUploadCardState();
}

class _DocumentUploadCardState extends State<DocumentUploadCard> {
  File? _selectedFile;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document title and required badge
            Row(
              children: [
                Icon(
                  _getIconForDocumentType(widget.documentType),
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (widget.isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Required',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Document description
            Text(
              widget.description,
              style: const TextStyle(color: AppTheme.lightTextColor),
            ),
            const SizedBox(height: 16),
            
            // Selected file preview
            if (_selectedFile != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFile!.path.split('/').last,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          FutureBuilder<int>(
                            future: _selectedFile!.length(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                final size = snapshot.data!;
                                return Text(
                                  _formatFileSize(size),
                                  style: const TextStyle(fontSize: 12, color: AppTheme.lightTextColor),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        setState(() {
                          _selectedFile = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Upload buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _selectFile,
                    icon: const Icon(Icons.file_upload),
                    label: Text(_selectedFile == null ? 'Select File' : 'Change File'),
                  ),
                ),
                if (_selectedFile != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _uploadFile,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: const Text('Upload'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFile() async {
    // In a real app, we would use a file picker plugin
    // For this demo, we'll just simulate selecting a file
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Simulate a selected file
    setState(() {
      _selectedFile = File('document.pdf');
    });
    
    // Show a snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File selected (simulated)'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      // Call the onUpload callback
      await widget.onUpload(
        _selectedFile!,
        widget.documentType,
        widget.title,
        widget.description,
      );
      
      // Reset the state
      if (mounted) {
        setState(() {
          _selectedFile = null;
          _isUploading = false;
        });
        
        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show an error message
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getIconForDocumentType(DocumentType type) {
    switch (type) {
      case DocumentType.reportCard:
        return Icons.grade;
      case DocumentType.certificate:
        return Icons.card_membership;
      case DocumentType.idCard:
        return Icons.badge;
      case DocumentType.birthCertificate:
        return Icons.child_care;
      case DocumentType.medicalRecord:
        return Icons.medical_services;
      case DocumentType.parentConsent:
        return Icons.family_restroom;
      case DocumentType.previousSchoolRecord:
        return Icons.school;
      case DocumentType.immunizationRecord:
        return Icons.health_and_safety;
      case DocumentType.other:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int size) {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
