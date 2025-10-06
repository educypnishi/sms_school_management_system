import 'package:flutter/material.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Role Selection',
      home: const TestRoleScreen(),
    );
  }
}

class TestRoleScreen extends StatelessWidget {
  const TestRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Role Selection'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Select Your Role',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            
            // Student Card
            Card(
              child: ListTile(
                leading: const Icon(Icons.school, color: Colors.blue),
                title: const Text('Student'),
                subtitle: const Text('Access your courses and grades'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Student selected!')),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Teacher Card
            Card(
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.green),
                title: const Text('Teacher'),
                subtitle: const Text('Manage classes and students'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Teacher selected!')),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Admin Card
            Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.orange),
                title: const Text('Administrator'),
                subtitle: const Text('System administration'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Admin selected!')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
