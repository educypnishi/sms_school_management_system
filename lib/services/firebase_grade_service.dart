import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/grade_model.dart';
import 'firebase_auth_service.dart';

class FirebaseGradeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create/Update a grade
  static Future<String> saveGrade({
    String? gradeId,
    required String studentId,
    required String studentName,
    required String classId,
    required String className,
    required String subject,
    required String assessmentType, // 'quiz', 'assignment', 'exam', 'project'
    required String assessmentTitle,
    required double score,
    required double maxScore,
    String? comments,
    bool isPublished = false,
  }) async {
    try {
      final teacherId = FirebaseAuthService.currentUserId;
      if (teacherId == null) throw Exception('Teacher not authenticated');

      // Get teacher info
      final teacherDoc = await _firestore.collection('users').doc(teacherId).get();
      final teacherName = teacherDoc.data()?['fullName'] ?? 'Unknown Teacher';

      // Calculate percentage and letter grade
      final percentage = (score / maxScore) * 100;
      final letterGrade = _calculateLetterGrade(percentage);

      final gradeData = {
        'studentId': studentId,
        'studentName': studentName,
        'classId': classId,
        'className': className,
        'subject': subject,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'assessmentType': assessmentType,
        'assessmentTitle': assessmentTitle,
        'score': score,
        'maxScore': maxScore,
        'percentage': percentage,
        'letterGrade': letterGrade,
        'comments': comments ?? '',
        'isPublished': isPublished,
        'gradedDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      String docId;
      if (gradeId != null) {
        // Update existing grade
        await _firestore.collection('grades').doc(gradeId).update(gradeData);
        docId = gradeId;
        debugPrint('✅ Grade updated successfully: $gradeId');
      } else {
        // Create new grade
        gradeData['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await _firestore.collection('grades').add(gradeData);
        docId = docRef.id;
        debugPrint('✅ Grade created successfully: $docId');
      }

      // Update class average if grade is published
      if (isPublished) {
        await _updateClassAverage(classId);
      }

      return docId;
    } catch (e) {
      debugPrint('❌ Error saving grade: $e');
      rethrow;
    }
  }

  // Get grades for a student
  static Future<List<GradeModel>> getStudentGrades(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('grades')
          .where('studentId', isEqualTo: studentId)
          .where('isPublished', isEqualTo: true)
          .orderBy('gradedDate', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return GradeModel(
          id: doc.id,
          studentId: data['studentId'] ?? '',
          studentName: data['studentName'] ?? '',
          courseId: data['classId'] ?? '',
          courseName: data['className'] ?? '',
          teacherId: data['teacherId'] ?? '',
          teacherName: data['teacherName'] ?? '',
          academicYear: DateTime.now().year.toString(),
          term: _getCurrentTerm(),
          score: (data['score'] as num?)?.toDouble() ?? 0.0,
          maxScore: (data['maxScore'] as num?)?.toDouble() ?? 100.0,
          letterGrade: data['letterGrade'] ?? 'F',
          comments: data['comments'],
          gradedDate: (data['gradedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          assessmentType: data['assessmentType'] ?? 'quiz',
          weightage: 1.0, // Default weightage
          isPublished: data['isPublished'] ?? false,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting student grades: $e');
      return [];
    }
  }

  // Get grades for a class
  static Future<List<GradeModel>> getClassGrades(String classId) async {
    try {
      final querySnapshot = await _firestore
          .collection('grades')
          .where('classId', isEqualTo: classId)
          .orderBy('gradedDate', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return GradeModel(
          id: doc.id,
          studentId: data['studentId'] ?? '',
          studentName: data['studentName'] ?? '',
          courseId: data['classId'] ?? '',
          courseName: data['className'] ?? '',
          teacherId: data['teacherId'] ?? '',
          teacherName: data['teacherName'] ?? '',
          academicYear: DateTime.now().year.toString(),
          term: _getCurrentTerm(),
          score: (data['score'] as num?)?.toDouble() ?? 0.0,
          maxScore: (data['maxScore'] as num?)?.toDouble() ?? 100.0,
          letterGrade: data['letterGrade'] ?? 'F',
          comments: data['comments'],
          gradedDate: (data['gradedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          assessmentType: data['assessmentType'] ?? 'quiz',
          weightage: 1.0,
          isPublished: data['isPublished'] ?? false,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting class grades: $e');
      return [];
    }
  }

  // Get teacher's grades
  static Future<List<GradeModel>> getTeacherGrades(String teacherId) async {
    try {
      final querySnapshot = await _firestore
          .collection('grades')
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('gradedDate', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return GradeModel(
          id: doc.id,
          studentId: data['studentId'] ?? '',
          studentName: data['studentName'] ?? '',
          courseId: data['classId'] ?? '',
          courseName: data['className'] ?? '',
          teacherId: data['teacherId'] ?? '',
          teacherName: data['teacherName'] ?? '',
          academicYear: DateTime.now().year.toString(),
          term: _getCurrentTerm(),
          score: (data['score'] as num?)?.toDouble() ?? 0.0,
          maxScore: (data['maxScore'] as num?)?.toDouble() ?? 100.0,
          letterGrade: data['letterGrade'] ?? 'F',
          comments: data['comments'],
          gradedDate: (data['gradedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          assessmentType: data['assessmentType'] ?? 'quiz',
          weightage: 1.0,
          isPublished: data['isPublished'] ?? false,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting teacher grades: $e');
      return [];
    }
  }

  // Publish/Unpublish grade
  static Future<void> publishGrade(String gradeId, bool isPublished) async {
    try {
      await _firestore.collection('grades').doc(gradeId).update({
        'isPublished': isPublished,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update class average if publishing
      if (isPublished) {
        final gradeDoc = await _firestore.collection('grades').doc(gradeId).get();
        final classId = gradeDoc.data()?['classId'];
        if (classId != null) {
          await _updateClassAverage(classId);
        }
      }

      debugPrint('✅ Grade ${isPublished ? 'published' : 'unpublished'} successfully');
    } catch (e) {
      debugPrint('❌ Error publishing grade: $e');
      rethrow;
    }
  }

  // Delete grade
  static Future<void> deleteGrade(String gradeId) async {
    try {
      await _firestore.collection('grades').doc(gradeId).delete();
      debugPrint('✅ Grade deleted successfully: $gradeId');
    } catch (e) {
      debugPrint('❌ Error deleting grade: $e');
      rethrow;
    }
  }

  // Get student's grade analytics
  static Future<Map<String, dynamic>> getStudentGradeAnalytics(String studentId) async {
    try {
      final grades = await getStudentGrades(studentId);
      
      if (grades.isEmpty) {
        return {
          'totalGrades': 0,
          'averageScore': 0.0,
          'averagePercentage': 0.0,
          'highestScore': 0.0,
          'lowestScore': 0.0,
          'gradeDistribution': <String, int>{},
          'subjectAverages': <String, double>{},
        };
      }

      final totalGrades = grades.length;
      final totalScore = grades.fold(0.0, (sum, grade) => sum + grade.score);
      final totalMaxScore = grades.fold(0.0, (sum, grade) => sum + grade.maxScore);
      final averagePercentage = (totalScore / totalMaxScore) * 100;

      final scores = grades.map((g) => g.score).toList();
      final highestScore = scores.reduce((a, b) => a > b ? a : b);
      final lowestScore = scores.reduce((a, b) => a < b ? a : b);

      // Grade distribution
      final gradeDistribution = <String, int>{};
      for (final grade in grades) {
        gradeDistribution[grade.letterGrade] = 
            (gradeDistribution[grade.letterGrade] ?? 0) + 1;
      }

      // Subject averages
      final subjectGrades = <String, List<double>>{};
      for (final grade in grades) {
        final subject = grade.courseName;
        subjectGrades[subject] = (subjectGrades[subject] ?? [])..add(grade.score);
      }

      final subjectAverages = <String, double>{};
      subjectGrades.forEach((subject, scores) {
        subjectAverages[subject] = scores.reduce((a, b) => a + b) / scores.length;
      });

      return {
        'totalGrades': totalGrades,
        'averageScore': totalScore / totalGrades,
        'averagePercentage': averagePercentage,
        'highestScore': highestScore,
        'lowestScore': lowestScore,
        'gradeDistribution': gradeDistribution,
        'subjectAverages': subjectAverages,
      };
    } catch (e) {
      debugPrint('❌ Error getting student analytics: $e');
      return {};
    }
  }

  // Helper method to calculate letter grade
  static String _calculateLetterGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 85) return 'A';
    if (percentage >= 80) return 'B+';
    if (percentage >= 75) return 'B';
    if (percentage >= 70) return 'C+';
    if (percentage >= 65) return 'C';
    if (percentage >= 60) return 'D+';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  // Helper method to get current term
  static String _getCurrentTerm() {
    final month = DateTime.now().month;
    if (month >= 1 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer';
    return 'Fall';
  }

  // Update class average grade
  static Future<void> _updateClassAverage(String classId) async {
    try {
      final gradesSnapshot = await _firestore
          .collection('grades')
          .where('classId', isEqualTo: classId)
          .where('isPublished', isEqualTo: true)
          .get();

      if (gradesSnapshot.docs.isEmpty) return;

      final totalScore = gradesSnapshot.docs.fold(0.0, (sum, doc) {
        final data = doc.data();
        return sum + ((data['score'] as num?)?.toDouble() ?? 0.0);
      });

      final totalMaxScore = gradesSnapshot.docs.fold(0.0, (sum, doc) {
        final data = doc.data();
        return sum + ((data['maxScore'] as num?)?.toDouble() ?? 100.0);
      });

      final averagePercentage = (totalScore / totalMaxScore) * 100;

      await _firestore.collection('classes').doc(classId).update({
        'averageGrade': averagePercentage,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Class average updated: $averagePercentage%');
    } catch (e) {
      debugPrint('❌ Error updating class average: $e');
    }
  }

  // Stream student grades for real-time updates
  static Stream<List<GradeModel>> streamStudentGrades(String studentId) {
    return _firestore
        .collection('grades')
        .where('studentId', isEqualTo: studentId)
        .where('isPublished', isEqualTo: true)
        .orderBy('gradedDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return GradeModel(
          id: doc.id,
          studentId: data['studentId'] ?? '',
          studentName: data['studentName'] ?? '',
          courseId: data['classId'] ?? '',
          courseName: data['className'] ?? '',
          teacherId: data['teacherId'] ?? '',
          teacherName: data['teacherName'] ?? '',
          academicYear: DateTime.now().year.toString(),
          term: _getCurrentTerm(),
          score: (data['score'] as num?)?.toDouble() ?? 0.0,
          maxScore: (data['maxScore'] as num?)?.toDouble() ?? 100.0,
          letterGrade: data['letterGrade'] ?? 'F',
          comments: data['comments'],
          gradedDate: (data['gradedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          assessmentType: data['assessmentType'] ?? 'quiz',
          weightage: 1.0,
          isPublished: data['isPublished'] ?? false,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }
}
