import 'package:flutter/material.dart';
import '../services/enrollment_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/notification_badge.dart';
import 'admin_applications_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _adminName = '';
  bool _isLoading = true;
  int _enrollmentCount = 0;
  int _pendingEnrollments = 0;
  final EnrollmentService _enrollmentService = EnrollmentService();

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // In a real app, you would fetch admin data from Firestore
      // For now, we'll just use a placeholder name
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get enrollment statistics
      final enrollments = await _enrollmentService.getAllEnrollments();
      final pendingEnrollments = enrollments.where(
        (enrollment) => enrollment.status == EnrollmentService.statusSubmitted || 
                enrollment.status == EnrollmentService.statusInReview
      ).toList();
      
      setState(() {
        _adminName = 'Admin';
        _enrollmentCount = enrollments.length;
        _pendingEnrollments = pendingEnrollments.length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading admin data: $e');
      setState(() {
        _adminName = 'Admin';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    // For Phase 1, we'll just navigate back to the login screen
    Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          const NotificationBadge(),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppConstants.settingsRoute);
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, $_adminName!',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Manage all aspects of the School Management System',
                            style: TextStyle(color: AppTheme.lightTextColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Action Buttons
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildActionCard(
                        context,
                        'Manage Enrollments',
                        Icons.assignment,
                        AppTheme.primaryColor,
                        () {
                          // Navigate to applications management
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminApplicationsScreen(),
                            ),
                          ).then((_) => _loadAdminData()); // Refresh data when returning
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Manage Teachers',
                        Icons.people,
                        AppTheme.secondaryColor,
                        () {
                          // Navigate to partner management
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Teacher management will be available soon')),
                          );
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Manage Courses',
                        Icons.school,
                        AppTheme.accentColor,
                        () {
                          // Navigate to program management
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Course management will be available soon')),
                          );
                        },
                      ),
                      _buildActionCard(
                        context,
                        'System Settings',
                        Icons.settings,
                        Colors.grey,
                        () {
                          // Navigate to settings
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('System settings will be available in future phases')),
                          );
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Analytics Dashboard',
                        Icons.analytics,
                        Colors.purple,
                        () {
                          // Navigate to analytics dashboard
                          Navigator.pushNamed(
                            context,
                            AppConstants.analyticsDashboardRoute,
                            arguments: {
                              'userRole': 'admin',
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Application Statistics
                  Text(
                    'Enrollment Statistics',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  _enrollmentCount > 0
                    ? Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatCard(
                                    'Total',
                                    _enrollmentCount.toString(),
                                    Icons.assignment,
                                    AppTheme.primaryColor,
                                  ),
                                  _buildStatCard(
                                    'Pending',
                                    _pendingEnrollments.toString(),
                                    Icons.pending_actions,
                                    Colors.orange,
                                  ),
                                  _buildStatCard(
                                    'Completed',
                                    (_enrollmentCount - _pendingEnrollments).toString(),
                                    Icons.check_circle,
                                    Colors.green,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AdminApplicationsScreen(),
                                    ),
                                  ).then((_) => _loadAdminData());
                                },
                                icon: const Icon(Icons.visibility),
                                label: const Text('View All Enrollments'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const Card(
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No enrollments yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Enrollments will appear here when students register',
                                style: TextStyle(color: AppTheme.lightTextColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.lightTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
