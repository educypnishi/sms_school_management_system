import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/application_model.dart';
import '../models/feedback_model.dart';
import '../services/auth_service.dart';

class ApplicationService {
  // Application status constants
  static const String statusDraft = 'draft';
  static const String statusSubmitted = 'submitted';
  static const String statusInReview = 'in_review';
  static const String statusAccepted = 'accepted';
  static const String statusRejected = 'rejected';
  
  // Feedback prefix for SharedPreferences keys
  static const String _feedbackPrefix = 'feedback_';
  // For Phase 3, we'll use SharedPreferences to store application data
  // In a real app, this would use Firestore
  
  // Save application as draft with all fields
  Future<ApplicationModel> saveDraft({
    String? id,
    required String name,
    required String email,
    required String phone,
    DateTime? dateOfBirth,
    String? nationality,
    String? passportNumber,
    DateTime? passportExpiryDate,
    String? currentAddress,
    String? gender,
    String? highestEducation,
    String? previousInstitution,
    String? fieldOfStudy,
    double? gpa,
    int? yearOfCompletion,
    List<String>? certificates,
    String? desiredProgram,
    String? desiredUniversity,
    String? studyLevel,
    String? preferredStartDate,
    bool? needsAccommodation,
    String? fundingSource,
    bool? hasFinancialDocuments,
    double? availableFunds,
    String? sponsorName,
    String? sponsorRelationship,
    String? passportScanUrl,
    String? photoUrl,
    String? transcriptsUrl,
    String? certificatesUrl,
    String? financialDocumentsUrl,
    String? motivationLetterUrl,
    String? recommendationLettersUrl,
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
      final applicationId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      // Get existing application if it exists
      ApplicationModel? existingApplication;
      final existingJson = prefs.getString('application_$applicationId');
      if (existingJson != null) {
        final existingMap = jsonDecode(existingJson) as Map<String, dynamic>;
        existingApplication = ApplicationModel.fromMap(existingMap, applicationId);
      }
      
      // Create or update application model
      final application = ApplicationModel(
        id: applicationId,
        userId: currentUser.id,
        name: name,
        email: email,
        phone: phone,
        dateOfBirth: dateOfBirth ?? existingApplication?.dateOfBirth,
        nationality: nationality ?? existingApplication?.nationality,
        passportNumber: passportNumber ?? existingApplication?.passportNumber,
        passportExpiryDate: passportExpiryDate ?? existingApplication?.passportExpiryDate,
        currentAddress: currentAddress ?? existingApplication?.currentAddress,
        gender: gender ?? existingApplication?.gender,
        highestEducation: highestEducation ?? existingApplication?.highestEducation,
        previousInstitution: previousInstitution ?? existingApplication?.previousInstitution,
        fieldOfStudy: fieldOfStudy ?? existingApplication?.fieldOfStudy,
        gpa: gpa ?? existingApplication?.gpa,
        yearOfCompletion: yearOfCompletion ?? existingApplication?.yearOfCompletion,
        certificates: certificates ?? existingApplication?.certificates,
        desiredProgram: desiredProgram ?? existingApplication?.desiredProgram,
        desiredUniversity: desiredUniversity ?? existingApplication?.desiredUniversity,
        studyLevel: studyLevel ?? existingApplication?.studyLevel,
        preferredStartDate: preferredStartDate ?? existingApplication?.preferredStartDate,
        needsAccommodation: needsAccommodation ?? existingApplication?.needsAccommodation,
        fundingSource: fundingSource ?? existingApplication?.fundingSource,
        hasFinancialDocuments: hasFinancialDocuments ?? existingApplication?.hasFinancialDocuments,
        availableFunds: availableFunds ?? existingApplication?.availableFunds,
        sponsorName: sponsorName ?? existingApplication?.sponsorName,
        sponsorRelationship: sponsorRelationship ?? existingApplication?.sponsorRelationship,
        passportScanUrl: passportScanUrl ?? existingApplication?.passportScanUrl,
        photoUrl: photoUrl ?? existingApplication?.photoUrl,
        transcriptsUrl: transcriptsUrl ?? existingApplication?.transcriptsUrl,
        certificatesUrl: certificatesUrl ?? existingApplication?.certificatesUrl,
        financialDocumentsUrl: financialDocumentsUrl ?? existingApplication?.financialDocumentsUrl,
        motivationLetterUrl: motivationLetterUrl ?? existingApplication?.motivationLetterUrl,
        recommendationLettersUrl: recommendationLettersUrl ?? existingApplication?.recommendationLettersUrl,
        status: 'draft',
        createdAt: existingApplication?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        currentStep: currentStep ?? existingApplication?.currentStep,
      );
      
      // Save application to SharedPreferences
      await prefs.setString('application_$applicationId', jsonEncode(application.toMap()));
      
      // Save application ID to user's applications list
      final applications = prefs.getStringList('user_applications_${currentUser.id}') ?? [];
      if (!applications.contains(applicationId)) {
        applications.add(applicationId);
        await prefs.setStringList('user_applications_${currentUser.id}', applications);
      }
      
      return application;
    } catch (e) {
      debugPrint('Error saving application draft: $e');
      rethrow;
    }
  }
  
  // Submit application
  Future<ApplicationModel> submitApplication(String applicationId) async {
    return updateApplicationStatus(applicationId, statusSubmitted);
  }
  
  // Update application status (admin function)
  Future<ApplicationModel> updateApplicationStatus(String applicationId, String newStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Get application from SharedPreferences
      final applicationJson = prefs.getString('application_$applicationId');
      if (applicationJson == null) {
        throw Exception('Application not found');
      }
      
      // Parse application
      final applicationMap = jsonDecode(applicationJson) as Map<String, dynamic>;
      final application = ApplicationModel.fromMap(applicationMap, applicationId);
      
      // Update application status
      final updatedApplication = application.copyWith(
        status: 'submitted',
        submittedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save updated application to SharedPreferences
      await prefs.setString('application_$applicationId', jsonEncode(updatedApplication.toMap()));
      
      return updatedApplication;
    } catch (e) {
      debugPrint('Error submitting application: $e');
      rethrow;
    }
  }
  
  // Get application by ID
  Future<ApplicationModel?> getApplicationById(String applicationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get application from SharedPreferences
      final applicationJson = prefs.getString('application_$applicationId');
      if (applicationJson == null) {
        return null;
      }
      
      // Parse application
      final applicationMap = jsonDecode(applicationJson) as Map<String, dynamic>;
      return ApplicationModel.fromMap(applicationMap, applicationId);
    } catch (e) {
      debugPrint('Error getting application: $e');
      return null;
    }
  }
  
  // Assign application to partner (admin function)
  Future<ApplicationModel> assignApplicationToPartner(
    String applicationId,
    String partnerId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get application from SharedPreferences
      final applicationJson = prefs.getString('application_$applicationId');
      if (applicationJson == null) {
        throw Exception('Application not found');
      }
      
      // Parse application
      final applicationMap = jsonDecode(applicationJson) as Map<String, dynamic>;
      final application = ApplicationModel.fromMap(applicationMap, applicationId);
      
      // Update application with partner assignment
      final updatedApplication = application.copyWith(
        assignedPartnerId: partnerId,
        assignedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save updated application to SharedPreferences
      await prefs.setString('application_$applicationId', jsonEncode(updatedApplication.toMap()));
      
      return updatedApplication;
    } catch (e) {
      debugPrint('Error assigning application to partner: $e');
      rethrow;
    }
  }
  
  // Add feedback to application (partner function)
  Future<void> addApplicationFeedback(
    String applicationId,
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
        applicationId: applicationId,
        partnerId: currentUser.id,
        text: feedbackText,
        date: DateTime.now().toString().substring(0, 16), // Format: YYYY-MM-DD HH:MM
      );
      
      // Save feedback to SharedPreferences
      await prefs.setString('${_feedbackPrefix}${applicationId}_$feedbackId', jsonEncode(feedback.toMap()));
      
      // Add feedback ID to application's feedback list
      final feedbackIds = prefs.getStringList('${_feedbackPrefix}${applicationId}_list') ?? [];
      feedbackIds.add(feedbackId);
      await prefs.setStringList('${_feedbackPrefix}${applicationId}_list', feedbackIds);
    } catch (e) {
      debugPrint('Error adding feedback: $e');
      rethrow;
    }
  }
  
  // Get feedback for application
  Future<List<FeedbackModel>> getApplicationFeedback(String applicationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get feedback IDs for application
      final feedbackIds = prefs.getStringList('${_feedbackPrefix}${applicationId}_list') ?? [];
      
      // Get feedback models
      final feedbackList = <FeedbackModel>[];
      for (final id in feedbackIds) {
        final feedbackJson = prefs.getString('${_feedbackPrefix}${applicationId}_$id');
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
  
  // Get applications assigned to partner
  Future<List<ApplicationModel>> getPartnerApplications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // For Phase 5, we'll simulate assigned applications for partners
      // In a real app with Firebase, we would filter by the actual partner ID
      
      // Get all applications
      final allApplications = await getAllApplications();
      
      // For testing purposes, if the user email contains 'partner1', assign to partner1
      // If it contains 'partner2', assign to partner2, otherwise show all applications
      if (currentUser.email.contains('partner1')) {
        return allApplications.where((app) => 
          app.assignedPartnerId == 'partner1' || app.assignedPartnerId == null
        ).toList();
      } else if (currentUser.email.contains('partner2')) {
        return allApplications.where((app) => 
          app.assignedPartnerId == 'partner2' || app.assignedPartnerId == null
        ).toList();
      } else {
        // For any other partner email, show all applications
        return allApplications;
      }
    } catch (e) {
      debugPrint('Error getting partner applications: $e');
      return [];
    }
  }
  
  // Get all applications (admin function)
  Future<List<ApplicationModel>> getAllApplications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all keys that start with 'application_'
      final allKeys = prefs.getKeys();
      final applicationKeys = allKeys.where((key) => key.startsWith('application_')).toList();
      
      // Get applications
      final applications = <ApplicationModel>[];
      for (final key in applicationKeys) {
        final applicationId = key.substring('application_'.length);
        final application = await getApplicationById(applicationId);
        if (application != null && application.status != statusDraft) {
          applications.add(application);
        }
      }
      
      // Sort by submission date (newest first)
      applications.sort((a, b) => 
        (b.submittedAt ?? DateTime.now()).compareTo(a.submittedAt ?? DateTime.now()));
      
      return applications;
    } catch (e) {
      debugPrint('Error getting all applications: $e');
      return [];
    }
  }
  
  // Get all applications for current user
  Future<List<ApplicationModel>> getUserApplications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Get application IDs from SharedPreferences
      final applicationIds = prefs.getStringList('user_applications_${currentUser.id}') ?? [];
      
      // Get applications
      final applications = <ApplicationModel>[];
      for (final id in applicationIds) {
        final application = await getApplicationById(id);
        if (application != null) {
          applications.add(application);
        }
      }
      
      return applications;
    } catch (e) {
      debugPrint('Error getting user applications: $e');
      return [];
    }
  }
  
  // Delete application
  Future<void> deleteApplication(String applicationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Remove application from SharedPreferences
      await prefs.remove('application_$applicationId');
      
      // Remove application ID from user's applications list
      final applications = prefs.getStringList('user_applications_${currentUser.id}') ?? [];
      applications.remove(applicationId);
      await prefs.setStringList('user_applications_${currentUser.id}', applications);
    } catch (e) {
      debugPrint('Error deleting application: $e');
      rethrow;
    }
  }
}
