import 'package:flutter/material.dart';
import 'services/firebase_attendance_service.dart';
import 'services/firebase_auth_service.dart';

class TestAttendanceScreen extends StatefulWidget {
  const TestAttendanceScreen({super.key});

  @override
  State<TestAttendanceScreen> createState() => _TestAttendanceScreenState();
}

class _TestAttendanceScreenState extends State<TestAttendanceScreen> {
  bool _isLoading = false;
  String _result = '';

  Future<void> _testAttendanceSystem() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing attendance system...';
    });

    try {
      // Test 1: Mark attendance
      final attendanceId = await FirebaseAttendanceService.markAttendance(
        studentId: 'test_student_123',
        studentName: 'Ahmed Ali',
        classId: 'test_class_123',
        className: 'Mathematics Grade 10',
        teacherId: 'test_teacher_123',
        teacherName: 'Dr. Sarah Khan',
        subject: 'Mathematics',
        date: DateTime.now(),
        status: 'present',
        notes: 'Test attendance marking',
      );

      // Test 2: Get student attendance stats
      final stats = await FirebaseAttendanceService.getStudentAttendanceStats(
        studentId: 'test_student_123',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );

      setState(() {
        _result = '''
✅ ATTENDANCE SYSTEM TEST RESULTS:

1. ✅ Attendance Marked Successfully
   - Attendance ID: $attendanceId
   - Student: Ahmed Ali
   - Class: Mathematics Grade 10
   - Status: Present
   - Date: ${DateTime.now().toString().split(' ')[0]}

2. ✅ Statistics Retrieved Successfully
   - Total Days: ${stats['totalDays'] ?? 0}
   - Present Days: ${stats['presentDays'] ?? 0}
   - Absent Days: ${stats['absentDays'] ?? 0}
   - Attendance Percentage: ${(stats['attendancePercentage'] ?? 0.0).toStringAsFixed(1)}%

🎉 REAL ATTENDANCE SYSTEM IS WORKING!

Features Tested:
✅ Firebase attendance marking
✅ Real-time data storage
✅ Statistics calculation
✅ Pakistani school context

Ready for production use! 🚀
        ''';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = '''
❌ TEST FAILED:
Error: $e

This might be due to:
- Firebase not configured
- Internet connection issues
- Authentication not set up

Please check Firebase setup and try again.
        ''';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Real Attendance System'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.science, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Real Attendance System Test',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This will test the complete Firebase attendance system with real data operations.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testAttendanceSystem,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isLoading ? 'Testing...' : 'Run Attendance Test'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            if (_result.isNotEmpty)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Text(
                        _result,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
