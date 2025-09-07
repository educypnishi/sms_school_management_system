import 'package:flutter/material.dart';
import 'class_model.dart';

/// Model for a course in the school management system
class CourseModel {
  final String id;
  final String name;
  final String description;
  final String subjectArea;
  final GradeLevel gradeLevel;
  final String teacherId;
  final String teacherName;
  final int creditHours;
  final List<String> prerequisites;
  final List<String> learningOutcomes;
  final String syllabus;
  final Map<String, dynamic> schedule;
  final int maxStudents;
  final int currentEnrollment;
  final double fee;
  final String currency;
  final bool isElective;
  final bool isActive;
  final List<String> resources;
  final List<String> assessmentMethods;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CourseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.subjectArea,
    required this.gradeLevel,
    required this.teacherId,
    required this.teacherName,
    required this.creditHours,
    required this.prerequisites,
    required this.learningOutcomes,
    required this.syllabus,
    required this.schedule,
    required this.maxStudents,
    required this.currentEnrollment,
    required this.fee,
    required this.currency,
    required this.isElective,
    required this.isActive,
    required this.resources,
    required this.assessmentMethods,
    required this.createdAt,
    this.updatedAt,
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

  /// Get formatted fee
  String get formattedFee {
    return '$fee $currency';
  }

  /// Get enrollment status
  String get enrollmentStatus {
    if (currentEnrollment >= maxStudents) {
      return 'Full';
    } else if (currentEnrollment >= maxStudents * 0.8) {
      return 'Almost Full';
    } else {
      return 'Open';
    }
  }

  /// Get enrollment percentage
  double get enrollmentPercentage {
    return maxStudents > 0 ? (currentEnrollment / maxStudents) * 100 : 0;
  }

  /// Create a copy of this course with updated fields
  CourseModel copyWith({
    String? id,
    String? name,
    String? description,
    String? subjectArea,
    GradeLevel? gradeLevel,
    String? teacherId,
    String? teacherName,
    int? creditHours,
    List<String>? prerequisites,
    List<String>? learningOutcomes,
    String? syllabus,
    Map<String, dynamic>? schedule,
    int? maxStudents,
    int? currentEnrollment,
    double? fee,
    String? currency,
    bool? isElective,
    bool? isActive,
    List<String>? resources,
    List<String>? assessmentMethods,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CourseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      subjectArea: subjectArea ?? this.subjectArea,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      creditHours: creditHours ?? this.creditHours,
      prerequisites: prerequisites ?? this.prerequisites,
      learningOutcomes: learningOutcomes ?? this.learningOutcomes,
      syllabus: syllabus ?? this.syllabus,
      schedule: schedule ?? this.schedule,
      maxStudents: maxStudents ?? this.maxStudents,
      currentEnrollment: currentEnrollment ?? this.currentEnrollment,
      fee: fee ?? this.fee,
      currency: currency ?? this.currency,
      isElective: isElective ?? this.isElective,
      isActive: isActive ?? this.isActive,
      resources: resources ?? this.resources,
      assessmentMethods: assessmentMethods ?? this.assessmentMethods,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create a CourseModel from a map
  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      subjectArea: map['subjectArea'] ?? '',
      gradeLevel: _parseGradeLevel(map['gradeLevel']),
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      creditHours: map['creditHours'] ?? 0,
      prerequisites: List<String>.from(map['prerequisites'] ?? []),
      learningOutcomes: List<String>.from(map['learningOutcomes'] ?? []),
      syllabus: map['syllabus'] ?? '',
      schedule: Map<String, dynamic>.from(map['schedule'] ?? {}),
      maxStudents: map['maxStudents'] ?? 0,
      currentEnrollment: map['currentEnrollment'] ?? 0,
      fee: map['fee']?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'USD',
      isElective: map['isElective'] ?? false,
      isActive: map['isActive'] ?? true,
      resources: List<String>.from(map['resources'] ?? []),
      assessmentMethods: List<String>.from(map['assessmentMethods'] ?? []),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
    );
  }

  /// Convert CourseModel to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'subjectArea': subjectArea,
      'gradeLevel': gradeLevel.toString().split('.').last,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'creditHours': creditHours,
      'prerequisites': prerequisites,
      'learningOutcomes': learningOutcomes,
      'syllabus': syllabus,
      'schedule': schedule,
      'maxStudents': maxStudents,
      'currentEnrollment': currentEnrollment,
      'fee': fee,
      'currency': currency,
      'isElective': isElective,
      'isActive': isActive,
      'resources': resources,
      'assessmentMethods': assessmentMethods,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
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
