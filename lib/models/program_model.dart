class ProgramModel {
  final String id;
  final String title;
  final String description;
  final String university;
  final String duration;
  final String degreeType;
  final String tuitionFee;
  final String imageUrl;
  final List<String> requirements;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProgramModel({
    required this.id,
    required this.title,
    required this.description,
    required this.university,
    required this.duration,
    required this.degreeType,
    required this.tuitionFee,
    required this.imageUrl,
    required this.requirements,
    required this.createdAt,
    this.updatedAt,
  });

  // Create a ProgramModel from a map
  factory ProgramModel.fromMap(Map<String, dynamic> map, String id) {
    return ProgramModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      university: map['university'] ?? '',
      duration: map['duration'] ?? '',
      degreeType: map['degreeType'] ?? '',
      tuitionFee: map['tuitionFee'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      requirements: List<String>.from(map['requirements'] ?? []),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
    );
  }

  // Convert ProgramModel to a map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'university': university,
      'duration': duration,
      'degreeType': degreeType,
      'tuitionFee': tuitionFee,
      'imageUrl': imageUrl,
      'requirements': requirements,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create a copy of ProgramModel with some fields changed
  ProgramModel copyWith({
    String? id,
    String? title,
    String? description,
    String? university,
    String? duration,
    String? degreeType,
    String? tuitionFee,
    String? imageUrl,
    List<String>? requirements,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProgramModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      university: university ?? this.university,
      duration: duration ?? this.duration,
      degreeType: degreeType ?? this.degreeType,
      tuitionFee: tuitionFee ?? this.tuitionFee,
      imageUrl: imageUrl ?? this.imageUrl,
      requirements: requirements ?? this.requirements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
