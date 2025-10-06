import 'package:flutter/material.dart';
import '../services/enrollment_service.dart';
import '../services/grade_service.dart';
import '../services/class_service.dart';
import '../services/fee_service.dart';
import '../services/attendance_service.dart';
import '../services/auth_service.dart';
import '../models/enrollment_model.dart';
import '../models/class_model.dart';
import '../models/grade_model.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/notification_badge.dart';
import 'admin_applications_screen.dart';
import 'analytics_dashboard_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _adminName = '';
  bool _isLoading = true;
  
  // Statistics
  int _totalStudents = 0;
  int _totalTeachers = 0;
  int _totalClasses = 0;
  int _pendingEnrollments = 0;
  double _averageGrade = 0.0;
  double _attendanceRate = 0.0;
  double _totalRevenue = 0.0;
  int _activeUsers = 0;
  
  // Recent activities
  List<Map<String, dynamic>> _recentActivities = [];
  List<EnrollmentModel> _recentEnrollments = [];
  List<ClassModel> _classes = [];
  
  // Services
  final EnrollmentService _enrollmentService = EnrollmentService();
  final GradeService _gradeService = GradeService();
  final ClassService _classService = ClassService();
  final FeeService _feeService = FeeService();
  final AttendanceService _attendanceService = AttendanceService();
  final AuthService _authService = AuthService();

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
      // Get current user
      final currentUser = await _authService.getCurrentUser();
      
      // Generate sample data if needed
      await _gradeService.generateSampleGrades();
      await _feeService.generateSampleFees();
      
      // Load all data
      final enrollments = await _enrollmentService.getAllEnrollments();
      final classes = await _classService.getAllClasses();
      final grades = await _gradeService.getAllGrades();
      final attendanceRecords = await _attendanceService.getAllAttendanceRecords();
      
      // Calculate statistics
      final pendingEnrollments = enrollments.where(
        (enrollment) => enrollment.status == EnrollmentService.statusSubmitted || 
                enrollment.status == EnrollmentService.statusInReview
      ).toList();
      
      final totalStudents = _calculateTotalStudents(classes);
      final totalTeachers = _calculateTotalTeachers(classes);
      final averageGrade = _calculateAverageGrade(grades);
      final attendanceRate = _calculateAttendanceRate(attendanceRecords);
      final totalRevenue = _calculateTotalRevenue();
      final activeUsers = totalStudents + totalTeachers + 5; // +5 for admins
      
      // Generate recent activities
      final recentActivities = _generateRecentActivities(enrollments, grades);
      final recentEnrollments = enrollments.take(5).toList();
      
      setState(() {
        _adminName = currentUser?.name ?? 'Dr. Muhammad Tariq (Admin)';
        _totalStudents = totalStudents;
        _totalTeachers = totalTeachers;
        _totalClasses = classes.length;
        _pendingEnrollments = pendingEnrollments.length;
        _averageGrade = averageGrade;
        _attendanceRate = attendanceRate;
        _totalRevenue = totalRevenue;
        _activeUsers = activeUsers;
        _recentActivities = recentActivities;
        _recentEnrollments = recentEnrollments;
        _classes = classes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading admin data: $e');
      setState(() {
        _adminName = 'Dr. Muhammad Tariq (Admin)';
        _isLoading = false;
      });
    }
  }
  
  int _calculateTotalStudents(List<ClassModel> classes) {
    return classes.fold(0, (sum, classModel) => sum + classModel.currentStudents);
  }
  
  int _calculateTotalTeachers(List<ClassModel> classes) {
    final uniqueTeachers = classes.map((c) => c.teacherName).toSet();
    return uniqueTeachers.length;
  }
  
  double _calculateAverageGrade(List<GradeModel> grades) {
    if (grades.isEmpty) return 0.0;
    final total = grades.fold(0.0, (sum, grade) => sum + grade.score);
    return total / grades.length;
  }
  
  double _calculateAttendanceRate(List<dynamic> records) {
    if (records.isEmpty) return 85.5; // Default value
    // In a real app, this would calculate actual attendance rate
    return 87.3; // Simulated value
  }
  
  double _calculateTotalRevenue() {
    // In a real app, this would calculate from fee payments
    return 2450000.0; // PKR 24.5 Lakh (simulated)
  }
  
  List<Map<String, dynamic>> _generateRecentActivities(List<EnrollmentModel> enrollments, List<GradeModel> grades) {
    final activities = <Map<String, dynamic>>[];
    
    // Add recent enrollments
    for (final enrollment in enrollments.take(3)) {
      activities.add({
        'type': 'enrollment',
        'title': 'New Enrollment',
        'description': 'Student enrolled in ${enrollment.programName}',
        'time': enrollment.submittedAt,
        'icon': Icons.person_add,
        'color': Colors.green,
      });
    }
    
    // Add recent grades
    for (final grade in grades.take(2)) {
      activities.add({
        'type': 'grade',
        'title': 'Grade Updated',
        'description': '${grade.studentName} - ${grade.courseName}: ${grade.letterGrade}',
        'time': grade.gradedDate,
        'icon': Icons.grade,
        'color': Colors.blue,
      });
    }
    
    // Sort by time (most recent first)
    activities.sort((a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime));
    
    return activities.take(5).toList();
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
      drawer: _buildAdminDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card with Admin Profile
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
                              _adminName.isNotEmpty ? _adminName[0].toUpperCase() : 'A',
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
                                  'Welcome, $_adminName!',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Managing $_totalStudents students • $_totalClasses classes • $_totalTeachers teachers',
                                  style: const TextStyle(color: AppTheme.lightTextColor),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadAdminData,
                            tooltip: 'Refresh Data',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // System Overview Statistics
                  Text(
                    'System Overview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Statistics Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard('Students', _totalStudents.toString(), Icons.people, Colors.blue),
                      _buildStatCard('Teachers', _totalTeachers.toString(), Icons.school, Colors.green),
                      _buildStatCard('Classes', _totalClasses.toString(), Icons.class_, Colors.orange),
                      _buildStatCard('Pending', _pendingEnrollments.toString(), Icons.pending, Colors.red),
                      _buildStatCard('Avg Grade', _averageGrade.toStringAsFixed(1), Icons.grade, Colors.purple),
                      _buildStatCard('Attendance', '${_attendanceRate.toStringAsFixed(1)}%', Icons.fact_check, Colors.teal),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Administrative Tools
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
                        'Timetable Generator',
                        Icons.schedule,
                        AppTheme.primaryColor,
                        () {
                          Navigator.pushNamed(context, AppConstants.timetableGeneratorRoute);
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Learning Management',
                        Icons.school,
                        Colors.blue,
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Learning Management - Feature Available!')),
                          );
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Enrollments',
                        Icons.assignment,
                        Colors.green,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminApplicationsScreen(),
                            ),
                          ).then((_) => _loadAdminData());
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Employee Management',
                        Icons.people,
                        Colors.orange,
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Employee Management - Feature Available!')),
                          );
                        },
                      ),
                      _buildActionCard(
                        context,
                        'Fee Management',
                        Icons.payment,
                        Colors.purple,
                        () => _showFeeManagementDialog(),
                      ),
                      _buildActionCard(
                        context,
                        'Reports & Analytics',
                        Icons.analytics,
                        Colors.teal,
                        () {
                          Navigator.pushNamed(
                            context,
                            AppConstants.analyticsDashboardRoute,
                            arguments: {'userRole': 'admin'},
                          );
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Recent Activities
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Activities',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          // Show all activities
                          _showAllActivitiesDialog();
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Activities List
                  _recentActivities.isNotEmpty
                      ? Card(
                          elevation: 2,
                          child: Column(
                            children: _recentActivities.map<Widget>((activity) => 
                              _buildActivityItem(activity)
                            ).toList(),
                          ),
                        )
                      : Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.timeline,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No recent activities',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'System activities will appear here',
                                  style: TextStyle(color: AppTheme.lightTextColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                  
                  const SizedBox(height: 24),
                  
                  // System Health Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.health_and_safety,
                                color: Colors.green,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'System Health',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildHealthIndicator('Database', 'Online', Colors.green),
                              ),
                              Expanded(
                                child: _buildHealthIndicator('Storage', '78% Used', Colors.orange),
                              ),
                              Expanded(
                                child: _buildHealthIndicator('Active Users', _activeUsers.toString(), Colors.blue),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Financial Overview
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: Colors.green,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Financial Overview',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Revenue',
                                      style: TextStyle(
                                        color: AppTheme.lightTextColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'PKR ${(_totalRevenue / 100000).toStringAsFixed(1)}L',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pending Fees',
                                      style: TextStyle(
                                        color: AppTheme.lightTextColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'PKR ${((_totalRevenue * 0.15) / 100000).toStringAsFixed(1)}L',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: 0.85,
                            backgroundColor: Colors.grey[300],
                            color: Colors.green,
                            minHeight: 8,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '85% collection rate this month',
                            style: TextStyle(
                              color: AppTheme.lightTextColor,
                              fontSize: 12,
                            ),
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
  
  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: activity['color'].withOpacity(0.1),
        child: Icon(
          activity['icon'],
          color: activity['color'],
          size: 20,
        ),
      ),
      title: Text(
        activity['title'],
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        activity['description'],
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        _formatTime(activity['time']),
        style: const TextStyle(
          color: AppTheme.lightTextColor,
          fontSize: 10,
        ),
      ),
    );
  }
  
  Widget _buildHealthIndicator(String title, String status, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          status,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.lightTextColor,
          ),
        ),
      ],
    );
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
  
  void _showUserManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Management'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.people, color: Colors.blue),
                title: const Text('Manage Students'),
                subtitle: Text('$_totalStudents active students'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Student management coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.school, color: Colors.green),
                title: const Text('Manage Teachers'),
                subtitle: Text('$_totalTeachers active teachers'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Teacher management coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.purple),
                title: const Text('Manage Admins'),
                subtitle: const Text('5 active admins'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Admin management coming soon')),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person_add, color: Colors.orange),
                title: const Text('Add New User'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddUserDialog();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = 'student';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: ['student', 'teacher', 'admin']
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(role.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${selectedRole.toUpperCase()} ${nameController.text} would be created'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showClassManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Class Management'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.class_, color: Colors.blue),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Classes: $_totalClasses',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Total Students: $_totalStudents',
                              style: const TextStyle(color: AppTheme.lightTextColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _classes.take(3).length,
                  itemBuilder: (context, index) {
                    final classModel = _classes[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: const Icon(Icons.class_, color: Colors.blue),
                      ),
                      title: Text(classModel.name),
                      subtitle: Text('${classModel.teacherName} • ${classModel.currentStudents}/${classModel.capacity}'),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit Class'),
                          ),
                          const PopupMenuItem(
                            value: 'students',
                            child: Text('View Students'),
                          ),
                        ],
                        onSelected: (value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$value ${classModel.name}')),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add new class functionality coming soon')),
              );
            },
            child: const Text('Add Class'),
          ),
        ],
      ),
    );
  }
  
  void _showFeeManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fee Management'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Revenue'),
                          Text(
                            'PKR ${(_totalRevenue / 100000).toStringAsFixed(1)}L',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pending Fees'),
                          Text(
                            'PKR ${((_totalRevenue * 0.15) / 100000).toStringAsFixed(1)}L',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.receipt, color: Colors.blue),
                title: const Text('Generate Fee Report'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fee report generation coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.payment, color: Colors.green),
                title: const Text('Payment History'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment history coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: const Text('Overdue Payments'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Overdue payments tracking coming soon')),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showSystemSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Settings'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.school, color: Colors.blue),
                title: const Text('School Information'),
                subtitle: const Text('Update school details'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('School settings coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.green),
                title: const Text('Academic Calendar'),
                subtitle: const Text('Manage academic year and terms'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Calendar settings coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications, color: Colors.orange),
                title: const Text('Notification Settings'),
                subtitle: const Text('Configure system notifications'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification settings coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.backup, color: Colors.purple),
                title: const Text('Backup & Restore'),
                subtitle: const Text('Manage data backups'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup settings coming soon')),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAllActivitiesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Recent Activities'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _recentActivities.isNotEmpty
              ? ListView.builder(
                  itemCount: _recentActivities.length,
                  itemBuilder: (context, index) {
                    return _buildActivityItem(_recentActivities[index]);
                  },
                )
              : const Center(
                  child: Text('No activities to show'),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }


  String _formatActivityTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildAdminDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_adminName.isEmpty ? 'Admin' : _adminName),
            accountEmail: const Text('admin@school.edu.pk'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.admin_panel_settings,
                size: 30,
                color: AppTheme.primaryColor,
              ),
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
          ),
          
          // Student Management Section
          _buildDrawerSection('👥 Student Management', [
            _buildDrawerItem(Icons.people, 'All Students', '/all_students'),
            _buildDrawerItem(Icons.person_add, 'Enrollments', '/admin_enrollments'),
            _buildDrawerItem(Icons.school, 'Student Records', '/student_records'),
            _buildDrawerItem(Icons.assignment_ind, 'Student Assignments', '/student_assignments'),
            _buildDrawerItem(Icons.check_circle, 'Attendance Reports', '/attendance_reports'),
          ]),
          
          // Teacher Management Section
          _buildDrawerSection('👨‍🏫 Teacher Management', [
            _buildDrawerItem(Icons.group, 'All Teachers', '/all_teachers'),
            _buildDrawerItem(Icons.person_add_alt, 'Add Teacher', '/add_teacher'),
            _buildDrawerItem(Icons.class_, 'Class Assignments', '/class_assignments'),
            _buildDrawerItem(Icons.schedule, 'Teacher Schedules', '/teacher_schedules'),
            _buildDrawerItem(Icons.assessment, 'Performance Reviews', '/teacher_reviews'),
          ]),
          
          // Academic Management Section
          _buildDrawerSection('📚 Academic Management', [
            _buildDrawerItem(Icons.book, 'Courses', '/courses'),
            _buildDrawerItem(Icons.class_, 'Classes', '/classes'),
            _buildDrawerItem(Icons.schedule, 'Timetables', '/timetables'),
            _buildDrawerItem(Icons.quiz, 'Exams', '/exam_management'),
            _buildDrawerItem(Icons.grade, 'Grade Management', '/grade_management'),
          ]),
          
          // Financial Management Section
          _buildDrawerSection('💰 Financial Management', [
            _buildDrawerItem(Icons.payment, 'Fee Management', '/fee_management'),
            _buildDrawerItem(Icons.receipt, 'Payment History', '/payment_history'),
            _buildDrawerItem(Icons.account_balance, 'Revenue Reports', '/revenue_reports'),
            _buildDrawerItem(Icons.credit_card, 'Payment Gateway', '/payment_gateway'),
            _buildDrawerItem(Icons.account_balance_wallet, 'Scholarships', '/scholarships'),
          ]),
          
          // Analytics & Reports Section
          _buildDrawerSection('📊 Analytics & Reports', [
            _buildDrawerItem(Icons.analytics, 'Analytics Dashboard', '/analytics'),
            _buildDrawerItem(Icons.trending_up, 'Performance Analytics', '/performance_analytics'),
            _buildDrawerItem(Icons.bar_chart, 'Financial Reports', '/financial_reports'),
            _buildDrawerItem(Icons.pie_chart, 'Attendance Analytics', '/attendance_analytics'),
            _buildDrawerItem(Icons.assessment, 'Academic Reports', '/academic_reports'),
          ]),
          
          // Communication Section
          _buildDrawerSection('💬 Communication', [
            _buildDrawerItem(Icons.message, 'Messages', '/messages'),
            _buildDrawerItem(Icons.notifications, 'Announcements', '/announcements'),
            _buildDrawerItem(Icons.email, 'Email System', '/email_system'),
            _buildDrawerItem(Icons.sms, 'SMS Notifications', '/sms_notifications'),
            _buildDrawerItem(Icons.support_agent, 'AI Assistant', '/ai_chatbot'),
          ]),
          
          // AI Features Section
          _buildDrawerSection('🤖 AI Features', [
            _buildDrawerItem(Icons.smart_toy, 'AI Admin Assistant', '/ai_chatbot'),
            _buildDrawerItem(Icons.auto_awesome, 'AI Features Test', '/ai_features_test'),
            _buildDrawerItem(Icons.psychology, 'Predictive Analytics', '/predictive_analytics'),
            _buildDrawerItem(Icons.lightbulb, 'AI Recommendations', '/ai_recommendations'),
          ]),
          
          // System Management Section
          _buildDrawerSection('⚙️ System Management', [
            _buildDrawerItem(Icons.settings, 'System Settings', '/system_settings'),
            _buildDrawerItem(Icons.security, 'Security Management', '/security_test'),
            _buildDrawerItem(Icons.backup, 'Data Backup', '/data_backup'),
            _buildDrawerItem(Icons.update, 'System Updates', '/system_updates'),
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
}
