import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_student_service.dart';
import '../services/firebase_class_service.dart';
import '../services/firebase_grade_service.dart';
import '../services/firebase_assignment_service.dart';
import '../services/firebase_attendance_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'student_attendance_analytics_screen.dart';
import 'qr_attendance_screen.dart';
import 'attendance_calendar_screen.dart';
import '../widgets/attendance_alerts_widget.dart';

class EnhancedStudentDashboard extends StatefulWidget {
  const EnhancedStudentDashboard({super.key});

  @override
  State<EnhancedStudentDashboard> createState() => _EnhancedStudentDashboardState();
}

class _EnhancedStudentDashboardState extends State<EnhancedStudentDashboard> {
  String _userName = 'Ahmed Ali';
  bool _isLoading = false;
  
  // Sample data
  double _totalDue = 15000.0;
  double _totalPaid = 25000.0;
  int _pendingFeesCount = 2;
  int _notificationCount = 3;
  List<Map<String, dynamic>> _todayClasses = [];
  List<Map<String, dynamic>> _upcomingExams = [];
  List<Map<String, dynamic>> _recentGrades = [];
  List<Map<String, dynamic>> _pendingAssignments = [];
  Map<String, dynamic> _attendanceStats = {};

  @override
  void initState() {
    super.initState();
    _loadEnhancedData();
  }

  Future<void> _loadEnhancedData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load data from Firebase if user is authenticated
      if (FirebaseAuthService.isAuthenticated) {
        final userId = FirebaseAuthService.currentUserId!;
        
        // Load all real data in parallel
        final results = await Future.wait([
          FirebaseStudentService.getStudentDashboardData(),
          FirebaseGradeService.getStudentGrades(userId),
          FirebaseAssignmentService.getStudentAssignments(userId),
          FirebaseAttendanceService.getStudentAttendanceStats(
            studentId: userId,
            startDate: DateTime.now().subtract(const Duration(days: 30)),
            endDate: DateTime.now(),
          ),
        ]);
        
        final dashboardData = results[0] as Map<String, dynamic>;
        final grades = results[1] as List;
        final assignments = results[2] as List;
        final attendanceStats = results[3] as Map<String, dynamic>;
        
        setState(() {
          _userName = dashboardData['user']['fullName'] ?? 'Student';
          _totalDue = dashboardData['fees']['totalDue']?.toDouble() ?? 0.0;
          _totalPaid = dashboardData['fees']['totalPaid']?.toDouble() ?? 0.0;
          _pendingFeesCount = dashboardData['fees']['pendingCount'] ?? 0;
          _notificationCount = dashboardData['notificationCount'] ?? 0;
          _todayClasses = List<Map<String, dynamic>>.from(dashboardData['todayClasses'] ?? []);
          _upcomingExams = List<Map<String, dynamic>>.from(dashboardData['upcomingExams'] ?? []);
          
          // Process real grades data
          _recentGrades = grades.take(3).map((grade) => {
            'subject': grade.courseName,
            'score': grade.score,
            'maxScore': grade.maxScore,
            'letterGrade': grade.letterGrade,
            'date': grade.gradedDate,
          }).toList();
          
          // Process real assignments data
          _pendingAssignments = assignments.where((assignment) {
            return assignment.dueDate.isAfter(DateTime.now());
          }).take(3).map((assignment) => {
            'title': assignment.title,
            'subject': assignment.subject,
            'dueDate': assignment.dueDate,
            'maxMarks': assignment.maxMarks,
          }).toList();
          
          // Set attendance stats
          _attendanceStats = attendanceStats;
        });
      } else {
        // Load sample data if not authenticated
        await _loadSampleData();
      }
    } catch (e) {
      debugPrint('Error loading enhanced data: $e');
      // Fallback to sample data on error
      await _loadSampleData();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSampleData() async {
    await _loadTodayClasses();
    await _loadUpcomingExams();
  }

  Future<void> _loadTodayClasses() async {
    setState(() {
      _todayClasses = [
        {
          'subject': 'Mathematics',
          'time': '9:00 AM - 10:00 AM',
          'room': 'Room 101',
          'teacher': 'Mr. Khan'
        },
        {
          'subject': 'Physics',
          'time': '11:00 AM - 12:00 PM',
          'room': 'Lab 1',
          'teacher': 'Dr. Ahmed'
        },
        {
          'subject': 'English',
          'time': '2:00 PM - 3:00 PM',
          'room': 'Room 205',
          'teacher': 'Ms. Fatima'
        },
      ];
    });
  }

  Future<void> _loadUpcomingExams() async {
    setState(() {
      _upcomingExams = [
        {
          'subject': 'Mathematics',
          'date': DateTime.now().add(const Duration(days: 5)),
          'type': 'Mid Term'
        },
        {
          'subject': 'Physics',
          'date': DateTime.now().add(const Duration(days: 12)),
          'type': 'Quiz'
        },
        {
          'subject': 'Chemistry',
          'date': DateTime.now().add(const Duration(days: 18)),
          'type': 'Final'
        },
      ];
    });
  }

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
      drawer: _buildComprehensiveDrawer(),
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
                    '$_pendingFeesCount pending',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
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
              const Icon(Icons.schedule, color: AppTheme.secondaryColor),
              const SizedBox(width: 8),
              Text(
                'Today\'s Classes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM dd').format(DateTime.now()),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_todayClasses.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'No classes scheduled for today',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Column(
              children: _todayClasses.take(3).map<Widget>((classInfo) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: const Border(
                      left: BorderSide(
                        color: AppTheme.secondaryColor,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classInfo['subject'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${classInfo['room']} • ${classInfo['teacher']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        classInfo['time'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/timetable_viewer');
            },
            icon: const Icon(Icons.calendar_view_day),
            label: const Text('View Full Timetable'),
          ),
        ],
        ),
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
              const Icon(Icons.quiz, color: AppTheme.accentColor),
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
          if (_upcomingExams.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'No upcoming exams',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Column(
              children: _upcomingExams.take(3).map<Widget>((exam) {
                final daysUntil = exam['date'].difference(DateTime.now()).inDays;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: const Border(
                      left: BorderSide(
                        color: AppTheme.accentColor,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exam['subject'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              exam['type'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: daysUntil <= 7 ? Colors.red : AppTheme.accentColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$daysUntil days',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd').format(exam['date']),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/exam_scheduler');
            },
            icon: const Icon(Icons.event_note),
            label: const Text('View All Exams'),
          ),
        ],
        ),
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
                'Exam Center',
                Icons.quiz,
                Colors.red,
                () => Navigator.pushNamed(context, '/student_exam_dashboard'),
              ),
              _buildActionCard(
                'Fee Payment',
                Icons.payment,
                Colors.green,
                () => Navigator.pushNamed(context, '/fee_payment'),
              ),
              _buildActionCard(
                'Notifications',
                Icons.notifications,
                Colors.orange,
                () => Navigator.pushNamed(context, '/notifications'),
              ),
              _buildActionCard(
                'Timetable',
                Icons.schedule,
                Colors.blue,
                () => Navigator.pushNamed(context, '/timetable'),
              ),
              _buildActionCard(
                'Performance',
                Icons.analytics,
                Colors.purple,
                () => Navigator.pushNamed(context, '/performance'),
              ),
              _buildActionCard(
                'Settings',
                Icons.settings,
                Colors.grey,
                () => Navigator.pushNamed(context, '/settings'),
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
  
  // Additional info card for large desktop layout
  Widget _buildAdditionalInfoCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Stats',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatItem('Total Students', '1,234', Icons.people, Colors.blue),
          const SizedBox(height: 12),
          _buildStatItem('Active Courses', '45', Icons.book, Colors.green),
          const SizedBox(height: 12),
          _buildStatItem('This Month', 'PKR 50,000', Icons.trending_up, Colors.orange),
          const SizedBox(height: 12),
          _buildStatItem('Attendance', '95%', Icons.check_circle, Colors.purple),
        ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComprehensiveDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_userName),
            accountEmail: const Text('ahmed.ali@student.edu.pk'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _userName.split(' ').map((e) => e[0]).join(''),
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
          
          // Academic Section
          _buildDrawerSection('📚 Academic', [
            _buildDrawerItem(Icons.assignment, 'Assignments', '/assignments'),
            _buildDrawerItem(Icons.quiz, 'Quizzes', '/quizzes'),
            _buildDrawerItem(Icons.school, 'My Exams', '/student_exams'),
            _buildDrawerItem(Icons.play_circle, 'Take Exam', '/take_exam'),
            _buildDrawerItem(Icons.grade, 'Grades', '/grades'),
            _buildDrawerItem(Icons.schedule, 'Timetable', '/timetable'),
            _buildDrawerItem(Icons.event, 'Calendar', '/calendar'),
            _buildDrawerItem(Icons.book, 'Courses', '/courses'),
          ]),
          
          // Performance Section
          _buildDrawerSection('📊 Performance', [
            _buildDrawerItem(Icons.analytics, 'Performance Analytics', '/student_performance_analytics'),
            _buildDrawerItem(Icons.trending_up, 'Progress Reports', '/progress'),
            _buildDrawerItem(Icons.assessment, 'Exam Results', '/exam_results'),
            _buildDrawerItem(Icons.history, 'Exam History', '/exam_history'),
            _buildDrawerItem(Icons.book, 'Student Gradebook', '/student_gradebook'),
            _buildDrawerItem(Icons.bar_chart, 'Attendance Analytics', '/student_attendance_analytics'),
            _buildDrawerItem(Icons.check_circle, 'Attendance', '/attendance'),
          ]),
          
          // Communication Section
          _buildDrawerSection('💬 Communication', [
            _buildDrawerItem(Icons.message, 'Messages', '/messages'),
            _buildDrawerItem(Icons.notifications, 'Notifications', '/notifications'),
            _buildDrawerItem(Icons.forum, 'Discussion Forums', '/forums'),
          ]),
          
          // Documents & Files Section
          _buildDrawerSection('📁 Documents', [
            _buildDrawerItem(Icons.folder, 'My Documents', '/documents'),
            _buildDrawerItem(Icons.download, 'Downloads', '/downloads'),
            _buildDrawerItem(Icons.upload_file, 'File Upload', '/upload'),
            _buildDrawerItem(Icons.library_books, 'Library', '/library'),
          ]),
          
          // Financial Section
          _buildDrawerSection('💰 Financial', [
            _buildDrawerItem(Icons.payment, 'Fee Payment', '/fee_payment'),
            _buildDrawerItem(Icons.receipt, 'Fee History', '/fee_history'),
            _buildDrawerItem(Icons.account_balance_wallet, 'Scholarships', '/scholarships'),
            _buildDrawerItem(Icons.credit_card, 'Payment Methods', '/payment_methods'),
          ]),
          
          // AI Features Section
          _buildDrawerSection('🤖 AI Features', [
            _buildDrawerItem(Icons.smart_toy, 'AI Chatbot', '/ai_chatbot'),
            _buildDrawerItem(Icons.auto_awesome, 'AI Features Test', '/ai_features_test'),
            _buildDrawerItem(Icons.psychology, 'Study Assistant', '/study_assistant'),
            _buildDrawerItem(Icons.lightbulb, 'Smart Recommendations', '/recommendations'),
          ]),
          
          // Settings & Security Section
          _buildDrawerSection('⚙️ Settings', [
            _buildDrawerItem(Icons.settings, 'Settings', '/settings'),
            _buildDrawerItem(Icons.security, 'Security Test', '/security_test'),
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

  Widget _buildDrawerItem(IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(title),
      contentPadding: const EdgeInsets.only(left: 32, right: 16),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }

  void _logout() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Sign out from Firebase
      await FirebaseAuthService.signOut();
      
      // Clear local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
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
