import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/program_model.dart';
import '../models/enrollment_model.dart';
import '../services/enrollment_service.dart';
import '../services/program_service.dart';
import '../services/attendance_service.dart';
import '../services/grade_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/notification_badge.dart';
import 'application_form_screen.dart';
import 'conversations_screen.dart';
import 'program_detail_screen.dart';
import 'program_list_screen.dart';
import 'university_comparison_screen.dart';
import 'cost_calculator_screen.dart';
import 'attendance_record_list_screen.dart';
import 'attendance_record_detail_screen.dart';
import 'student_gradebook_screen.dart';
import 'grade_report_screen.dart';
import 'grade_detail_screen.dart';

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
  final _enrollmentService = EnrollmentService();
  final _programService = ProgramService();
  final _attendanceService = AttendanceService();
  final _gradeService = GradeService();
  List<ProgramModel> _featuredPrograms = [];
  List<EnrollmentModel> _enrollments = [];
  double _overallGPA = 0.0;
  List<Map<String, dynamic>> _recentGrades = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFeaturedPrograms();
    _loadEnrollments();
    _loadGrades();
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
  
  Future<void> _loadEnrollments() async {
    try {
      // Get user enrollments
      final enrollments = await _enrollmentService.getUserEnrollments();
      
      setState(() {
        _enrollments = enrollments;
      });
    } catch (e) {
      debugPrint('Error loading enrollment records: $e');
    }
  }
  
  Future<void> _loadGrades() async {
    try {
      // For demo purposes, generate sample grades if needed
      await _gradeService.generateSampleGrades();
      
      // Get overall GPA
      final gpa = await _gradeService.getStudentGPA('user123');
      
      // Get all grades for the student
      final grades = await _gradeService.getGradesForStudent('user123');
      
      // Sort by date (newest first) and take the 3 most recent grades
      grades.sort((a, b) => b.gradedDate.compareTo(a.gradedDate));
      final recentGrades = grades.take(3).map((grade) => {
        'id': grade.id,
        'title': grade.assessmentType,
        'courseName': grade.courseName,
        'score': grade.score,
        'maxScore': grade.maxScore,
        'letterGrade': grade.letterGrade,
        'date': grade.gradedDate,
      }).toList();
      
      setState(() {
        _overallGPA = gpa;
        _recentGrades = recentGrades;
      });
    } catch (e) {
      debugPrint('Error loading grades: $e');
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Set demo user details if not already set
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('userId') == null) {
        await prefs.setString('userId', 'demo_user_123');
        await prefs.setString('userName', 'Ahmed Ali');
        await prefs.setString('userEmail', 'ahmed.ali@school.edu.pk');
        await prefs.setString('userRole', 'student');
        await prefs.setString('userPhone', '+92-300-1234567');
        await prefs.setBool('isLoggedIn', true);
      }
      
      // Debug: Print user details
      debugPrint('=== USER DETAILS ===');
      debugPrint('User ID: ${prefs.getString('userId') ?? 'Not set'}');
      debugPrint('User Name: ${prefs.getString('userName') ?? 'Not set'}');
      debugPrint('User Email: ${prefs.getString('userEmail') ?? 'Not set'}');
      debugPrint('User Role: ${prefs.getString('userRole') ?? 'Not set'}');
      debugPrint('User Phone: ${prefs.getString('userPhone') ?? 'Not set'}');
      debugPrint('==================');
      
      // In a real app, you would fetch user data from Firestore
      // For now, we'll just use a placeholder name
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check if user has an enrollment
      final enrollments = await _enrollmentService.getUserEnrollments();
      _hasApplication = enrollments.isNotEmpty;
      
      if (_hasApplication) {
        _applicationStatus = enrollments.last.status;
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

  Future<Map<String, String?>> _getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString('userId') ?? 'demo_user_123',
      'userName': prefs.getString('userName') ?? 'Ahmed Ali',
      'userEmail': prefs.getString('userEmail') ?? 'ahmed.ali@school.edu.pk',
      'userRole': prefs.getString('userRole') ?? 'student',
      'userPhone': prefs.getString('userPhone') ?? '+92-300-1234567',
    };
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
                  // Welcome Card with User Details
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
                          const SizedBox(height: 12),
                          // User Details Section
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: FutureBuilder<Map<String, String?>>(
                              future: _getUserDetails(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final userDetails = snapshot.data!;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'User Details:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text('ID: ${userDetails['userId'] ?? 'Not set'}'),
                                      Text('Name: ${userDetails['userName'] ?? 'Not set'}'),
                                      Text('Email: ${userDetails['userEmail'] ?? 'Not set'}'),
                                      Text('Phone: ${userDetails['userPhone'] ?? 'Not set'}'),
                                      Text('Role: ${userDetails['userRole'] ?? 'Not set'}'),
                                    ],
                                  );
                                }
                                return const Text('Loading user details...');
                              },
                            ),
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
                    childAspectRatio: 1.2, // Adjust this value to prevent overflow
                    children: [
                      _buildActionCard(
                        context,
                        'My Assignments',
                        Icons.assignment,
                        AppTheme.secondaryColor,
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('My Assignments - Feature Available!')),
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
                          // Navigate to attendance record list
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AttendanceRecordListScreen(
                                userId: 'user123', // Using a sample user ID for demo
                              ),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Performance Analytics',
                        Icons.analytics,
                        Colors.purple,
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Performance Analytics - Feature Available!')),
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
                  
                  // Enrollments
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Enrollments',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ApplicationFormScreen(),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Enrollments list
                  _enrollments.isEmpty
                      ? _buildEmptyEnrollmentsCard()
                      : Column(
                          children: _enrollments
                              .take(2) // Show only the first 2 enrollments
                              .map((record) => _buildEnrollmentCard(record))
                              .toList(),
                        ),
                        
                  const SizedBox(height: 24),
                  
                  // Academic Performance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Academic Performance',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GradeReportScreen(
                                studentId: 'user123', // Using a sample user ID for demo
                              ),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // GPA Card
                  _buildGPACard(),
                  
                  const SizedBox(height: 16),
                  
                  // Recent Grades
                  _recentGrades.isEmpty
                      ? _buildEmptyGradesCard()
                      : Column(
                          children: _recentGrades
                              .map((grade) => _buildGradeCard(grade))
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
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 8),
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
  
  Widget _buildEmptyEnrollmentsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No enrollments yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start your enrollment in a course',
              style: TextStyle(color: AppTheme.lightTextColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ApplicationFormScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Start Enrollment'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGPACard() {
    final Color color = _getGPAColor(_overallGPA);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
                border: Border.all(
                  color: color,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  _overallGPA.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current GPA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getGPADescription(_overallGPA),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _overallGPA / 4.0, // Assuming 4.0 scale
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyGradesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No grades yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your grades will appear here once they are available',
              style: TextStyle(color: AppTheme.lightTextColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GradeReportScreen(
                      studentId: 'user123', // Using a sample user ID for demo
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.grade),
              label: const Text('View Gradebook'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGradeCard(Map<String, dynamic> grade) {
    final letterGrade = grade['letterGrade'] as String;
    final score = grade['score'] as double;
    final maxScore = grade['maxScore'] as double;
    final percentage = (score / maxScore) * 100;
    final color = _getGradeColor(letterGrade);
    final date = grade['date'] as DateTime;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GradeDetailScreen(
                gradeId: grade['id'] as String,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                  border: Border.all(
                    color: color,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    letterGrade,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grade['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      grade['courseName'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.lightTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${score.toStringAsFixed(1)}/${maxScore.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
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
  
  Widget _buildEnrollmentCard(EnrollmentModel record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ApplicationFormScreen(),
            ),
          ).then((_) => _loadEnrollments());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: record.status == 'accepted' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    record.status == 'accepted' ? Icons.check_circle : Icons.pending,
                    color: record.status == 'accepted' ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Class Attendance',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.status.toUpperCase(),
                          style: TextStyle(
                            color: record.status == 'accepted' ? Colors.green : Colors.orange,
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
                  // Course and Room
                  Row(
                    children: [
                      const Icon(Icons.school, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${record.desiredClass ?? 'Unknown Class'} - Grade ${record.desiredGrade ?? 'Unknown'}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Date and Time
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Submitted'),
                          Text(record.submittedAt != null ? '${record.submittedAt!.day}/${record.submittedAt!.month}/${record.submittedAt!.year}' : 'Not submitted'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Academic Year'),
                          Text(record.academicYear ?? 'Not specified'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Teacher
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      const Text(
                        'Teacher:',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          record.assignedTeacherId != null ? 'Assigned Teacher' : 'Not assigned yet',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getGPAColor(double gpa) {
    if (gpa >= 3.5) {
      return Colors.green;
    } else if (gpa >= 2.5) {
      return Colors.blue;
    } else if (gpa >= 1.5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getGPADescription(double gpa) {
    if (gpa >= 3.5) {
      return 'Excellent';
    } else if (gpa >= 2.5) {
      return 'Good';
    } else if (gpa >= 1.5) {
      return 'Satisfactory';
    } else {
      return 'Needs Improvement';
    }
  }

  Color _getGradeColor(String letterGrade) {
    switch (letterGrade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
