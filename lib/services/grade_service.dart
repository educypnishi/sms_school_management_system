import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grade_model.dart';
import '../services/auth_service.dart';

class GradeService {
  // Save a grade
  Future<GradeModel> saveGrade({
    String? id,
    required String studentId,
    required String studentName,
    required String courseId,
    required String courseName,
    required String teacherId,
    required String teacherName,
    required String academicYear,
    required String term,
    required double score,
    double maxScore = 100.0,
    required String assessmentType,
    required double weightage,
    String? comments,
    bool isPublished = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generate a new ID if not provided
      final gradeId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      // Calculate letter grade based on score
      final letterGrade = _calculateLetterGrade(score);
      
      // Create grade model
      final grade = GradeModel(
        id: gradeId,
        studentId: studentId,
        studentName: studentName,
        courseId: courseId,
        courseName: courseName,
        teacherId: teacherId,
        teacherName: teacherName,
        academicYear: academicYear,
        term: term,
        score: score,
        maxScore: maxScore,
        letterGrade: letterGrade,
        comments: comments,
        gradedDate: DateTime.now(),
        assessmentType: assessmentType,
        weightage: weightage,
        isPublished: isPublished,
        createdAt: DateTime.now(),
      );
      
      // Save grade to SharedPreferences
      await prefs.setString('grade_$gradeId', jsonEncode(grade.toMap()));
      
      // Add grade ID to course's grades list
      final courseGrades = prefs.getStringList('course_grades_$courseId') ?? [];
      if (!courseGrades.contains(gradeId)) {
        courseGrades.add(gradeId);
        await prefs.setStringList('course_grades_$courseId', courseGrades);
      }
      
      // Add grade ID to student's grades list
      final studentGrades = prefs.getStringList('student_grades_$studentId') ?? [];
      if (!studentGrades.contains(gradeId)) {
        studentGrades.add(gradeId);
        await prefs.setStringList('student_grades_$studentId', studentGrades);
      }
      
      return grade;
    } catch (e) {
      debugPrint('Error saving grade: $e');
      rethrow;
    }
  }
  
  // Get grade by ID
  Future<GradeModel?> getGradeById(String gradeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get grade from SharedPreferences
      final gradeJson = prefs.getString('grade_$gradeId');
      if (gradeJson == null) {
        return null;
      }
      
      // Parse grade
      final gradeMap = jsonDecode(gradeJson) as Map<String, dynamic>;
      return GradeModel.fromMap(gradeMap, gradeId);
    } catch (e) {
      debugPrint('Error getting grade: $e');
      return null;
    }
  }
  
  // Get all grades
  Future<List<GradeModel>> getAllGrades() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('grade_')).toList();
      
      final grades = <GradeModel>[];
      for (final key in keys) {
        final gradeJson = prefs.getString(key);
        if (gradeJson != null) {
          final gradeMap = jsonDecode(gradeJson) as Map<String, dynamic>;
          final gradeId = key.substring('grade_'.length);
          grades.add(GradeModel.fromMap(gradeMap, gradeId));
        }
      }
      
      return grades;
    } catch (e) {
      debugPrint('Error getting all grades: $e');
      return [];
    }
  }
  
  // Update grade
  Future<GradeModel> updateGrade({
    required String id,
    double? score,
    String? comments,
    bool? isPublished,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing grade
      final existingGradeJson = prefs.getString('grade_$id');
      if (existingGradeJson == null) {
        throw Exception('Grade not found');
      }
      
      // Parse existing grade
      final existingGradeMap = jsonDecode(existingGradeJson) as Map<String, dynamic>;
      final existingGrade = GradeModel.fromMap(existingGradeMap, id);
      
      // Calculate new letter grade if score is updated
      String? newLetterGrade;
      if (score != null) {
        newLetterGrade = _calculateLetterGrade(score);
      }
      
      // Update grade
      final updatedGrade = existingGrade.copyWith(
        score: score,
        letterGrade: newLetterGrade,
        comments: comments,
        isPublished: isPublished,
        updatedAt: DateTime.now(),
      );
      
      // Save updated grade to SharedPreferences
      await prefs.setString('grade_$id', jsonEncode(updatedGrade.toMap()));
      
      return updatedGrade;
    } catch (e) {
      debugPrint('Error updating grade: $e');
      rethrow;
    }
  }
  
  // Delete grade
  Future<void> deleteGrade(String gradeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get grade to delete
      final gradeJson = prefs.getString('grade_$gradeId');
      if (gradeJson == null) {
        return;
      }
      
      // Parse grade
      final gradeMap = jsonDecode(gradeJson) as Map<String, dynamic>;
      final grade = GradeModel.fromMap(gradeMap, gradeId);
      
      // Remove grade from SharedPreferences
      await prefs.remove('grade_$gradeId');
      
      // Remove grade ID from course's grades list
      final courseGrades = prefs.getStringList('course_grades_${grade.courseId}') ?? [];
      courseGrades.remove(gradeId);
      await prefs.setStringList('course_grades_${grade.courseId}', courseGrades);
      
      // Remove grade ID from student's grades list
      final studentGrades = prefs.getStringList('student_grades_${grade.studentId}') ?? [];
      studentGrades.remove(gradeId);
      await prefs.setStringList('student_grades_${grade.studentId}', studentGrades);
    } catch (e) {
      debugPrint('Error deleting grade: $e');
      rethrow;
    }
  }
  
  // Get grades for a student
  Future<List<GradeModel>> getGradesForStudent(String studentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get student's grade IDs
      final gradeIds = prefs.getStringList('student_grades_$studentId') ?? [];
      
      // Get grades
      final grades = <GradeModel>[];
      for (final id in gradeIds) {
        final grade = await getGradeById(id);
        if (grade != null && (grade.isPublished || _isTeacher())) {
          grades.add(grade);
        }
      }
      
      // Sort by course name and then by graded date (newest first)
      grades.sort((a, b) {
        final courseComparison = a.courseName.compareTo(b.courseName);
        if (courseComparison != 0) {
          return courseComparison;
        }
        return b.gradedDate.compareTo(a.gradedDate);
      });
      
      return grades;
    } catch (e) {
      debugPrint('Error getting grades for student: $e');
      return [];
    }
  }
  
  // Get grades for a course
  Future<List<GradeModel>> getGradesForCourse(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get course's grade IDs
      final gradeIds = prefs.getStringList('course_grades_$courseId') ?? [];
      
      // Get grades
      final grades = <GradeModel>[];
      for (final id in gradeIds) {
        final grade = await getGradeById(id);
        if (grade != null) {
          grades.add(grade);
        }
      }
      
      // Sort by student name and then by graded date (newest first)
      grades.sort((a, b) {
        final studentComparison = a.studentName.compareTo(b.studentName);
        if (studentComparison != 0) {
          return studentComparison;
        }
        return b.gradedDate.compareTo(a.gradedDate);
      });
      
      return grades;
    } catch (e) {
      debugPrint('Error getting grades for course: $e');
      return [];
    }
  }
  
  // Get grades for a teacher
  Future<List<GradeModel>> getGradesForTeacher(String teacherId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all keys that start with 'grade_'
      final allKeys = prefs.getKeys();
      final gradeKeys = allKeys.where((key) => key.startsWith('grade_')).toList();
      
      // Get grades
      final grades = <GradeModel>[];
      for (final key in gradeKeys) {
        final gradeId = key.substring('grade_'.length);
        final grade = await getGradeById(gradeId);
        if (grade != null && grade.teacherId == teacherId) {
          grades.add(grade);
        }
      }
      
      // Sort by course name, then by student name, then by graded date (newest first)
      grades.sort((a, b) {
        final courseComparison = a.courseName.compareTo(b.courseName);
        if (courseComparison != 0) {
          return courseComparison;
        }
        
        final studentComparison = a.studentName.compareTo(b.studentName);
        if (studentComparison != 0) {
          return studentComparison;
        }
        
        return b.gradedDate.compareTo(a.gradedDate);
      });
      
      return grades;
    } catch (e) {
      debugPrint('Error getting grades for teacher: $e');
      return [];
    }
  }
  
  // Get student's grades by term
  Future<Map<String, List<GradeModel>>> getStudentGradesByTerm(String studentId) async {
    try {
      // Get all grades for the student
      final allGrades = await getGradesForStudent(studentId);
      
      // Group grades by term
      final gradesByTerm = <String, List<GradeModel>>{};
      for (final grade in allGrades) {
        if (!gradesByTerm.containsKey(grade.term)) {
          gradesByTerm[grade.term] = [];
        }
        gradesByTerm[grade.term]!.add(grade);
      }
      
      return gradesByTerm;
    } catch (e) {
      debugPrint('Error getting student grades by term: $e');
      return {};
    }
  }
  
  // Get student's GPA
  Future<double> getStudentGPA(String studentId, {String? term}) async {
    try {
      // Get all grades for the student
      final allGrades = await getGradesForStudent(studentId);
      
      // Filter grades by term if specified
      final grades = term != null
          ? allGrades.where((grade) => grade.term == term).toList()
          : allGrades;
      
      if (grades.isEmpty) {
        return 0.0;
      }
      
      // Calculate weighted GPA
      double totalWeightedPoints = 0.0;
      double totalWeightage = 0.0;
      
      for (final grade in grades) {
        final gradePoints = _getGradePoints(grade.letterGrade);
        totalWeightedPoints += gradePoints * grade.weightage;
        totalWeightage += grade.weightage;
      }
      
      if (totalWeightage == 0.0) {
        return 0.0;
      }
      
      return totalWeightedPoints / totalWeightage;
    } catch (e) {
      debugPrint('Error calculating student GPA: $e');
      return 0.0;
    }
  }
  
  // Generate sample grades for demo purposes
  Future<void> generateSampleGrades() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Check if sample grades already exist
      final hasSampleGrades = prefs.getBool('has_sample_grades') ?? false;
      if (hasSampleGrades) {
        return;
      }
      
      // Sample courses
      final courses = [
        {'id': 'course1', 'name': 'Mathematics'},
        {'id': 'course2', 'name': 'Physics'},
        {'id': 'course3', 'name': 'English'},
        {'id': 'course4', 'name': 'Pakistan Studies'},
        {'id': 'course5', 'name': 'Computer Science'},
        {'id': 'course6', 'name': 'Urdu'},
        {'id': 'course7', 'name': 'Islamic Studies'},
      ];
      
      // Sample assessment types
      final assessmentTypes = [
        {'type': 'Quiz', 'weightage': 0.1},
        {'type': 'Assignment', 'weightage': 0.2},
        {'type': 'Project', 'weightage': 0.3},
        {'type': 'Midterm Exam', 'weightage': 0.4},
        {'type': 'Final Exam', 'weightage': 0.5},
      ];
      
      // Sample terms
      final terms = ['Term 1', 'Term 2', 'Term 3'];
      
      // Generate sample grades
      for (final course in courses) {
        for (final term in terms) {
          for (final assessment in assessmentTypes) {
            final score = 60.0 + (40.0 * (DateTime.now().millisecondsSinceEpoch % 100) / 100);
            
            await saveGrade(
              studentId: currentUser.id,
              studentName: 'Fatima Sheikh',
              courseId: course['id'] as String,
              courseName: course['name'] as String,
              teacherId: 'teacher1',
              teacherName: 'Prof. Dr. Ayesha Rahman',
              academicYear: '2025-2026',
              term: term,
              score: score,
              maxScore: 100.0,
              assessmentType: assessment['type'] as String,
              weightage: assessment['weightage'] as double,
              comments: 'Excellent work! Keep it up.',
              isPublished: true,
            );
          }
        }
      }
      
      // Mark that sample grades have been generated
      await prefs.setBool('has_sample_grades', true);
    } catch (e) {
      debugPrint('Error generating sample grades: $e');
    }
  }
  
  // Helper method to calculate letter grade from score
  String _calculateLetterGrade(double score) {
    if (score >= 90) {
      return 'A';
    } else if (score >= 80) {
      return 'B';
    } else if (score >= 70) {
      return 'C';
    } else if (score >= 60) {
      return 'D';
    } else {
      return 'F';
    }
  }
  
  // Helper method to get grade points from letter grade
  double _getGradePoints(String letterGrade) {
    switch (letterGrade) {
      case 'A':
        return 4.0;
      case 'B':
        return 3.0;
      case 'C':
        return 2.0;
      case 'D':
        return 1.0;
      case 'F':
        return 0.0;
      default:
        return 0.0;
    }
  }
  
  // Helper method to check if current user is a teacher
  bool _isTeacher() {
    // In a real app, this would check the user's role
    // For demo purposes, we'll return true
    return true;
  }
}
