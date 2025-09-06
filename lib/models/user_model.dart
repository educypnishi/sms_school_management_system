class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    required this.createdAt,
  });

  // Create a UserModel from a map (e.g., from Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      phone: map['phone'],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as DateTime) 
          : DateTime.now(),
    );
  }

  // Convert UserModel to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'createdAt': createdAt,
    };
  }

  // Create a copy of UserModel with some fields changed
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
