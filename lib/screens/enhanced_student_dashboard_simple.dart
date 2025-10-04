import 'package:flutter/material.dart';

class EnhancedStudentDashboard extends StatefulWidget {
  const EnhancedStudentDashboard({super.key});

  @override
  State<EnhancedStudentDashboard> createState() => _EnhancedStudentDashboardState();
}

class _EnhancedStudentDashboardState extends State<EnhancedStudentDashboard> {
  String _userName = 'Ahmed Ali';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $_userName'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard,
              size: 100,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              'Enhanced Student Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Dashboard is working!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
