import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PayrollManagementScreen extends StatefulWidget {
  const PayrollManagementScreen({super.key});

  @override
  State<PayrollManagementScreen> createState() => _PayrollManagementScreenState();
}

class _PayrollManagementScreenState extends State<PayrollManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _selectedMonth = 'January 2025';

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
        title: const Text('Payroll Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Salary Processing', icon: Icon(Icons.payment)),
            Tab(text: 'Payslips', icon: Icon(Icons.receipt)),
            Tab(text: 'Reports', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Month Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Text('Payroll Month: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedMonth,
                    isExpanded: true,
                    items: [
                      'January 2025',
                      'December 2024',
                      'November 2024',
                      'October 2024',
                    ].map((month) => DropdownMenuItem(
                      value: month,
                      child: Text(month),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _showProcessPayrollDialog();
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Process Payroll'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSalaryProcessingTab(),
                _buildPayslipsTab(),
                _buildReportsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryProcessingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Processing Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payroll Processing Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(child: _buildStatusCard('Total Employees', '33', Colors.blue)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatusCard('Processed', '28', Colors.green)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildStatusCard('Pending', '5', Colors.orange)),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  LinearProgressIndicator(
                    value: 28 / 33,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  const Text('85% Complete', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Employee List
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Employee Salary Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      final isProcessed = index < 7;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isProcessed ? Colors.green : Colors.orange,
                            child: Icon(
                              isProcessed ? Icons.check : Icons.pending,
                              color: Colors.white,
                            ),
                          ),
                          title: Text('Employee ${index + 1}'),
                          subtitle: Text('Department: ${_getDepartmentName(index)}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'PKR ${(40000 + (index * 2000)).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                isProcessed ? 'Processed' : 'Pending',
                                style: TextStyle(
                                  color: isProcessed ? Colors.green : Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            _showSalaryDetailsDialog(index);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayslipsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search and Filter
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search employee...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  _showBulkActionsDialog();
                },
                icon: const Icon(Icons.download),
                label: const Text('Bulk Download'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Payslips List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 15,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.receipt, color: Colors.white),
                  ),
                  title: Text('Employee ${index + 1}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Department: ${_getDepartmentName(index)}'),
                      Text('Net Salary: PKR ${(40000 + (index * 2000)).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          // View payslip
                        },
                        icon: const Icon(Icons.visibility),
                        tooltip: 'View Payslip',
                      ),
                      IconButton(
                        onPressed: () {
                          // Download payslip
                        },
                        icon: const Icon(Icons.download),
                        tooltip: 'Download PDF',
                      ),
                      IconButton(
                        onPressed: () {
                          // Send via email
                        },
                        icon: const Icon(Icons.email),
                        tooltip: 'Send Email',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(child: _buildReportCard('Total Payroll', 'PKR 1,485,000', Icons.account_balance_wallet, Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _buildReportCard('Tax Deducted', 'PKR 89,100', Icons.receipt, Colors.red)),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(child: _buildReportCard('Average Salary', 'PKR 45,000', Icons.trending_up, Colors.green)),
              const SizedBox(width: 8),
              Expanded(child: _buildReportCard('Employees Paid', '33', Icons.people, Colors.orange)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Department-wise Breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Department-wise Payroll',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      final departments = [
                        {'name': 'Teaching Staff', 'count': 20, 'amount': 900000},
                        {'name': 'Administration', 'count': 5, 'amount': 225000},
                        {'name': 'Maintenance', 'count': 4, 'amount': 160000},
                        {'name': 'Security', 'count': 3, 'amount': 120000},
                        {'name': 'Transport', 'count': 1, 'amount': 80000},
                      ];
                      
                      final dept = departments[index];
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          child: Text('${dept['count']}', style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(dept['name'] as String),
                        subtitle: Text('${dept['count']} employees'),
                        trailing: Text(
                          'PKR ${(dept['amount'] as int).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Export Options
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export Reports',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Export to Excel
                          },
                          icon: const Icon(Icons.table_chart),
                          label: const Text('Export to Excel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Export to PDF
                          },
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Export to PDF'),
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

  Widget _buildStatusCard(String title, String count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getDepartmentName(int index) {
    final departments = ['Teaching', 'Administration', 'Maintenance', 'Security', 'Transport'];
    return departments[index % departments.length];
  }

  void _showProcessPayrollDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Payroll'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Process payroll for $_selectedMonth?'),
            const SizedBox(height: 16),
            const Text('This will:'),
            const Text('• Calculate salaries for all employees'),
            const Text('• Generate payslips'),
            const Text('• Update payment records'),
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
              // Process payroll logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payroll processing started...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Process'),
          ),
        ],
      ),
    );
  }

  void _showSalaryDetailsDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Employee ${index + 1} - Salary Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSalaryDetailRow('Basic Salary', 'PKR 35,000'),
            _buildSalaryDetailRow('Allowances', 'PKR 10,000'),
            _buildSalaryDetailRow('Overtime', 'PKR 2,000'),
            const Divider(),
            _buildSalaryDetailRow('Gross Salary', 'PKR 47,000', isTotal: true),
            _buildSalaryDetailRow('Tax', 'PKR 2,000', isDeduction: true),
            _buildSalaryDetailRow('EOBI', 'PKR 500', isDeduction: true),
            const Divider(),
            _buildSalaryDetailRow('Net Salary', 'PKR 44,500', isTotal: true),
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
              // Generate payslip
            },
            child: const Text('Generate Payslip'),
          ),
        ],
      ),
    );
  }

  void _showBulkActionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download All Payslips'),
              onTap: () {
                Navigator.pop(context);
                // Download all payslips
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Send All via Email'),
              onTap: () {
                Navigator.pop(context);
                // Send all via email
              },
            ),
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Print All Payslips'),
              onTap: () {
                Navigator.pop(context);
                // Print all payslips
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryDetailRow(String label, String amount, {bool isTotal = false, bool isDeduction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            isDeduction ? '- $amount' : amount,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDeduction ? Colors.red : (isTotal ? Colors.green : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
