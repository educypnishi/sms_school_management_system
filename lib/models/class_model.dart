import 'package:flutter/material.dart';

/// Represents a class grade level
enum GradeLevel {
  preschool,
  elementary,
  middle,
  high,
  special,
}

/// Represents a school course
class SchoolCourse {
  final String id;
  final String name;
  final String description;
  final GradeLevel gradeLevel;
  final int durationWeeks;
  final double feePerTerm;
  final String currency;
  final List<String> subjects;
  final List<String> requirements;
  final bool hasScholarship;
  final double? scholarshipAmount;
  final String? scholarshipCriteria;

  SchoolCourse({
    required this.id,
    required this.name,
    required this.description,
    required this.gradeLevel,
    required this.durationWeeks,
    required this.feePerTerm,
    required this.currency,
    required this.subjects,
    required this.requirements,
    required this.hasScholarship,
    this.scholarshipAmount,
    this.scholarshipCriteria,
  });

  /// Get a formatted duration string
  String get formattedDuration {
    final terms = (durationWeeks / 12).floor();
    final weeks = durationWeeks % 12;
    
    if (terms > 0 && weeks > 0) {
      return '$terms term${terms > 1 ? 's' : ''} $weeks week${weeks > 1 ? 's' : ''}';
    } else if (terms > 0) {
      return '$terms term${terms > 1 ? 's' : ''}';
    } else {
      return '$weeks week${weeks > 1 ? 's' : ''}';
    }
  }

  /// Get a formatted fee string
  String get formattedFee {
    return '$feePerTerm $currency per term';
  }

  /// Get a formatted grade level string
  String get formattedGradeLevel {
    switch (gradeLevel) {
      case GradeLevel.preschool:
        return 'Preschool';
      case GradeLevel.elementary:
        return 'Elementary School';
      case GradeLevel.middle:
        return 'Middle School';
      case GradeLevel.high:
        return 'High School';
      case GradeLevel.special:
        return 'Special Education';
    }
  }

  /// Create a copy of this course with updated fields
  SchoolCourse copyWith({
    String? id,
    String? name,
    String? description,
    GradeLevel? gradeLevel,
    int? durationWeeks,
    double? feePerTerm,
    String? currency,
    List<String>? subjects,
    List<String>? requirements,
    bool? hasScholarship,
    double? scholarshipAmount,
    String? scholarshipCriteria,
  }) {
    return SchoolCourse(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      feePerTerm: feePerTerm ?? this.feePerTerm,
      currency: currency ?? this.currency,
      subjects: subjects ?? this.subjects,
      requirements: requirements ?? this.requirements,
      hasScholarship: hasScholarship ?? this.hasScholarship,
      scholarshipAmount: scholarshipAmount ?? this.scholarshipAmount,
      scholarshipCriteria: scholarshipCriteria ?? this.scholarshipCriteria,
    );
  }

  /// Create a SchoolCourse from a map
  factory SchoolCourse.fromMap(Map<String, dynamic> map) {
    return SchoolCourse(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      gradeLevel: _parseGradeLevel(map['gradeLevel']),
      durationWeeks: map['durationWeeks'] ?? 0,
      feePerTerm: map['feePerTerm']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'USD',
      subjects: List<String>.from(map['subjects'] ?? []),
      requirements: List<String>.from(map['requirements'] ?? []),
      hasScholarship: map['hasScholarship'] ?? false,
      scholarshipAmount: map['scholarshipAmount']?.toDouble(),
      scholarshipCriteria: map['scholarshipCriteria'],
    );
  }

  /// Convert SchoolCourse to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'gradeLevel': gradeLevel.toString().split('.').last,
      'durationWeeks': durationWeeks,
      'feePerTerm': feePerTerm,
      'currency': currency,
      'subjects': subjects,
      'requirements': requirements,
      'hasScholarship': hasScholarship,
      'scholarshipAmount': scholarshipAmount,
      'scholarshipCriteria': scholarshipCriteria,
    };
  }

  /// Parse GradeLevel from string
  static GradeLevel _parseGradeLevel(String? value) {
    if (value == null) return GradeLevel.elementary;
    
    switch (value.toLowerCase()) {
      case 'preschool':
        return GradeLevel.preschool;
      case 'middle':
        return GradeLevel.middle;
      case 'high':
        return GradeLevel.high;
      case 'special':
        return GradeLevel.special;
      case 'elementary':
      default:
        return GradeLevel.elementary;
    }
  }
}

/// Represents a school facility
class SchoolFacility {
  final String name;
  final String description;
  final IconData icon;

  SchoolFacility({
    required this.name,
    required this.description,
    required this.icon,
  });

  /// Create a SchoolFacility from a map
  factory SchoolFacility.fromMap(Map<String, dynamic> map) {
    return SchoolFacility(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      icon: _getIconForFacility(map['name'] ?? ''),
    );
  }

  /// Convert SchoolFacility to a map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
    };
  }

  /// Get icon for facility based on name
  static IconData _getIconForFacility(String facilityName) {
    final name = facilityName.toLowerCase();
    
    if (name.contains('library')) return Icons.local_library;
    if (name.contains('lab')) return Icons.science;
    if (name.contains('sport')) return Icons.sports;
    if (name.contains('gym')) return Icons.fitness_center;
    if (name.contains('cafeteria') || name.contains('canteen')) return Icons.restaurant;
    if (name.contains('wifi')) return Icons.wifi;
    if (name.contains('parking')) return Icons.local_parking;
    if (name.contains('dorm') || name.contains('housing')) return Icons.home;
    if (name.contains('medical') || name.contains('health')) return Icons.local_hospital;
    if (name.contains('computer')) return Icons.computer;
    if (name.contains('playground')) return Icons.park;
    if (name.contains('music')) return Icons.music_note;
    if (name.contains('art')) return Icons.palette;
    
    return Icons.school;
  }
}

/// Model for a class in the school management system
class ClassModel {
  final String id;
  final String name;
  final String description;
  final String logoUrl;
  final String location;
  final int capacity;
  final int currentEnrollment;
  final String teacherId;
  final String teacherName;
  final GradeLevel gradeLevel;
  final double rating;
  final int reviewCount;
  final List<String> subjects;
  final List<SchoolCourse> courses;
  final List<SchoolFacility> facilities;
  final String? virtualTourUrl;
  final List<String> photoUrls;
  final Map<String, dynamic> schedule;
  final bool isFavorite;

  ClassModel({
    required this.id,
    required this.name,
    required this.description,
    required this.logoUrl,
    required this.location,
    required this.capacity,
    required this.currentEnrollment,
    required this.teacherId,
    required this.teacherName,
    required this.gradeLevel,
    required this.rating,
    required this.reviewCount,
    required this.subjects,
    required this.courses,
    required this.facilities,
    this.virtualTourUrl,
    required this.photoUrls,
    required this.schedule,
    this.isFavorite = false,
  });

  /// Get the formatted grade level
  String get formattedGradeLevel {
    switch (gradeLevel) {
      case GradeLevel.preschool:
        return 'Preschool';
      case GradeLevel.elementary:
        return 'Elementary School';
      case GradeLevel.middle:
        return 'Middle School';
      case GradeLevel.high:
        return 'High School';
      case GradeLevel.special:
        return 'Special Education';
    }
  }

  /// Get the student-to-capacity ratio
  double get enrollmentRatio => capacity > 0 ? currentEnrollment / capacity : 0;

  /// Get formatted enrollment ratio
  String get formattedEnrollmentRatio => capacity > 0 
      ? '${(currentEnrollment / capacity * 100).toStringAsFixed(1)}%' 
      : 'N/A';

  /// Get the minimum fee among all courses
  double get minFee {
    if (courses.isEmpty) return 0;
    return courses.map((p) => p.feePerTerm).reduce((a, b) => a < b ? a : b);
  }

  /// Get the maximum fee among all courses
  double get maxFee {
    if (courses.isEmpty) return 0;
    return courses.map((p) => p.feePerTerm).reduce((a, b) => a > b ? a : b);
  }

  /// Get the fee range as a string
  String get feeRange {
    if (courses.isEmpty) return 'N/A';
    final currency = courses.first.currency;
    return '$minFee - $maxFee $currency per term';
  }

  /// Create a copy of this class with updated fields
  ClassModel copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? location,
    int? capacity,
    int? currentEnrollment,
    String? teacherId,
    String? teacherName,
    GradeLevel? gradeLevel,
    double? rating,
    int? reviewCount,
    List<String>? subjects,
    List<SchoolCourse>? courses,
    List<SchoolFacility>? facilities,
    String? virtualTourUrl,
    List<String>? photoUrls,
    Map<String, dynamic>? schedule,
    bool? isFavorite,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      currentEnrollment: currentEnrollment ?? this.currentEnrollment,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      subjects: subjects ?? this.subjects,
      courses: courses ?? this.courses,
      facilities: facilities ?? this.facilities,
      virtualTourUrl: virtualTourUrl ?? this.virtualTourUrl,
      photoUrls: photoUrls ?? this.photoUrls,
      schedule: schedule ?? this.schedule,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Create a ClassModel from a map
  factory ClassModel.fromMap(Map<String, dynamic> map) {
    // Parse courses
    final coursesList = <SchoolCourse>[];
    if (map['courses'] != null) {
      for (final course in map['courses']) {
        coursesList.add(SchoolCourse.fromMap(course));
      }
    }
    
    // Parse facilities
    final facilitiesList = <SchoolFacility>[];
    if (map['facilities'] != null) {
      for (final facility in map['facilities']) {
        facilitiesList.add(SchoolFacility.fromMap(facility));
      }
    }
    
    return ClassModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      location: map['location'] ?? '',
      capacity: map['capacity'] ?? 0,
      currentEnrollment: map['currentEnrollment'] ?? 0,
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      gradeLevel: _parseGradeLevel(map['gradeLevel']),
      rating: map['rating']?.toDouble() ?? 0.0,
      reviewCount: map['reviewCount'] ?? 0,
      subjects: List<String>.from(map['subjects'] ?? []),
      courses: coursesList,
      facilities: facilitiesList,
      virtualTourUrl: map['virtualTourUrl'],
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      schedule: Map<String, dynamic>.from(map['schedule'] ?? {}),
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  /// Convert ClassModel to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'location': location,
      'capacity': capacity,
      'currentEnrollment': currentEnrollment,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'gradeLevel': gradeLevel.toString().split('.').last,
      'rating': rating,
      'reviewCount': reviewCount,
      'subjects': subjects,
      'courses': courses.map((p) => p.toMap()).toList(),
      'facilities': facilities.map((f) => f.toMap()).toList(),
      'virtualTourUrl': virtualTourUrl,
      'photoUrls': photoUrls,
      'schedule': schedule,
      'isFavorite': isFavorite,
    };
  }
  
  /// Parse GradeLevel from string
  static GradeLevel _parseGradeLevel(String? value) {
    if (value == null) return GradeLevel.elementary;
    
    switch (value.toLowerCase()) {
      case 'preschool':
        return GradeLevel.preschool;
      case 'middle':
        return GradeLevel.middle;
      case 'high':
        return GradeLevel.high;
      case 'special':
        return GradeLevel.special;
      case 'elementary':
      default:
        return GradeLevel.elementary;
    }
  }
}
