import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/enhanced_student_dashboard.dart';
import 'screens/teacher_dashboard_screen.dart';
import 'test_attendance.dart';

class MobileTestLauncher extends StatelessWidget {
  const MobileTestLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Mobile Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TestSelectionScreen(),
    );
  }
}

class TestSelectionScreen extends StatelessWidget {
  const TestSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Mobile Testing'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.phone_android, size: 48, color: Colors.blue[700]),
                    const SizedBox(height: 8),
                    Text(
                      'Mobile Testing Suite',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Test all attendance system features on mobile device',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Test Buttons
            _buildTestButton(
              context,
              'Test Attendance System',
              'Complete Firebase attendance testing',
              Icons.assignment_turned_in,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TestAttendanceScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildTestButton(
              context,
              'Student Dashboard',
              'Test enhanced student dashboard',
              Icons.dashboard,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EnhancedStudentDashboard(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            _buildTestButton(
              context,
              'Teacher Dashboard',
              'Test teacher dashboard features',
              Icons.school,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherDashboardScreen(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Firebase Status
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.cloud_done, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Firebase Status: Connected',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          Text(
                            'Project: school-management-system-79445',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
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

  Widget _buildTestButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

// Main function for mobile testing
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }
  
  runApp(const MobileTestLauncher());
}
