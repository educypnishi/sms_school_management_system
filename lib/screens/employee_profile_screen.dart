import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EmployeeProfileScreen extends StatefulWidget {
  final String employeeId;
  
  const EmployeeProfileScreen({
    super.key,
    required this.employeeId,
  });

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Employee Profile'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              // Edit employee
            },
            icon: const Icon(Icons.edit),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Personal Info'),
            Tab(text: 'Employment'),
            Tab(text: 'Attendance'),
            Tab(text: 'Payroll'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Employee Header
          Container(
            color: AppTheme.primaryColor.withOpacity(0.1),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryColor,
                  child: const Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ahmed Hassan Khan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Administrative Assistant',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
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
                _buildPersonalInfoTab(),
                _buildEmploymentTab(),
                _buildAttendanceTab(),
                _buildPayrollTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            'Basic Information',
            [
              _buildInfoRow('Full Name', 'Ahmed Hassan Khan'),
              _buildInfoRow('Employee ID', 'EMP001'),
              _buildInfoRow('CNIC', '42101-1234567-8'),
              _buildInfoRow('Date of Birth', '15/03/1985'),
              _buildInfoRow('Gender', 'Male'),
              _buildInfoRow('Blood Group', 'B+'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildInfoSection(
            'Contact Information',
            [
              _buildInfoRow('Phone', '+92 300 1234567'),
              _buildInfoRow('Email', 'ahmed.hassan@school.edu.pk'),
              _buildInfoRow('Address', 'House 123, Block A, Gulshan-e-Iqbal, Karachi'),
              _buildInfoRow('Emergency Contact', '+92 321 7654321'),
              _buildInfoRow('Emergency Contact Name', 'Fatima Khan (Wife)'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildInfoSection(
            'Family Information',
            [
              _buildInfoRow('Marital Status', 'Married'),
              _buildInfoRow('Spouse Name', 'Fatima Khan'),
              _buildInfoRow('Children', '2 (Ali - 8 years, Sara - 5 years)'),
              _buildInfoRow('Father Name', 'Hassan Khan'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmploymentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            'Employment Details',
            [
              _buildInfoRow('Department', 'Administration'),
              _buildInfoRow('Designation', 'Administrative Assistant'),
              _buildInfoRow('Joining Date', '01/09/2020'),
              _buildInfoRow('Employment Type', 'Full Time'),
              _buildInfoRow('Probation Period', 'Completed'),
              _buildInfoRow('Reporting Manager', 'Syed Ali Shah'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildInfoSection(
            'Qualifications',
            [
              _buildInfoRow('Education', 'Bachelor in Business Administration'),
              _buildInfoRow('University', 'University of Karachi'),
              _buildInfoRow('Year of Graduation', '2018'),
              _buildInfoRow('Previous Experience', '2 years'),
              _buildInfoRow('Skills', 'MS Office, Data Entry, Customer Service'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildInfoSection(
            'Work Schedule',
            [
              _buildInfoRow('Working Days', 'Monday to Friday'),
              _buildInfoRow('Working Hours', '9:00 AM - 5:00 PM'),
              _buildInfoRow('Break Time', '1:00 PM - 2:00 PM'),
              _buildInfoRow('Weekly Hours', '40 hours'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Attendance Summary
          Row(
            children: [
              Expanded(
                child: _buildAttendanceCard('Present Days', '22', Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAttendanceCard('Absent Days', '2', Colors.red),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAttendanceCard('Late Days', '1', Colors.orange),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Monthly Attendance
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This Month Attendance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Calendar view placeholder
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Attendance Calendar'),
                          Text('(Calendar view will be implemented)', 
                               style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Recent Attendance
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Attendance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final date = DateTime.now().subtract(Duration(days: index));
                      final status = index == 1 ? 'Absent' : (index == 3 ? 'Late' : 'Present');
                      final color = status == 'Present' ? Colors.green : 
                                   status == 'Absent' ? Colors.red : Colors.orange;
                      
                      return ListTile(
                        leading: Icon(
                          status == 'Present' ? Icons.check_circle : 
                          status == 'Absent' ? Icons.cancel : Icons.access_time,
                          color: color,
                        ),
                        title: Text('${date.day}/${date.month}/${date.year}'),
                        subtitle: Text(status),
                        trailing: status != 'Absent' 
                            ? Text('9:${(index * 5 % 60).toString().padLeft(2, '0')} AM')
                            : null,
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

  Widget _buildPayrollTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Salary Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Salary Structure',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSalaryRow('Basic Salary', 'PKR 35,000'),
                  _buildSalaryRow('House Allowance', 'PKR 7,000'),
                  _buildSalaryRow('Transport Allowance', 'PKR 3,000'),
                  const Divider(),
                  _buildSalaryRow('Gross Salary', 'PKR 45,000', isTotal: true),
                  const SizedBox(height: 8),
                  _buildSalaryRow('Tax Deduction', 'PKR 2,000', isDeduction: true),
                  _buildSalaryRow('EOBI', 'PKR 500', isDeduction: true),
                  const Divider(),
                  _buildSalaryRow('Net Salary', 'PKR 42,500', isTotal: true),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Recent Payslips
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Payslips',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // View all payslips
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      final date = DateTime.now().subtract(Duration(days: 30 * index));
                      return ListTile(
                        leading: const Icon(Icons.receipt, color: Colors.blue),
                        title: Text('${_getMonthName(date.month)} ${date.year}'),
                        subtitle: const Text('PKR 42,500'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                // Download payslip
                              },
                              icon: const Icon(Icons.download),
                            ),
                            IconButton(
                              onPressed: () {
                                // View payslip
                              },
                              icon: const Icon(Icons.visibility),
                            ),
                          ],
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

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
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

  Widget _buildAttendanceCard(String title, String count, Color color) {
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

  Widget _buildSalaryRow(String label, String amount, {bool isTotal = false, bool isDeduction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDeduction ? Colors.red : Colors.black,
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

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
