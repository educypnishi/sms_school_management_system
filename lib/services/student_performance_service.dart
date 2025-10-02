import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_performance_model.dart';

class StudentPerformanceService {
  static const String _performancePrefix = 'performance_';
  static const String _performanceListKey = 'performance_list';

  // Add new performance record
  Future<StudentPerformanceModel> addPerformanceRecord({
    required String studentId,
    required String studentName,
    required String className,
    required String subject,
    required String assessmentType,
    required double marksObtained,
    required double totalMarks,
    required DateTime assessmentDate,
    required String teacherId,
    required String teacherName,
    String? semester,
    int? academicYear,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generate unique ID
      final performanceId = 'perf_${DateTime.now().millisecondsSinceEpoch}';
      
      // Calculate percentage and grade
      double percentage = (marksObtained / totalMarks) * 100;
      String grade = StudentPerformanceModel.calculateGrade(percentage);
      
      // Create performance record
      final performance = StudentPerformanceModel(
        id: performanceId,
        studentId: studentId,
        studentName: studentName,
        className: className,
        subject: subject,
        assessmentType: assessmentType,
        marksObtained: marksObtained,
        totalMarks: totalMarks,
        percentage: percentage,
        grade: grade,
        assessmentDate: assessmentDate,
        teacherId: teacherId,
        teacherName: teacherName,
        semester: semester ?? _getCurrentSemester(),
        academicYear: academicYear ?? DateTime.now().year,
      );
      
      // Save performance record
      await prefs.setString(
        '$_performancePrefix$performanceId',
        jsonEncode(performance.toMap()),
      );
      
      // Add to performance list
      final performanceIds = prefs.getStringList(_performanceListKey) ?? [];
      performanceIds.add(performanceId);
      await prefs.setStringList(_performanceListKey, performanceIds);
      
      debugPrint('Performance record added: $performanceId');
      return performance;
      
    } catch (e) {
      debugPrint('Error adding performance record: $e');
      rethrow;
    }
  }

  // Get all performance records
  Future<List<StudentPerformanceModel>> getAllPerformances() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final performanceIds = prefs.getStringList(_performanceListKey) ?? [];
      
      List<StudentPerformanceModel> performances = [];
      for (final id in performanceIds) {
        final performanceJson = prefs.getString('$_performancePrefix$id');
        if (performanceJson != null) {
          final performanceMap = jsonDecode(performanceJson) as Map<String, dynamic>;
          performances.add(StudentPerformanceModel.fromMap(performanceMap, id));
        }
      }
      
      // Sort by assessment date (newest first)
      performances.sort((a, b) => b.assessmentDate.compareTo(a.assessmentDate));
      
      return performances;
    } catch (e) {
      debugPrint('Error getting all performances: $e');
      return [];
    }
  }

  // Get performances by student ID
  Future<List<StudentPerformanceModel>> getStudentPerformances(String studentId) async {
    try {
      final allPerformances = await getAllPerformances();
      return allPerformances.where((p) => p.studentId == studentId).toList();
    } catch (e) {
      debugPrint('Error getting student performances: $e');
      return [];
    }
  }

  // Get performances by class
  Future<List<StudentPerformanceModel>> getClassPerformances(String className) async {
    try {
      final allPerformances = await getAllPerformances();
      return allPerformances.where((p) => p.className == className).toList();
    } catch (e) {
      debugPrint('Error getting class performances: $e');
      return [];
    }
  }

  // Get performances by subject
  Future<List<StudentPerformanceModel>> getSubjectPerformances(String subject) async {
    try {
      final allPerformances = await getAllPerformances();
      return allPerformances.where((p) => p.subject == subject).toList();
    } catch (e) {
      debugPrint('Error getting subject performances: $e');
      return [];
    }
  }

  // Get student analytics summary
  Future<StudentAnalyticsSummary> getStudentAnalytics(String studentId) async {
    try {
      final performances = await getStudentPerformances(studentId);
      
      if (performances.isEmpty) {
        return StudentAnalyticsSummary(
          studentId: studentId,
          studentName: 'Unknown Student',
          className: 'Unknown Class',
          overallGPA: 0.0,
          overallPercentage: 0.0,
          overallGrade: 'F',
          totalAssessments: 0,
          subjectGPAs: {},
          subjectGrades: {},
          subjectAssessmentCounts: {},
          recentPerformances: [],
          monthlyAverages: {},
          semester: _getCurrentSemester(),
          academicYear: DateTime.now().year,
        );
      }

      return StudentAnalyticsSummary.fromPerformances(
        studentId,
        performances.first.studentName,
        performances.first.className,
        performances,
        _getCurrentSemester(),
        DateTime.now().year,
      );
    } catch (e) {
      debugPrint('Error getting student analytics: $e');
      rethrow;
    }
  }

  // Get class analytics
  Future<Map<String, StudentAnalyticsSummary>> getClassAnalytics(String className) async {
    try {
      final classPerformances = await getClassPerformances(className);
      Map<String, StudentAnalyticsSummary> classAnalytics = {};
      
      // Group by student
      Map<String, List<StudentPerformanceModel>> studentPerformances = {};
      for (var performance in classPerformances) {
        if (!studentPerformances.containsKey(performance.studentId)) {
          studentPerformances[performance.studentId] = [];
        }
        studentPerformances[performance.studentId]!.add(performance);
      }
      
      // Create analytics for each student
      for (var entry in studentPerformances.entries) {
        final studentId = entry.key;
        final performances = entry.value;
        
        classAnalytics[studentId] = StudentAnalyticsSummary.fromPerformances(
          studentId,
          performances.first.studentName,
          className,
          performances,
          _getCurrentSemester(),
          DateTime.now().year,
        );
      }
      
      return classAnalytics;
    } catch (e) {
      debugPrint('Error getting class analytics: $e');
      return {};
    }
  }

  // Generate sample performance data
  Future<void> generateSamplePerformances() async {
    try {
      final sampleStudents = [
        {'id': 'std_001', 'name': 'Ahmed Ali', 'class': 'Class 9-A'},
        {'id': 'std_002', 'name': 'Fatima Khan', 'class': 'Class 9-A'},
        {'id': 'std_003', 'name': 'Hassan Ahmed', 'class': 'Class 9-B'},
        {'id': 'std_004', 'name': 'Ayesha Malik', 'class': 'Class 9-B'},
        {'id': 'std_005', 'name': 'Muhammad Usman', 'class': 'Class 10-A'},
      ];

      final subjects = ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'English', 'Urdu', 'Islamiat', 'Pakistan Studies'];
      final assessmentTypes = ['Quiz', 'Assignment', 'Test', 'Mid-Term', 'Final Exam'];
      final random = Random();

      for (var student in sampleStudents) {
        for (var subject in subjects) {
          // Generate 3-5 records per subject per student
          int recordCount = 3 + random.nextInt(3);
          
          for (int i = 0; i < recordCount; i++) {
            // Generate random marks with some realistic distribution
            double totalMarks = 100.0;
            double marksObtained = 40 + random.nextDouble() * 55; // 40-95 range
            
            // Better students get higher marks
            if (student['name']!.contains('Fatima') || student['name']!.contains('Ahmed')) {
              marksObtained = 70 + random.nextDouble() * 25; // 70-95 range
            }
            
            await addPerformanceRecord(
              studentId: student['id']!,
              studentName: student['name']!,
              className: student['class']!,
              subject: subject,
              assessmentType: assessmentTypes[random.nextInt(assessmentTypes.length)],
              marksObtained: marksObtained,
              totalMarks: totalMarks,
              assessmentDate: DateTime.now().subtract(Duration(days: random.nextInt(90))),
              teacherId: 'teacher_${random.nextInt(5) + 1}',
              teacherName: 'Teacher ${random.nextInt(5) + 1}',
            );
          }
        }
      }
      
      debugPrint('Sample performance data generated successfully');
    } catch (e) {
      debugPrint('Error generating sample performances: $e');
    }
  }

  // Get top performers in class
  Future<List<StudentAnalyticsSummary>> getTopPerformers(String className, {int limit = 5}) async {
    try {
      final classAnalytics = await getClassAnalytics(className);
      final sortedStudents = classAnalytics.values.toList()
        ..sort((a, b) => b.overallGPA.compareTo(a.overallGPA));
      
      return sortedStudents.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting top performers: $e');
      return [];
    }
  }

  // Get subject-wise class average
  Future<Map<String, double>> getSubjectAverages(String className) async {
    try {
      final classPerformances = await getClassPerformances(className);
      Map<String, List<double>> subjectMarks = {};
      
      for (var performance in classPerformances) {
        if (!subjectMarks.containsKey(performance.subject)) {
          subjectMarks[performance.subject] = [];
        }
        subjectMarks[performance.subject]!.add(performance.percentage);
      }
      
      Map<String, double> averages = {};
      subjectMarks.forEach((subject, marks) {
        averages[subject] = marks.reduce((a, b) => a + b) / marks.length;
      });
      
      return averages;
    } catch (e) {
      debugPrint('Error getting subject averages: $e');
      return {};
    }
  }

  // Helper method to get current semester
  String _getCurrentSemester() {
    final now = DateTime.now();
    // Pakistani academic calendar: Spring (Jan-June), Fall (July-Dec)
    return now.month <= 6 ? 'Spring' : 'Fall';
  }

  // Delete performance record
  Future<void> deletePerformance(String performanceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove from storage
      await prefs.remove('$_performancePrefix$performanceId');
      
      // Remove from list
      final performanceIds = prefs.getStringList(_performanceListKey) ?? [];
      performanceIds.remove(performanceId);
      await prefs.setStringList(_performanceListKey, performanceIds);
      
      debugPrint('Performance record deleted: $performanceId');
    } catch (e) {
      debugPrint('Error deleting performance: $e');
      rethrow;
    }
  }

  // Update performance record
  Future<StudentPerformanceModel> updatePerformance(
    String performanceId,
    StudentPerformanceModel updatedPerformance,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Update the record
      await prefs.setString(
        '$_performancePrefix$performanceId',
        jsonEncode(updatedPerformance.toMap()),
      );
      
      debugPrint('Performance record updated: $performanceId');
      return updatedPerformance;
    } catch (e) {
      debugPrint('Error updating performance: $e');
      rethrow;
    }
  }
}
