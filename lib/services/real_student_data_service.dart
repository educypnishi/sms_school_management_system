import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student_model.dart';
import '../models/real_attendance_model.dart';
import '../models/real_grade_model.dart';
import '../models/real_fee_model.dart';
import '../models/real_class_model.dart';

class RealStudentDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current student data
  Future<StudentModel?> getCurrentStudent() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final studentDoc = await _firestore
          .collection('students')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (studentDoc.docs.isEmpty) return null;

      final doc = studentDoc.docs.first;
      return StudentModel.fromMap(doc.data(), doc.id);
    } catch (e) {
      print('Error getting current student: $e');
      return null;
    }
  }

  // Get student by ID
  Future<StudentModel?> getStudentById(String studentId) async {
    try {
      final doc = await _firestore.collection('students').doc(studentId).get();
      if (!doc.exists) return null;
      
      return StudentModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting student by ID: $e');
      return null;
    }
  }

  // Get student's attendance summary
  Future<AttendanceSummary?> getAttendanceSummary(String studentId, {String period = 'monthly'}) async {
    try {
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate = now;

      switch (period) {
        case 'weekly':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          break;
        case 'monthly':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'yearly':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, 1);
      }

      final attendanceQuery = await _firestore
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final records = attendanceQuery.docs
          .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
          .toList();

      return AttendanceSummary.fromRecords(studentId, records, period, startDate, endDate);
    } catch (e) {
      print('Error getting attendance summary: $e');
      return null;
    }
  }

  // Get student's recent grades
  Future<List<RealGradeModel>> getRecentGrades(String studentId, {int limit = 10}) async {
    try {
      final gradesQuery = await _firestore
          .collection('grades')
          .where('studentId', isEqualTo: studentId)
          .orderBy('assessmentDate', descending: true)
          .limit(limit)
          .get();

      return gradesQuery.docs
          .map((doc) => RealGradeModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting recent grades: $e');
      return [];
    }
  }

  // Get student's GPA for current term
  Future<StudentGPA?> getCurrentGPA(String studentId) async {
    try {
      // Get current academic term (you might want to make this configurable)
      final currentTerm = 'Fall 2024';
      
      final gradesQuery = await _firestore
          .collection('grades')
          .where('studentId', isEqualTo: studentId)
          .get();

      final grades = gradesQuery.docs
          .map((doc) => RealGradeModel.fromMap(doc.data(), doc.id))
          .toList();

      // Group grades by subject
      final gradesBySubject = <String, List<RealGradeModel>>{};
      for (final grade in grades) {
        if (!gradesBySubject.containsKey(grade.subjectId)) {
          gradesBySubject[grade.subjectId] = [];
        }
        gradesBySubject[grade.subjectId]!.add(grade);
      }

      // Calculate subject summaries
      final subjectSummaries = gradesBySubject.entries
          .map((entry) => SubjectGradeSummary.fromGrades(
                entry.key,
                entry.value.first.subjectName,
                entry.value,
              ))
          .toList();

      return StudentGPA.calculate(studentId, currentTerm, subjectSummaries);
    } catch (e) {
      print('Error calculating GPA: $e');
      return null;
    }
  }

  // Get student's fee summary
  Future<StudentFeeSummary?> getFeeSummary(String studentId) async {
    try {
      final feeQuery = await _firestore
          .collection('student_fees')
          .where('studentId', isEqualTo: studentId)
          .get();

      final feeRecords = feeQuery.docs
          .map((doc) => StudentFeeRecord.fromMap(doc.data(), doc.id))
          .toList();

      return StudentFeeSummary.fromFeeRecords(studentId, feeRecords);
    } catch (e) {
      print('Error getting fee summary: $e');
      return null;
    }
  }

  // Get today's class schedule
  Future<TodayClassSchedule?> getTodaySchedule(String studentId) async {
    try {
      // First get student's class enrollment
      final enrollmentQuery = await _firestore
          .collection('class_enrollments')
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'active')
          .get();

      if (enrollmentQuery.docs.isEmpty) return null;

      final enrollment = StudentClassEnrollment.fromMap(
        enrollmentQuery.docs.first.data(),
        enrollmentQuery.docs.first.id,
      );

      // Get class schedules for the student's class
      final scheduleQuery = await _firestore
          .collection('class_schedules')
          .where('classId', isEqualTo: enrollment.classId)
          .where('isActive', isEqualTo: true)
          .get();

      final schedules = scheduleQuery.docs
          .map((doc) => ClassSchedule.fromMap(doc.data(), doc.id))
          .toList();

      return TodayClassSchedule.fromSchedules(studentId, schedules);
    } catch (e) {
      print('Error getting today\'s schedule: $e');
      return null;
    }
  }

  // Get upcoming assignments
  Future<List<Map<String, dynamic>>> getUpcomingAssignments(String studentId, {int limit = 5}) async {
    try {
      final now = DateTime.now();
      final assignmentsQuery = await _firestore
          .collection('assignments')
          .where('studentIds', arrayContains: studentId)
          .where('dueDate', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('dueDate')
          .limit(limit)
          .get();

      return assignmentsQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'subject': data['subject'] ?? '',
          'dueDate': (data['dueDate'] as Timestamp).toDate(),
          'maxMarks': data['maxMarks'] ?? 0,
          'description': data['description'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error getting upcoming assignments: $e');
      return [];
    }
  }

  // Get upcoming exams
  Future<List<Map<String, dynamic>>> getUpcomingExams(String studentId, {int limit = 5}) async {
    try {
      final now = DateTime.now();
      final examsQuery = await _firestore
          .collection('exams')
          .where('studentIds', arrayContains: studentId)
          .where('examDate', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('examDate')
          .limit(limit)
          .get();

      return examsQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'subject': data['subject'] ?? '',
          'date': (data['examDate'] as Timestamp).toDate(),
          'type': data['examType'] ?? '',
          'duration': data['duration'] ?? 0,
          'totalMarks': data['totalMarks'] ?? 0,
        };
      }).toList();
    } catch (e) {
      print('Error getting upcoming exams: $e');
      return [];
    }
  }

  // Update student profile
  Future<bool> updateStudentProfile(String studentId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore.collection('students').doc(studentId).update(updates);
      return true;
    } catch (e) {
      print('Error updating student profile: $e');
      return false;
    }
  }

  // Create initial student data (for new registrations)
  Future<String?> createStudent(StudentModel student) async {
    try {
      final docRef = await _firestore.collection('students').add(student.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating student: $e');
      return null;
    }
  }

  // Get student's notification count
  Future<int> getNotificationCount(String studentId) async {
    try {
      final notificationsQuery = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: studentId)
          .where('isRead', isEqualTo: false)
          .get();

      return notificationsQuery.docs.length;
    } catch (e) {
      print('Error getting notification count: $e');
      return 0;
    }
  }

  // Get student dashboard summary data
  Future<Map<String, dynamic>> getDashboardSummary(String studentId) async {
    try {
      final futures = await Future.wait([
        getCurrentStudent(),
        getAttendanceSummary(studentId),
        getFeeSummary(studentId),
        getTodaySchedule(studentId),
        getRecentGrades(studentId, limit: 3),
        getUpcomingAssignments(studentId, limit: 3),
        getUpcomingExams(studentId, limit: 3),
        getNotificationCount(studentId),
      ]);

      return {
        'student': futures[0] as StudentModel?,
        'attendance': futures[1] as AttendanceSummary?,
        'fees': futures[2] as StudentFeeSummary?,
        'todaySchedule': futures[3] as TodayClassSchedule?,
        'recentGrades': futures[4] as List<RealGradeModel>,
        'upcomingAssignments': futures[5] as List<Map<String, dynamic>>,
        'upcomingExams': futures[6] as List<Map<String, dynamic>>,
        'notificationCount': futures[7] as int,
      };
    } catch (e) {
      print('Error getting dashboard summary: $e');
      return {};
    }
  }
}
