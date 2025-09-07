class ApplicationModel {
  final String id;
  final String userId;
  
  // Step 1: Personal Information
  final String name;
  final String email;
  final String phone;
  final DateTime? dateOfBirth;
  final String? nationality;
  final String? passportNumber;
  final DateTime? passportExpiryDate;
  final String? currentAddress;
  final String? gender;
  
  // Step 2: Educational Background
  final String? highestEducation;
  final String? previousInstitution;
  final String? fieldOfStudy;
  final double? gpa;
  final int? yearOfCompletion;
  final List<String>? certificates;
  
  // Step 3: Program Selection
  final String? desiredProgram;
  final String? desiredUniversity;
  final String? studyLevel; // Bachelors, Masters, PhD
  final String? preferredStartDate; // Fall 2025, Spring 2026, etc.
  final bool? needsAccommodation;
  
  // Step 4: Financial Information
  final String? fundingSource; // Self, Family, Scholarship, Loan
  final bool? hasFinancialDocuments;
  final double? availableFunds;
  final String? sponsorName;
  final String? sponsorRelationship;
  
  // Step 5: Document Uploads
  final String? passportScanUrl;
  final String? photoUrl;
  final String? transcriptsUrl;
  final String? certificatesUrl;
  final String? financialDocumentsUrl;
  final String? motivationLetterUrl;
  final String? recommendationLettersUrl;
  
  // Application Status
  final String status;
  final String? assignedPartnerId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;
  final DateTime? assignedAt;
  final int? currentStep; // Tracks which step the user is on (1-5)

  ApplicationModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    this.dateOfBirth,
    this.nationality,
    this.passportNumber,
    this.passportExpiryDate,
    this.currentAddress,
    this.gender,
    this.highestEducation,
    this.previousInstitution,
    this.fieldOfStudy,
    this.gpa,
    this.yearOfCompletion,
    this.certificates,
    this.desiredProgram,
    this.desiredUniversity,
    this.studyLevel,
    this.preferredStartDate,
    this.needsAccommodation,
    this.fundingSource,
    this.hasFinancialDocuments,
    this.availableFunds,
    this.sponsorName,
    this.sponsorRelationship,
    this.passportScanUrl,
    this.photoUrl,
    this.transcriptsUrl,
    this.certificatesUrl,
    this.financialDocumentsUrl,
    this.motivationLetterUrl,
    this.recommendationLettersUrl,
    required this.status,
    this.assignedPartnerId,
    required this.createdAt,
    this.updatedAt,
    this.submittedAt,
    this.assignedAt,
    this.currentStep,
  });

  // Create an ApplicationModel from a map (e.g., from Firestore)
  factory ApplicationModel.fromMap(Map<String, dynamic> map, String id) {
    return ApplicationModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      
      // Step 1: Personal Information
      dateOfBirth: map['dateOfBirth'] != null 
          ? DateTime.parse(map['dateOfBirth']) 
          : null,
      nationality: map['nationality'],
      passportNumber: map['passportNumber'],
      passportExpiryDate: map['passportExpiryDate'] != null 
          ? DateTime.parse(map['passportExpiryDate']) 
          : null,
      currentAddress: map['currentAddress'],
      gender: map['gender'],
      
      // Step 2: Educational Background
      highestEducation: map['highestEducation'],
      previousInstitution: map['previousInstitution'],
      fieldOfStudy: map['fieldOfStudy'],
      gpa: map['gpa'] != null ? (map['gpa'] as num).toDouble() : null,
      yearOfCompletion: map['yearOfCompletion'],
      certificates: map['certificates'] != null 
          ? List<String>.from(map['certificates']) 
          : null,
      
      // Step 3: Program Selection
      desiredProgram: map['desiredProgram'],
      desiredUniversity: map['desiredUniversity'],
      studyLevel: map['studyLevel'],
      preferredStartDate: map['preferredStartDate'],
      needsAccommodation: map['needsAccommodation'],
      
      // Step 4: Financial Information
      fundingSource: map['fundingSource'],
      hasFinancialDocuments: map['hasFinancialDocuments'],
      availableFunds: map['availableFunds'] != null 
          ? (map['availableFunds'] as num).toDouble() 
          : null,
      sponsorName: map['sponsorName'],
      sponsorRelationship: map['sponsorRelationship'],
      
      // Step 5: Document Uploads
      passportScanUrl: map['passportScanUrl'],
      photoUrl: map['photoUrl'],
      transcriptsUrl: map['transcriptsUrl'],
      certificatesUrl: map['certificatesUrl'],
      financialDocumentsUrl: map['financialDocumentsUrl'],
      motivationLetterUrl: map['motivationLetterUrl'],
      recommendationLettersUrl: map['recommendationLettersUrl'],
      
      // Application Status
      status: map['status'] ?? 'draft',
      assignedPartnerId: map['assignedPartnerId'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
      submittedAt: map['submittedAt'] != null 
          ? DateTime.parse(map['submittedAt']) 
          : null,
      assignedAt: map['assignedAt'] != null 
          ? DateTime.parse(map['assignedAt']) 
          : null,
      currentStep: map['currentStep'],
    );
  }

  // Convert ApplicationModel to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      
      // Step 1: Personal Information
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'nationality': nationality,
      'passportNumber': passportNumber,
      'passportExpiryDate': passportExpiryDate?.toIso8601String(),
      'currentAddress': currentAddress,
      'gender': gender,
      
      // Step 2: Educational Background
      'highestEducation': highestEducation,
      'previousInstitution': previousInstitution,
      'fieldOfStudy': fieldOfStudy,
      'gpa': gpa,
      'yearOfCompletion': yearOfCompletion,
      'certificates': certificates,
      
      // Step 3: Program Selection
      'desiredProgram': desiredProgram,
      'desiredUniversity': desiredUniversity,
      'studyLevel': studyLevel,
      'preferredStartDate': preferredStartDate,
      'needsAccommodation': needsAccommodation,
      
      // Step 4: Financial Information
      'fundingSource': fundingSource,
      'hasFinancialDocuments': hasFinancialDocuments,
      'availableFunds': availableFunds,
      'sponsorName': sponsorName,
      'sponsorRelationship': sponsorRelationship,
      
      // Step 5: Document Uploads
      'passportScanUrl': passportScanUrl,
      'photoUrl': photoUrl,
      'transcriptsUrl': transcriptsUrl,
      'certificatesUrl': certificatesUrl,
      'financialDocumentsUrl': financialDocumentsUrl,
      'motivationLetterUrl': motivationLetterUrl,
      'recommendationLettersUrl': recommendationLettersUrl,
      
      // Application Status
      'status': status,
      'assignedPartnerId': assignedPartnerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'submittedAt': submittedAt?.toIso8601String(),
      'assignedAt': assignedAt?.toIso8601String(),
      'currentStep': currentStep,
    };
  }

  // Create a copy of ApplicationModel with some fields changed
  ApplicationModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
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
    String? status,
    String? assignedPartnerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
    DateTime? assignedAt,
    int? currentStep,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationality: nationality ?? this.nationality,
      passportNumber: passportNumber ?? this.passportNumber,
      passportExpiryDate: passportExpiryDate ?? this.passportExpiryDate,
      currentAddress: currentAddress ?? this.currentAddress,
      gender: gender ?? this.gender,
      highestEducation: highestEducation ?? this.highestEducation,
      previousInstitution: previousInstitution ?? this.previousInstitution,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      gpa: gpa ?? this.gpa,
      yearOfCompletion: yearOfCompletion ?? this.yearOfCompletion,
      certificates: certificates ?? this.certificates,
      desiredProgram: desiredProgram ?? this.desiredProgram,
      desiredUniversity: desiredUniversity ?? this.desiredUniversity,
      studyLevel: studyLevel ?? this.studyLevel,
      preferredStartDate: preferredStartDate ?? this.preferredStartDate,
      needsAccommodation: needsAccommodation ?? this.needsAccommodation,
      fundingSource: fundingSource ?? this.fundingSource,
      hasFinancialDocuments: hasFinancialDocuments ?? this.hasFinancialDocuments,
      availableFunds: availableFunds ?? this.availableFunds,
      sponsorName: sponsorName ?? this.sponsorName,
      sponsorRelationship: sponsorRelationship ?? this.sponsorRelationship,
      passportScanUrl: passportScanUrl ?? this.passportScanUrl,
      photoUrl: photoUrl ?? this.photoUrl,
      transcriptsUrl: transcriptsUrl ?? this.transcriptsUrl,
      certificatesUrl: certificatesUrl ?? this.certificatesUrl,
      financialDocumentsUrl: financialDocumentsUrl ?? this.financialDocumentsUrl,
      motivationLetterUrl: motivationLetterUrl ?? this.motivationLetterUrl,
      recommendationLettersUrl: recommendationLettersUrl ?? this.recommendationLettersUrl,
      status: status ?? this.status,
      assignedPartnerId: assignedPartnerId ?? this.assignedPartnerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      assignedAt: assignedAt ?? this.assignedAt,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}
