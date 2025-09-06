class ApplicationModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String status;
  final String? assignedPartnerId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;
  final DateTime? assignedAt;

  ApplicationModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    this.assignedPartnerId,
    required this.createdAt,
    this.updatedAt,
    this.submittedAt,
    this.assignedAt,
  });

  // Create an ApplicationModel from a map (e.g., from Firestore)
  factory ApplicationModel.fromMap(Map<String, dynamic> map, String id) {
    return ApplicationModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
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
    );
  }

  // Convert ApplicationModel to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'status': status,
      'assignedPartnerId': assignedPartnerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'submittedAt': submittedAt?.toIso8601String(),
      'assignedAt': assignedAt?.toIso8601String(),
    };
  }

  // Create a copy of ApplicationModel with some fields changed
  ApplicationModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? status,
    String? assignedPartnerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
    DateTime? assignedAt,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      assignedPartnerId: assignedPartnerId ?? this.assignedPartnerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      assignedAt: assignedAt ?? this.assignedAt,
    );
  }
}
