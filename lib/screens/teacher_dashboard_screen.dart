import 'package:flutter/material.dart';
import '../services/application_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/notification_badge.dart';
import 'partner_applications_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  String _teacherName = '';
  bool _isLoading = true;
  int _assignedClasses = 0;
  final ApplicationService _applicationService = ApplicationService();

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // In a real app, you would fetch teacher data from Firestore
      // For now, we'll just use a placeholder name
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get assigned applications count (will be classes in the future)
      final applications = await _applicationService.getPartnerApplications();
      
      setState(() {
        _teacherName = 'Teacher';
        _assignedClasses = applications.length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading teacher data: $e');
      setState(() {
        _teacherName = 'Teacher';
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
        title: const Text('Teacher Dashboard'),
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
                            'Welcome, $_teacherName!',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Manage your classes and student enrollments',
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
                        'Manage Classes',
                        Icons.class_,
                        AppTheme.primaryColor,
                        () {
                          // Navigate to classes management
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PartnerApplicationsScreen(),
                            ),
                          ).then((_) => _loadTeacherData()); // Refresh data when returning
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Student Records',
                        Icons.folder_shared,
                        AppTheme.secondaryColor,
                        () {
                          // Navigate to student records
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Student records will be available soon')),
                          );
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Take Attendance',
                        Icons.fact_check,
                        Colors.green,
                        () {
                          // Navigate to attendance taking
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Attendance feature will be available soon')),
                          );
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Grade Assignments',
                        Icons.grading,
                        Colors.orange,
                        () {
                          // Navigate to grading
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Grading feature will be available soon')),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Assigned Classes
                  Text(
                    'Assigned Classes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  _assignedClasses > 0
                    ? Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.class_,
                                    color: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$_assignedClasses Classes Assigned',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Manage your classes and student enrollments',
                                style: TextStyle(color: AppTheme.lightTextColor),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PartnerApplicationsScreen(),
                                    ),
                                  ).then((_) => _loadTeacherData());
                                },
                                icon: const Icon(Icons.visibility),
                                label: const Text('View Classes'),
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
                                'No classes assigned yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Classes will be assigned by admin',
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
}
