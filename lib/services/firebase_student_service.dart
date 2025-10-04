import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';

class FirebaseStudentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get student dashboard data
  static Future<Map<String, dynamic>> getStudentDashboardData() async {
    try {
      final userId = FirebaseAuthService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Get user data
      final userData = await FirestoreService.getDocument(
        collection: 'users',
        docId: userId,
      );

      if (userData == null) throw Exception('User data not found');

      // Get fees data
      final fees = await _getStudentFees(userId);
      
      // Get today's classes
      final todayClasses = await _getTodayClasses(userData['class'] ?? '');
      
      // Get upcoming exams
      final upcomingExams = await _getUpcomingExams(userData['class'] ?? '');
      
      // Get notifications count
      final notificationCount = await _getUnreadNotificationCount(userId);

      return {
        'user': userData,
        'fees': fees,
        'todayClasses': todayClasses,
        'upcomingExams': upcomingExams,
        'notificationCount': notificationCount,
      };
    } catch (e) {
      debugPrint('❌ Error getting student dashboard data: $e');
      rethrow;
    }
  }

  // Get student fees
  static Future<Map<String, dynamic>> _getStudentFees(String studentId) async {
    try {
      final fees = await FirestoreService.getCollection(
        collection: 'fees',
        queryBuilder: (query) => query.where('studentId', isEqualTo: studentId),
      );

      double totalDue = 0.0;
      double totalPaid = 0.0;
      int pendingCount = 0;

      for (var fee in fees) {
        totalDue += (fee['amount'] as num).toDouble();
        totalPaid += (fee['paidAmount'] as num).toDouble();
        if (fee['status'] == 'pending') pendingCount++;
      }

      return {
        'totalDue': totalDue,
        'totalPaid': totalPaid,
        'pendingFees': totalDue - totalPaid,
        'pendingCount': pendingCount,
        'fees': fees,
      };
    } catch (e) {
      debugPrint('❌ Error getting student fees: $e');
      return {
        'totalDue': 0.0,
        'totalPaid': 0.0,
        'pendingFees': 0.0,
        'pendingCount': 0,
        'fees': [],
      };
    }
  }

  // Get today's classes
  static Future<List<Map<String, dynamic>>> _getTodayClasses(String classId) async {
    try {
      if (classId.isEmpty) return [];

      final today = DateTime.now();
      final dayName = _getDayName(today.weekday);

      final timetable = await FirestoreService.getCollection(
        collection: 'timetable',
        queryBuilder: (query) => query
            .where('classId', isEqualTo: classId)
            .where('dayOfWeek', isEqualTo: dayName),
      );

      return timetable;
    } catch (e) {
      debugPrint('❌ Error getting today\'s classes: $e');
      return [];
    }
  }

  // Get upcoming exams
  static Future<List<Map<String, dynamic>>> _getUpcomingExams(String classId) async {
    try {
      if (classId.isEmpty) return [];

      final now = Timestamp.now();
      final exams = await FirestoreService.getCollection(
        collection: 'exams',
        queryBuilder: (query) => query
            .where('classId', isEqualTo: classId)
            .where('examDate', isGreaterThan: now)
            .orderBy('examDate')
            .limit(5),
      );

      return exams;
    } catch (e) {
      debugPrint('❌ Error getting upcoming exams: $e');
      return [];
    }
  }

  // Get unread notification count
  static Future<int> _getUnreadNotificationCount(String userId) async {
    try {
      final notifications = await FirestoreService.getCollection(
        collection: 'notifications',
        queryBuilder: (query) => query
            .where('recipientIds', arrayContains: userId)
            .where('isRead', isEqualTo: false),
      );

      return notifications.length;
    } catch (e) {
      debugPrint('❌ Error getting notification count: $e');
      return 0;
    }
  }

  // Helper method to get day name
  static String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Monday';
    }
  }

  // Stream student dashboard data
  static Stream<Map<String, dynamic>> streamStudentDashboardData() {
    final userId = FirebaseAuthService.currentUserId;
    if (userId == null) {
      return Stream.error('User not authenticated');
    }

    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await getStudentDashboardData();
    }).asyncMap((future) => future);
  }
}
