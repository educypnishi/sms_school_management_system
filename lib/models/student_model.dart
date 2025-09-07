class StudentModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final String? guardianName;
  final String? guardianRelationship;
  final String? guardianPhone;
  final String? guardianEmail;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;
  final String? bloodGroup;
  final List<String>? allergies;
  final List<String>? medicalConditions;
  final String? currentGrade;
  final String? currentClass;
  final String? admissionNumber;
  final DateTime? admissionDate;
  final String? previousSchool;
  final String? photoUrl;
  final Map<String, dynamic>? academicRecords;
  final Map<String, dynamic>? attendanceRecords;
  final Map<String, dynamic>? feePaymentRecords;
  final List<String>? extracurricularActivities;
  final String status; // active, inactive, suspended, graduated
  final DateTime createdAt;
  final DateTime? updatedAt;

  StudentModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.guardianName,
    this.guardianRelationship,
    this.guardianPhone,
    this.guardianEmail,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
    this.bloodGroup,
    this.allergies,
    this.medicalConditions,
    this.currentGrade,
    this.currentClass,
    this.admissionNumber,
    this.admissionDate,
    this.previousSchool,
    this.photoUrl,
    this.academicRecords,
    this.attendanceRecords,
    this.feePaymentRecords,
    this.extracurricularActivities,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  // Create a StudentModel from a map (e.g., from Firestore)
  factory StudentModel.fromMap(Map<String, dynamic> map, String id) {
    return StudentModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      dateOfBirth: map['dateOfBirth'] != null 
          ? DateTime.parse(map['dateOfBirth']) 
          : null,
      gender: map['gender'],
      address: map['address'],
      guardianName: map['guardianName'],
      guardianRelationship: map['guardianRelationship'],
      guardianPhone: map['guardianPhone'],
      guardianEmail: map['guardianEmail'],
      emergencyContactName: map['emergencyContactName'],
      emergencyContactPhone: map['emergencyContactPhone'],
      emergencyContactRelationship: map['emergencyContactRelationship'],
      bloodGroup: map['bloodGroup'],
      allergies: map['allergies'] != null 
          ? List<String>.from(map['allergies']) 
          : null,
      medicalConditions: map['medicalConditions'] != null 
          ? List<String>.from(map['medicalConditions']) 
          : null,
      currentGrade: map['currentGrade'],
      currentClass: map['currentClass'],
      admissionNumber: map['admissionNumber'],
      admissionDate: map['admissionDate'] != null 
          ? DateTime.parse(map['admissionDate']) 
          : null,
      previousSchool: map['previousSchool'],
      photoUrl: map['photoUrl'],
      academicRecords: map['academicRecords'],
      attendanceRecords: map['attendanceRecords'],
      feePaymentRecords: map['feePaymentRecords'],
      extracurricularActivities: map['extracurricularActivities'] != null 
          ? List<String>.from(map['extracurricularActivities']) 
          : null,
      status: map['status'] ?? 'active',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
    );
  }

  // Convert StudentModel to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'address': address,
      'guardianName': guardianName,
      'guardianRelationship': guardianRelationship,
      'guardianPhone': guardianPhone,
      'guardianEmail': guardianEmail,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'emergencyContactRelationship': emergencyContactRelationship,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'medicalConditions': medicalConditions,
      'currentGrade': currentGrade,
      'currentClass': currentClass,
      'admissionNumber': admissionNumber,
      'admissionDate': admissionDate?.toIso8601String(),
      'previousSchool': previousSchool,
      'photoUrl': photoUrl,
      'academicRecords': academicRecords,
      'attendanceRecords': attendanceRecords,
      'feePaymentRecords': feePaymentRecords,
      'extracurricularActivities': extracurricularActivities,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create a copy of StudentModel with some fields changed
  StudentModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? guardianName,
    String? guardianRelationship,
    String? guardianPhone,
    String? guardianEmail,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
    String? bloodGroup,
    List<String>? allergies,
    List<String>? medicalConditions,
    String? currentGrade,
    String? currentClass,
    String? admissionNumber,
    DateTime? admissionDate,
    String? previousSchool,
    String? photoUrl,
    Map<String, dynamic>? academicRecords,
    Map<String, dynamic>? attendanceRecords,
    Map<String, dynamic>? feePaymentRecords,
    List<String>? extracurricularActivities,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      guardianName: guardianName ?? this.guardianName,
      guardianRelationship: guardianRelationship ?? this.guardianRelationship,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      guardianEmail: guardianEmail ?? this.guardianEmail,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelationship: emergencyContactRelationship ?? this.emergencyContactRelationship,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      currentGrade: currentGrade ?? this.currentGrade,
      currentClass: currentClass ?? this.currentClass,
      admissionNumber: admissionNumber ?? this.admissionNumber,
      admissionDate: admissionDate ?? this.admissionDate,
      previousSchool: previousSchool ?? this.previousSchool,
      photoUrl: photoUrl ?? this.photoUrl,
      academicRecords: academicRecords ?? this.academicRecords,
      attendanceRecords: attendanceRecords ?? this.attendanceRecords,
      feePaymentRecords: feePaymentRecords ?? this.feePaymentRecords,
      extracurricularActivities: extracurricularActivities ?? this.extracurricularActivities,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
