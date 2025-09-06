import 'package:flutter/material.dart';
import '../models/program_model.dart';
import '../services/application_service.dart';
import '../services/program_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/notification_badge.dart';
import 'application_form_screen.dart';
import 'conversations_screen.dart';
import 'program_detail_screen.dart';
import 'program_list_screen.dart';

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
  List<ProgramModel> _featuredPrograms = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFeaturedPrograms();
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
                            'Start your journey to study in Cyprus',
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
                        'Apply Now',
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
                        'Browse Programs',
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
                          // Navigate to documents
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Documents will be available in future phases')),
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
                          // Navigate to chat
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Chat support will be available in Phase 9')),
                          );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Application Status
                  Text(
                    'Application Status',
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
                                        ? 'Application Submitted'
                                        : 'Application Draft',
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
                                    ? 'Your application has been submitted and is under review'
                                    : 'Continue working on your application',
                                style: const TextStyle(color: AppTheme.lightTextColor),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ApplicationFormScreen(),
                                    ),
                                  ).then((_) => _loadUserData());
                                },
                                icon: Icon(_applicationStatus == 'submitted' ? Icons.visibility : Icons.edit),
                                label: Text(_applicationStatus == 'submitted' ? 'View Application' : 'Continue Editing'),
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
                                'No applications yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start your application to study in Cyprus',
                                style: TextStyle(color: AppTheme.lightTextColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                  
                  const SizedBox(height: 24),
                  
                  // Featured Programs
                  Text(
                    'Featured Programs',
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
                      label: const Text('View All Programs'),
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
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 30,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Program Title
                    Text(
                      program.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // University
                    Text(
                      program.university,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.lightTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Degree Type
                    Text(
                      program.degreeType,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
