import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/student_dashboard_screen.dart';
import 'screens/teacher_dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_applications_screen.dart';
import 'screens/teacher_classes_screen.dart' as original_teacher_classes;
import 'screens/enrollment_form_screen.dart';
import 'screens/course_list_screen.dart';
import 'screens/course_detail_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/conversations_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/enrollment_progress_screen.dart' as original_enrollment_progress;
import 'screens/document_management_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/program_comparison_screen.dart' as original_program_comparison;
import 'screens/saved_comparisons_screen.dart';
import 'screens/analytics_dashboard_screen.dart';
import 'screens/timetable_generator_screen.dart';
import 'screens/timetable_viewer_screen.dart';
import 'screens/notification_center_screen.dart';
import 'screens/student_performance_analytics_screen.dart';
import 'screens/learning_management_screen.dart';
import 'screens/assignment_creator_screen.dart';
import 'screens/assignment_list_screen.dart';
import 'screens/quiz_builder_screen.dart';
import 'screens/employee_dashboard_screen.dart';
import 'screens/employee_management_screen.dart';
import 'screens/payroll_management_screen.dart';
import 'screens/payment_gateway_screen.dart';
import 'screens/grade_analytics_screen.dart';
import 'screens/attendance_tracker_screen.dart';
import 'screens/exam_scheduler_screen.dart';
// import 'screens/fee_payment_screen.dart';
import 'screens/student_fee_dashboard_screen.dart';
import 'screens/university_comparison_screen.dart';
import 'screens/visa_application_detail_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

// For Phase 1, we'll use a simplified version without Firebase
// We'll properly integrate Firebase in later phases
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load theme preference
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('darkMode') ?? false;
  
  runApp(MyApp(isDarkMode: isDarkMode));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  
  const MyApp({super.key, required this.isDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDarkMode;
  
  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.isDarkMode;
  }
  
  void _toggleTheme(bool isDarkMode) {
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: AppConstants.splashRoute,
      routes: {
        AppConstants.splashRoute: (context) => const SplashScreen(),
        AppConstants.loginRoute: (context) => const LoginScreen(),
        AppConstants.signupRoute: (context) => const SignupScreen(),
        AppConstants.studentDashboardRoute: (context) => const StudentDashboardScreen(),
        AppConstants.teacherDashboardRoute: (context) => const TeacherDashboardScreen(),
        AppConstants.adminDashboardRoute: (context) => const AdminDashboardScreen(),
        AppConstants.enrollmentFormRoute: (context) => const EnrollmentFormScreen(),
        AppConstants.adminEnrollmentsRoute: (context) => const AdminApplicationsScreen(),
        AppConstants.teacherClassesRoute: (context) => const original_teacher_classes.TeacherClassesScreen(),
        AppConstants.courseListRoute: (context) => const CourseListScreen(),
        AppConstants.courseDetailRoute: (context) => CourseDetailScreen(
          programId: ModalRoute.of(context)!.settings.arguments as String,
        ),
        AppConstants.notificationsRoute: (context) => Scaffold(
          appBar: AppBar(title: const Text('Notifications')),
          body: const Center(child: Text('Notification Center - Coming Soon!')),
        ),
        AppConstants.conversationsRoute: (context) => const ConversationsScreen(),
        AppConstants.chatRoute: (context) => ChatScreen(
          conversationId: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['conversationId'] as String,
          title: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['title'] as String,
        ),
        AppConstants.profileRoute: (context) => const ProfileScreen(),
        AppConstants.settingsRoute: (context) => const SettingsScreen(),
        AppConstants.enrollmentProgressRoute: (context) => original_enrollment_progress.EnrollmentProgressScreen(
          enrollmentId: ModalRoute.of(context)!.settings.arguments as String,
        ),
        AppConstants.documentManagementRoute: (context) => DocumentManagementScreen(
          userId: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['userId'] as String,
          enrollmentId: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['enrollmentId'] as String,
          isAdmin: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['isAdmin'] as bool? ?? false,
        ),
        AppConstants.calendarRoute: (context) => CalendarScreen(
          userId: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['userId'] as String,
        ),
        AppConstants.courseComparisonRoute: (context) => original_program_comparison.ProgramComparisonScreen(
          userId: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['userId'] as String,
          initialProgramIds: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['programIds'] as List<String>?,
        ),
        AppConstants.savedComparisonsRoute: (context) => SavedComparisonsScreen(
          userId: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['userId'] as String,
        ),
        AppConstants.analyticsDashboardRoute: (context) => const AnalyticsDashboardScreen(
          userRole: 'admin',
        ),
        
        // Timetable Routes
        AppConstants.timetableGeneratorRoute: (context) => const TimetableGeneratorScreen(),
        AppConstants.timetableViewerRoute: (context) => const TimetableViewerScreen(),
        
        // Notification Routes
        AppConstants.notificationCenterRoute: (context) => const NotificationCenterScreen(),
        
        // Analytics Routes
        AppConstants.studentPerformanceAnalyticsRoute: (context) => const StudentPerformanceAnalyticsScreen(),
        
        // Learning Management Routes
        AppConstants.learningManagementRoute: (context) => const LearningManagementScreen(),
        AppConstants.assignmentCreatorRoute: (context) => const AssignmentCreatorScreen(),
        AppConstants.assignmentListRoute: (context) => const AssignmentListScreen(),
        AppConstants.quizBuilderRoute: (context) => const QuizBuilderScreen(),
        
        // Employee Management Routes
        AppConstants.employeeDashboardRoute: (context) => const EmployeeDashboardScreen(),
        AppConstants.employeeManagementRoute: (context) => const EmployeeManagementScreen(),
        AppConstants.payrollManagementRoute: (context) => const PayrollManagementScreen(),
        
        // Payment Routes
        AppConstants.paymentGatewayRoute: (context) => PaymentGatewayScreen(
          studentId: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['studentId'] as String,
          amount: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['amount'] as double,
          description: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['description'] as String,
        ),
        AppConstants.feePaymentRoute: (context) => Scaffold(
          appBar: AppBar(title: const Text('Fee Payment')),
          body: const Center(child: Text('Fee Payment - Coming Soon!')),
        ),
        AppConstants.studentFeeDashboardRoute: (context) => const StudentFeeDashboardScreen(
          studentId: 'demo_student',
        ),
        
        // Additional Analytics Routes - Temporarily disabled
        AppConstants.gradeAnalyticsRoute: (context) => Scaffold(
          appBar: AppBar(title: const Text('Grade Analytics')),
          body: const Center(child: Text('Grade Analytics - Coming Soon!')),
        ),
        
        // Additional Academic Routes
        AppConstants.attendanceTrackerRoute: (context) => const AttendanceTrackerScreen(
          userId: 'demo_user',
        ),
        AppConstants.examSchedulerRoute: (context) => const ExamSchedulerScreen(),
        
        // University & Visa Routes
        AppConstants.universityComparisonRoute: (context) => const UniversityComparisonScreen(),
        AppConstants.visaApplicationDetailRoute: (context) => const VisaApplicationDetailScreen(
          visaApplicationId: 'demo_visa_app',
        ),
      },
    );
  }
}
