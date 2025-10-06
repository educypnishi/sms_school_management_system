import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SimpleDocumentScreen extends StatefulWidget {
  const SimpleDocumentScreen({super.key});

  @override
  State<SimpleDocumentScreen> createState() => _SimpleDocumentScreenState();
}

class _SimpleDocumentScreenState extends State<SimpleDocumentScreen> {
  final List<Map<String, dynamic>> _documents = [
    {
      'name': 'Academic Transcript',
      'type': 'PDF',
      'size': '2.4 MB',
      'uploadDate': '2024-09-15',
      'status': 'Approved',
      'icon': Icons.description,
      'color': Colors.green,
    },
    {
      'name': 'Identity Card Copy',
      'type': 'PDF',
      'size': '1.2 MB',
      'uploadDate': '2024-09-10',
      'status': 'Approved',
      'icon': Icons.credit_card,
      'color': Colors.green,
    },
    {
      'name': 'Fee Receipt',
      'type': 'PDF',
      'size': '856 KB',
      'uploadDate': '2024-10-01',
      'status': 'Pending Review',
      'icon': Icons.receipt,
      'color': Colors.orange,
    },
  ];

  final List<Map<String, dynamic>> _requiredDocuments = [
    {
      'name': 'Medical Certificate',
      'description': 'Required for enrollment completion',
      'icon': Icons.local_hospital,
      'color': Colors.red,
    },
    {
      'name': 'Character Certificate',
      'description': 'From previous institution',
      'icon': Icons.verified_user,
      'color': Colors.blue,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              _showUploadDialog();
            },
            tooltip: 'Upload Document',
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
                tabs: [
                  Tab(
                    icon: Icon(Icons.folder),
                    text: 'My Documents',
                  ),
                  Tab(
                    icon: Icon(Icons.warning),
                    text: 'Required',
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildDocumentsTab(),
                  _buildRequiredTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final doc = _documents[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (doc['color'] as Color? ?? Colors.blue).withAlpha(25),
              child: Icon(
                doc['icon'] as IconData? ?? Icons.description,
                color: doc['color'] as Color? ?? Colors.blue,
              ),
            ),
            title: Text(
              doc['name'] as String? ?? 'Unknown Document',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${doc['type'] ?? 'Unknown'} • ${doc['size'] ?? 'Unknown size'}'),
                Text('Uploaded: ${doc['uploadDate'] ?? 'Unknown date'}'),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (doc['color'] as Color? ?? Colors.blue).withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    doc['status'] as String? ?? 'Unknown Status',
                    style: TextStyle(
                      color: doc['color'] as Color? ?? Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    _viewDocument(doc);
                    break;
                  case 'download':
                    _downloadDocument(doc);
                    break;
                  case 'delete':
                    _deleteDocument(doc);
                    break;
                }
              },
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
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequiredTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requiredDocuments.length,
      itemBuilder: (context, index) {
        final doc = _requiredDocuments[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: (doc['color'] as Color? ?? Colors.red).withAlpha(25),
              child: Icon(
                doc['icon'] as IconData? ?? Icons.description,
                color: doc['color'] as Color? ?? Colors.red,
              ),
            ),
            title: Text(
              doc['name'] as String? ?? 'Required Document',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(doc['description'] as String? ?? 'No description available'),
            trailing: ElevatedButton.icon(
              onPressed: () {
                _uploadRequiredDocument(doc);
              },
              icon: const Icon(Icons.upload, size: 16),
              label: const Text('Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: doc['color'] as Color? ?? Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Document'),
        content: const Text('Document upload functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Upload functionality coming soon!'),
                ),
              );
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  void _viewDocument(Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing ${doc['name'] ?? 'document'}'),
      ),
    );
  }

  void _downloadDocument(Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${doc['name'] ?? 'document'}'),
      ),
    );
  }

  void _deleteDocument(Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete ${doc['name'] ?? 'this document'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _documents.remove(doc);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${doc['name'] ?? 'Document'} deleted'),
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

  void _uploadRequiredDocument(Map<String, dynamic> doc) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Upload ${doc['name'] ?? 'document'} functionality coming soon!'),
      ),
    );
  }
}
