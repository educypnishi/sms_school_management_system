import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_service.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/firebase_login_screen.dart';
import 'screens/firebase_signup_screen.dart';
import 'screens/student_dashboard_screen.dart';
import 'screens/enhanced_student_dashboard.dart';
import 'screens/security_test_screen.dart';
import 'screens/ai_chatbot_screen.dart';
import 'screens/ai_features_test_screen.dart';
import 'screens/assignment_list_screen.dart';
import 'screens/document_management_screen.dart';
import 'screens/grade_analytics_screen.dart';
import 'screens/attendance_tracker_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/teacher_dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_applications_screen.dart';
import 'screens/teacher_classes_screen.dart' as original_teacher_classes;
import 'screens/enrollment_form_screen.dart';
import 'screens/course_list_screen.dart';
import 'screens/course_detail_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/conversations_screen.dart';
import 'screens/exam_management_screen.dart';
import 'screens/exam_results_screen.dart';
import 'screens/student_exams_screen.dart';
import 'screens/teacher_exams_screen.dart';
import 'screens/student_exam_dashboard_screen.dart';
import 'screens/student_take_exam_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/timetable_viewer_screen.dart';
import 'screens/notification_center_screen.dart';
import 'screens/enrollment_progress_screen.dart' as original_enrollment_progress;
import 'screens/simple_document_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/program_comparison_screen.dart' as original_program_comparison;
import 'screens/saved_comparisons_screen.dart';
import 'screens/analytics_dashboard_screen.dart';
import 'screens/timetable_generator_screen.dart';
import 'screens/timetable_viewer_screen.dart';
import 'screens/notification_center_screen.dart';
import 'screens/student_performance_analytics_screen.dart';
import 'screens/student_gradebook_screen.dart';
import 'screens/student_attendance_analytics_screen.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await FirebaseService.initializeFirebase();
    debugPrint('🔥 Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
    // Continue app execution even if Firebase fails
  }
  
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
        AppConstants.loginRoute: (context) => const FirebaseLoginScreen(),
        AppConstants.signupRoute: (context) => const FirebaseSignupScreen(),
        '/legacy_login': (context) => const LoginScreen(),
        '/legacy_signup': (context) => const SignupScreen(),
        '/firebase_login': (context) => const FirebaseLoginScreen(),
        '/firebase_signup': (context) => const FirebaseSignupScreen(),
        AppConstants.studentDashboardRoute: (context) => const EnhancedStudentDashboard(),
        '/security_test': (context) => const SecurityTestScreen(),
        '/ai_chatbot': (context) => const AIChatbotScreen(),
        '/ai_features_test': (context) => const AIFeaturesTestScreen(),
        '/assignments': (context) => const AssignmentListScreen(),
        '/grades': (context) => const GradeAnalyticsScreen(),
        '/fee_payment': (context) => const StudentFeeDashboardScreen(studentId: 'demo_student'),
        '/documents': (context) => const SimpleDocumentScreen(),
        '/messages': (context) => const ConversationsScreen(),
        '/performance': (context) => const GradeAnalyticsScreen(),
        '/attendance': (context) => const AttendanceTrackerScreen(userId: 'demo_student'),
        '/calendar': (context) => const CalendarScreen(userId: 'demo_student'),
        '/timetable_viewer': (context) => const TimetableViewerScreen(),
        '/timetable': (context) => const TimetableViewerScreen(),
        '/exam_management': (context) => const ExamManagementScreen(),
        '/create_exam': (context) => const TeacherExamsScreen(),
        '/teacher_exams': (context) => const TeacherExamsScreen(),
        '/grade_exams': (context) => const TeacherExamsScreen(),
        '/exam_analytics': (context) => const TeacherExamsScreen(),
        '/student_exams': (context) => const StudentExamsScreen(),
        '/student_exam_dashboard': (context) => const StudentExamDashboardScreen(),
        '/take_exam': (context) => const StudentExamDashboardScreen(),
        '/exam_results': (context) => const StudentExamsScreen(),
        '/exam_history': (context) => const StudentExamsScreen(),
        '/notifications': (context) => const NotificationCenterScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/student_fee_dashboard': (context) => const StudentFeeDashboardScreen(studentId: 'demo_student'),
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
        '/student_performance_analytics': (context) => const StudentPerformanceAnalyticsScreen(),
        '/student_gradebook': (context) => StudentGradebookScreen(studentId: 'demo_student'),
        '/student_attendance_analytics': (context) => const StudentAttendanceAnalyticsScreen(),
        
        // Missing Navigation Routes
        '/courses': (context) => const CourseListScreen(),
        '/progress': (context) => Scaffold(
          appBar: AppBar(title: const Text('Progress Reports')),
          body: const Center(child: Text('Progress Reports - Coming Soon!')),
        ),
        '/forums': (context) => Scaffold(
          appBar: AppBar(title: const Text('Discussion Forums')),
          body: const Center(child: Text('Discussion Forums - Coming Soon!')),
        ),
        '/downloads': (context) => Scaffold(
          appBar: AppBar(title: const Text('Downloads')),
          body: const Center(child: Text('Downloads - Coming Soon!')),
        ),
        '/upload': (context) => Scaffold(
          appBar: AppBar(title: const Text('File Upload')),
          body: const Center(child: Text('File Upload - Coming Soon!')),
        ),
        '/library': (context) => Scaffold(
          appBar: AppBar(title: const Text('Library')),
          body: const Center(child: Text('Library - Coming Soon!')),
        ),
        '/fee_history': (context) => Scaffold(
          appBar: AppBar(title: const Text('Fee History')),
          body: const Center(child: Text('Fee History - Coming Soon!')),
        ),
        '/scholarships': (context) => Scaffold(
          appBar: AppBar(title: const Text('Scholarships')),
          body: const Center(child: Text('Scholarships - Coming Soon!')),
        ),
        '/payment_methods': (context) => Scaffold(
          appBar: AppBar(title: const Text('Payment Methods')),
          body: const Center(child: Text('Payment Methods - Coming Soon!')),
        ),
        '/study_assistant': (context) => Scaffold(
          appBar: AppBar(title: const Text('Study Assistant')),
          body: const Center(child: Text('AI Study Assistant - Coming Soon!')),
        ),
        '/recommendations': (context) => Scaffold(
          appBar: AppBar(title: const Text('Smart Recommendations')),
          body: const Center(child: Text('Smart Recommendations - Coming Soon!')),
        ),
        
        // Learning Management Routes
        AppConstants.learningManagementRoute: (context) => const LearningManagementScreen(),
        AppConstants.assignmentCreatorRoute: (context) => const AssignmentCreatorScreen(),
        AppConstants.assignmentListRoute: (context) => const AssignmentListScreen(),
        AppConstants.quizBuilderRoute: (context) => const QuizBuilderScreen(),
        '/quiz_builder': (context) => const QuizBuilderScreen(),
        '/quizzes': (context) => const QuizBuilderScreen(),
        
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
        
        // Additional Analytics Routes
        AppConstants.gradeAnalyticsRoute: (context) => const GradeAnalyticsScreen(),
        
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
