import 'package:flutter/material.dart';
import '../utils/toast_util.dart';
import '../models/application_model.dart';
import '../models/user_model.dart';
import '../services/application_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  State<AdminApplicationsScreen> createState() => _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
  final ApplicationService _applicationService = ApplicationService();
  final AuthService _authService = AuthService();
  List<ApplicationModel> _applications = [];
  List<UserModel> _partners = [];
  bool _isLoading = true;
  String? _selectedPartnerId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    await Future.wait([
      _loadApplications(),
      _loadPartners(),
    ]);
  }

  Future<void> _loadApplications() async {
    try {
      // For Phase 4, we'll get all applications
      // In a real app, this would filter by status, date, etc.
      final applications = await _applicationService.getAllApplications();
      
      setState(() {
        _applications = applications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading applications: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ToastUtil.showToast(
      context: context,
      message: 'Error loading applications: $e',
    );
    }
  }
  
  Future<void> _loadPartners() async {
    try {
      // For Phase 5, we'll simulate getting partners
      // In a real app, this would get partners from Firestore
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Create dummy partner users - use the same IDs as in the application service
      final partners = [
        UserModel(
          id: 'partner1',
          name: 'Partner 1',
          email: 'partner1@example.com',
          role: 'partner',
          createdAt: DateTime.now(),
        ),
        UserModel(
          id: 'partner2',
          name: 'Partner 2',
          email: 'partner2@example.com',
          role: 'partner',
          createdAt: DateTime.now(),
        ),
      ];
      
      setState(() {
        _partners = partners;
      });
    } catch (e) {
      debugPrint('Error loading partners: $e');
    }
  }

  Future<void> _updateApplicationStatus(String applicationId, String newStatus) async {
    try {
      await _applicationService.updateApplicationStatus(applicationId, newStatus);
      
      // Refresh applications list
      await _loadApplications();
      
      // Show success message
      ToastUtil.showToast(
      context: context,
      message: 'Application status updated',
    );
    } catch (e) {
      debugPrint('Error updating application status: $e');
      
      // Show error message
      ToastUtil.showToast(
      context: context,
      message: 'Error updating application status: $e',
    );
    }
  }
  
  Future<void> _assignToPartner(String applicationId) async {
    // Reset selected partner
    _selectedPartnerId = null;
    
    // Show partner selection dialog
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign to Partner'),
        content: _partners.isEmpty
            ? const Text('No partners available')
            : DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Partner',
                  border: OutlineInputBorder(),
                ),
                items: _partners.map((partner) {
                  return DropdownMenuItem<String>(
                    value: partner.id,
                    child: Text(partner.name),
                  );
                }).toList(),
                onChanged: (value) {
                  _selectedPartnerId = value;
                },
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_selectedPartnerId != null) {
                Navigator.pop(context);
                
                try {
                  await _applicationService.assignApplicationToPartner(
                    applicationId,
                    _selectedPartnerId!,
                  );
                  
                  // Refresh applications list
                  await _loadApplications();
                  
                  // Show success message
                  ToastUtil.showToast(
      context: context,
      message: 'Application assigned to partner',
    );
                } catch (e) {
                  debugPrint('Error assigning application: $e');
                  
                  // Show error message
                  ToastUtil.showToast(
      context: context,
      message: 'Error assigning application: $e',
    );
                }
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
              ? const Center(
                  child: Text(
                    'No applications found',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _applications.length,
                  itemBuilder: (context, index) {
                    final application = _applications[index];
                    return _buildApplicationCard(application);
                  },
                ),
    );
  }

  Widget _buildApplicationCard(ApplicationModel application) {
    // Determine status color
    Color statusColor;
    switch (application.status) {
      case 'submitted':
        statusColor = Colors.blue;
        break;
      case 'in_review':
        statusColor = Colors.orange;
        break;
      case 'accepted':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Application ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ID: ${application.id.substring(0, 8)}...',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTextColor,
                  ),
                ),
                Chip(
                  label: Text(
                    application.status.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.whiteColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Applicant Details
            Text(
              application.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              application.email,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.lightTextColor,
              ),
            ),
            Text(
              application.phone,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.lightTextColor,
              ),
            ),
            
            // Partner Assignment Info
            if (application.assignedPartnerId != null) ...[  
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.business,
                    size: 16,
                    color: AppTheme.secondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned to Partner: ${_partners.firstWhere(
                      (p) => p.id == application.assignedPartnerId,
                      orElse: () => UserModel(
                        id: '',
                        name: 'Unknown',
                        email: '',
                        role: '',
                        createdAt: DateTime.now(),
                      ),
                    ).name}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            
            // Timestamps
            Text(
              'Submitted: ${application.submittedAt?.toString().substring(0, 16) ?? 'Not submitted'}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.lightTextColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // In Review Button
                if (application.status == 'submitted')
                  ElevatedButton(
                    onPressed: () => _updateApplicationStatus(application.id, 'in_review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Mark In Review'),
                  ),
                  
                // Assign to Partner Button
                if (application.status == 'submitted' && application.assignedPartnerId == null)
                  ElevatedButton(
                    onPressed: () => _assignToPartner(application.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('Assign to Partner'),
                  ),
                  
                // Accept/Reject Buttons
                if (application.status == 'in_review') ...[
                  ElevatedButton(
                    onPressed: () => _updateApplicationStatus(application.id, 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Accept'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _updateApplicationStatus(application.id, 'rejected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Reject'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
