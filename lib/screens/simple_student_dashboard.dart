import 'package:flutter/material.dart';
import '../services/demo_auth_service.dart';
import '../theme/app_theme.dart';

class SimpleStudentDashboard extends StatefulWidget {
  const SimpleStudentDashboard({super.key});

  @override
  State<SimpleStudentDashboard> createState() => _SimpleStudentDashboardState();
}

class _SimpleStudentDashboardState extends State<SimpleStudentDashboard> {
  String _userName = 'Student';
  String _userEmail = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await DemoAuthService.getCurrentUser();
      if (user != null) {
        setState(() {
          _userName = user['name'] ?? 'Student';
          _userEmail = user['email'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $_userName'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
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
                  _buildWelcomeCard(),
                  const SizedBox(height: 16),
                  _buildQuickActionsCard(),
                  const SizedBox(height: 16),
                  _buildInfoCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: AppTheme.primaryColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_userEmail.isNotEmpty)
                        Text(
                          _userEmail,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Your student dashboard is ready! Use the navigation menu to access all features.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 4,
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
              crossAxisCount: 2,
              mainAxisSpacing: 12.0,
              crossAxisSpacing: 12.0,
              childAspectRatio: 1.5,
              children: [
                _buildActionCard(
                  'Assignments',
                  Icons.assignment,
                  Colors.blue,
                  () => _showFeatureDialog('Assignments'),
                ),
                _buildActionCard(
                  'Grades',
                  Icons.grade,
                  Colors.green,
                  () => _showFeatureDialog('Grades'),
                ),
                _buildActionCard(
                  'Timetable',
                  Icons.schedule,
                  Colors.orange,
                  () => _showFeatureDialog('Timetable'),
                ),
                _buildActionCard(
                  'Fees',
                  Icons.payment,
                  Colors.purple,
                  () => _showFeatureDialog('Fee Payment'),
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28.0, color: color),
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

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Name', _userName),
            _buildInfoRow('Email', _userEmail.isNotEmpty ? _userEmail : 'Not available'),
            _buildInfoRow('Role', 'Student'),
            _buildInfoRow('Status', 'Active'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
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
            accountEmail: Text(_userEmail.isNotEmpty ? _userEmail : 'Student Portal'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Assignments'),
            onTap: () => _showFeatureDialog('Assignments'),
          ),
          ListTile(
            leading: const Icon(Icons.grade),
            title: const Text('Grades'),
            onTap: () => _showFeatureDialog('Grades'),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Timetable'),
            onTap: () => _showFeatureDialog('Timetable'),
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Fee Payment'),
            onTap: () => _showFeatureDialog('Fee Payment'),
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Documents'),
            onTap: () => _showFeatureDialog('Documents'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => _showFeatureDialog('Settings'),
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help'),
            onTap: () => _showFeatureDialog('Help'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  void _showFeatureDialog(String feature) {
    Navigator.pop(context); // Close drawer
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text('$feature feature will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await DemoAuthService.logout();
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pushReplacementNamed(context, '/role_selection');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
