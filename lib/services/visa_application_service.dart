import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/visa_application_model.dart';

/// Service to manage visa applications in the system
class VisaApplicationService {
  // Shared Preferences keys
  static const String _visaApplicationsKey = 'visa_applications';
  
  // In-memory cache
  final Map<String, VisaApplicationModel> _visaApplications = {};
  
  /// Get all visa applications for a user
  Future<List<VisaApplicationModel>> getVisaApplicationsForUser(String userId) async {
    // Load visa applications if not already loaded
    if (_visaApplications.isEmpty) {
      await _loadVisaApplications();
    }
    
    // Filter by user ID
    return _visaApplications.values
        .where((application) => application.userId == userId)
        .toList();
  }
  
  /// Get a specific visa application by ID
  Future<VisaApplicationModel?> getVisaApplication(String id) async {
    // Load visa applications if not already loaded
    if (_visaApplications.isEmpty) {
      await _loadVisaApplications();
    }
    
    return _visaApplications[id];
  }
  
  /// Create a new visa application
  Future<VisaApplicationModel> createVisaApplication({
    required String userId,
    required String applicationId,
    required VisaType visaType,
    required String country,
    required String embassy,
  }) async {
    // Generate a unique ID
    final id = 'visa_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create default milestones
    final milestones = _createDefaultMilestones();
    
    // Create default documents
    final documents = _createDefaultDocuments(visaType);
    
    // Create the visa application
    final visaApplication = VisaApplicationModel(
      id: id,
      userId: userId,
      applicationId: applicationId,
      visaType: visaType,
      status: VisaApplicationStatus.notStarted,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      country: country,
      embassy: embassy,
      milestones: milestones,
      documents: documents,
      notes: [],
      appointments: [],
      completionPercentage: 0.0,
    );
    
    // Add to in-memory cache
    _visaApplications[id] = visaApplication;
    
    // Save to SharedPreferences
    await _saveVisaApplications();
    
    return visaApplication;
  }
  
  /// Update an existing visa application
  Future<VisaApplicationModel> updateVisaApplication(VisaApplicationModel visaApplication) async {
    // Update the timestamp
    final updatedVisaApplication = visaApplication.copyWith(
      updatedAt: DateTime.now(),
    );
    
    // Update in-memory cache
    _visaApplications[updatedVisaApplication.id] = updatedVisaApplication;
    
    // Save to SharedPreferences
    await _saveVisaApplications();
    
    return updatedVisaApplication;
  }
  
  /// Delete a visa application
  Future<bool> deleteVisaApplication(String id) async {
    // Remove from in-memory cache
    final removed = _visaApplications.remove(id);
    
    // Save to SharedPreferences
    await _saveVisaApplications();
    
    return removed != null;
  }
  
  /// Update the status of a visa application
  Future<VisaApplicationModel> updateVisaApplicationStatus(
    String id, 
    VisaApplicationStatus status,
  ) async {
    // Get the visa application
    final visaApplication = _visaApplications[id];
    if (visaApplication == null) {
      throw Exception('Visa application not found');
    }
    
    // Update the status and relevant timestamps
    VisaApplicationModel updatedVisaApplication;
    
    switch (status) {
      case VisaApplicationStatus.submitted:
        updatedVisaApplication = visaApplication.copyWith(
          status: status,
          submittedAt: DateTime.now(),
        );
        break;
      case VisaApplicationStatus.approved:
        updatedVisaApplication = visaApplication.copyWith(
          status: status,
          approvedAt: DateTime.now(),
        );
        break;
      case VisaApplicationStatus.rejected:
        updatedVisaApplication = visaApplication.copyWith(
          status: status,
          rejectedAt: DateTime.now(),
        );
        break;
      default:
        updatedVisaApplication = visaApplication.copyWith(
          status: status,
        );
    }
    
    // Update in-memory cache
    _visaApplications[id] = updatedVisaApplication;
    
    // Save to SharedPreferences
    await _saveVisaApplications();
    
    return updatedVisaApplication;
  }
  
  /// Add a milestone to a visa application
  Future<VisaApplicationModel> addMilestone(
    String visaApplicationId,
    String title,
    String description,
    DateTime? dueDate,
    bool isRequired,
  ) async {
    // Get the visa application
    final visaApplication = _visaApplications[visaApplicationId];
    if (visaApplication == null) {
      throw Exception('Visa application not found');
    }
    
    // Generate a unique ID
    final id = 'milestone_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create the milestone
    final milestone = VisaMilestone(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate,
      isCompleted: false,
      isRequired: isRequired,
      order: visaApplication.milestones.length,
    );
    
    // Add the milestone
    final updatedMilestones = List<VisaMilestone>.from(visaApplication.milestones)
      ..add(milestone);
    
    // Update the visa application
    final updatedVisaApplication = visaApplication.copyWith(
      milestones: updatedMilestones,
      updatedAt: DateTime.now(),
    );
    
    // Update in-memory cache
    _visaApplications[visaApplicationId] = updatedVisaApplication;
    
    // Save to SharedPreferences
    await _saveVisaApplications();
    
    return updatedVisaApplication;
  }
  
  /// Update a milestone in a visa application
  Future<VisaApplicationModel> updateMilestone(
    String visaApplicationId,
    VisaMilestone milestone,
  ) async {
    // Get the visa application
    final visaApplication = _visaApplications[visaApplicationId];
    if (visaApplication == null) {
      throw Exception('Visa application not found');
    }
    
    // Find the milestone index
    final milestoneIndex = visaApplication.milestones.indexWhere((m) => m.id == milestone.id);
    if (milestoneIndex == -1) {
      throw Exception('Milestone not found');
    }
    
    // Update the milestone
    final updatedMilestones = List<VisaMilestone>.from(visaApplication.milestones);
    updatedMilestones[milestoneIndex] = milestone;
    
    // Update the visa application
    final updatedVisaApplication = visaApplication.copyWith(
      milestones: updatedMilestones,
      updatedAt: DateTime.now(),
    );
    
    // Update completion percentage
    final updatedWithPercentage = _updateCompletionPercentage(updatedVisaApplication);
    
    // Update in-memory cache
    _visaApplications[visaApplicationId] = updatedWithPercentage;
    
    // Save to SharedPreferences
    await _saveVisaApplications();
    
    return updatedWithPercentage;
  }
  
  /// Complete a milestone in a visa application
  Future<VisaApplicationModel> completeMilestone(
    String visaApplicationId,
    String milestoneId,
  ) async {
    // Get the visa application
    final visaApplication = _visaApplications[visaApplicationId];
    if (visaApplication == null) {
      throw Exception('Visa application not found');
    }
    
    // Find the milestone index
    final milestoneIndex = visaApplication.milestones.indexWhere((m) => m.id == milestoneId);
    if (milestoneIndex == -1) {
      throw Exception('Milestone not found');
    }
    
    // Update the milestone
    final milestone = visaApplication.milestones[milestoneIndex];
    final updatedMilestone = milestone.copyWith(
      isCompleted: true,
      completedDate: DateTime.now(),
    );
    
    // Update the milestones list
    final updatedMilestones = List<VisaMilestone>.from(visaApplication.milestones);
    updatedMilestones[milestoneIndex] = updatedMilestone;
    
    // Update the visa application
    final updatedVisaApplication = visaApplication.copyWith(
      milestones: updatedMilestones,
      updatedAt: DateTime.now(),
    );
    
    // Update completion percentage
    final updatedWithPercentage = _updateCompletionPercentage(updatedVisaApplication);
    
    // Update in-memory cache
    _visaApplications[visaApplicationId] = updatedWithPercentage;
    
    // Save to SharedPreferences
    await _saveVisaApplications();
    
    return updatedWithPercentage;
  }
  
  /// Add a document to a visa application
  Future<VisaApplicationModel> addDocument(
    String visaApplicationId,
    String name,
    String description,
    bool isRequired,
  ) async {
    // Get the visa application
    final visaApplication = _visaApplications[visaApplicationId];
    if (visaApplication == null) {
      throw Exception('Visa application not found');
    }
    
    // Generate a unique ID
    final id = 'document_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create the document
    final document = VisaDocument(
      id: id,
      name: name,
      description: description,
      isSubmitted: false,
      isApproved: false,
      isRejected: false,
      isRequired: isRequired,
    );
    
    // Add the document
    final updatedDocuments = List<VisaDocument>.from(visaApplication.documents)
      ..add(document);
    
    // Update the visa application
    final updatedVisaApplication = visaApplication.copyWith(
      documents: updatedDocuments,
      updatedAt: DateTime.now(),
    );
    
    // Update in-memory cache
    _visaApplications[visaApplicationId] = updatedVisaApplication;
    
    // Save to SharedPreferences
    await _saveVisaApplications();
    
    return updatedVisaApplication;
  }
  
  /// Update a document in a visa application
  Future<VisaApplicationModel> updateDocument(
    String visaApplicationId,
    VisaDocument document,
  ) async {
    // Get the visa application
    final visaApplication = _visaApplications[visaApplicationId];
    if (visaApplication == null) {
      throw Exception('Visa application not found');
    }
    
    // Find the document index
    final documentIndex = visaApplication.documents.indexWhere((d) => d.id == document.id);
    if (documentIndex == -1) {
      throw Exception('Document not found');
    }
    
    // Update the document
    final updatedDocuments = List<VisaDocument>.from(visaApplication.documents);
    updatedDocuments[documentIndex] = document;
    
    // Update the visa application
    final updatedVisaApplication = visaApplication.copyWith(
      documents: updatedDocuments,
      updatedAt: DateTime.now(),
    );
    
    // Update completion percentage
    final updatedWithPercentage = _updateCompletionPercentage(updatedVisaApplication);
    
    // Update in-memory cache
    _visaApplications[visaApplicationId] = updatedWithPercentage;
    
    // Save to SharedPreferences
    await _saveVisaApplications();
    
    return updatedWithPercentage;
  }
  
  /// Submit a document in a visa application
  Future<VisaApplicationModel> submitDocument(
    String visaApplicationId,
    String documentId,
    String? fileUrl,
  ) async {
    // Get the visa application
    final visaApplication = _visaApplications[visaApplicationId];
    if (visaApplication == null) {
      throw Exception('Visa application not found');
    }
    
    // Find the document index
    final documentIndex = visaApplication.documents.indexWhere((d) => d.id == documentId);
    if (documentIndex == -1) {
      throw Exception('Document not found');
    }
    
    // Update the document
    final document = visaApplication.documents[documentIndex];
    final updatedDocument = document.copyWith(
      isSubmitted: true,
      submissionDate: DateTime.now(),
      fileUrl: fileUrl,
    );
    
    // Update the documents list
    final updatedDocuments = List<VisaDocument>.from(visaApplication.documents);
    updatedDocuments[documentIndex] = updatedDocument;
    
    // Update the visa application
    final updatedVisaApplication = visaApplication.copyWith(
      documents: updatedDocuments,
      updatedAt: DateTime.now(),
    );
    
    // Update completion percentage
    final updatedWithPercentage = _updateCompletionPercentage(updatedVisaApplication);
    
    // Update in-memory cache
    _visaApplications[visaApplicationId] = updatedWithPercentage;
    
    // Save to SharedPreferences
    await _saveVisaApplications();
    
    return updatedWithPercentage;
  }
  
  /// Add a note to a visa application
  Future<VisaApplicationModel> addNote(
    String visaApplicationId,
    String content,
    String createdBy,
    bool isImportant,
  ) async {
    // Get the visa application
    final visaApplication = _visaApplications[visaApplicationId];
    if (visaApplication == null) {
      throw Exception('Visa application not found');
    }
    
    // Generate a unique ID
    final id = 'note_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create the note
    final note = VisaNote(
      id: id,
      content: content,
      createdAt: DateTime.now(),
      createdBy: createdBy,
      isImportant: isImportant,
    );
    
    // Add the note
    final updatedNotes = List<VisaNote>.from(visaApplication.notes)
      ..add(note);
    
    // Update the visa application
    final updatedVisaApplication = visaApplication.copyWith(
      notes: updatedNotes,
      updatedAt: DateTime.now(),
    );
    
    // Update in-memory cache
    _visaApplications[visaApplicationId] = updatedVisaApplication;
    
    // Save to SharedPreferences
    await _saveVisaApplications();
    
    return updatedVisaApplication;
  }
  
  /// Add an appointment to a visa application
  Future<VisaApplicationModel> addAppointment(
    String visaApplicationId,
    String title,
    String description,
    DateTime dateTime,
    String location,
  ) async {
    // Get the visa application
    final visaApplication = _visaApplications[visaApplicationId];
    if (visaApplication == null) {
      throw Exception('Visa application not found');
    }
    
    // Generate a unique ID
    final id = 'appointment_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create the appointment
    final appointment = VisaAppointment(
      id: id,
      title: title,
      description: description,
      dateTime: dateTime,
      location: location,
      isCompleted: false,
      isReminded: false,
    );
    
    // Add the appointment
    final updatedAppointments = List<VisaAppointment>.from(visaApplication.appointments)
      ..add(appointment);
    
    // Update the visa application
    final updatedVisaApplication = visaApplication.copyWith(
      appointments: updatedAppointments,
      updatedAt: DateTime.now(),
    );
    
    // Update in-memory cache
    _visaApplications[visaApplicationId] = updatedVisaApplication;
    
    // Save to SharedPreferences
    await _saveVisaApplications();
    
    return updatedVisaApplication;
  }
  
  /// Complete an appointment in a visa application
  Future<VisaApplicationModel> completeAppointment(
    String visaApplicationId,
    String appointmentId,
    String? notes,
  ) async {
    // Get the visa application
    final visaApplication = _visaApplications[visaApplicationId];
    if (visaApplication == null) {
      throw Exception('Visa application not found');
    }
    
    // Find the appointment index
    final appointmentIndex = visaApplication.appointments.indexWhere((a) => a.id == appointmentId);
    if (appointmentIndex == -1) {
      throw Exception('Appointment not found');
    }
    
    // Update the appointment
    final appointment = visaApplication.appointments[appointmentIndex];
    final updatedAppointment = appointment.copyWith(
      isCompleted: true,
      notes: notes,
    );
    
    // Update the appointments list
    final updatedAppointments = List<VisaAppointment>.from(visaApplication.appointments);
    updatedAppointments[appointmentIndex] = updatedAppointment;
    
    // Update the visa application
    final updatedVisaApplication = visaApplication.copyWith(
      appointments: updatedAppointments,
      updatedAt: DateTime.now(),
    );
    
    // Update in-memory cache
    _visaApplications[visaApplicationId] = updatedVisaApplication;
    
    // Save to SharedPreferences
    await _saveVisaApplications();
    
    return updatedVisaApplication;
  }
  
  /// Load visa applications from SharedPreferences
  Future<void> _loadVisaApplications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final visaApplicationsJson = prefs.getStringList(_visaApplicationsKey);
      
      if (visaApplicationsJson == null || visaApplicationsJson.isEmpty) {
        // No saved visa applications
        return;
      }
      
      // Parse visa applications
      for (final json in visaApplicationsJson) {
        try {
          final map = jsonDecode(json) as Map<String, dynamic>;
          final visaApplication = VisaApplicationModel.fromMap(map);
          _visaApplications[visaApplication.id] = visaApplication;
        } catch (e) {
          debugPrint('Error parsing visa application: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading visa applications: $e');
    }
  }
  
  /// Save visa applications to SharedPreferences
  Future<void> _saveVisaApplications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final visaApplicationsJson = _visaApplications.values.map((visaApplication) => 
        jsonEncode(visaApplication.toMap())
      ).toList();
      
      await prefs.setStringList(_visaApplicationsKey, visaApplicationsJson);
    } catch (e) {
      debugPrint('Error saving visa applications: $e');
    }
  }
  
  /// Create default milestones for a new visa application
  List<VisaMilestone> _createDefaultMilestones() {
    return [
      VisaMilestone(
        id: 'milestone_1',
        title: 'Gather Required Documents',
        description: 'Collect all necessary documents for your visa application.',
        isCompleted: false,
        isRequired: true,
        order: 0,
      ),
      VisaMilestone(
        id: 'milestone_2',
        title: 'Complete Application Form',
        description: 'Fill out the visa application form with accurate information.',
        isCompleted: false,
        isRequired: true,
        order: 1,
      ),
      VisaMilestone(
        id: 'milestone_3',
        title: 'Pay Application Fee',
        description: 'Pay the required visa application fee.',
        isCompleted: false,
        isRequired: true,
        order: 2,
      ),
      VisaMilestone(
        id: 'milestone_4',
        title: 'Schedule Appointment',
        description: 'Schedule an appointment with the embassy or consulate.',
        isCompleted: false,
        isRequired: true,
        order: 3,
      ),
      VisaMilestone(
        id: 'milestone_5',
        title: 'Attend Interview',
        description: 'Attend the visa interview at the embassy or consulate.',
        isCompleted: false,
        isRequired: true,
        order: 4,
      ),
      VisaMilestone(
        id: 'milestone_6',
        title: 'Submit Biometrics',
        description: 'Provide fingerprints and photo for biometric data.',
        isCompleted: false,
        isRequired: true,
        order: 5,
      ),
      VisaMilestone(
        id: 'milestone_7',
        title: 'Wait for Decision',
        description: 'Wait for the visa application decision.',
        isCompleted: false,
        isRequired: true,
        order: 6,
      ),
      VisaMilestone(
        id: 'milestone_8',
        title: 'Collect Visa',
        description: 'Collect your visa from the embassy or consulate.',
        isCompleted: false,
        isRequired: true,
        order: 7,
      ),
    ];
  }
  
  /// Create default documents for a new visa application based on visa type
  List<VisaDocument> _createDefaultDocuments(VisaType visaType) {
    final commonDocuments = [
      VisaDocument(
        id: 'document_1',
        name: 'Valid Passport',
        description: 'Passport valid for at least 6 months beyond your stay.',
        isSubmitted: false,
        isApproved: false,
        isRejected: false,
        isRequired: true,
      ),
      VisaDocument(
        id: 'document_2',
        name: 'Visa Application Form',
        description: 'Completed and signed visa application form.',
        isSubmitted: false,
        isApproved: false,
        isRejected: false,
        isRequired: true,
      ),
      VisaDocument(
        id: 'document_3',
        name: 'Passport Photos',
        description: 'Recent passport-sized photos with white background.',
        isSubmitted: false,
        isApproved: false,
        isRejected: false,
        isRequired: true,
      ),
      VisaDocument(
        id: 'document_4',
        name: 'Proof of Payment',
        description: 'Receipt of visa application fee payment.',
        isSubmitted: false,
        isApproved: false,
        isRejected: false,
        isRequired: true,
      ),
      VisaDocument(
        id: 'document_5',
        name: 'Travel Insurance',
        description: 'Travel health insurance covering your entire stay.',
        isSubmitted: false,
        isApproved: false,
        isRejected: false,
        isRequired: true,
      ),
    ];
    
    // Add visa type specific documents
    switch (visaType) {
      case VisaType.student:
        return [
          ...commonDocuments,
          VisaDocument(
            id: 'document_6',
            name: 'Acceptance Letter',
            description: 'Official acceptance letter from the educational institution.',
            isSubmitted: false,
            isApproved: false,
            isRejected: false,
            isRequired: true,
          ),
          VisaDocument(
            id: 'document_7',
            name: 'Proof of Financial Means',
            description: 'Bank statements or scholarship letter showing sufficient funds.',
            isSubmitted: false,
            isApproved: false,
            isRejected: false,
            isRequired: true,
          ),
          VisaDocument(
            id: 'document_8',
            name: 'Academic Transcripts',
            description: 'Certified copies of academic transcripts and diplomas.',
            isSubmitted: false,
            isApproved: false,
            isRejected: false,
            isRequired: true,
          ),
          VisaDocument(
            id: 'document_9',
            name: 'Language Proficiency',
            description: 'Proof of English or Greek language proficiency.',
            isSubmitted: false,
            isApproved: false,
            isRejected: false,
            isRequired: true,
          ),
          VisaDocument(
            id: 'document_10',
            name: 'Accommodation Proof',
            description: 'Proof of accommodation arrangements in Cyprus.',
            isSubmitted: false,
            isApproved: false,
            isRejected: false,
            isRequired: false,
          ),
        ];
      case VisaType.work:
        return [
          ...commonDocuments,
          VisaDocument(
            id: 'document_6',
            name: 'Employment Contract',
            description: 'Signed employment contract from a Cypriot employer.',
            isSubmitted: false,
            isApproved: false,
            isRejected: false,
            isRequired: true,
          ),
          VisaDocument(
            id: 'document_7',
            name: 'Work Permit',
            description: 'Approved work permit from the Department of Labor.',
            isSubmitted: false,
            isApproved: false,
            isRejected: false,
            isRequired: true,
          ),
          VisaDocument(
            id: 'document_8',
            name: 'CV/Resume',
            description: 'Updated curriculum vitae or resume.',
            isSubmitted: false,
            isApproved: false,
            isRejected: false,
            isRequired: true,
          ),
          VisaDocument(
            id: 'document_9',
            name: 'Qualifications',
            description: 'Certified copies of qualifications and certificates.',
            isSubmitted: false,
            isApproved: false,
            isRejected: false,
            isRequired: true,
          ),
        ];
      case VisaType.tourist:
        return [
          ...commonDocuments,
          VisaDocument(
            id: 'document_6',
            name: 'Travel Itinerary',
            description: 'Detailed travel itinerary including flight and accommodation bookings.',
            isSubmitted: false,
            isApproved: false,
            isRejected: false,
            isRequired: true,
          ),
          VisaDocument(
            id: 'document_7',
            name: 'Proof of Financial Means',
            description: 'Bank statements showing sufficient funds for your stay.',
            isSubmitted: false,
            isApproved: false,
            isRejected: false,
            isRequired: true,
          ),
          VisaDocument(
            id: 'document_8',
            name: 'Return Ticket',
            description: 'Confirmed return or onward ticket.',
            isSubmitted: false,
            isApproved: false,
            isRejected: false,
            isRequired: true,
          ),
        ];
      case VisaType.family:
        return [
          ...commonDocuments,
          VisaDocument(
            id: 'document_6',
            name: 'Relationship Proof',
            description: 'Marriage certificate, birth certificate, or other proof of relationship.',
            isSubmitted: false,
            isApproved: false,
            isRejected: false,
            isRequired: true,
          ),
          VisaDocument(
            id: 'document_7',
            name: 'Sponsor Documents',
            description: 'Documents of the family member in Cyprus (residence permit, etc.).',
            isSubmitted: false,
            isApproved: false,
            isRejected: false,
            isRequired: true,
          ),
          VisaDocument(
            id: 'document_8',
            name: 'Proof of Financial Means',
            description: 'Bank statements showing sufficient funds for your stay.',
            isSubmitted: false,
            isApproved: false,
            isRejected: false,
            isRequired: true,
          ),
          VisaDocument(
            id: 'document_9',
            name: 'Accommodation Proof',
            description: 'Proof of accommodation arrangements in Cyprus.',
            isSubmitted: false,
            isApproved: false,
            isRejected: false,
            isRequired: true,
          ),
        ];
      case VisaType.other:
      default:
        return commonDocuments;
    }
  }
  
  /// Update the completion percentage of a visa application
  VisaApplicationModel _updateCompletionPercentage(VisaApplicationModel visaApplication) {
    // Calculate completion percentage based on milestones and documents
    double milestonesWeight = 0.6; // 60% of the total
    double documentsWeight = 0.4; // 40% of the total
    
    // Calculate milestones completion
    int completedMilestones = visaApplication.milestones
        .where((m) => m.isCompleted)
        .length;
    int totalMilestones = visaApplication.milestones.length;
    double milestonesPercentage = totalMilestones > 0 
        ? (completedMilestones / totalMilestones) * 100 
        : 0;
    
    // Calculate documents completion
    int submittedDocuments = visaApplication.documents
        .where((d) => d.isSubmitted)
        .length;
    int totalDocuments = visaApplication.documents.length;
    double documentsPercentage = totalDocuments > 0 
        ? (submittedDocuments / totalDocuments) * 100 
        : 0;
    
    // Calculate weighted total
    double completionPercentage = (milestonesPercentage * milestonesWeight) + 
        (documentsPercentage * documentsWeight);
    
    // Round to 2 decimal places
    completionPercentage = double.parse(completionPercentage.toStringAsFixed(2));
    
    // Update the visa application
    return visaApplication.copyWith(
      completionPercentage: completionPercentage,
    );
  }
}
