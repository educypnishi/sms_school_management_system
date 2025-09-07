import 'package:flutter/material.dart';
import '../models/visa_application_model.dart';
import '../services/visa_application_service.dart';
import '../theme/app_theme.dart';

class VisaApplicationDetailScreen extends StatefulWidget {
  final String visaApplicationId;
  
  const VisaApplicationDetailScreen({
    super.key,
    required this.visaApplicationId,
  });

  @override
  State<VisaApplicationDetailScreen> createState() => _VisaApplicationDetailScreenState();
}

class _VisaApplicationDetailScreenState extends State<VisaApplicationDetailScreen> with SingleTickerProviderStateMixin {
  final VisaApplicationService _visaApplicationService = VisaApplicationService();
  bool _isLoading = true;
  VisaApplicationModel? _visaApplication;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadVisaApplication();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadVisaApplication() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final visaApplication = await _visaApplicationService.getVisaApplication(widget.visaApplicationId);
      
      setState(() {
        _visaApplication = visaApplication;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading visa application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _updateStatus(VisaApplicationStatus status) async {
    if (_visaApplication == null) return;
    
    try {
      await _visaApplicationService.updateVisaApplicationStatus(
        _visaApplication!.id,
        status,
      );
      
      // Reload visa application
      await _loadVisaApplication();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${status.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_visaApplication?.visaType.displayName ?? 'Visa Application'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadVisaApplication,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Milestones'),
            Tab(text: 'Documents'),
            Tab(text: 'Notes'),
          ],
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _visaApplication == null
              ? const Center(child: Text('Visa application not found'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildMilestonesTab(),
                    _buildDocumentsTab(),
                    _buildNotesTab(),
                  ],
                ),
    );
  }
  
  Widget _buildOverviewTab() {
    if (_visaApplication == null) {
      return const Center(child: Text('No data available'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status card
          Card(
            color: _visaApplication!.status.color.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _visaApplication!.status.icon,
                        color: _visaApplication!.status.color,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Status: ${_visaApplication!.status.displayName}',
                        style: TextStyle(
                          color: _visaApplication!.status.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Status update buttons
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusButton(VisaApplicationStatus.notStarted),
                        _buildStatusButton(VisaApplicationStatus.preparing),
                        _buildStatusButton(VisaApplicationStatus.submitted),
                        _buildStatusButton(VisaApplicationStatus.underReview),
                        _buildStatusButton(VisaApplicationStatus.additionalDocumentsRequested),
                        _buildStatusButton(VisaApplicationStatus.approved),
                        _buildStatusButton(VisaApplicationStatus.rejected),
                        _buildStatusButton(VisaApplicationStatus.appealing),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Progress card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Overall Progress'),
                          Text('${_visaApplication!.completionPercentage.toStringAsFixed(0)}%'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _visaApplication!.completionPercentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _visaApplication!.status.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Milestones progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Milestones'),
                      Text(
                        '${_visaApplication!.completedMilestonesCount}/${_visaApplication!.milestones.length}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _visaApplication!.milestones.isNotEmpty
                        ? _visaApplication!.completedMilestonesCount / _visaApplication!.milestones.length
                        : 0,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 16),
                  
                  // Documents progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Documents'),
                      Text(
                        '${_visaApplication!.completedDocumentsCount}/${_visaApplication!.requiredDocumentsCount}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _visaApplication!.requiredDocumentsCount > 0
                        ? _visaApplication!.completedDocumentsCount / _visaApplication!.requiredDocumentsCount
                        : 0,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Details card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Application Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDetailRow('Visa Type', _visaApplication!.visaType.displayName),
                  _buildDetailRow('Application ID', _visaApplication!.applicationId),
                  _buildDetailRow('Country', _visaApplication!.country),
                  _buildDetailRow('Embassy/Consulate', _visaApplication!.embassy),
                  if (_visaApplication!.referenceNumber != null)
                    _buildDetailRow('Reference Number', _visaApplication!.referenceNumber!),
                  _buildDetailRow('Created', _formatDate(_visaApplication!.createdAt)),
                  if (_visaApplication!.submittedAt != null)
                    _buildDetailRow('Submitted', _formatDate(_visaApplication!.submittedAt!)),
                  if (_visaApplication!.approvedAt != null)
                    _buildDetailRow('Approved', _formatDate(_visaApplication!.approvedAt!)),
                  if (_visaApplication!.rejectedAt != null) ...[
                    _buildDetailRow('Rejected', _formatDate(_visaApplication!.rejectedAt!)),
                    if (_visaApplication!.rejectionReason != null)
                      _buildDetailRow('Rejection Reason', _visaApplication!.rejectionReason!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Next steps card
          if (_visaApplication!.nextMilestone != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next Steps',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.flag, color: Colors.white),
                      ),
                      title: Text(_visaApplication!.nextMilestone!.title),
                      subtitle: Text(_visaApplication!.nextMilestone!.description),
                      trailing: _visaApplication!.nextMilestone!.dueDate != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Due Date'),
                                Text(
                                  _formatDate(_visaApplication!.nextMilestone!.dueDate!),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Upcoming appointments card
          if (_visaApplication!.nextAppointment != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upcoming Appointment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.purple,
                        child: Icon(Icons.calendar_today, color: Colors.white),
                      ),
                      title: Text(_visaApplication!.nextAppointment!.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_visaApplication!.nextAppointment!.description),
                          const SizedBox(height: 4),
                          Text(
                            'Location: ${_visaApplication!.nextAppointment!.location}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatDate(_visaApplication!.nextAppointment!.dateTime),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatTime(_visaApplication!.nextAppointment!.dateTime),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildMilestonesTab() {
    if (_visaApplication == null) {
      return const Center(child: Text('No data available'));
    }
    
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Milestones (${_visaApplication!.completedMilestonesCount}/${_visaApplication!.milestones.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Milestone'),
                onPressed: _addMilestone,
              ),
            ],
          ),
        ),
        
        // Milestones list
        Expanded(
          child: _visaApplication!.milestones.isEmpty
              ? const Center(
                  child: Text('No milestones yet'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _visaApplication!.milestones.length,
                  itemBuilder: (context, index) {
                    // Sort milestones by order
                    final sortedMilestones = List<VisaMilestone>.from(_visaApplication!.milestones)
                      ..sort((a, b) => a.order.compareTo(b.order));
                    
                    final milestone = sortedMilestones[index];
                    return _buildMilestoneCard(milestone);
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildMilestoneCard(VisaMilestone milestone) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: milestone.isCompleted
                  ? Colors.green.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  milestone.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                  color: milestone.isCompleted ? Colors.green : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    milestone.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editMilestone(milestone);
                    } else if (value == 'delete') {
                      _deleteMilestone(milestone.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
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
                Text(milestone.description),
                const SizedBox(height: 16),
                
                // Due date
                if (milestone.dueDate != null) ...[                  
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${_formatDate(milestone.dueDate!)}',
                        style: TextStyle(
                          color: milestone.isCompleted
                              ? Colors.grey
                              : milestone.dueDate!.isBefore(DateTime.now())
                                  ? Colors.red
                                  : Colors.grey,
                          fontWeight: milestone.dueDate!.isBefore(DateTime.now()) && !milestone.isCompleted
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Completed date
                if (milestone.completedDate != null) ...[                  
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Completed: ${_formatDate(milestone.completedDate!)}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Required
                Row(
                  children: [
                    Icon(
                      milestone.isRequired ? Icons.priority_high : Icons.low_priority,
                      size: 16,
                      color: milestone.isRequired ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      milestone.isRequired ? 'Required' : 'Optional',
                      style: TextStyle(
                        color: milestone.isRequired ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!milestone.isCompleted) ...[                  
                  TextButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Mark as Completed'),
                    onPressed: () => _completeMilestone(milestone.id),
                  ),
                ] else ...[                  
                  TextButton.icon(
                    icon: const Icon(Icons.undo),
                    label: const Text('Mark as Incomplete'),
                    onPressed: () => _markMilestoneIncomplete(milestone),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _addMilestone() async {
    if (_visaApplication == null) return;
    
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? dueDate;
    bool isRequired = true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Milestone'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Submit Application Form',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g., Fill out and submit the visa application form',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Due Date:'),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      
                      if (selectedDate != null) {
                        dueDate = selectedDate;
                      }
                    },
                    child: const Text('Select Date'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Required Milestone'),
                value: isRequired,
                onChanged: (value) {
                  if (value != null) {
                    isRequired = value;
                  }
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    
    if (result == true && 
        titleController.text.isNotEmpty && 
        descriptionController.text.isNotEmpty) {
      try {
        await _visaApplicationService.addMilestone(
          _visaApplication!.id,
          titleController.text,
          descriptionController.text,
          dueDate,
          isRequired,
        );
        
        // Reload visa application
        await _loadVisaApplication();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Milestone added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding milestone: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _editMilestone(VisaMilestone milestone) async {
    if (_visaApplication == null) return;
    
    final titleController = TextEditingController(text: milestone.title);
    final descriptionController = TextEditingController(text: milestone.description);
    DateTime? dueDate = milestone.dueDate;
    bool isRequired = milestone.isRequired;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Milestone'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Due Date:'),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      
                      if (selectedDate != null) {
                        dueDate = selectedDate;
                      }
                    },
                    child: Text(dueDate != null ? _formatDate(dueDate!) : 'Select Date'),
                  ),
                  if (dueDate != null) ...[                    
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        dueDate = null;
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Required Milestone'),
                value: isRequired,
                onChanged: (value) {
                  if (value != null) {
                    isRequired = value;
                  }
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result == true && 
        titleController.text.isNotEmpty && 
        descriptionController.text.isNotEmpty) {
      try {
        final updatedMilestone = milestone.copyWith(
          title: titleController.text,
          description: descriptionController.text,
          dueDate: dueDate,
          isRequired: isRequired,
        );
        
        await _visaApplicationService.updateMilestone(
          _visaApplication!.id,
          updatedMilestone,
        );
        
        // Reload visa application
        await _loadVisaApplication();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Milestone updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating milestone: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _deleteMilestone(String milestoneId) async {
    if (_visaApplication == null) return;
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Milestone'),
        content: const Text('Are you sure you want to delete this milestone? This action cannot be undone.'),
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
        // Get the milestone index
        final milestoneIndex = _visaApplication!.milestones.indexWhere((m) => m.id == milestoneId);
        if (milestoneIndex == -1) {
          throw Exception('Milestone not found');
        }
        
        // Remove the milestone
        final updatedMilestones = List<VisaMilestone>.from(_visaApplication!.milestones);
        updatedMilestones.removeAt(milestoneIndex);
        
        // Update the visa application
        final updatedVisaApplication = _visaApplication!.copyWith(
          milestones: updatedMilestones,
        );
        
        await _visaApplicationService.updateVisaApplication(updatedVisaApplication);
        
        // Reload visa application
        await _loadVisaApplication();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Milestone deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting milestone: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _completeMilestone(String milestoneId) async {
    if (_visaApplication == null) return;
    
    try {
      await _visaApplicationService.completeMilestone(
        _visaApplication!.id,
        milestoneId,
      );
      
      // Reload visa application
      await _loadVisaApplication();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Milestone completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing milestone: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _markMilestoneIncomplete(VisaMilestone milestone) async {
    if (_visaApplication == null) return;
    
    try {
      final updatedMilestone = milestone.copyWith(
        isCompleted: false,
        completedDate: null,
      );
      
      await _visaApplicationService.updateMilestone(
        _visaApplication!.id,
        updatedMilestone,
      );
      
      // Reload visa application
      await _loadVisaApplication();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Milestone marked as incomplete'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating milestone: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Widget _buildDocumentsTab() {
    if (_visaApplication == null) {
      return const Center(child: Text('No data available'));
    }
    
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Documents (${_visaApplication!.completedDocumentsCount}/${_visaApplication!.requiredDocumentsCount})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Document'),
                onPressed: _addDocument,
              ),
            ],
          ),
        ),
        
        // Documents list
        Expanded(
          child: _visaApplication!.documents.isEmpty
              ? const Center(
                  child: Text('No documents yet'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _visaApplication!.documents.length,
                  itemBuilder: (context, index) {
                    // Group documents by status
                    final documents = _visaApplication!.documents;
                    
                    // First show required documents that are not submitted
                    final requiredNotSubmitted = documents.where(
                      (d) => d.isRequired && !d.isSubmitted
                    ).toList();
                    
                    // Then show submitted documents
                    final submitted = documents.where(
                      (d) => d.isSubmitted
                    ).toList();
                    
                    // Then show optional documents that are not submitted
                    final optionalNotSubmitted = documents.where(
                      (d) => !d.isRequired && !d.isSubmitted
                    ).toList();
                    
                    // Combine the lists
                    final sortedDocuments = [
                      ...requiredNotSubmitted,
                      ...submitted,
                      ...optionalNotSubmitted,
                    ];
                    
                    final document = sortedDocuments[index];
                    return _buildDocumentCard(document);
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildDocumentCard(VisaDocument document) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: document.statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  document.isSubmitted
                      ? document.isApproved
                          ? Icons.check_circle
                          : document.isRejected
                              ? Icons.cancel
                              : Icons.hourglass_top
                      : Icons.file_present,
                  color: document.statusColor,
                ),
                const SizedBox(width: 8),
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
                        document.status,
                        style: TextStyle(
                          color: document.statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editDocument(document);
                    } else if (value == 'delete') {
                      _deleteDocument(document.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
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
                Text(document.description),
                const SizedBox(height: 16),
                
                // Submission date
                if (document.submissionDate != null) ...[                  
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Submitted: ${_formatDate(document.submissionDate!)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Approval date
                if (document.approvalDate != null) ...[                  
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Approved: ${_formatDate(document.approvalDate!)}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Rejection date and reason
                if (document.rejectionDate != null) ...[                  
                  Row(
                    children: [
                      const Icon(Icons.cancel, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        'Rejected: ${_formatDate(document.rejectionDate!)}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                  if (document.rejectionReason != null) ...[                    
                    const SizedBox(height: 4),
                    Text(
                      'Reason: ${document.rejectionReason}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
                
                // Required
                Row(
                  children: [
                    Icon(
                      document.isRequired ? Icons.priority_high : Icons.low_priority,
                      size: 16,
                      color: document.isRequired ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      document.isRequired ? 'Required' : 'Optional',
                      style: TextStyle(
                        color: document.isRequired ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),
                
                // File URL
                if (document.fileUrl != null) ...[                  
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.attach_file, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          document.fileUrl!,
                          style: const TextStyle(color: Colors.blue),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Actions
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!document.isSubmitted) ...[                  
                  TextButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Submit Document'),
                    onPressed: () => _submitDocument(document.id),
                  ),
                ] else if (!document.isApproved && !document.isRejected) ...[                  
                  TextButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Mark as Approved'),
                    onPressed: () => _approveDocument(document),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Mark as Rejected'),
                    onPressed: () => _rejectDocument(document),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _addDocument() async {
    if (_visaApplication == null) return;
    
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isRequired = true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Document'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g., Passport Copy',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g., Copy of passport bio page',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Required Document'),
                value: isRequired,
                onChanged: (value) {
                  if (value != null) {
                    isRequired = value;
                  }
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    
    if (result == true && 
        nameController.text.isNotEmpty && 
        descriptionController.text.isNotEmpty) {
      try {
        await _visaApplicationService.addDocument(
          _visaApplication!.id,
          nameController.text,
          descriptionController.text,
          isRequired,
        );
        
        // Reload visa application
        await _loadVisaApplication();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding document: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _editDocument(VisaDocument document) async {
    if (_visaApplication == null) return;
    
    final nameController = TextEditingController(text: document.name);
    final descriptionController = TextEditingController(text: document.description);
    bool isRequired = document.isRequired;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Document'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Required Document'),
                value: isRequired,
                onChanged: (value) {
                  if (value != null) {
                    isRequired = value;
                  }
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result == true && 
        nameController.text.isNotEmpty && 
        descriptionController.text.isNotEmpty) {
      try {
        final updatedDocument = document.copyWith(
          name: nameController.text,
          description: descriptionController.text,
          isRequired: isRequired,
        );
        
        await _visaApplicationService.updateDocument(
          _visaApplication!.id,
          updatedDocument,
        );
        
        // Reload visa application
        await _loadVisaApplication();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating document: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _deleteDocument(String documentId) async {
    if (_visaApplication == null) return;
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document? This action cannot be undone.'),
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
        // Get the document index
        final documentIndex = _visaApplication!.documents.indexWhere((d) => d.id == documentId);
        if (documentIndex == -1) {
          throw Exception('Document not found');
        }
        
        // Remove the document
        final updatedDocuments = List<VisaDocument>.from(_visaApplication!.documents);
        updatedDocuments.removeAt(documentIndex);
        
        // Update the visa application
        final updatedVisaApplication = _visaApplication!.copyWith(
          documents: updatedDocuments,
        );
        
        await _visaApplicationService.updateVisaApplication(updatedVisaApplication);
        
        // Reload visa application
        await _loadVisaApplication();
        
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
  }
  
  Future<void> _submitDocument(String documentId) async {
    if (_visaApplication == null) return;
    
    // In a real app, this would open a file picker
    // For demo purposes, we'll simulate uploading a document
    final fileUrl = 'https://example.com/documents/$documentId.pdf';
    
    try {
      await _visaApplicationService.submitDocument(
        _visaApplication!.id,
        documentId,
        fileUrl,
      );
      
      // Reload visa application
      await _loadVisaApplication();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _approveDocument(VisaDocument document) async {
    if (_visaApplication == null) return;
    
    try {
      final updatedDocument = document.copyWith(
        isApproved: true,
        isRejected: false,
        approvalDate: DateTime.now(),
        rejectionDate: null,
        rejectionReason: null,
      );
      
      await _visaApplicationService.updateDocument(
        _visaApplication!.id,
        updatedDocument,
      );
      
      // Reload visa application
      await _loadVisaApplication();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _rejectDocument(VisaDocument document) async {
    if (_visaApplication == null) return;
    
    final reasonController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'e.g., Document is not clear',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
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
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      try {
        final updatedDocument = document.copyWith(
          isApproved: false,
          isRejected: true,
          approvalDate: null,
          rejectionDate: DateTime.now(),
          rejectionReason: reasonController.text.isNotEmpty
              ? reasonController.text
              : null,
        );
        
        await _visaApplicationService.updateDocument(
          _visaApplication!.id,
          updatedDocument,
        );
        
        // Reload visa application
        await _loadVisaApplication();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document rejected successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error rejecting document: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Widget _buildNotesTab() {
    // This will be implemented in the next step
    return const Center(
      child: Text('Notes tab will be implemented in the next step'),
    );
  }
  
  Widget _buildStatusButton(VisaApplicationStatus status) {
    final isCurrentStatus = _visaApplication?.status == status;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton.icon(
        icon: Icon(
          status.icon,
          size: 16,
          color: isCurrentStatus ? Colors.white : status.color,
        ),
        label: Text(
          status.displayName,
          style: TextStyle(
            color: isCurrentStatus ? Colors.white : null,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isCurrentStatus ? status.color : Colors.white,
          foregroundColor: isCurrentStatus ? Colors.white : status.color,
          side: BorderSide(color: status.color),
        ),
        onPressed: isCurrentStatus ? null : () => _updateStatus(status),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
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
