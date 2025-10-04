import 'package:flutter/material.dart';

class EnhancedStudentDashboard extends StatefulWidget {
  const EnhancedStudentDashboard({super.key});

  @override
  State<EnhancedStudentDashboard> createState() => _EnhancedStudentDashboardState();
}

class _EnhancedStudentDashboardState extends State<EnhancedStudentDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
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
              color: Colors.purple,
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
              'Dashboard is working successfully!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
