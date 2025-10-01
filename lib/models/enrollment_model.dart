class EnrollmentModel {
  final String id;
  final String studentId;
  
  // Step 1: Personal Information
  final String name;
  final String email;
  final String phone;
  final DateTime? dateOfBirth;
  final String? nationality;
  final String? idNumber;
  final String? currentAddress;
  final String? gender;
  
  // Step 2: Educational Background
  final String? previousSchool;
  final String? previousGrade;
  final String? previousPerformance;
  final double? gpa;
  final int? yearOfCompletion;
  final List<String>? certificates;
  
  // Step 3: Course Selection
  final String? desiredClass;
  final String? desiredGrade;
  final String? programName; // Program name for the enrollment
  final String? academicYear; // 2025-2026, etc.
  final String? preferredStartDate; // Fall 2025, Spring 2026, etc.
  final bool? needsTransportation;
  
  // Step 4: Financial Information
  final String? paymentMethod; // Monthly, Termly, Yearly
  final bool? hasScholarship;
  final double? scholarshipAmount;
  final String? guardianName;
  final String? guardianRelationship;
  
  // Step 5: Document Uploads
  final String? idCardUrl;
  final String? photoUrl;
  final String? previousReportCardsUrl;
  final String? certificatesUrl;
  final String? medicalRecordsUrl;
  final String? parentConsentFormUrl;
  final String? otherDocumentsUrl;
  
  // Enrollment Status
  final String status;
  final String? assignedTeacherId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;
  final DateTime? assignedAt;
  final int? currentStep; // Tracks which step the user is on (1-5)

  EnrollmentModel({
    required this.id,
    required this.studentId,
    required this.name,
    required this.email,
    required this.phone,
    this.dateOfBirth,
    this.nationality,
    this.idNumber,
    this.currentAddress,
    this.gender,
    this.previousSchool,
    this.previousGrade,
    this.previousPerformance,
    this.gpa,
    this.yearOfCompletion,
    this.certificates,
    this.desiredClass,
    this.desiredGrade,
    this.programName,
    this.academicYear,
    this.preferredStartDate,
    this.needsTransportation,
    this.paymentMethod,
    this.hasScholarship,
    this.scholarshipAmount,
    this.guardianName,
    this.guardianRelationship,
    this.idCardUrl,
    this.photoUrl,
    this.previousReportCardsUrl,
    this.certificatesUrl,
    this.medicalRecordsUrl,
    this.parentConsentFormUrl,
    this.otherDocumentsUrl,
    required this.status,
    this.assignedTeacherId,
    required this.createdAt,
    this.updatedAt,
    this.submittedAt,
    this.assignedAt,
    this.currentStep,
  });

  // Create an EnrollmentModel from a map (e.g., from Firestore)
  factory EnrollmentModel.fromMap(Map<String, dynamic> map, String id) {
    return EnrollmentModel(
      id: id,
      studentId: map['studentId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      
      // Step 1: Personal Information
      dateOfBirth: map['dateOfBirth'] != null 
          ? DateTime.parse(map['dateOfBirth']) 
          : null,
      nationality: map['nationality'],
      idNumber: map['idNumber'],
      currentAddress: map['currentAddress'],
      gender: map['gender'],
      
      // Step 2: Educational Background
      previousSchool: map['previousSchool'],
      previousGrade: map['previousGrade'],
      previousPerformance: map['previousPerformance'],
      gpa: map['gpa'] != null ? (map['gpa'] as num).toDouble() : null,
      yearOfCompletion: map['yearOfCompletion'],
      certificates: map['certificates'] != null 
          ? List<String>.from(map['certificates']) 
          : null,
      
      // Step 3: Course Selection
      desiredClass: map['desiredClass'],
      desiredGrade: map['desiredGrade'],
      programName: map['programName'],
      academicYear: map['academicYear'],
      preferredStartDate: map['preferredStartDate'],
      needsTransportation: map['needsTransportation'],
      
      // Step 4: Financial Information
      paymentMethod: map['paymentMethod'],
      hasScholarship: map['hasScholarship'],
      scholarshipAmount: map['scholarshipAmount'] != null 
          ? (map['scholarshipAmount'] as num).toDouble() 
          : null,
      guardianName: map['guardianName'],
      guardianRelationship: map['guardianRelationship'],
      
      // Step 5: Document Uploads
      idCardUrl: map['idCardUrl'],
      photoUrl: map['photoUrl'],
      previousReportCardsUrl: map['previousReportCardsUrl'],
      certificatesUrl: map['certificatesUrl'],
      medicalRecordsUrl: map['medicalRecordsUrl'],
      parentConsentFormUrl: map['parentConsentFormUrl'],
      otherDocumentsUrl: map['otherDocumentsUrl'],
      
      // Enrollment Status
      status: map['status'] ?? 'draft',
      assignedTeacherId: map['assignedTeacherId'],
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

  // Convert EnrollmentModel to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'name': name,
      'email': email,
      'phone': phone,
      
      // Step 1: Personal Information
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'nationality': nationality,
      'idNumber': idNumber,
      'currentAddress': currentAddress,
      'gender': gender,
      
      // Step 2: Educational Background
      'previousSchool': previousSchool,
      'previousGrade': previousGrade,
      'previousPerformance': previousPerformance,
      'gpa': gpa,
      'yearOfCompletion': yearOfCompletion,
      'certificates': certificates,
      
      // Step 3: Course Selection
      'desiredClass': desiredClass,
      'desiredGrade': desiredGrade,
      'programName': programName,
      'academicYear': academicYear,
      'preferredStartDate': preferredStartDate,
      'needsTransportation': needsTransportation,
      
      // Step 4: Financial Information
      'paymentMethod': paymentMethod,
      'hasScholarship': hasScholarship,
      'scholarshipAmount': scholarshipAmount,
      'guardianName': guardianName,
      'guardianRelationship': guardianRelationship,
      
      // Step 5: Document Uploads
      'idCardUrl': idCardUrl,
      'photoUrl': photoUrl,
      'previousReportCardsUrl': previousReportCardsUrl,
      'certificatesUrl': certificatesUrl,
      'medicalRecordsUrl': medicalRecordsUrl,
      'parentConsentFormUrl': parentConsentFormUrl,
      'otherDocumentsUrl': otherDocumentsUrl,
      
      // Enrollment Status
      'status': status,
      'assignedTeacherId': assignedTeacherId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'submittedAt': submittedAt?.toIso8601String(),
      'assignedAt': assignedAt?.toIso8601String(),
      'currentStep': currentStep,
    };
  }

  // Create a copy of EnrollmentModel with some fields changed
  EnrollmentModel copyWith({
    String? id,
    String? studentId,
    String? name,
    String? email,
    String? phone,
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
    String? status,
    String? assignedTeacherId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
    DateTime? assignedAt,
    int? currentStep,
  }) {
    return EnrollmentModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationality: nationality ?? this.nationality,
      idNumber: idNumber ?? this.idNumber,
      currentAddress: currentAddress ?? this.currentAddress,
      gender: gender ?? this.gender,
      previousSchool: previousSchool ?? this.previousSchool,
      previousGrade: previousGrade ?? this.previousGrade,
      previousPerformance: previousPerformance ?? this.previousPerformance,
      gpa: gpa ?? this.gpa,
      yearOfCompletion: yearOfCompletion ?? this.yearOfCompletion,
      certificates: certificates ?? this.certificates,
      desiredClass: desiredClass ?? this.desiredClass,
      desiredGrade: desiredGrade ?? this.desiredGrade,
      academicYear: academicYear ?? this.academicYear,
      preferredStartDate: preferredStartDate ?? this.preferredStartDate,
      needsTransportation: needsTransportation ?? this.needsTransportation,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      hasScholarship: hasScholarship ?? this.hasScholarship,
      scholarshipAmount: scholarshipAmount ?? this.scholarshipAmount,
      guardianName: guardianName ?? this.guardianName,
      guardianRelationship: guardianRelationship ?? this.guardianRelationship,
      idCardUrl: idCardUrl ?? this.idCardUrl,
      photoUrl: photoUrl ?? this.photoUrl,
      previousReportCardsUrl: previousReportCardsUrl ?? this.previousReportCardsUrl,
      certificatesUrl: certificatesUrl ?? this.certificatesUrl,
      medicalRecordsUrl: medicalRecordsUrl ?? this.medicalRecordsUrl,
      parentConsentFormUrl: parentConsentFormUrl ?? this.parentConsentFormUrl,
      otherDocumentsUrl: otherDocumentsUrl ?? this.otherDocumentsUrl,
      status: status ?? this.status,
      assignedTeacherId: assignedTeacherId ?? this.assignedTeacherId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      assignedAt: assignedAt ?? this.assignedAt,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}
