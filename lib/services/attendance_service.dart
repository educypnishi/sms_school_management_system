import 'dart:math';
import '../models/attendance_model.dart';

class AttendanceService {
  // Simulate a database with some sample data
  final List<AttendanceModel> _attendanceRecords = [];
  
  AttendanceService() {
    // Initialize with some sample data
    _generateSampleData();
  }
  
  void _generateSampleData() {
    final random = Random();
    final studentId = 'student123';
    final courses = [
      {'id': 'course1', 'name': 'Mathematics', 'teacher': 'Dr. Muhammad Hassan', 'room': 'A101'},
      {'id': 'course2', 'name': 'Physics', 'teacher': 'Prof. Zara Ahmed', 'room': 'B202'},
      {'id': 'course3', 'name': 'English Literature', 'teacher': 'Ms. Sana Malik', 'room': 'C303'},
      {'id': 'course4', 'name': 'Computer Science', 'teacher': 'Dr. Ali Raza', 'room': 'D404'},
      {'id': 'course5', 'name': 'Urdu', 'teacher': 'Prof. Farah Khan', 'room': 'E505'},
      {'id': 'course6', 'name': 'Islamic Studies', 'teacher': 'Maulana Abdul Rahman', 'room': 'F606'},
    ];
    
    // Generate attendance for the last 3 months
    final now = DateTime.now();
    for (var month = 0; month < 3; month++) {
      final daysInMonth = DateTime(now.year, now.month - month + 1, 0).day;
      
      // Generate 15-20 attendance records per month
      final recordsCount = 15 + random.nextInt(6);
      final selectedDays = <int>{};
      
      while (selectedDays.length < recordsCount) {
        final day = 1 + random.nextInt(daysInMonth);
        selectedDays.add(day);
      }
      
      for (final day in selectedDays) {
        final date = DateTime(now.year, now.month - month, day);
        
        // Skip weekends
        if (date.weekday > 5) continue;
        
        for (final course in courses) {
          // Not every course has a class every day
          if (random.nextBool()) continue;
          
          final statusRandom = random.nextDouble();
          String status;
          String? reason;
          String? notes;
          
          if (statusRandom > 0.85) {
            status = 'absent';
            reason = random.nextBool() ? 'Sick leave' : 'Family emergency';
            notes = 'Student notified in advance';
          } else if (statusRandom > 0.7) {
            status = 'late';
            reason = 'Traffic delay';
            notes = 'Arrived 10 minutes late';
          } else {
            status = 'present';
            reason = null;
            notes = random.nextBool() ? 'Participated actively in class' : null;
          }
          
          final startTime = DateTime(
            date.year, 
            date.month, 
            date.day, 
            8 + random.nextInt(8), // 8 AM to 4 PM
            random.nextInt(4) * 15, // 0, 15, 30, or 45 minutes
          );
          
          final endTime = DateTime(
            startTime.year,
            startTime.month,
            startTime.day,
            startTime.hour + 1 + random.nextInt(2), // 1-2 hours later
            startTime.minute,
          );
          
          _attendanceRecords.add(AttendanceModel(
            id: 'attendance_${_attendanceRecords.length + 1}',
            studentId: studentId,
            studentName: 'Hassan Ali Shah',
            courseId: course['id'] as String,
            courseName: course['name'] as String,
            teacherId: 'teacher_${course['id']}',
            teacherName: course['teacher'] as String,
            subject: course['name'] as String,
            date: date,
            status: status,
            reason: reason,
            notes: notes,
            markedAt: date,
          ));
        }
      }
    }
    // Sort by date (newest first)
    _attendanceRecords.sort((a, b) => b.date.compareTo(a.date));
  }
  
  // Get all attendance records
  Future<List<AttendanceModel>> getAllAttendanceRecords() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    return List.from(_attendanceRecords);
  }
  
  // Get attendance records for a specific date range
  Future<List<AttendanceModel>> getAttendanceByDateRange(
    String studentId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    return _attendanceRecords
        .where((record) => 
            record.studentId == studentId &&
            record.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            record.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }
  
  // Get attendance records for a user (alias for getAttendanceForStudent)
  Future<List<AttendanceModel>> getAttendanceRecordsForUser(String userId) async {
    return getAttendanceForStudent(userId);
  }
  
  // Get attendance for student
  Future<List<AttendanceModel>> getAttendanceForStudent(String studentId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    return _attendanceRecords
        .where((record) => record.studentId == studentId)
        .toList();
  }
  
  // Get attendance by ID
  Future<AttendanceModel> getAttendanceById(String id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final record = _attendanceRecords.firstWhere(
      (record) => record.id == id,
      orElse: () => throw Exception('Attendance record not found'),
    );
    
    return record;
  }
  
  // Get attendance statistics for a student
  Future<Map<String, dynamic>> getAttendanceStatistics(String studentId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
    final records = _attendanceRecords
        .where((record) => record.studentId == studentId)
        .toList();
    
    final totalDays = records.length;
    final presentDays = records.where((r) => r.status == 'present').length;
    final absentDays = records.where((r) => r.status == 'absent').length;
    final lateDays = records.where((r) => r.status == 'late').length;
    
    return {
      'totalDays': totalDays,
      'presentDays': presentDays,
      'absentDays': absentDays,
      'lateDays': lateDays,
      'attendancePercentage': totalDays > 0 ? (presentDays / totalDays * 100) : 0,
    };
  }
}
