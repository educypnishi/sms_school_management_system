import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NewDocumentsScreen extends StatefulWidget {
  const NewDocumentsScreen({super.key});

  @override
  State<NewDocumentsScreen> createState() => _NewDocumentsScreenState();
}

class _NewDocumentsScreenState extends State<NewDocumentsScreen> {
  // Sample documents with proper typing
  final List<DocumentItem> _documents = [
    DocumentItem(
      name: 'Academic Transcript',
      type: 'PDF',
      size: '2.4 MB',
      uploadDate: '2024-09-15',
      status: 'Approved',
      icon: Icons.description,
      color: Colors.green,
    ),
    DocumentItem(
      name: 'Identity Card Copy',
      type: 'PDF',
      size: '1.2 MB',
      uploadDate: '2024-09-10',
      status: 'Approved',
      icon: Icons.credit_card,
      color: Colors.green,
    ),
    DocumentItem(
      name: 'Fee Receipt',
      type: 'PDF',
      size: '856 KB',
      uploadDate: '2024-10-01',
      status: 'Pending Review',
      icon: Icons.receipt,
      color: Colors.orange,
    ),
    DocumentItem(
      name: 'Medical Certificate',
      type: 'PDF',
      size: '1.8 MB',
      uploadDate: '2024-09-20',
      status: 'Under Review',
      icon: Icons.local_hospital,
      color: Colors.blue,
    ),
  ];

  final List<RequiredDocumentItem> _requiredDocuments = [
    RequiredDocumentItem(
      name: 'Character Certificate',
      description: 'From previous institution',
      icon: Icons.verified_user,
      color: Colors.red,
      isUrgent: true,
    ),
    RequiredDocumentItem(
      name: 'Birth Certificate',
      description: 'Official birth certificate copy',
      icon: Icons.child_care,
      color: Colors.orange,
      isUrgent: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _showUploadDialog,
            tooltip: 'Upload Document',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDocuments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: AppTheme.primaryColor,
              child: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    icon: Icon(Icons.folder_open),
                    text: 'My Documents',
                  ),
                  Tab(
                    icon: Icon(Icons.warning_amber),
                    text: 'Required',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildMyDocumentsTab(),
                  _buildRequiredDocumentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMyDocumentsTab() {
    if (_documents.isEmpty) {
      return _buildEmptyState(
        icon: Icons.folder_open,
        title: 'No Documents Yet',
        subtitle: 'Upload your first document to get started',
        actionText: 'Upload Document',
        onAction: _showUploadDialog,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshDocuments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _documents.length,
        itemBuilder: (context, index) {
          final document = _documents[index];
          return _buildDocumentCard(document);
        },
      ),
    );
  }

  Widget _buildRequiredDocumentsTab() {
    if (_requiredDocuments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle,
        title: 'All Documents Submitted',
        subtitle: 'You have submitted all required documents',
        actionText: null,
        onAction: null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requiredDocuments.length,
      itemBuilder: (context, index) {
        final document = _requiredDocuments[index];
        return _buildRequiredDocumentCard(document);
      },
    );
  }

  Widget _buildDocumentCard(DocumentItem document) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: document.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _viewDocument(document),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: document.color.withOpacity(0.1),
                    radius: 24,
                    child: Icon(
                      document.icon,
                      color: document.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${document.type} • ${document.size}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Uploaded: ${document.uploadDate}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleDocumentAction(value, document),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.visibility),
                          title: Text('View'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'download',
                        child: ListTile(
                          leading: Icon(Icons.download),
                          title: Text('Download'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.share),
                          title: Text('Share'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: document.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: document.color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(document.status),
                      size: 16,
                      color: document.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      document.status,
                      style: TextStyle(
                        color: document.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequiredDocumentCard(RequiredDocumentItem document) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: document.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: document.color.withOpacity(0.1),
                  radius: 24,
                  child: Icon(
                    document.icon,
                    color: document.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              document.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (document.isUrgent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'URGENT',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        document.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _uploadRequiredDocument(document),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: document.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.upload_file),
                label: Text(actionText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'pending review':
      case 'under review':
        return Icons.schedule;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  void _handleDocumentAction(String action, DocumentItem document) {
    switch (action) {
      case 'view':
        _viewDocument(document);
        break;
      case 'download':
        _downloadDocument(document);
        break;
      case 'share':
        _shareDocument(document);
        break;
      case 'delete':
        _deleteDocument(document);
        break;
    }
  }

  void _viewDocument(DocumentItem document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('View Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${document.name}'),
            Text('Type: ${document.type}'),
            Text('Size: ${document.size}'),
            Text('Status: ${document.status}'),
            Text('Uploaded: ${document.uploadDate}'),
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
              _downloadDocument(document);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _downloadDocument(DocumentItem document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${document.name}...'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'View',
          onPressed: () {},
        ),
      ),
    );
  }

  void _shareDocument(DocumentItem document) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${document.name}...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _deleteDocument(DocumentItem document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _documents.remove(document);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${document.name} deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _uploadRequiredDocument(RequiredDocumentItem document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload ${document.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(document.description),
            const SizedBox(height: 16),
            const Text('Supported formats: PDF, JPG, PNG'),
            const Text('Maximum size: 10 MB'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Upload functionality for ${document.name} coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Choose File'),
          ),
        ],
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload New Document'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select a document to upload:'),
            SizedBox(height: 16),
            Text('Supported formats: PDF, JPG, PNG, DOC, DOCX'),
            Text('Maximum size: 10 MB'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document upload functionality coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            icon: const Icon(Icons.upload_file),
            label: const Text('Choose File'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshDocuments() async {
    // Simulate refresh delay
    await Future.delayed(const Duration(seconds: 1));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Documents refreshed'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

// Document model classes with proper typing
class DocumentItem {
  final String name;
  final String type;
  final String size;
  final String uploadDate;
  final String status;
  final IconData icon;
  final Color color;

  DocumentItem({
    required this.name,
    required this.type,
    required this.size,
    required this.uploadDate,
    required this.status,
    required this.icon,
    required this.color,
  });
}

class RequiredDocumentItem {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUrgent;

  RequiredDocumentItem({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUrgent,
  });
}
