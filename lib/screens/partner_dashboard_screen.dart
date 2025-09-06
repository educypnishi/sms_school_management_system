import 'package:flutter/material.dart';
import '../services/application_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/notification_badge.dart';
import 'partner_applications_screen.dart';

class PartnerDashboardScreen extends StatefulWidget {
  const PartnerDashboardScreen({super.key});

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  String _partnerName = '';
  bool _isLoading = true;
  int _assignedApplications = 0;
  final ApplicationService _applicationService = ApplicationService();

  @override
  void initState() {
    super.initState();
    _loadPartnerData();
  }

  Future<void> _loadPartnerData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // In a real app, you would fetch partner data from Firestore
      // For now, we'll just use a placeholder name
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get assigned applications count
      final applications = await _applicationService.getPartnerApplications();
      
      setState(() {
        _partnerName = 'Partner';
        _assignedApplications = applications.length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading partner data: $e');
      setState(() {
        _partnerName = 'Partner';
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
        title: const Text('Partner Dashboard'),
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
                            'Welcome, $_partnerName!',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Manage student applications for your institution',
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
                        'Review Applications',
                        Icons.assignment,
                        AppTheme.primaryColor,
                        () {
                          // Navigate to applications review
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PartnerApplicationsScreen(),
                            ),
                          ).then((_) => _loadPartnerData()); // Refresh data when returning
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Student Documents',
                        Icons.folder_shared,
                        AppTheme.secondaryColor,
                        () {
                          // Navigate to student documents
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Student documents will be available in Phase 7')),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Assigned Applications
                  Text(
                    'Assigned Applications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  _assignedApplications > 0
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
                                    Icons.assignment,
                                    color: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$_assignedApplications Applications Assigned',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Review applications and provide feedback',
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
                                  ).then((_) => _loadPartnerData());
                                },
                                icon: const Icon(Icons.visibility),
                                label: const Text('View Applications'),
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
                                'No applications assigned yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Applications will be assigned by admin',
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
