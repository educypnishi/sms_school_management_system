import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_class_service.dart';
import '../services/firebase_grade_service.dart';
import '../services/firebase_assignment_service.dart';
import '../services/firebase_attendance_service.dart';
import '../services/application_service.dart';
import '../services/attendance_service.dart';
import 'teacher_attendance_screen.dart';
import 'qr_attendance_screen.dart';
import '../models/class_model.dart';
import '../models/grade_model.dart';
import '../models/attendance_model.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/notification_badge.dart';
import 'partner_applications_screen.dart';
import 'teacher_classes_screen.dart';
// import 'teacher_gradebook_screen.dart';
import 'attendance_tracker_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  String _teacherName = '';
  bool _isLoading = true;
  int _assignedClasses = 0;
  int _totalStudents = 0;
  double _averageGrade = 0.0;
  int _pendingGrades = 0;
  List<ClassModel> _classes = [];
  List<GradeModel> _recentGrades = [];
  Map<String, dynamic> _attendanceStats = {};
  
  final ApplicationService _applicationService = ApplicationService();
  final AttendanceService _attendanceService = AttendanceService();

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
      // Load real Firebase data if authenticated
      if (FirebaseAuthService.isAuthenticated) {
        final teacherId = FirebaseAuthService.currentUserId!;
        
        // Get teacher info
        final teacherDoc = await FirebaseAuthService.currentUser;
        
        // Load teacher's classes and grades in parallel
        final results = await Future.wait([
          FirebaseClassService.getClassesByTeacher(teacherId),
          FirebaseGradeService.getTeacherGrades(teacherId),
        ]);
        
        final classes = results[0] as List<ClassModel>;
        final allGrades = results[1] as List<GradeModel>;
        
        // Calculate statistics
        final totalStudents = _calculateTotalStudents(classes);
        final averageGrade = _calculateAverageGrade(allGrades);
        final pendingGrades = _calculatePendingGrades(allGrades);
        final recentGrades = _getRecentGrades(allGrades, 5);
        
        // Get attendance statistics (using existing service for now)
        final attendanceRecords = await _attendanceService.getAllAttendanceRecords();
        final attendanceStats = _calculateAttendanceStats(attendanceRecords);
        
        setState(() {
          _teacherName = teacherDoc?.displayName ?? 'Teacher';
          _assignedClasses = classes.length;
          _totalStudents = totalStudents;
          _averageGrade = averageGrade;
          _pendingGrades = pendingGrades;
          _classes = classes.isNotEmpty ? classes.take(3).toList() : [];
          _recentGrades = recentGrades.isNotEmpty ? recentGrades : [];
          _attendanceStats = attendanceStats;
          _isLoading = false;
        });
      } else {
        // Fallback to sample data
        await _loadSampleData();
      }
    } catch (e) {
      debugPrint('Error loading teacher data: $e');
      await _loadSampleData();
    }
  }
  
  Future<void> _loadSampleData() async {
    setState(() {
      _teacherName = 'Dr. Ayesha Rahman';
      _assignedClasses = 8;
      _totalStudents = 169;
      _attendanceStats = {'rate': 62.3};
      _isLoading = false;
    });
  }
  
  int _calculateTotalStudents(List<ClassModel> classes) {
    return classes.fold(0, (sum, classModel) => sum + classModel.currentStudents);
  }
  
  double _calculateAverageGrade(List<GradeModel> grades) {
    if (grades.isEmpty) return 0.0;
    final total = grades.fold(0.0, (sum, grade) => sum + grade.score);
    return total / grades.length;
  }
  
  int _calculatePendingGrades(List<GradeModel> grades) {
    // In a real app, this would check for ungraded assignments
    return (grades.length * 0.2).round(); // Simulate 20% pending
  }
  
  List<GradeModel> _getRecentGrades(List<GradeModel> grades, int count) {
    if (grades.isEmpty) return [];
    grades.sort((a, b) => b.gradedDate.compareTo(a.gradedDate));
    return grades.take(count).toList();
  }
  
  Map<String, dynamic> _calculateAttendanceStats(List<AttendanceModel> records) {
    if (records.isEmpty) {
      return {'present': 0, 'absent': 0, 'late': 0, 'rate': 0.0};
    }
    
    final present = records.where((r) => r.status == 'present').length;
    final absent = records.where((r) => r.status == 'absent').length;
    final late = records.where((r) => r.status == 'late').length;
    final rate = (present / records.length) * 100;
    
    return {
      'present': present,
      'absent': absent,
      'late': late,
      'rate': rate,
    };
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadTeacherData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppConstants.settingsRoute);
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      drawer: _buildTeacherDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTeacherData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppTheme.primaryColor,
                              child: Text(
                                _teacherName.isNotEmpty ? _teacherName.substring(0, 1).toUpperCase() : 'T',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, $_teacherName!',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Managing $_assignedClasses classes • $_totalStudents students',
                                    style: const TextStyle(color: AppTheme.lightTextColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Statistics Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Classes',
                            _assignedClasses.toString(),
                            Icons.class_,
                            AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Students',
                            _totalStudents.toString(),
                            Icons.people,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Avg Grade',
                            _averageGrade.toStringAsFixed(1),
                            Icons.grade,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Attendance',
                            '${((_attendanceStats['rate'] as num?) ?? 0.0).toStringAsFixed(1)}%',
                            Icons.fact_check,
                            Colors.orange,
                          ),
                        ),
                      ],
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
                      childAspectRatio: 1.2,
                      children: [
                        _buildActionCard(
                          context,
                          'Create Assignment',
                          Icons.assignment,
                          AppTheme.primaryColor,
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Assignment Creator - Feature Available!')),
                            );
                          },
                        ),
                        _buildActionCard(
                          context,
                          'Quiz Builder',
                          Icons.quiz,
                          Colors.green,
                          () {
                            Navigator.pushNamed(context, AppConstants.quizBuilderRoute);
                          },
                        ),
                        _buildActionCard(
                          context,
                          'Timetable Generator',
                          Icons.schedule,
                          Colors.blue,
                          () {
                            Navigator.pushNamed(context, AppConstants.timetableGeneratorRoute);
                          },
                        ),
                        _buildActionCard(
                          context,
                          'My Assignments',
                          Icons.list_alt,
                          Colors.orange,
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Assignment List - Feature Available!')),
                            );
                          },
                        ),
                        _buildActionCard(
                          context,
                          'Analytics',
                          Icons.analytics,
                          Colors.purple,
                          () {
                            Navigator.pushNamed(
                              context,
                              AppConstants.analyticsDashboardRoute,
                              arguments: {'userRole': 'teacher'},
                            );
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // My Classes Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Classes',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TeacherClassesScreen(),
                              ),
                            );
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _classes.isNotEmpty
                        ? Column(
                            children: _classes.map((classModel) => 
                              _buildClassCard(classModel)
                            ).toList(),
                          )
                        : Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.class_,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No classes assigned yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Classes will be assigned by the admin',
                                    style: TextStyle(color: AppTheme.lightTextColor),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                    
                    const SizedBox(height: 24),
                    
                    // Recent Grades Section
                    if (_recentGrades.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Grades',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gradebook temporarily disabled')),
                              );
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Card(
                        elevation: 2,
                        child: Column(
                          children: _recentGrades.take(3).map((grade) => 
                            _buildGradeItem(grade)
                          ).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.lightTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
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
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildClassCard(ClassModel classModel) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.class_,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classModel.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${classModel.grade} • ${classModel.subject}',
                        style: const TextStyle(
                          color: AppTheme.lightTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${classModel.currentStudents}/${classModel.capacity}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  classModel.room,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    classModel.schedule,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGradeItem(GradeModel grade) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getGradeColor(grade.letterGrade),
        child: Text(
          grade.letterGrade,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        grade.courseName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${grade.assessmentType} • ${grade.studentName}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${grade.score.toStringAsFixed(1)}/${grade.maxScore.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            _formatDate(grade.gradedDate),
            style: const TextStyle(
              color: AppTheme.lightTextColor,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
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
        return Colors.red;
      case 'F':
        return Colors.red[800]!;
      default:
        return Colors.grey;
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildTeacherDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_teacherName),
            accountEmail: const Text('teacher@school.edu.pk'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _teacherName.isNotEmpty ? _teacherName.split(' ').where((e) => e.isNotEmpty).map((e) => e.substring(0, 1)).join('') : 'T',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
          ),
          
          // Teaching Section
          _buildDrawerSection('👨‍🏫 Teaching', [
            _buildDrawerItem(Icons.class_, 'My Classes', '/teacher_classes'),
            _buildDrawerItem(Icons.assignment, 'Assignments', '/teacher_assignments'),
            _buildDrawerItem(Icons.quiz, 'Create Quiz', '/create_quiz'),
            _buildDrawerItem(Icons.grade, 'Gradebook', '/gradebook'),
            _buildDrawerItem(Icons.schedule, 'Class Schedule', '/class_schedule'),
            _buildDrawerItem(Icons.event, 'Calendar', '/calendar'),
          ]),
          
          // Student Management Section
          _buildDrawerSection('👥 Student Management', [
            _buildDrawerItem(Icons.people, 'Student List', '/student_list'),
            _buildDrawerItem(Icons.check_circle, 'Mark Attendance', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TeacherAttendanceScreen()),
              );
            }),
            _buildDrawerItem(Icons.qr_code, 'QR Attendance', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QRAttendanceScreen(isTeacher: true)),
              );
            }),
            _buildDrawerItem(Icons.analytics, 'Student Performance', '/student_performance'),
            _buildDrawerItem(Icons.assessment, 'Progress Reports', '/progress_reports'),
          ]),
          
          // Communication Section
          _buildDrawerSection('💬 Communication', [
            _buildDrawerItem(Icons.message, 'Messages', '/messages'),
            _buildDrawerItem(Icons.notifications, 'Announcements', '/announcements'),
            _buildDrawerItem(Icons.forum, 'Class Discussions', '/class_discussions'),
            _buildDrawerItem(Icons.support_agent, 'AI Assistant', '/ai_chatbot'),
          ]),
          
          // Resources Section
          _buildDrawerSection('📚 Resources', [
            _buildDrawerItem(Icons.folder, 'Course Materials', '/course_materials'),
            _buildDrawerItem(Icons.library_books, 'Digital Library', '/library'),
            _buildDrawerItem(Icons.upload_file, 'Upload Resources', '/upload_resources'),
            _buildDrawerItem(Icons.video_library, 'Video Lectures', '/video_lectures'),
          ]),
          
          // Assessment Section
          _buildDrawerSection('📊 Assessment', [
            _buildDrawerItem(Icons.quiz, 'Online Exams', '/online_exams'),
            _buildDrawerItem(Icons.auto_awesome, 'AI Grading', '/ai_grading'),
            _buildDrawerItem(Icons.analytics, 'Grade Analytics', '/grade_analytics'),
            _buildDrawerItem(Icons.trending_up, 'Performance Trends', '/performance_trends'),
          ]),
          
          // AI Features Section
          _buildDrawerSection('🤖 AI Features', [
            _buildDrawerItem(Icons.smart_toy, 'AI Teaching Assistant', '/ai_chatbot'),
            _buildDrawerItem(Icons.auto_awesome, 'AI Features Test', '/ai_features_test'),
            _buildDrawerItem(Icons.psychology, 'Student Insights', '/student_insights'),
            _buildDrawerItem(Icons.lightbulb, 'Teaching Recommendations', '/teaching_recommendations'),
          ]),
          
          // Settings Section
          _buildDrawerSection('⚙️ Settings', [
            _buildDrawerItem(Icons.settings, 'Settings', '/settings'),
            _buildDrawerItem(Icons.security, 'Security', '/security_test'),
            _buildDrawerItem(Icons.account_circle, 'Profile', '/profile'),
            _buildDrawerItem(Icons.help, 'Help & Support', '/help'),
          ]),
          
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

  Widget _buildDrawerSection(String title, List<Widget> items) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      initiallyExpanded: false,
      children: items,
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, dynamic action) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(title),
      contentPadding: const EdgeInsets.only(left: 32, right: 16),
      onTap: () {
        Navigator.pop(context);
        if (action is String) {
          Navigator.pushNamed(context, action);
        } else if (action is Function) {
          action();
        }
      },
    );
  }
}
