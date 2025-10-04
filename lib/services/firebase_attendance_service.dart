import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/attendance_model.dart';
import 'firebase_auth_service.dart';

class FirebaseAttendanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mark attendance for a student
  static Future<String> markAttendance({
    required String studentId,
    required String studentName,
    required String classId,
    required String className,
    required String teacherId,
    required String teacherName,
    required String subject,
    required DateTime date,
    required String status, // 'present', 'absent', 'late', 'excused'
    String? reason,
    String? notes,
    DateTime? checkInTime,
    DateTime? checkOutTime,
  }) async {
    try {
      // Create unique attendance ID for the day
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final attendanceId = '${studentId}_${classId}_$dateStr';

      final attendanceData = {
        'studentId': studentId,
        'studentName': studentName,
        'classId': classId,
        'className': className,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'subject': subject,
        'date': Timestamp.fromDate(date),
        'status': status,
        'reason': reason ?? '',
        'notes': notes ?? '',
        'checkInTime': checkInTime != null ? Timestamp.fromDate(checkInTime) : null,
        'checkOutTime': checkOutTime != null ? Timestamp.fromDate(checkOutTime) : null,
        'markedAt': FieldValue.serverTimestamp(),
        'markedBy': teacherId,
        'isLate': status == 'late',
        'isExcused': status == 'excused',
        'academicYear': date.year.toString(),
        'month': date.month,
        'dayOfWeek': _getDayOfWeek(date.weekday),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Use set with merge to update if exists
      await _firestore
          .collection('attendance')
          .doc(attendanceId)
          .set(attendanceData, SetOptions(merge: true));

      // Update student's attendance statistics
      await _updateStudentAttendanceStats(studentId, status);

      // Update class attendance statistics
      await _updateClassAttendanceStats(classId, date);

      // Send notification to parents if absent
      if (status == 'absent') {
        await _sendAbsentNotification(studentId, studentName, className, date);
      }

      debugPrint('✅ Attendance marked successfully: $attendanceId');
      return attendanceId;
    } catch (e) {
      debugPrint('❌ Error marking attendance: $e');
      rethrow;
    }
  }

  // Bulk mark attendance for entire class
  static Future<void> markClassAttendance({
    required String classId,
    required String className,
    required String teacherId,
    required String teacherName,
    required String subject,
    required DateTime date,
    required List<Map<String, dynamic>> attendanceList,
  }) async {
    try {
      final batch = _firestore.batch();
      
      for (final attendance in attendanceList) {
        final studentId = attendance['studentId'];
        final studentName = attendance['studentName'];
        final status = attendance['status'];
        final reason = attendance['reason'];
        final notes = attendance['notes'];

        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final attendanceId = '${studentId}_${classId}_$dateStr';

        final attendanceData = {
          'studentId': studentId,
          'studentName': studentName,
          'classId': classId,
          'className': className,
          'teacherId': teacherId,
          'teacherName': teacherName,
          'subject': subject,
          'date': Timestamp.fromDate(date),
          'status': status,
          'reason': reason ?? '',
          'notes': notes ?? '',
          'markedAt': FieldValue.serverTimestamp(),
          'markedBy': teacherId,
          'isLate': status == 'late',
          'isExcused': status == 'excused',
          'academicYear': date.year.toString(),
          'month': date.month,
          'dayOfWeek': _getDayOfWeek(date.weekday),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        final docRef = _firestore.collection('attendance').doc(attendanceId);
        batch.set(docRef, attendanceData, SetOptions(merge: true));
      }

      await batch.commit();

      // Update class statistics
      await _updateClassAttendanceStats(classId, date);

      debugPrint('✅ Class attendance marked successfully');
    } catch (e) {
      debugPrint('❌ Error marking class attendance: $e');
      rethrow;
    }
  }

  // Get student attendance records
  static Future<List<AttendanceModel>> getStudentAttendance({
    required String studentId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection('attendance')
          .where('studentId', isEqualTo: studentId);

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      query = query.orderBy('date', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AttendanceModel(
          id: doc.id,
          studentId: data['studentId'] ?? '',
          studentName: data['studentName'] ?? '',
          courseId: data['classId'] ?? '',
          courseName: data['className'] ?? '',
          teacherId: data['teacherId'] ?? '',
          teacherName: data['teacherName'] ?? '',
          subject: data['subject'] ?? '',
          date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: data['status'] ?? 'absent',
          reason: data['reason'],
          notes: data['notes'],
          checkInTime: (data['checkInTime'] as Timestamp?)?.toDate(),
          checkOutTime: (data['checkOutTime'] as Timestamp?)?.toDate(),
          markedAt: (data['markedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting student attendance: $e');
      return [];
    }
  }

  // Get class attendance for a specific date
  static Future<List<AttendanceModel>> getClassAttendance({
    required String classId,
    required DateTime date,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection('attendance')
          .where('classId', isEqualTo: classId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('date')
          .orderBy('studentName')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return AttendanceModel(
          id: doc.id,
          studentId: data['studentId'] ?? '',
          studentName: data['studentName'] ?? '',
          courseId: data['classId'] ?? '',
          courseName: data['className'] ?? '',
          teacherId: data['teacherId'] ?? '',
          teacherName: data['teacherName'] ?? '',
          subject: data['subject'] ?? '',
          date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: data['status'] ?? 'absent',
          reason: data['reason'],
          notes: data['notes'],
          checkInTime: (data['checkInTime'] as Timestamp?)?.toDate(),
          checkOutTime: (data['checkOutTime'] as Timestamp?)?.toDate(),
          markedAt: (data['markedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting class attendance: $e');
      return [];
    }
  }

  // Get attendance statistics for a student
  static Future<Map<String, dynamic>> getStudentAttendanceStats({
    required String studentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final attendanceRecords = await getStudentAttendance(
        studentId: studentId,
        startDate: startDate,
        endDate: endDate,
      );

      if (attendanceRecords.isEmpty) {
        return {
          'totalDays': 0,
          'presentDays': 0,
          'absentDays': 0,
          'lateDays': 0,
          'excusedDays': 0,
          'attendancePercentage': 0.0,
          'punctualityPercentage': 0.0,
        };
      }

      final totalDays = attendanceRecords.length;
      final presentDays = attendanceRecords.where((a) => a.status == 'present').length;
      final absentDays = attendanceRecords.where((a) => a.status == 'absent').length;
      final lateDays = attendanceRecords.where((a) => a.status == 'late').length;
      final excusedDays = attendanceRecords.where((a) => a.status == 'excused').length;

      final attendancePercentage = ((presentDays + lateDays + excusedDays) / totalDays) * 100;
      final punctualityPercentage = (presentDays / totalDays) * 100;

      return {
        'totalDays': totalDays,
        'presentDays': presentDays,
        'absentDays': absentDays,
        'lateDays': lateDays,
        'excusedDays': excusedDays,
        'attendancePercentage': attendancePercentage,
        'punctualityPercentage': punctualityPercentage,
        'monthlyStats': _calculateMonthlyStats(attendanceRecords),
        'weeklyPattern': _calculateWeeklyPattern(attendanceRecords),
      };
    } catch (e) {
      debugPrint('❌ Error getting attendance stats: $e');
      return {};
    }
  }

  // Get class attendance statistics
  static Future<Map<String, dynamic>> getClassAttendanceStats({
    required String classId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection('attendance')
          .where('classId', isEqualTo: classId);

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.get();
      final attendanceRecords = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AttendanceModel(
          id: doc.id,
          studentId: data['studentId'] ?? '',
          studentName: data['studentName'] ?? '',
          courseId: data['classId'] ?? '',
          courseName: data['className'] ?? '',
          teacherId: data['teacherId'] ?? '',
          teacherName: data['teacherName'] ?? '',
          subject: data['subject'] ?? '',
          date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: data['status'] ?? 'absent',
          reason: data['reason'],
          notes: data['notes'],
          checkInTime: (data['checkInTime'] as Timestamp?)?.toDate(),
          checkOutTime: (data['checkOutTime'] as Timestamp?)?.toDate(),
          markedAt: (data['markedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      if (attendanceRecords.isEmpty) {
        return {
          'totalRecords': 0,
          'averageAttendance': 0.0,
          'presentCount': 0,
          'absentCount': 0,
          'lateCount': 0,
          'excusedCount': 0,
        };
      }

      final totalRecords = attendanceRecords.length;
      final presentCount = attendanceRecords.where((a) => a.status == 'present').length;
      final absentCount = attendanceRecords.where((a) => a.status == 'absent').length;
      final lateCount = attendanceRecords.where((a) => a.status == 'late').length;
      final excusedCount = attendanceRecords.where((a) => a.status == 'excused').length;

      final averageAttendance = ((presentCount + lateCount + excusedCount) / totalRecords) * 100;

      return {
        'totalRecords': totalRecords,
        'averageAttendance': averageAttendance,
        'presentCount': presentCount,
        'absentCount': absentCount,
        'lateCount': lateCount,
        'excusedCount': excusedCount,
        'dailyStats': _calculateDailyStats(attendanceRecords),
        'studentStats': _calculateStudentStats(attendanceRecords),
      };
    } catch (e) {
      debugPrint('❌ Error getting class attendance stats: $e');
      return {};
    }
  }

  // QR Code check-in
  static Future<String> checkInWithQR({
    required String studentId,
    required String qrData,
    required DateTime checkInTime,
  }) async {
    try {
      // Parse QR data (format: classId_date_subject)
      final qrParts = qrData.split('_');
      if (qrParts.length < 3) {
        throw Exception('Invalid QR code format');
      }

      final classId = qrParts[0];
      final dateStr = qrParts[1];
      final subject = qrParts[2];

      // Get student and class info
      final studentDoc = await _firestore.collection('users').doc(studentId).get();
      final classDoc = await _firestore.collection('classes').doc(classId).get();

      if (!studentDoc.exists || !classDoc.exists) {
        throw Exception('Student or class not found');
      }

      final studentData = studentDoc.data()!;
      final classData = classDoc.data()!;

      // Determine if late (assuming class starts at 8:00 AM)
      final classStartTime = DateTime(
        checkInTime.year,
        checkInTime.month,
        checkInTime.day,
        8, 0, 0,
      );

      final status = checkInTime.isAfter(classStartTime.add(const Duration(minutes: 15))) 
          ? 'late' 
          : 'present';

      return await markAttendance(
        studentId: studentId,
        studentName: studentData['fullName'] ?? '',
        classId: classId,
        className: classData['name'] ?? '',
        teacherId: classData['teacherId'] ?? '',
        teacherName: classData['teacherName'] ?? '',
        subject: subject,
        date: checkInTime,
        status: status,
        checkInTime: checkInTime,
        notes: 'QR Code Check-in',
      );
    } catch (e) {
      debugPrint('❌ Error with QR check-in: $e');
      rethrow;
    }
  }

  // Helper methods
  static String _getDayOfWeek(int weekday) {
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

  static Future<void> _updateStudentAttendanceStats(String studentId, String status) async {
    try {
      final statsDoc = _firestore.collection('attendanceStats').doc(studentId);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(statsDoc);
        
        if (snapshot.exists) {
          final data = snapshot.data()!;
          final totalDays = (data['totalDays'] ?? 0) + 1;
          final presentDays = data['presentDays'] ?? 0;
          final absentDays = data['absentDays'] ?? 0;
          final lateDays = data['lateDays'] ?? 0;
          final excusedDays = data['excusedDays'] ?? 0;

          Map<String, dynamic> updateData = {'totalDays': totalDays};
          
          switch (status) {
            case 'present':
              updateData['presentDays'] = presentDays + 1;
              break;
            case 'absent':
              updateData['absentDays'] = absentDays + 1;
              break;
            case 'late':
              updateData['lateDays'] = lateDays + 1;
              break;
            case 'excused':
              updateData['excusedDays'] = excusedDays + 1;
              break;
          }

          final attendancePercentage = ((updateData['presentDays'] ?? presentDays) + 
              (updateData['lateDays'] ?? lateDays) + 
              (updateData['excusedDays'] ?? excusedDays)) / totalDays * 100;
          
          updateData['attendancePercentage'] = attendancePercentage;
          updateData['updatedAt'] = FieldValue.serverTimestamp();

          transaction.update(statsDoc, updateData);
        } else {
          final newData = {
            'studentId': studentId,
            'totalDays': 1,
            'presentDays': status == 'present' ? 1 : 0,
            'absentDays': status == 'absent' ? 1 : 0,
            'lateDays': status == 'late' ? 1 : 0,
            'excusedDays': status == 'excused' ? 1 : 0,
            'attendancePercentage': status != 'absent' ? 100.0 : 0.0,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };
          transaction.set(statsDoc, newData);
        }
      });
    } catch (e) {
      debugPrint('❌ Error updating student stats: $e');
    }
  }

  static Future<void> _updateClassAttendanceStats(String classId, DateTime date) async {
    // Implementation for updating class statistics
    // This would calculate daily class attendance rates
  }

  static Future<void> _sendAbsentNotification(
    String studentId,
    String studentName,
    String className,
    DateTime date,
  ) async {
    try {
      // Get parent/guardian contact info
      final studentDoc = await _firestore.collection('users').doc(studentId).get();
      final parentId = studentDoc.data()?['parentId'];
      
      if (parentId != null) {
        await _firestore.collection('notifications').add({
          'title': 'Student Absent Today',
          'message': '$studentName was marked absent in $className on ${date.day}/${date.month}/${date.year}',
          'type': 'attendance',
          'recipientIds': [parentId],
          'metadata': {
            'studentId': studentId,
            'classId': className,
            'date': date.toIso8601String(),
            'status': 'absent',
          },
          'isRead': false,
          'sentAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('❌ Error sending absent notification: $e');
    }
  }

  static Map<String, dynamic> _calculateMonthlyStats(List<AttendanceModel> records) {
    final monthlyStats = <int, Map<String, int>>{};
    
    for (final record in records) {
      final month = record.date.month;
      monthlyStats[month] ??= {
        'present': 0,
        'absent': 0,
        'late': 0,
        'excused': 0,
      };
      monthlyStats[month]![record.status] = (monthlyStats[month]![record.status] ?? 0) + 1;
    }
    
    return monthlyStats.map((month, stats) => MapEntry(month.toString(), stats));
  }

  static Map<String, int> _calculateWeeklyPattern(List<AttendanceModel> records) {
    final weeklyPattern = <String, int>{
      'Monday': 0,
      'Tuesday': 0,
      'Wednesday': 0,
      'Thursday': 0,
      'Friday': 0,
      'Saturday': 0,
      'Sunday': 0,
    };
    
    for (final record in records) {
      final dayName = _getDayOfWeek(record.date.weekday);
      if (record.status == 'present') {
        weeklyPattern[dayName] = (weeklyPattern[dayName] ?? 0) + 1;
      }
    }
    
    return weeklyPattern;
  }

  static Map<String, dynamic> _calculateDailyStats(List<AttendanceModel> records) {
    final dailyStats = <String, Map<String, int>>{};
    
    for (final record in records) {
      final dateKey = '${record.date.year}-${record.date.month}-${record.date.day}';
      dailyStats[dateKey] ??= {
        'present': 0,
        'absent': 0,
        'late': 0,
        'excused': 0,
      };
      dailyStats[dateKey]![record.status] = (dailyStats[dateKey]![record.status] ?? 0) + 1;
    }
    
    return dailyStats;
  }

  static Map<String, dynamic> _calculateStudentStats(List<AttendanceModel> records) {
    final studentStats = <String, Map<String, int>>{};
    
    for (final record in records) {
      studentStats[record.studentId] ??= {
        'present': 0,
        'absent': 0,
        'late': 0,
        'excused': 0,
      };
      studentStats[record.studentId]![record.status] = 
          (studentStats[record.studentId]![record.status] ?? 0) + 1;
    }
    
    return studentStats;
  }

  // Stream attendance for real-time updates
  static Stream<List<AttendanceModel>> streamStudentAttendance(String studentId) {
    return _firestore
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .orderBy('date', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AttendanceModel(
          id: doc.id,
          studentId: data['studentId'] ?? '',
          studentName: data['studentName'] ?? '',
          courseId: data['classId'] ?? '',
          courseName: data['className'] ?? '',
          teacherId: data['teacherId'] ?? '',
          teacherName: data['teacherName'] ?? '',
          subject: data['subject'] ?? '',
          date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: data['status'] ?? 'absent',
          reason: data['reason'],
          notes: data['notes'],
          checkInTime: (data['checkInTime'] as Timestamp?)?.toDate(),
          checkOutTime: (data['checkOutTime'] as Timestamp?)?.toDate(),
          markedAt: (data['markedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }
}
