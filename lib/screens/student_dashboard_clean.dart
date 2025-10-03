import 'package:flutter/material.dart';
import 'enhanced_student_dashboard.dart';

// Clean wrapper - redirects to enhanced dashboard
class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EnhancedStudentDashboard();
  }
}
