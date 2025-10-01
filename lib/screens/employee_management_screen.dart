import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All Employees', icon: Icon(Icons.people)),
            Tab(text: 'Departments', icon: Icon(Icons.business)),
            Tab(text: 'Attendance', icon: Icon(Icons.access_time)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search employees...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEmployeesList(),
                _buildDepartmentsList(),
                _buildAttendanceView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEmployeeDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmployeesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 10, // Placeholder count
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Text('E${index + 1}', style: const TextStyle(color: Colors.white)),
            ),
            title: Text('Employee ${index + 1}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Department: ${_getDepartmentName(index)}'),
                Text('ID: EMP00${index + 1}'),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility),
                      SizedBox(width: 8),
                      Text('View Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                _handleEmployeeAction(value.toString(), index);
              },
            ),
            onTap: () {
              // Navigate to employee profile
            },
          ),
        );
      },
    );
  }

  Widget _buildDepartmentsList() {
    final departments = [
      {'name': 'Administration', 'count': 5, 'head': 'Ahmad Ali'},
      {'name': 'Maintenance', 'count': 8, 'head': 'Syed Hassan'},
      {'name': 'Security', 'count': 4, 'head': 'Muhammad Khan'},
      {'name': 'Cafeteria', 'count': 6, 'head': 'Fatima Sheikh'},
      {'name': 'Transport', 'count': 3, 'head': 'Ali Raza'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: departments.length,
      itemBuilder: (context, index) {
        final dept = departments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Text('${dept['count']}', style: const TextStyle(color: Colors.white)),
            ),
            title: Text(dept['name'] as String),
            subtitle: Text('Head: ${dept['head']}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDeptStat('Total Staff', '${dept['count']}'),
                        _buildDeptStat('Present Today', '${(dept['count'] as int) - 1}'),
                        _buildDeptStat('On Leave', '1'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // View department details
                            },
                            icon: const Icon(Icons.visibility),
                            label: const Text('View Details'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Manage department
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('Manage'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceView() {
    return Column(
      children: [
        // Date Selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('Today\'s Attendance'),
                        const SizedBox(height: 8),
                        Text(
                          '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  // Select different date
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('Change Date'),
              ),
            ],
          ),
        ),
        
        // Attendance Summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: _buildAttendanceStat('Present', '28', Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _buildAttendanceStat('Absent', '3', Colors.red)),
              const SizedBox(width: 8),
              Expanded(child: _buildAttendanceStat('Late', '2', Colors.orange)),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Attendance List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 15,
            itemBuilder: (context, index) {
              final status = index < 10 ? 'Present' : (index < 13 ? 'Absent' : 'Late');
              final color = status == 'Present' ? Colors.green : 
                           status == 'Absent' ? Colors.red : Colors.orange;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: Icon(
                      status == 'Present' ? Icons.check : 
                      status == 'Absent' ? Icons.close : Icons.access_time,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text('Employee ${index + 1}'),
                  subtitle: Text('Department: ${_getDepartmentName(index)}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (status == 'Present' || status == 'Late')
                        Text(
                          '9:${(index % 60).toString().padLeft(2, '0')} AM',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDeptStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAttendanceStat(String label, String count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }

  String _getDepartmentName(int index) {
    final departments = ['Administration', 'Maintenance', 'Security', 'Cafeteria', 'Transport'];
    return departments[index % departments.length];
  }

  void _handleEmployeeAction(String action, int index) {
    switch (action) {
      case 'view':
        // Navigate to employee profile
        break;
      case 'edit':
        // Navigate to edit employee
        break;
      case 'delete':
        _showDeleteConfirmation(index);
        break;
    }
  }

  void _showAddEmployeeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Employee'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Employee ID',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
              ),
            ),
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
              // Add employee logic
            },
            child: const Text('Add Employee'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete Employee ${index + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Delete employee logic
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
