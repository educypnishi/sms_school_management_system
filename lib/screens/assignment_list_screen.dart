import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/assignment_service.dart';
import '../models/assignment_model.dart';
import 'assignment_creator_screen.dart';

class AssignmentListScreen extends StatefulWidget {
  final String? className;
  final String? teacherId;
  final bool isTeacherView;

  const AssignmentListScreen({
    super.key,
    this.className,
    this.teacherId,
    this.isTeacherView = false,
  });

  @override
  State<AssignmentListScreen> createState() => _AssignmentListScreenState();
}

class _AssignmentListScreenState extends State<AssignmentListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AssignmentService _assignmentService = AssignmentService();
  List<AssignmentModel> _assignments = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAssignments();
    _generateSampleData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generateSampleData() async {
    await _assignmentService.generateSampleAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() => _isLoading = true);
    
    try {
      List<AssignmentModel> assignments;
      
      if (widget.className != null) {
        assignments = await _assignmentService.getAssignmentsByClass(widget.className!);
      } else if (widget.teacherId != null) {
        assignments = await _assignmentService.getAssignmentsByTeacher(widget.teacherId!);
      } else {
        assignments = await _assignmentService.getAllAssignments();
      }
      
      setState(() {
        _assignments = assignments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading assignments: $e')),
        );
      }
    }
  }

  List<AssignmentModel> get _filteredAssignments {
    switch (_selectedFilter) {
      case 'Active':
        return _assignments.where((a) => a.status == AssignmentStatus.active).toList();
      case 'Overdue':
        return _assignments.where((a) => a.isOverdue && a.status == AssignmentStatus.active).toList();
      case 'Draft':
        return _assignments.where((a) => a.status == AssignmentStatus.draft).toList();
      case 'Closed':
        return _assignments.where((a) => a.status == AssignmentStatus.closed).toList();
      default:
        return _assignments;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTeacherView ? 'My Assignments' : 'Assignments'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list)),
            Tab(text: 'Active', icon: Icon(Icons.assignment_turned_in)),
            Tab(text: 'Overdue', icon: Icon(Icons.warning)),
            Tab(text: 'Draft', icon: Icon(Icons.drafts)),
          ],
        ),
        actions: [
          if (widget.isTeacherView)
            IconButton(
              onPressed: _createNewAssignment,
              icon: const Icon(Icons.add),
              tooltip: 'Create Assignment',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedFilter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Assignments')),
              const PopupMenuItem(value: 'Active', child: Text('Active Only')),
              const PopupMenuItem(value: 'Overdue', child: Text('Overdue Only')),
              const PopupMenuItem(value: 'Draft', child: Text('Drafts Only')),
              const PopupMenuItem(value: 'Closed', child: Text('Closed Only')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssignmentList(_assignments),
          _buildAssignmentList(_assignments.where((a) => a.status == AssignmentStatus.active).toList()),
          _buildAssignmentList(_assignments.where((a) => a.isOverdue && a.status == AssignmentStatus.active).toList()),
          _buildAssignmentList(_assignments.where((a) => a.status == AssignmentStatus.draft).toList()),
        ],
      ),
      floatingActionButton: widget.isTeacherView
          ? FloatingActionButton(
              onPressed: _createNewAssignment,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildAssignmentList(List<AssignmentModel> assignments) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (assignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No assignments found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              widget.isTeacherView 
                  ? 'Create your first assignment to get started'
                  : 'Check back later for new assignments',
              style: TextStyle(color: Colors.grey[500]),
            ),
            if (widget.isTeacherView) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _createNewAssignment,
                icon: const Icon(Icons.add),
                label: const Text('Create Assignment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssignments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: assignments.length,
        itemBuilder: (context, index) {
          final assignment = assignments[index];
          return _buildAssignmentCard(assignment);
        },
      ),
    );
  }

  Widget _buildAssignmentCard(AssignmentModel assignment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _viewAssignmentDetails(assignment),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${assignment.subject} • ${assignment.className}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: assignment.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: assignment.statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      assignment.statusDisplayName,
                      style: TextStyle(
                        color: assignment.statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Text(
                assignment.description,
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    assignment.teacherName,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    assignment.dueDateFormatted,
                    style: TextStyle(
                      color: assignment.isOverdue ? Colors.red : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: assignment.isOverdue ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${assignment.maxMarks} marks',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
              if (assignment.attachments.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attach_file, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${assignment.attachments.length} attachment${assignment.attachments.length > 1 ? 's' : ''}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
              
              if (widget.isTeacherView) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _viewSubmissions(assignment),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Submissions'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleAssignmentAction(assignment, value),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                        const PopupMenuItem(value: 'close', child: Text('Close')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      child: const Icon(Icons.more_vert),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _createNewAssignment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AssignmentCreatorScreen(),
      ),
    ).then((_) => _loadAssignments());
  }

  void _viewAssignmentDetails(AssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      assignment.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Subject', assignment.subject),
                      _buildDetailRow('Class', assignment.className),
                      _buildDetailRow('Teacher', assignment.teacherName),
                      _buildDetailRow('Due Date', assignment.dueDateFormatted),
                      _buildDetailRow('Max Marks', '${assignment.maxMarks}'),
                      _buildDetailRow('Late Submission', assignment.allowLateSubmission ? 'Allowed' : 'Not Allowed'),
                      const SizedBox(height: 16),
                      const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(assignment.description),
                      if (assignment.attachments.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Attachments:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...assignment.attachments.map((attachment) => 
                          ListTile(
                            leading: const Icon(Icons.attach_file),
                            title: Text(attachment),
                            dense: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!widget.isTeacherView)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _submitAssignment(assignment),
                    icon: const Icon(Icons.upload),
                    label: const Text('Submit Assignment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
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
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _viewSubmissions(AssignmentModel assignment) {
    // Navigate to submissions screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Submissions view will be implemented')),
    );
  }

  void _handleAssignmentAction(AssignmentModel assignment, String action) {
    switch (action) {
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit assignment will be implemented')),
        );
        break;
      case 'duplicate':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment duplicated')),
        );
        break;
      case 'close':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment closed')),
        );
        break;
      case 'delete':
        _deleteAssignment(assignment);
        break;
    }
  }

  void _deleteAssignment(AssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assignment'),
        content: Text('Are you sure you want to delete "${assignment.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _assignmentService.deleteAssignment(assignment.id);
                _loadAssignments();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Assignment deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting assignment: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _submitAssignment(AssignmentModel assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Assignment'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Submission Text',
                border: OutlineInputBorder(),
                hintText: 'Enter your submission or notes',
              ),
              maxLines: 4,
            ),
            SizedBox(height: 16),
            Text('File attachments will be implemented in the next update.'),
          ],
        ),
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
                  content: Text('Assignment submitted successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
