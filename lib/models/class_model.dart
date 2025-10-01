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
  final String grade;
  final String subject;
  final String teacherName;
  final String room;
  final String schedule;
  final int capacity;
  final int currentStudents;
  final double averageGrade;

  ClassModel({
    required this.id,
    required this.name,
    required this.grade,
    required this.subject,
    required this.teacherName,
    required this.room,
    required this.schedule,
    required this.capacity,
    required this.currentStudents,
    required this.averageGrade,
  });

  /// Get the student-to-capacity ratio
  double get enrollmentRatio => capacity > 0 ? currentStudents / capacity : 0;

  /// Get formatted enrollment ratio
  String get formattedEnrollmentRatio => capacity > 0 
      ? '${(currentStudents / capacity * 100).toStringAsFixed(1)}%' 
      : 'N/A';

  /// Check if class is full
  bool get isFull => currentStudents >= capacity;

  /// Get available spots
  int get availableSpots => capacity - currentStudents;

  /// Get grade letter based on average grade
  String get gradeLevel {
    if (averageGrade >= 90) return 'A';
    if (averageGrade >= 80) return 'B';
    if (averageGrade >= 70) return 'C';
    if (averageGrade >= 60) return 'D';
    return 'F';
  }

  /// Create a copy of this class with updated fields
  ClassModel copyWith({
    String? id,
    String? name,
    String? grade,
    String? subject,
    String? teacherName,
    String? room,
    String? schedule,
    int? capacity,
    int? currentStudents,
    double? averageGrade,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      subject: subject ?? this.subject,
      teacherName: teacherName ?? this.teacherName,
      room: room ?? this.room,
      schedule: schedule ?? this.schedule,
      capacity: capacity ?? this.capacity,
      currentStudents: currentStudents ?? this.currentStudents,
      averageGrade: averageGrade ?? this.averageGrade,
    );
  }

  /// Create a ClassModel from a map
  factory ClassModel.fromMap(Map<String, dynamic> map, String id) {
    return ClassModel(
      id: id,
      name: map['name'] ?? '',
      grade: map['grade'] ?? '',
      subject: map['subject'] ?? '',
      teacherName: map['teacherName'] ?? '',
      room: map['room'] ?? '',
      schedule: map['schedule'] ?? '',
      capacity: map['capacity'] ?? 0,
      currentStudents: map['currentStudents'] ?? 0,
      averageGrade: map['averageGrade']?.toDouble() ?? 0.0,
    );
  }

  /// Convert ClassModel to a map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'grade': grade,
      'subject': subject,
      'teacherName': teacherName,
      'room': room,
      'schedule': schedule,
      'capacity': capacity,
      'currentStudents': currentStudents,
      'averageGrade': averageGrade,
    };
  }
}
