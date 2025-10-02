class AppConstants {
  // App name
  static const String appName = 'SchoolSM';
  
  // Routes
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String homeRoute = '/home';
  static const String studentDashboardRoute = '/student/dashboard';
  static const String teacherDashboardRoute = '/teacher/dashboard';
  static const String adminDashboardRoute = '/admin/dashboard';
  static const String enrollmentFormRoute = '/student/enrollment';
  static const String adminEnrollmentsRoute = '/admin/enrollments';
  static const String teacherClassesRoute = '/teacher/classes';
  static const String courseListRoute = '/courses';
  static const String courseDetailRoute = '/courses/detail';
  static const String notificationsRoute = '/notifications';
  static const String conversationsRoute = '/conversations';
  static const String chatRoute = '/chat';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';
  static const String enrollmentProgressRoute = '/enrollment/progress';
  static const String documentManagementRoute = '/documents';
  static const String calendarRoute = '/calendar';
  static const String courseComparisonRoute = '/courses/compare';
  static const String savedComparisonsRoute = '/courses/comparisons';
  static const String analyticsDashboardRoute = '/analytics';
  
  // Timetable Routes
  static const String timetableGeneratorRoute = '/timetable/generator';
  static const String timetableViewerRoute = '/timetable/viewer';
  
  // Learning Management Routes
  static const String learningManagementRoute = '/learning';
  static const String assignmentCreatorRoute = '/assignment/creator';
  static const String assignmentListRoute = '/assignment/list';
  static const String quizBuilderRoute = '/quiz/builder';
  
  // Employee Management Routes
  static const String employeeDashboardRoute = '/employee/dashboard';
  static const String employeeManagementRoute = '/employee/management';
  static const String payrollManagementRoute = '/payroll/management';
  
  // Payment Routes
  static const String paymentGatewayRoute = '/payment/gateway';
  
  // Notification Routes
  static const String notificationCenterRoute = '/notifications/center';
  
  // Analytics Routes
  static const String studentPerformanceAnalyticsRoute = '/analytics/student-performance';
  
  // Shared Preferences Keys
  static const String userIdKey = 'userId';
  static const String userNameKey = 'userName';
  static const String userEmailKey = 'userEmail';
  static const String userRoleKey = 'userRole';
  static const String userPhoneKey = 'userPhone';
  static const String isLoggedInKey = 'isLoggedIn';
  
  // User Roles
  static const String studentRole = 'student';
  static const String teacherRole = 'teacher';
  static const String adminRole = 'admin';
}
