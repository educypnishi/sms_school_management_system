import 'package:flutter/material.dart';
import '../models/program_model.dart';
import '../models/visa_application_model.dart';
import '../services/application_service.dart';
import '../services/program_service.dart';
import '../services/visa_application_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/notification_badge.dart';
import 'application_form_screen.dart';
import 'conversations_screen.dart';
import 'program_detail_screen.dart';
import 'program_list_screen.dart';
import 'university_comparison_screen.dart';
import 'cost_calculator_screen.dart';
import 'visa_application_list_screen.dart';
import 'visa_application_detail_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  String _userName = '';
  bool _isLoading = true;
  bool _hasApplication = false;
  String? _applicationStatus;
  final _applicationService = ApplicationService();
  final _programService = ProgramService();
  final _visaApplicationService = VisaApplicationService();
  List<ProgramModel> _featuredPrograms = [];
  List<VisaApplicationModel> _visaApplications = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFeaturedPrograms();
    _loadVisaApplications();
  }
  
  Future<void> _loadFeaturedPrograms() async {
    try {
      final programs = await _programService.getAllPrograms();
      
      // Take the first 3 programs as featured
      setState(() {
        _featuredPrograms = programs.take(3).toList();
      });
    } catch (e) {
      debugPrint('Error loading featured programs: $e');
    }
  }
  
  Future<void> _loadVisaApplications() async {
    try {
      final visaApplications = await _visaApplicationService.getVisaApplicationsForUser('user123');
      
      setState(() {
        _visaApplications = visaApplications;
      });
    } catch (e) {
      debugPrint('Error loading visa applications: $e');
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // In a real app, you would fetch user data from Firestore
      // For now, we'll just use a placeholder name
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check if user has an application
      final applications = await _applicationService.getUserApplications();
      _hasApplication = applications.isNotEmpty;
      
      if (_hasApplication) {
        _applicationStatus = applications.last.status;
      }
      
      setState(() {
        _userName = 'Student';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        _userName = 'Student';
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
        title: const Text('Student Dashboard'),
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
                            'Welcome, $_userName!',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Manage your school activities and courses',
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
                        'Enroll in Course',
                        Icons.school,
                        AppTheme.primaryColor,
                        () {
                          // Navigate to application form
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ApplicationFormScreen(),
                            ),
                          ).then((_) => _loadUserData()); // Refresh data when returning
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Browse Courses',
                        Icons.search,
                        AppTheme.secondaryColor,
                        () {
                          // Navigate to programs list
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProgramListScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        context,
                        'My Documents',
                        Icons.folder,
                        AppTheme.accentColor,
                        () {
                          // Navigate to document management
                          Navigator.pushNamed(
                            context,
                            AppConstants.documentManagementRoute,
                            arguments: {
                              'userId': 'user123', // Using a sample user ID for demo
                              'applicationId': 'APP001', // Using a sample application ID for demo
                              'isAdmin': false,
                            },
                          );
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Messages',
                        Icons.chat,
                        Colors.green,
                        () {
                          // Navigate to conversations
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ConversationsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Chat Support',
                        Icons.chat,
                        Colors.purple,
                        () {
                          // Navigate to conversations screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ConversationsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Calendar & Deadlines',
                        Icons.calendar_today,
                        Colors.teal,
                        () {
                          // Navigate to calendar
                          Navigator.pushNamed(
                            context,
                            AppConstants.calendarRoute,
                            arguments: {
                              'userId': 'user123', // Using a sample user ID for demo
                            },
                          );
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Class Comparison',
                        Icons.compare,
                        Colors.indigo,
                        () {
                          // Navigate to university comparison
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UniversityComparisonScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Fee Calculator',
                        Icons.calculate,
                        Colors.amber,
                        () {
                          // Navigate to cost calculator
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CostCalculatorScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Attendance Tracker',
                        Icons.fact_check,
                        Colors.teal,
                        () {
                          // Navigate to visa application list
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VisaApplicationListScreen(
                                userId: 'user123', // Using a sample user ID for demo
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Application Status
                  Text(
                    'Enrollment Status',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  _hasApplication
                    ? Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _applicationStatus == 'submitted'
                                        ? Icons.check_circle
                                        : Icons.edit_document,
                                    color: _applicationStatus == 'submitted'
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _applicationStatus == 'submitted'
                                        ? 'Enrollment Submitted'
                                        : 'Enrollment Draft',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _applicationStatus == 'submitted'
                                    ? 'Your enrollment has been submitted and is under review'
                                    : 'Continue working on your enrollment',
                                style: const TextStyle(color: AppTheme.lightTextColor),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const ApplicationFormScreen(),
                                          ),
                                        ).then((_) => _loadUserData());
                                      },
                                      icon: Icon(_applicationStatus == 'submitted' ? Icons.visibility : Icons.edit),
                                      label: Text(_applicationStatus == 'submitted' ? 'View Enrollment' : 'Continue Editing'),
                                    ),
                                  ),
                                ],
                              ),
                              if (_applicationStatus == 'submitted') ...[  
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context, 
                                      AppConstants.enrollmentProgressRoute,
                                      arguments: 'APP001', // Using a sample application ID for demo
                                    );
                                  },
                                  icon: const Icon(Icons.timeline),
                                  label: const Text('Track Progress'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
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
                                'Start your enrollment in a course',
                                style: TextStyle(color: AppTheme.lightTextColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                  
                  const SizedBox(height: 24),
                  
                  // Featured Programs
                  Text(
                    'Featured Courses',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  _featuredPrograms.isEmpty
                    ? const Card(
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: Text('Loading programs...'),
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _featuredPrograms.length,
                          itemBuilder: (context, index) {
                            final program = _featuredPrograms[index];
                            return _buildProgramCard(program);
                          },
                        ),
                      ),
                  
                  const SizedBox(height: 16),
                  
                  // View All Programs Button
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProgramListScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.view_list),
                      label: const Text('View All Courses'),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Visa Applications
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Attendance Records',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VisaApplicationListScreen(
                                userId: 'user123', // Using a sample user ID for demo
                              ),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Visa applications list
                  _visaApplications.isEmpty
                      ? _buildEmptyVisaApplicationsCard()
                      : Column(
                          children: _visaApplications
                              .take(2) // Show only the first 2 applications
                              .map((application) => _buildVisaApplicationCard(application))
                              .toList(),
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
  
  Widget _buildProgramCard(ProgramModel program) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProgramDetailScreen(programId: program.id),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Program Image
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  program.imageUrl,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                program.university,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                program.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.lightTextColor),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${program.duration} ${program.degreeType}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '€${program.tuitionFee}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyVisaApplicationsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No attendance records yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start tracking your class attendance',
              style: TextStyle(color: AppTheme.lightTextColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VisaApplicationListScreen(
                      userId: 'user123', // Using a sample user ID for demo
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('View Attendance Records'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVisaApplicationCard(VisaApplicationModel application) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VisaApplicationDetailScreen(
                visaApplicationId: application.id,
              ),
            ),
          ).then((_) => _loadVisaApplications());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: application.status.color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    application.status.icon,
                    color: application.status.color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.visaType.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          application.status.displayName,
                          style: TextStyle(
                            color: application.status.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Country and Embassy
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${application.country} - ${application.embassy}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Progress
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Progress'),
                          Text('${application.completionPercentage.toStringAsFixed(0)}%'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: application.completionPercentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          application.status.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Next Milestone
                  if (application.nextMilestone != null) ...[                    
                    Row(
                      children: [
                        const Icon(Icons.flag, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        const Text(
                          'Next Step:',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            application.nextMilestone!.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
