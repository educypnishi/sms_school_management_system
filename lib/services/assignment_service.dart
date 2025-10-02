import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/assignment_model.dart';
// import '../services/notification_service.dart';

class AssignmentService {
  // Create a new assignment
  Future<AssignmentModel> createAssignment({
    required String title,
    required String description,
    required String className,
    required String subject,
    required String teacherId,
    required String teacherName,
    required DateTime dueDate,
    required TimeOfDay dueTime,
    required int maxMarks,
    bool allowLateSubmission = true,
    List<String>? attachments,
    List<Map<String, dynamic>>? rubricCriteria,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generate assignment ID
      final assignmentId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Combine due date and time
      final dueDateTime = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        dueTime.hour,
        dueTime.minute,
      );
      
      // Create assignment model
      final assignment = AssignmentModel(
        id: assignmentId,
        title: title,
        description: description,
        className: className,
        subject: subject,
        teacherId: teacherId,
        teacherName: teacherName,
        dueDate: dueDateTime,
        maxMarks: maxMarks,
        allowLateSubmission: allowLateSubmission,
        attachments: attachments ?? [],
        rubricCriteria: rubricCriteria ?? [],
        createdAt: DateTime.now(),
        status: AssignmentStatus.active,
      );
      
      // Save to local storage
      await _saveAssignment(assignment);
      
      // Create notification for students in the class
      // await _createAssignmentNotification(assignment);
      
      debugPrint('Assignment created successfully: $title');
      return assignment;
      
    } catch (e) {
      debugPrint('Error creating assignment: $e');
      rethrow;
    }
  }

  // Save assignment to local storage
  Future<void> _saveAssignment(AssignmentModel assignment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final assignmentsJson = prefs.getStringList('assignments') ?? [];
      
      // Add new assignment
      assignmentsJson.add(assignment.toJsonString());
      
      // Save back to preferences
      await prefs.setStringList('assignments', assignmentsJson);
      
    } catch (e) {
      debugPrint('Error saving assignment: $e');
    }
  }

  // Get all assignments
  Future<List<AssignmentModel>> getAllAssignments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final assignmentsJson = prefs.getStringList('assignments') ?? [];
      
      return assignmentsJson
          .map((json) => AssignmentModel.fromJsonString(json))
          .toList();
    } catch (e) {
      debugPrint('Error loading assignments: $e');
      return [];
    }
  }
  
  // Create notification for assignment
  Future<void> _createAssignmentNotification(AssignmentModel assignment) async {
    try {
      final notificationService = NotificationService();
      
      // In a real app, you would get the list of students in the class
      // For demo purposes, we'll create a notification for the current user
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId != null) {
        await notificationService.createAssignmentNotification(
          userId: userId,
          assignmentTitle: assignment.title,
          subject: assignment.subject,
          dueDate: assignment.dueDate,
          assignmentId: assignment.id,
        );
        
        debugPrint('Assignment notification created for user: $userId');
      }
    } catch (e) {
      debugPrint('Error creating assignment notification: $e');
      // Don't rethrow - notification failure shouldn't break assignment creation
    }
  }

  // Get assignments by class
  Future<List<AssignmentModel>> getAssignmentsByClass(String className) async {
    try {
      final allAssignments = await getAllAssignments();
      return allAssignments
          .where((assignment) => assignment.className == className)
          .toList();
    } catch (e) {
      debugPrint('Error getting assignments by class: $e');
      return [];
    }
  }

  // Get assignments by teacher
  Future<List<AssignmentModel>> getAssignmentsByTeacher(String teacherId) async {
    try {
      final allAssignments = await getAllAssignments();
      return allAssignments
          .where((assignment) => assignment.teacherId == teacherId)
          .toList();
    } catch (e) {
      debugPrint('Error getting assignments by teacher: $e');
      return [];
    }
  }

  // Submit assignment
  Future<AssignmentSubmissionModel> submitAssignment({
    required String assignmentId,
    required String studentId,
    required String studentName,
    String? submissionText,
    List<String>? attachments,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generate submission ID
      final submissionId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Get assignment details
      final assignment = await getAssignmentById(assignmentId);
      if (assignment == null) {
        throw Exception('Assignment not found');
      }
      
      // Check if submission is late
      final now = DateTime.now();
      final isLate = now.isAfter(assignment.dueDate);
      
      // Check if late submission is allowed
      if (isLate && !assignment.allowLateSubmission) {
        throw Exception('Late submission not allowed for this assignment');
      }
      
      // Create submission model
      final submission = AssignmentSubmissionModel(
        id: submissionId,
        assignmentId: assignmentId,
        studentId: studentId,
        studentName: studentName,
        submissionText: submissionText ?? '',
        attachments: attachments ?? [],
        submittedAt: now,
        isLate: isLate,
        status: SubmissionStatus.submitted,
      );
      
      // Save submission
      await _saveSubmission(submission);
      
      debugPrint('Assignment submitted successfully by $studentName');
      return submission;
      
    } catch (e) {
      debugPrint('Error submitting assignment: $e');
      rethrow;
    }
  }

  // Save submission to local storage
  Future<void> _saveSubmission(AssignmentSubmissionModel submission) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final submissionsJson = prefs.getStringList('assignment_submissions') ?? [];
      
      // Add new submission
      submissionsJson.add(submission.toJsonString());
      
      // Save back to preferences
      await prefs.setStringList('assignment_submissions', submissionsJson);
      
    } catch (e) {
      debugPrint('Error saving submission: $e');
    }
  }

  // Get assignment by ID
  Future<AssignmentModel?> getAssignmentById(String assignmentId) async {
    try {
      final allAssignments = await getAllAssignments();
      return allAssignments
          .where((assignment) => assignment.id == assignmentId)
          .firstOrNull;
    } catch (e) {
      debugPrint('Error getting assignment by ID: $e');
      return null;
    }
  }

  // Get submissions for an assignment
  Future<List<AssignmentSubmissionModel>> getSubmissionsForAssignment(String assignmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final submissionsJson = prefs.getStringList('assignment_submissions') ?? [];
      
      return submissionsJson
          .map((json) => AssignmentSubmissionModel.fromJsonString(json))
          .where((submission) => submission.assignmentId == assignmentId)
          .toList();
    } catch (e) {
      debugPrint('Error getting submissions for assignment: $e');
      return [];
    }
  }

  // Get submissions by student
  Future<List<AssignmentSubmissionModel>> getSubmissionsByStudent(String studentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final submissionsJson = prefs.getStringList('assignment_submissions') ?? [];
      
      return submissionsJson
          .map((json) => AssignmentSubmissionModel.fromJsonString(json))
          .where((submission) => submission.studentId == studentId)
          .toList();
    } catch (e) {
      debugPrint('Error getting submissions by student: $e');
      return [];
    }
  }

  // Grade assignment submission
  Future<void> gradeSubmission({
    required String submissionId,
    required double marks,
    required String feedback,
    String? teacherId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final submissionsJson = prefs.getStringList('assignment_submissions') ?? [];
      
      // Find and update the submission
      for (int i = 0; i < submissionsJson.length; i++) {
        final submission = AssignmentSubmissionModel.fromJsonString(submissionsJson[i]);
        
        if (submission.id == submissionId) {
          final updatedSubmission = submission.copyWith(
            marks: marks,
            feedback: feedback,
            gradedAt: DateTime.now(),
            gradedBy: teacherId,
            status: SubmissionStatus.graded,
          );
          
          submissionsJson[i] = updatedSubmission.toJsonString();
          break;
        }
      }
      
      // Save back to preferences
      await prefs.setStringList('assignment_submissions', submissionsJson);
      
      debugPrint('Assignment submission graded successfully');
      
    } catch (e) {
      debugPrint('Error grading submission: $e');
      rethrow;
    }
  }

  // Update assignment
  Future<void> updateAssignment(AssignmentModel assignment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final assignmentsJson = prefs.getStringList('assignments') ?? [];
      
      // Find and update the assignment
      for (int i = 0; i < assignmentsJson.length; i++) {
        final existingAssignment = AssignmentModel.fromJsonString(assignmentsJson[i]);
        
        if (existingAssignment.id == assignment.id) {
          assignmentsJson[i] = assignment.toJsonString();
          break;
        }
      }
      
      // Save back to preferences
      await prefs.setStringList('assignments', assignmentsJson);
      
      debugPrint('Assignment updated successfully');
      
    } catch (e) {
      debugPrint('Error updating assignment: $e');
      rethrow;
    }
  }

  // Delete assignment
  Future<void> deleteAssignment(String assignmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final assignmentsJson = prefs.getStringList('assignments') ?? [];
      
      // Remove the assignment
      assignmentsJson.removeWhere((json) {
        final assignment = AssignmentModel.fromJsonString(json);
        return assignment.id == assignmentId;
      });
      
      // Save back to preferences
      await prefs.setStringList('assignments', assignmentsJson);
      
      // Also remove related submissions
      final submissionsJson = prefs.getStringList('assignment_submissions') ?? [];
      submissionsJson.removeWhere((json) {
        final submission = AssignmentSubmissionModel.fromJsonString(json);
        return submission.assignmentId == assignmentId;
      });
      
      await prefs.setStringList('assignment_submissions', submissionsJson);
      
      debugPrint('Assignment deleted successfully');
      
    } catch (e) {
      debugPrint('Error deleting assignment: $e');
      rethrow;
    }
  }

  // Get assignment statistics
  Future<Map<String, dynamic>> getAssignmentStatistics(String assignmentId) async {
    try {
      final submissions = await getSubmissionsForAssignment(assignmentId);
      final assignment = await getAssignmentById(assignmentId);
      
      if (assignment == null) {
        return {};
      }
      
      final totalSubmissions = submissions.length;
      final gradedSubmissions = submissions.where((s) => s.status == SubmissionStatus.graded).length;
      final lateSubmissions = submissions.where((s) => s.isLate).length;
      final pendingSubmissions = submissions.where((s) => s.status == SubmissionStatus.submitted).length;
      
      double averageMarks = 0.0;
      if (gradedSubmissions > 0) {
        final totalMarks = submissions
            .where((s) => s.marks != null)
            .fold(0.0, (sum, s) => sum + s.marks!);
        averageMarks = totalMarks / gradedSubmissions;
      }
      
      return {
        'assignmentTitle': assignment.title,
        'totalSubmissions': totalSubmissions,
        'gradedSubmissions': gradedSubmissions,
        'pendingSubmissions': pendingSubmissions,
        'lateSubmissions': lateSubmissions,
        'averageMarks': averageMarks,
        'maxMarks': assignment.maxMarks,
        'dueDate': assignment.dueDate,
        'isOverdue': DateTime.now().isAfter(assignment.dueDate),
      };
      
    } catch (e) {
      debugPrint('Error getting assignment statistics: $e');
      return {};
    }
  }

  // Generate sample assignments for testing
  Future<void> generateSampleAssignments() async {
    try {
      final existingAssignments = await getAllAssignments();
      if (existingAssignments.isNotEmpty) return; // Don't generate if already exist
      
      final sampleAssignments = [
        {
          'title': 'Quadratic Equations Practice',
          'description': 'Solve the given quadratic equations using different methods. Show all working steps.',
          'className': 'Class 9-A',
          'subject': 'Mathematics',
          'teacherId': 'teacher1',
          'teacherName': 'Dr. Ahmad Hassan',
          'dueDate': DateTime.now().add(const Duration(days: 7)),
          'maxMarks': 50,
        },
        {
          'title': 'Physics Lab Report - Pendulum Experiment',
          'description': 'Write a detailed lab report on the simple pendulum experiment conducted in class.',
          'className': 'Class 9-A',
          'subject': 'Physics',
          'teacherId': 'teacher2',
          'teacherName': 'Prof. Zara Ahmed',
          'dueDate': DateTime.now().add(const Duration(days: 5)),
          'maxMarks': 75,
        },
        {
          'title': 'Essay: Environmental Conservation',
          'description': 'Write a 500-word essay on the importance of environmental conservation in Pakistan.',
          'className': 'Class 9-B',
          'subject': 'English',
          'teacherId': 'teacher3',
          'teacherName': 'Ms. Rabia Iqbal',
          'dueDate': DateTime.now().add(const Duration(days: 10)),
          'maxMarks': 100,
        },
      ];
      
      for (final assignmentData in sampleAssignments) {
        await createAssignment(
          title: assignmentData['title'] as String,
          description: assignmentData['description'] as String,
          className: assignmentData['className'] as String,
          subject: assignmentData['subject'] as String,
          teacherId: assignmentData['teacherId'] as String,
          teacherName: assignmentData['teacherName'] as String,
          dueDate: assignmentData['dueDate'] as DateTime,
          dueTime: const TimeOfDay(hour: 23, minute: 59),
          maxMarks: assignmentData['maxMarks'] as int,
          allowLateSubmission: true,
        );
      }
      
      debugPrint('Sample assignments generated successfully');
      
    } catch (e) {
      debugPrint('Error generating sample assignments: $e');
    }
  }
}
