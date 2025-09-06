import 'package:flutter/material.dart';
import 'program_model.dart';

/// Model for comparing educational programs
class ProgramComparisonModel {
  final List<ProgramModel> programs;
  final List<String> comparisonCriteria;
  final DateTime createdAt;
  final String? userId;
  final String? id;
  final String? title;
  final bool isSaved;

  ProgramComparisonModel({
    required this.programs,
    required this.comparisonCriteria,
    required this.createdAt,
    this.userId,
    this.id,
    this.title,
    this.isSaved = false,
  });

  /// Create a copy of this comparison with updated fields
  ProgramComparisonModel copyWith({
    List<ProgramModel>? programs,
    List<String>? comparisonCriteria,
    DateTime? createdAt,
    String? userId,
    String? id,
    String? title,
    bool? isSaved,
  }) {
    return ProgramComparisonModel(
      programs: programs ?? this.programs,
      comparisonCriteria: comparisonCriteria ?? this.comparisonCriteria,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      id: id ?? this.id,
      title: title ?? this.title,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  /// Add a program to the comparison
  ProgramComparisonModel addProgram(ProgramModel program) {
    if (programs.length >= 3) {
      throw Exception('Cannot compare more than 3 programs at once');
    }
    
    if (programs.any((p) => p.id == program.id)) {
      throw Exception('Program is already in the comparison');
    }
    
    return copyWith(
      programs: [...programs, program],
    );
  }

  /// Remove a program from the comparison
  ProgramComparisonModel removeProgram(String programId) {
    return copyWith(
      programs: programs.where((p) => p.id != programId).toList(),
    );
  }

  /// Add a criterion to the comparison
  ProgramComparisonModel addCriterion(String criterion) {
    if (comparisonCriteria.contains(criterion)) {
      return this;
    }
    
    return copyWith(
      comparisonCriteria: [...comparisonCriteria, criterion],
    );
  }

  /// Remove a criterion from the comparison
  ProgramComparisonModel removeCriterion(String criterion) {
    return copyWith(
      comparisonCriteria: comparisonCriteria.where((c) => c != criterion).toList(),
    );
  }

  /// Get the value for a specific criterion and program
  String getCriterionValue(String criterion, ProgramModel program) {
    switch (criterion) {
      case 'title':
        return program.title;
      case 'university':
        return program.university;
      case 'duration':
        return program.duration;
      case 'degreeType':
        return program.degreeType;
      case 'tuitionFee':
        return program.tuitionFee;
      case 'requirements':
        return program.requirements.join(', ');
      default:
        return '';
    }
  }

  /// Get the display name for a criterion
  static String getCriterionDisplayName(String criterion) {
    switch (criterion) {
      case 'title':
        return 'Program Title';
      case 'university':
        return 'University';
      case 'duration':
        return 'Duration';
      case 'degreeType':
        return 'Degree Type';
      case 'tuitionFee':
        return 'Tuition Fee';
      case 'requirements':
        return 'Requirements';
      default:
        return criterion;
    }
  }

  /// Get the icon for a criterion
  static IconData getCriterionIcon(String criterion) {
    switch (criterion) {
      case 'title':
        return Icons.title;
      case 'university':
        return Icons.school;
      case 'duration':
        return Icons.access_time;
      case 'degreeType':
        return Icons.workspace_premium;
      case 'tuitionFee':
        return Icons.euro;
      case 'requirements':
        return Icons.checklist;
      default:
        return Icons.info;
    }
  }

  /// Get all available criteria for comparison
  static List<String> getAllCriteria() {
    return [
      'title',
      'university',
      'duration',
      'degreeType',
      'tuitionFee',
      'requirements',
    ];
  }

  /// Create a new empty comparison
  static ProgramComparisonModel createEmpty({String? userId}) {
    return ProgramComparisonModel(
      programs: [],
      comparisonCriteria: getAllCriteria(),
      createdAt: DateTime.now(),
      userId: userId,
    );
  }
}
