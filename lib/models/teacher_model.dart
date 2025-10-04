class TeacherModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? address;
  final String? qualification;
  final String? specialization;
  final int? yearsOfExperience;
  final DateTime? joiningDate;
  final String? employeeId;
  final List<String>? classesTaught;
  final List<String>? subjectsTaught;
  final String? photoUrl;
  final Map<String, dynamic>? schedule;
  final Map<String, dynamic>? performanceReviews;
  final String status; // active, inactive, on leave
  final DateTime createdAt;
  final DateTime? updatedAt;

  TeacherModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.qualification,
    this.specialization,
    this.yearsOfExperience,
    this.joiningDate,
    this.employeeId,
    this.classesTaught,
    this.subjectsTaught,
    this.photoUrl,
    this.schedule,
    this.performanceReviews,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  // Create a TeacherModel from a map (e.g., from Firestore)
  factory TeacherModel.fromMap(Map<String, dynamic> map, String id) {
    return TeacherModel(
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
      qualification: map['qualification'],
      specialization: map['specialization'],
      yearsOfExperience: map['yearsOfExperience'],
      joiningDate: map['joiningDate'] != null 
          ? DateTime.parse(map['joiningDate']) 
          : null,
      employeeId: map['employeeId'],
      classesTaught: map['classesTaught'] != null 
          ? List<String>.from(map['classesTaught']) 
          : null,
      subjectsTaught: map['subjectsTaught'] != null 
          ? List<String>.from(map['subjectsTaught']) 
          : null,
      photoUrl: map['photoUrl'],
      schedule: map['schedule'],
      performanceReviews: map['performanceReviews'],
      status: map['status'] ?? 'active',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
    );
  }

  // Convert TeacherModel to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'address': address,
      'qualification': qualification,
      'specialization': specialization,
      'yearsOfExperience': yearsOfExperience,
      'joiningDate': joiningDate?.toIso8601String(),
      'employeeId': employeeId,
      'classesTaught': classesTaught,
      'subjectsTaught': subjectsTaught,
      'photoUrl': photoUrl,
      'schedule': schedule,
      'performanceReviews': performanceReviews,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create a copy of TeacherModel with some fields changed
  TeacherModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? qualification,
    String? specialization,
    int? yearsOfExperience,
    DateTime? joiningDate,
    String? employeeId,
    List<String>? classesTaught,
    List<String>? subjectsTaught,
    String? photoUrl,
    Map<String, dynamic>? schedule,
    Map<String, dynamic>? performanceReviews,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeacherModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      qualification: qualification ?? this.qualification,
      specialization: specialization ?? this.specialization,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      joiningDate: joiningDate ?? this.joiningDate,
      employeeId: employeeId ?? this.employeeId,
      subjectsTaught: subjectsTaught ?? this.subjectsTaught,
      photoUrl: photoUrl ?? this.photoUrl,
      schedule: schedule ?? this.schedule,
      performanceReviews: performanceReviews ?? this.performanceReviews,
      status: status ?? this.status,
    );
  }

  // Getter for timetable compatibility
  List<String> get subjects => subjectsTaught ?? [];
