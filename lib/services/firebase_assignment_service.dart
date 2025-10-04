import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/assignment_model.dart';
import 'firebase_auth_service.dart';

class FirebaseAssignmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create assignment
  static Future<String> createAssignment({
    required String title,
    required String description,
    required String classId,
    required String className,
    required String subject,
    required DateTime dueDate,
    required int maxMarks,
    bool allowLateSubmission = true,
    List<String>? attachmentUrls,
    List<Map<String, dynamic>>? rubricCriteria,
    String? instructions,
  }) async {
    try {
      final teacherId = FirebaseAuthService.currentUserId;
      if (teacherId == null) throw Exception('Teacher not authenticated');

      // Get teacher info
      final teacherDoc = await _firestore.collection('users').doc(teacherId).get();
      final teacherName = teacherDoc.data()?['fullName'] ?? 'Unknown Teacher';

      final assignmentData = {
        'title': title,
        'description': description,
        'classId': classId,
        'className': className,
        'subject': subject,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'dueDate': Timestamp.fromDate(dueDate),
        'maxMarks': maxMarks,
        'allowLateSubmission': allowLateSubmission,
        'attachmentUrls': attachmentUrls ?? [],
        'rubricCriteria': rubricCriteria ?? [],
        'instructions': instructions ?? '',
        'status': 'active',
        'totalSubmissions': 0,
        'gradedSubmissions': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('assignments').add(assignmentData);
      
      // Create notifications for students in the class
      await _createAssignmentNotifications(docRef.id, classId, title, teacherName);
      
      debugPrint('✅ Assignment created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating assignment: $e');
      rethrow;
    }
  }

  // Get assignments for a class
  static Future<List<AssignmentModel>> getClassAssignments(String classId) async {
    try {
      final querySnapshot = await _firestore
          .collection('assignments')
          .where('classId', isEqualTo: classId)
          .where('status', isEqualTo: 'active')
          .orderBy('dueDate', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return AssignmentModel(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          className: data['className'] ?? '',
          subject: data['subject'] ?? '',
          teacherId: data['teacherId'] ?? '',
          teacherName: data['teacherName'] ?? '',
          dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          maxMarks: data['maxMarks'] ?? 0,
          allowLateSubmission: data['allowLateSubmission'] ?? false,
          attachments: List<String>.from(data['attachmentUrls'] ?? []),
          rubricCriteria: List<Map<String, dynamic>>.from(data['rubricCriteria'] ?? []),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: _parseAssignmentStatus(data['status']),
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting class assignments: $e');
      return [];
    }
  }

  // Get assignments for a student
  static Future<List<AssignmentModel>> getStudentAssignments(String studentId) async {
    try {
      // First get student's class
      final userDoc = await _firestore.collection('users').doc(studentId).get();
      final classId = userDoc.data()?['class'];
      
      if (classId == null) return [];

      final querySnapshot = await _firestore
          .collection('assignments')
          .where('classId', isEqualTo: classId)
          .where('status', isEqualTo: 'active')
          .orderBy('dueDate', descending: false)
          .get();

      List<AssignmentModel> assignments = [];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        
        // Check if student has submitted
        final submissionDoc = await _firestore
            .collection('assignments')
            .doc(doc.id)
            .collection('submissions')
            .doc(studentId)
            .get();

        final assignment = AssignmentModel(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          className: data['className'] ?? '',
          subject: data['subject'] ?? '',
          teacherId: data['teacherId'] ?? '',
          teacherName: data['teacherName'] ?? '',
          dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          maxMarks: data['maxMarks'] ?? 0,
          allowLateSubmission: data['allowLateSubmission'] ?? false,
          attachments: List<String>.from(data['attachmentUrls'] ?? []),
          rubricCriteria: List<Map<String, dynamic>>.from(data['rubricCriteria'] ?? []),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: _parseAssignmentStatus(data['status']),
        );

        assignments.add(assignment);
      }

      return assignments;
    } catch (e) {
      debugPrint('❌ Error getting student assignments: $e');
      return [];
    }
  }

  // Submit assignment
  static Future<void> submitAssignment({
    required String assignmentId,
    required String studentId,
    required String submissionText,
    List<String>? attachmentUrls,
  }) async {
    try {
      // Get student info
      final userDoc = await _firestore.collection('users').doc(studentId).get();
      final studentName = userDoc.data()?['fullName'] ?? 'Unknown Student';

      final submissionData = {
        'studentId': studentId,
        'studentName': studentName,
        'submissionText': submissionText,
        'attachmentUrls': attachmentUrls ?? [],
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
        'grade': null,
        'feedback': '',
        'gradedAt': null,
        'isLate': false, // Will be calculated
      };

      // Check if submission is late
      final assignmentDoc = await _firestore.collection('assignments').doc(assignmentId).get();
      final dueDate = (assignmentDoc.data()?['dueDate'] as Timestamp?)?.toDate();
      if (dueDate != null && DateTime.now().isAfter(dueDate)) {
        submissionData['isLate'] = true;
      }

      // Save submission
      await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .collection('submissions')
          .doc(studentId)
          .set(submissionData);

      // Update assignment submission count
      await _firestore.collection('assignments').doc(assignmentId).update({
        'totalSubmissions': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Assignment submitted successfully');
    } catch (e) {
      debugPrint('❌ Error submitting assignment: $e');
      rethrow;
    }
  }

  // Grade assignment submission
  static Future<void> gradeSubmission({
    required String assignmentId,
    required String studentId,
    required double grade,
    required double maxGrade,
    String? feedback,
  }) async {
    try {
      final gradeData = {
        'grade': grade,
        'maxGrade': maxGrade,
        'percentage': (grade / maxGrade) * 100,
        'feedback': feedback ?? '',
        'gradedAt': FieldValue.serverTimestamp(),
        'status': 'graded',
      };

      await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .collection('submissions')
          .doc(studentId)
          .update(gradeData);

      // Update assignment graded count
      await _firestore.collection('assignments').doc(assignmentId).update({
        'gradedSubmissions': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Assignment graded successfully');
    } catch (e) {
      debugPrint('❌ Error grading assignment: $e');
      rethrow;
    }
  }

  // Get assignment submissions for teacher
  static Future<List<Map<String, dynamic>>> getAssignmentSubmissions(String assignmentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .collection('submissions')
          .orderBy('submittedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting submissions: $e');
      return [];
    }
  }

  // Get student's submission for an assignment
  static Future<Map<String, dynamic>?> getStudentSubmission({
    required String assignmentId,
    required String studentId,
  }) async {
    try {
      final doc = await _firestore
          .collection('assignments')
          .doc(assignmentId)
          .collection('submissions')
          .doc(studentId)
          .get();

      if (!doc.exists) return null;

      return {
        'id': doc.id,
        ...doc.data()!,
      };
    } catch (e) {
      debugPrint('❌ Error getting student submission: $e');
      return null;
    }
  }

  // Update assignment
  static Future<void> updateAssignment({
    required String assignmentId,
    String? title,
    String? description,
    DateTime? dueDate,
    int? maxMarks,
    bool? allowLateSubmission,
    String? instructions,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (dueDate != null) updateData['dueDate'] = Timestamp.fromDate(dueDate);
      if (maxMarks != null) updateData['maxMarks'] = maxMarks;
      if (allowLateSubmission != null) updateData['allowLateSubmission'] = allowLateSubmission;
      if (instructions != null) updateData['instructions'] = instructions;

      await _firestore.collection('assignments').doc(assignmentId).update(updateData);
      debugPrint('✅ Assignment updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating assignment: $e');
      rethrow;
    }
  }

  // Delete assignment
  static Future<void> deleteAssignment(String assignmentId) async {
    try {
      await _firestore.collection('assignments').doc(assignmentId).update({
        'status': 'deleted',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Assignment deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting assignment: $e');
      rethrow;
    }
  }

  // Helper method to create notifications
  static Future<void> _createAssignmentNotifications(
    String assignmentId,
    String classId,
    String title,
    String teacherName,
  ) async {
    try {
      // Get all students in the class
      final studentsSnapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .where('isActive', isEqualTo: true)
          .get();

      // Create notification for each student
      for (final studentDoc in studentsSnapshot.docs) {
        final studentId = studentDoc.data()['studentId'];
        
        await _firestore.collection('notifications').add({
          'title': 'New Assignment: $title',
          'message': 'You have a new assignment from $teacherName. Check the details and submit before the due date.',
          'type': 'assignment',
          'recipientIds': [studentId],
          'actionUrl': '/assignments/$assignmentId',
          'metadata': {
            'assignmentId': assignmentId,
            'classId': classId,
          },
          'isRead': false,
          'sentAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('❌ Error creating notifications: $e');
    }
  }

  // Helper method to parse assignment status
  static AssignmentStatus _parseAssignmentStatus(String? status) {
    switch (status) {
      case 'active':
        return AssignmentStatus.active;
      case 'completed':
        return AssignmentStatus.completed;
      case 'cancelled':
        return AssignmentStatus.cancelled;
      default:
        return AssignmentStatus.active;
    }
  }

  // Stream assignments for real-time updates
  static Stream<List<AssignmentModel>> streamClassAssignments(String classId) {
    return _firestore
        .collection('assignments')
        .where('classId', isEqualTo: classId)
        .where('status', isEqualTo: 'active')
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AssignmentModel(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          className: data['className'] ?? '',
          subject: data['subject'] ?? '',
          teacherId: data['teacherId'] ?? '',
          teacherName: data['teacherName'] ?? '',
          dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          maxMarks: data['maxMarks'] ?? 0,
          allowLateSubmission: data['allowLateSubmission'] ?? false,
          attachments: List<String>.from(data['attachmentUrls'] ?? []),
          rubricCriteria: List<Map<String, dynamic>>.from(data['rubricCriteria'] ?? []),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: _parseAssignmentStatus(data['status']),
        );
      }).toList();
    });
  }
}
