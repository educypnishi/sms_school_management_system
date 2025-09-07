import 'package:flutter/material.dart';
import '../models/visa_application_model.dart';
import '../services/visa_application_service.dart';
import '../theme/app_theme.dart';
import 'visa_application_detail_screen.dart';

class VisaApplicationListScreen extends StatefulWidget {
  final String userId;
  
  const VisaApplicationListScreen({
    super.key,
    required this.userId,
  });

  @override
  State<VisaApplicationListScreen> createState() => _VisaApplicationListScreenState();
}

class _VisaApplicationListScreenState extends State<VisaApplicationListScreen> {
  final VisaApplicationService _visaApplicationService = VisaApplicationService();
  bool _isLoading = true;
  List<VisaApplicationModel> _visaApplications = [];
  
  @override
  void initState() {
    super.initState();
    _loadVisaApplications();
  }
  
  Future<void> _loadVisaApplications() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final visaApplications = await _visaApplicationService.getVisaApplicationsForUser(widget.userId);
      
      setState(() {
        _visaApplications = visaApplications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading visa applications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _createNewVisaApplication() async {
    // Show dialog to create a new visa application
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CreateVisaApplicationDialog(),
    );
    
    if (result != null) {
      try {
        await _visaApplicationService.createVisaApplication(
          userId: widget.userId,
          applicationId: result['applicationId'],
          visaType: result['visaType'],
          country: result['country'],
          embassy: result['embassy'],
        );
        
        // Reload visa applications
        await _loadVisaApplications();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visa application created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating visa application: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _deleteVisaApplication(String id) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Visa Application'),
        content: const Text('Are you sure you want to delete this visa application? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await _visaApplicationService.deleteVisaApplication(id);
        
        // Reload visa applications
        await _loadVisaApplications();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visa application deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting visa application: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visa Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadVisaApplications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _visaApplications.isEmpty
              ? _buildEmptyState()
              : _buildVisaApplicationsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewVisaApplication,
        tooltip: 'Create New Visa Application',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.flight_takeoff,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Visa Applications Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a new visa application to get started',
            style: TextStyle(color: AppTheme.lightTextColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewVisaApplication,
            icon: const Icon(Icons.add),
            label: const Text('Create New Visa Application'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVisaApplicationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _visaApplications.length,
      itemBuilder: (context, index) {
        final visaApplication = _visaApplications[index];
        return _buildVisaApplicationCard(visaApplication);
      },
    );
  }
  
  Widget _buildVisaApplicationCard(VisaApplicationModel visaApplication) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VisaApplicationDetailScreen(
                visaApplicationId: visaApplication.id,
              ),
            ),
          ).then((_) => _loadVisaApplications());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: visaApplication.status.color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    visaApplication.status.icon,
                    color: visaApplication.status.color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visaApplication.visaType.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          visaApplication.status.displayName,
                          style: TextStyle(
                            color: visaApplication.status.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteVisaApplication(visaApplication.id);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Country and Embassy
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${visaApplication.country} - ${visaApplication.embassy}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Reference Number
                  if (visaApplication.referenceNumber != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.numbers, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Ref: ${visaApplication.referenceNumber}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Progress
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Progress'),
                          Text('${visaApplication.completionPercentage.toStringAsFixed(0)}%'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: visaApplication.completionPercentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          visaApplication.status.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Next Milestone
                  if (visaApplication.nextMilestone != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.flag, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        const Text(
                          'Next Step:',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(visaApplication.nextMilestone!.title),
                    if (visaApplication.nextMilestone!.dueDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Due: ${_formatDate(visaApplication.nextMilestone!.dueDate!)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ],
                  
                  // Next Appointment
                  if (visaApplication.nextAppointment != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.purple),
                        const SizedBox(width: 4),
                        const Text(
                          'Upcoming Appointment:',
                          style: TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(visaApplication.nextAppointment!.title),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDate(visaApplication.nextAppointment!.dateTime)} at ${_formatTime(visaApplication.nextAppointment!.dateTime)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created: ${_formatDate(visaApplication.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Updated: ${_formatDate(visaApplication.updatedAt)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
  
  String _formatTime(DateTime dateTime) {
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _CreateVisaApplicationDialog extends StatefulWidget {
  @override
  State<_CreateVisaApplicationDialog> createState() => _CreateVisaApplicationDialogState();
}

class _CreateVisaApplicationDialogState extends State<_CreateVisaApplicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _applicationIdController = TextEditingController();
  final _countryController = TextEditingController(text: 'Cyprus');
  final _embassyController = TextEditingController();
  VisaType _visaType = VisaType.student;
  
  @override
  void dispose() {
    _applicationIdController.dispose();
    _countryController.dispose();
    _embassyController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Visa Application'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Application ID
              TextFormField(
                controller: _applicationIdController,
                decoration: const InputDecoration(
                  labelText: 'Application ID',
                  hintText: 'e.g., APP123456',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an application ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Visa Type
              const Text('Visa Type:'),
              DropdownButtonFormField<VisaType>(
                value: _visaType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: VisaType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _visaType = value;
                    });
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a visa type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Country
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a country';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Embassy
              TextFormField(
                controller: _embassyController,
                decoration: const InputDecoration(
                  labelText: 'Embassy/Consulate',
                  hintText: 'e.g., Cyprus Embassy in London',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an embassy or consulate';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'applicationId': _applicationIdController.text,
                'visaType': _visaType,
                'country': _countryController.text,
                'embassy': _embassyController.text,
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
