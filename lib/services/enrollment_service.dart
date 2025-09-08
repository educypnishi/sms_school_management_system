import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/enrollment_model.dart';
import '../models/feedback_model.dart';
import '../services/auth_service.dart';

class EnrollmentService {
  // Enrollment status constants
  static const String statusDraft = 'draft';
  static const String statusSubmitted = 'submitted';
  static const String statusInReview = 'in_review';
  static const String statusAccepted = 'accepted';
  static const String statusRejected = 'rejected';
  
  // Feedback prefix for SharedPreferences keys
  static const String _feedbackPrefix = 'feedback_';
  
  // Save enrollment as draft with all fields
  Future<EnrollmentModel> saveDraft({
    String? id,
    required String name,
    required String email,
    required String phone,
    DateTime? dateOfBirth,
    String? nationality,
    String? idNumber,
    String? currentAddress,
    String? gender,
    String? previousSchool,
    String? previousGrade,
    String? previousPerformance,
    double? gpa,
    int? yearOfCompletion,
    List<String>? certificates,
    String? desiredClass,
    String? desiredGrade,
    String? academicYear,
    String? preferredStartDate,
    bool? needsTransportation,
    String? paymentMethod,
    bool? hasScholarship,
    double? scholarshipAmount,
    String? guardianName,
    String? guardianRelationship,
    String? idCardUrl,
    String? photoUrl,
    String? previousReportCardsUrl,
    String? certificatesUrl,
    String? medicalRecordsUrl,
    String? parentConsentFormUrl,
    String? otherDocumentsUrl,
    int? currentStep,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Generate a new ID if not provided
      final enrollmentId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      // Get existing enrollment if it exists
      EnrollmentModel? existingEnrollment;
      final existingJson = prefs.getString('enrollment_$enrollmentId');
      if (existingJson != null) {
        final existingMap = jsonDecode(existingJson) as Map<String, dynamic>;
        existingEnrollment = EnrollmentModel.fromMap(existingMap, enrollmentId);
      }
      
      // Create or update enrollment model
      final enrollment = EnrollmentModel(
        id: enrollmentId,
        studentId: currentUser.id,
        name: name,
        email: email,
        phone: phone,
        dateOfBirth: dateOfBirth ?? existingEnrollment?.dateOfBirth,
        nationality: nationality ?? existingEnrollment?.nationality,
        idNumber: idNumber ?? existingEnrollment?.idNumber,
        currentAddress: currentAddress ?? existingEnrollment?.currentAddress,
        gender: gender ?? existingEnrollment?.gender,
        previousSchool: previousSchool ?? existingEnrollment?.previousSchool,
        previousGrade: previousGrade ?? existingEnrollment?.previousGrade,
        previousPerformance: previousPerformance ?? existingEnrollment?.previousPerformance,
        gpa: gpa ?? existingEnrollment?.gpa,
        yearOfCompletion: yearOfCompletion ?? existingEnrollment?.yearOfCompletion,
        certificates: certificates ?? existingEnrollment?.certificates,
        desiredClass: desiredClass ?? existingEnrollment?.desiredClass,
        desiredGrade: desiredGrade ?? existingEnrollment?.desiredGrade,
        academicYear: academicYear ?? existingEnrollment?.academicYear,
        preferredStartDate: preferredStartDate ?? existingEnrollment?.preferredStartDate,
        needsTransportation: needsTransportation ?? existingEnrollment?.needsTransportation,
        paymentMethod: paymentMethod ?? existingEnrollment?.paymentMethod,
        hasScholarship: hasScholarship ?? existingEnrollment?.hasScholarship,
        scholarshipAmount: scholarshipAmount ?? existingEnrollment?.scholarshipAmount,
        guardianName: guardianName ?? existingEnrollment?.guardianName,
        guardianRelationship: guardianRelationship ?? existingEnrollment?.guardianRelationship,
        idCardUrl: idCardUrl ?? existingEnrollment?.idCardUrl,
        photoUrl: photoUrl ?? existingEnrollment?.photoUrl,
        previousReportCardsUrl: previousReportCardsUrl ?? existingEnrollment?.previousReportCardsUrl,
        certificatesUrl: certificatesUrl ?? existingEnrollment?.certificatesUrl,
        medicalRecordsUrl: medicalRecordsUrl ?? existingEnrollment?.medicalRecordsUrl,
        parentConsentFormUrl: parentConsentFormUrl ?? existingEnrollment?.parentConsentFormUrl,
        otherDocumentsUrl: otherDocumentsUrl ?? existingEnrollment?.otherDocumentsUrl,
        status: 'draft',
        createdAt: existingEnrollment?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        currentStep: currentStep ?? existingEnrollment?.currentStep,
      );
      
      // Save enrollment to SharedPreferences
      await prefs.setString('enrollment_$enrollmentId', jsonEncode(enrollment.toMap()));
      
      // Save enrollment ID to user's enrollments list
      final enrollments = prefs.getStringList('user_enrollments_${currentUser.id}') ?? [];
      if (!enrollments.contains(enrollmentId)) {
        enrollments.add(enrollmentId);
        await prefs.setStringList('user_enrollments_${currentUser.id}', enrollments);
      }
      
      return enrollment;
    } catch (e) {
      debugPrint('Error saving enrollment draft: $e');
      rethrow;
    }
  }
  
  // Submit enrollment
  Future<EnrollmentModel> submitEnrollment(String enrollmentId) async {
    return updateEnrollmentStatus(enrollmentId, statusSubmitted);
  }
  
  // Update enrollment status (admin function)
  Future<EnrollmentModel> updateEnrollmentStatus(String enrollmentId, String newStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Get enrollment from SharedPreferences
      final enrollmentJson = prefs.getString('enrollment_$enrollmentId');
      if (enrollmentJson == null) {
        throw Exception('Enrollment not found');
      }
      
      // Parse enrollment
      final enrollmentMap = jsonDecode(enrollmentJson) as Map<String, dynamic>;
      final enrollment = EnrollmentModel.fromMap(enrollmentMap, enrollmentId);
      
      // Update enrollment status
      final updatedEnrollment = enrollment.copyWith(
        status: newStatus,
        submittedAt: newStatus == statusSubmitted ? DateTime.now() : enrollment.submittedAt,
        updatedAt: DateTime.now(),
      );
      
      // Save updated enrollment to SharedPreferences
      await prefs.setString('enrollment_$enrollmentId', jsonEncode(updatedEnrollment.toMap()));
      
      return updatedEnrollment;
    } catch (e) {
      debugPrint('Error updating enrollment status: $e');
      rethrow;
    }
  }
  
  // Get enrollment by ID
  Future<EnrollmentModel?> getEnrollmentById(String enrollmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get enrollment from SharedPreferences
      final enrollmentJson = prefs.getString('enrollment_$enrollmentId');
      if (enrollmentJson == null) {
        return null;
      }
      
      // Parse enrollment
      final enrollmentMap = jsonDecode(enrollmentJson) as Map<String, dynamic>;
      return EnrollmentModel.fromMap(enrollmentMap, enrollmentId);
    } catch (e) {
      debugPrint('Error getting enrollment: $e');
      return null;
    }
  }
  
  // Assign enrollment to teacher (admin function)
  Future<EnrollmentModel> assignEnrollmentToTeacher(
    String enrollmentId,
    String teacherId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get enrollment from SharedPreferences
      final enrollmentJson = prefs.getString('enrollment_$enrollmentId');
      if (enrollmentJson == null) {
        throw Exception('Enrollment not found');
      }
      
      // Parse enrollment
      final enrollmentMap = jsonDecode(enrollmentJson) as Map<String, dynamic>;
      final enrollment = EnrollmentModel.fromMap(enrollmentMap, enrollmentId);
      
      // Update enrollment with teacher assignment
      final updatedEnrollment = enrollment.copyWith(
        assignedTeacherId: teacherId,
        assignedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save updated enrollment to SharedPreferences
      await prefs.setString('enrollment_$enrollmentId', jsonEncode(updatedEnrollment.toMap()));
      
      return updatedEnrollment;
    } catch (e) {
      debugPrint('Error assigning enrollment to teacher: $e');
      rethrow;
    }
  }
  
  // Add feedback to enrollment (teacher function)
  Future<void> addEnrollmentFeedback(
    String enrollmentId,
    String feedbackText,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Generate a new feedback ID
      final feedbackId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create feedback model
      final feedback = FeedbackModel(
        id: feedbackId,
        applicationId: enrollmentId, // Reusing the same model for now
        partnerId: currentUser.id,
        text: feedbackText,
        date: DateTime.now().toString().substring(0, 16), // Format: YYYY-MM-DD HH:MM
      );
      
      // Save feedback to SharedPreferences
      await prefs.setString('${_feedbackPrefix}${enrollmentId}_$feedbackId', jsonEncode(feedback.toMap()));
      
      // Add feedback ID to enrollment's feedback list
      final feedbackIds = prefs.getStringList('${_feedbackPrefix}${enrollmentId}_list') ?? [];
      feedbackIds.add(feedbackId);
      await prefs.setStringList('${_feedbackPrefix}${enrollmentId}_list', feedbackIds);
    } catch (e) {
      debugPrint('Error adding feedback: $e');
      rethrow;
    }
  }
  
  // Get feedback for enrollment
  Future<List<FeedbackModel>> getEnrollmentFeedback(String enrollmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get feedback IDs for enrollment
      final feedbackIds = prefs.getStringList('${_feedbackPrefix}${enrollmentId}_list') ?? [];
      
      // Get feedback models
      final feedbackList = <FeedbackModel>[];
      for (final id in feedbackIds) {
        final feedbackJson = prefs.getString('${_feedbackPrefix}${enrollmentId}_$id');
        if (feedbackJson != null) {
          final feedbackMap = jsonDecode(feedbackJson) as Map<String, dynamic>;
          feedbackList.add(FeedbackModel.fromMap(feedbackMap, id));
        }
      }
      
      // Sort by date (newest first)
      feedbackList.sort((a, b) => b.date.compareTo(a.date));
      
      return feedbackList;
    } catch (e) {
      debugPrint('Error getting feedback: $e');
      return [];
    }
  }
  
  // Get enrollments assigned to teacher
  Future<List<EnrollmentModel>> getTeacherEnrollments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Get all enrollments
      final allEnrollments = await getAllEnrollments();
      
      // Filter by teacher ID
      return allEnrollments.where((enrollment) => 
        enrollment.assignedTeacherId == currentUser.id || enrollment.assignedTeacherId == null
      ).toList();
    } catch (e) {
      debugPrint('Error getting teacher enrollments: $e');
      return [];
    }
  }
  
  // Get all enrollments (admin function)
  Future<List<EnrollmentModel>> getAllEnrollments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all keys that start with 'enrollment_'
      final allKeys = prefs.getKeys();
      final enrollmentKeys = allKeys.where((key) => key.startsWith('enrollment_')).toList();
      
      // Get enrollments
      final enrollments = <EnrollmentModel>[];
      for (final key in enrollmentKeys) {
        final enrollmentId = key.substring('enrollment_'.length);
        final enrollment = await getEnrollmentById(enrollmentId);
        if (enrollment != null && enrollment.status != statusDraft) {
          enrollments.add(enrollment);
        }
      }
      
      // Sort by submission date (newest first)
      enrollments.sort((a, b) => 
        (b.submittedAt ?? DateTime.now()).compareTo(a.submittedAt ?? DateTime.now()));
      
      return enrollments;
    } catch (e) {
      debugPrint('Error getting all enrollments: $e');
      return [];
    }
  }
  
  // Get all enrollments for current user (student)
  Future<List<EnrollmentModel>> getStudentEnrollments() async {
    return getUserEnrollments();
  }
  
  // Get all enrollments for current user (alias for getStudentEnrollments)
  Future<List<EnrollmentModel>> getUserEnrollments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Get enrollment IDs from SharedPreferences
      final enrollmentIds = prefs.getStringList('user_enrollments_${currentUser.id}') ?? [];
      
      // Get enrollments
      final enrollments = <EnrollmentModel>[];
      for (final id in enrollmentIds) {
        final enrollment = await getEnrollmentById(id);
        if (enrollment != null) {
          enrollments.add(enrollment);
        }
      }
      
      return enrollments;
    } catch (e) {
      debugPrint('Error getting student enrollments: $e');
      return [];
    }
  }
  
  // Delete enrollment
  Future<void> deleteEnrollment(String enrollmentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Remove enrollment from SharedPreferences
      await prefs.remove('enrollment_$enrollmentId');
      
      // Remove enrollment ID from user's enrollments list
      final enrollments = prefs.getStringList('user_enrollments_${currentUser.id}') ?? [];
      enrollments.remove(enrollmentId);
      await prefs.setStringList('user_enrollments_${currentUser.id}', enrollments);
    } catch (e) {
      debugPrint('Error deleting enrollment: $e');
      rethrow;
    }
  }
}
