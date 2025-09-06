import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/student_dashboard_screen.dart';
import 'screens/partner_dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_applications_screen.dart';
import 'screens/partner_applications_screen.dart';
import 'screens/application_form_screen.dart';
import 'screens/program_list_screen.dart';
import 'screens/program_detail_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/conversations_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/application_progress_screen.dart';
import 'screens/document_management_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/program_comparison_screen.dart';
import 'screens/saved_comparisons_screen.dart';
import 'screens/analytics_dashboard_screen.dart';
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
        AppConstants.partnerDashboardRoute: (context) => const PartnerDashboardScreen(),
        AppConstants.adminDashboardRoute: (context) => const AdminDashboardScreen(),
        AppConstants.applicationFormRoute: (context) => const ApplicationFormScreen(),
        AppConstants.adminApplicationsRoute: (context) => const AdminApplicationsScreen(),
        AppConstants.partnerApplicationsRoute: (context) => const PartnerApplicationsScreen(),
        AppConstants.programListRoute: (context) => const ProgramListScreen(),
        AppConstants.programDetailRoute: (context) => ProgramDetailScreen(
          programId: ModalRoute.of(context)!.settings.arguments as String,
        ),
        AppConstants.notificationsRoute: (context) => const NotificationsScreen(),
        AppConstants.conversationsRoute: (context) => const ConversationsScreen(),
        AppConstants.chatRoute: (context) => ChatScreen(
          conversationId: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['conversationId'] as String,
          title: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['title'] as String,
        ),
        AppConstants.profileRoute: (context) => const ProfileScreen(),
        AppConstants.settingsRoute: (context) => const SettingsScreen(),
        AppConstants.applicationProgressRoute: (context) => ApplicationProgressScreen(
          applicationId: ModalRoute.of(context)!.settings.arguments as String,
        ),
        AppConstants.documentManagementRoute: (context) => DocumentManagementScreen(
          userId: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['userId'] as String,
          applicationId: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['applicationId'] as String,
          isAdmin: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['isAdmin'] as bool? ?? false,
        ),
        AppConstants.calendarRoute: (context) => CalendarScreen(
          userId: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['userId'] as String,
        ),
        AppConstants.programComparisonRoute: (context) => ProgramComparisonScreen(
          userId: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['userId'] as String,
          initialProgramIds: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['programIds'] as List<String>?,
        ),
        AppConstants.savedComparisonsRoute: (context) => SavedComparisonsScreen(
          userId: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['userId'] as String,
        ),
        AppConstants.analyticsDashboardRoute: (context) => AnalyticsDashboardScreen(
          userRole: (ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>)['userRole'] as String,
        ),
      },
    );
  }
}
