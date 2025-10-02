import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/notification_badge.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          const NotificationBadge(),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppTheme.primaryColor,
                            child: const Icon(Icons.person, size: 30, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, Ahmed Hassan',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Administrative Assistant',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'Employee ID: EMP001',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick Stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Present Days',
                          '22',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Absent Days',
                          '2',
                          Icons.cancel,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Leave Balance',
                          '8 Days',
                          Icons.calendar_today,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'This Month Salary',
                          'PKR 45,000',
                          Icons.account_balance_wallet,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                    children: [
                      _buildActionCard(
                        'Mark Attendance',
                        Icons.fingerprint,
                        Colors.green,
                        () {
                          // Navigate to attendance marking
                        },
                      ),
                      _buildActionCard(
                        'Apply Leave',
                        Icons.event_busy,
                        Colors.orange,
                        () {
                          // Navigate to leave application
                        },
                      ),
                      _buildActionCard(
                        'View Payslip',
                        Icons.receipt,
                        Colors.blue,
                        () {
                          // Navigate to payslip
                        },
                      ),
                      _buildActionCard(
                        'My Profile',
                        Icons.person_outline,
                        Colors.purple,
                        () {
                          // Navigate to profile
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Recent Activities
                  Text(
                    'Recent Activities',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Card(
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildActivityItem(
                          'Attendance marked for today',
                          '9:00 AM',
                          Icons.check_circle,
                          Colors.green,
                        ),
                        const Divider(height: 1),
                        _buildActivityItem(
                          'Leave application submitted',
                          'Yesterday',
                          Icons.event_busy,
                          Colors.orange,
                        ),
                        const Divider(height: 1),
                        _buildActivityItem(
                          'Salary credited',
                          '3 days ago',
                          Icons.account_balance_wallet,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(time),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
