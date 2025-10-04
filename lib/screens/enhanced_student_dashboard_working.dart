import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

class EnhancedStudentDashboard extends StatefulWidget {
  const EnhancedStudentDashboard({super.key});

  @override
  State<EnhancedStudentDashboard> createState() => _EnhancedStudentDashboardState();
}

class _EnhancedStudentDashboardState extends State<EnhancedStudentDashboard> {
  final String _userName = 'Ahmed Ali';
  final bool _isLoading = false;
  
  // Sample data
  final double _totalDue = 15000.0;
  final double _totalPaid = 25000.0;
  final int _pendingFeesCount = 2;
  final int _notificationCount = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $_userName'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
                tooltip: 'Notifications',
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFeeSummaryCard(),
                  const SizedBox(height: 16),
                  _buildTodayClassesCard(),
                  const SizedBox(height: 16),
                  _buildUpcomingExamsCard(),
                  const SizedBox(height: 16),
                  _buildQuickActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_userName),
            accountEmail: const Text('ahmed.ali@student.edu.pk'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppTheme.primaryColor),
            ),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Assignments'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/assignments');
            },
          ),
          ListTile(
            leading: const Icon(Icons.grade),
            title: const Text('Grades'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/grades');
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Fee Payment'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/fee_payment');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeSummaryCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Fee Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_pendingFeesCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_pendingFeesCount Pending',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFeeStatCard(
                    'Total Due',
                    'PKR ${NumberFormat('#,##0').format(_totalDue)}',
                    Colors.red,
                    Icons.payment,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFeeStatCard(
                    'Total Paid',
                    'PKR ${NumberFormat('#,##0').format(_totalPaid)}',
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/student_fee_dashboard');
              },
              icon: const Icon(Icons.payment),
              label: const Text('Pay Fees'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeStatCard(String title, String amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              crossAxisCount: 3,
              mainAxisSpacing: 12.0,
              crossAxisSpacing: 12.0,
              childAspectRatio: 1.2,
              children: [
                _buildActionCard(
                  'Assignments',
                  Icons.assignment,
                  AppTheme.secondaryColor,
                  () => Navigator.pushNamed(context, '/assignments'),
                ),
                _buildActionCard(
                  'Documents',
                  Icons.folder,
                  Colors.orange,
                  () => Navigator.pushNamed(context, '/documents'),
                ),
                _buildActionCard(
                  'Messages',
                  Icons.message,
                  Colors.blue,
                  () => Navigator.pushNamed(context, '/messages'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: color.withAlpha(76)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32.0,
              color: color,
            ),
            const SizedBox(height: 8.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayClassesCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Today\'s Classes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildClassItem('Mathematics', '9:00 AM - 10:00 AM', 'Room 101', 'Mr. Khan'),
            const SizedBox(height: 8),
            _buildClassItem('Physics', '10:30 AM - 11:30 AM', 'Lab 201', 'Dr. Ahmed'),
            const SizedBox(height: 8),
            _buildClassItem('English', '2:00 PM - 3:00 PM', 'Room 105', 'Ms. Fatima'),
          ],
        ),
      ),
    );
  }

  Widget _buildClassItem(String subject, String time, String room, String teacher) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withAlpha(76)),
      ),
      child: Row(
        children: [
          Icon(Icons.book, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$time • $room',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  teacher,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingExamsCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.quiz, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Upcoming Exams',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildExamItem('Mathematics Mid-term', 'Oct 15, 2024', '3 days', Colors.red),
            const SizedBox(height: 8),
            _buildExamItem('Physics Quiz', 'Oct 20, 2024', '8 days', Colors.orange),
            const SizedBox(height: 8),
            _buildExamItem('English Final', 'Nov 5, 2024', '24 days', Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildExamItem(String exam, String date, String countdown, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Row(
        children: [
          Icon(Icons.event, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              countdown,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
