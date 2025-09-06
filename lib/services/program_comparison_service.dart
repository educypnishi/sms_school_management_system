import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/program_comparison_model.dart';
import '../models/program_model.dart';
import '../services/program_service.dart';

/// Service to manage program comparisons
class ProgramComparisonService {
  final ProgramService _programService = ProgramService();
  
  // Shared Preferences key prefix
  static const String _comparisonPrefix = 'comparison_';
  
  /// Get all saved comparisons for a user
  Future<List<ProgramComparisonModel>> getUserComparisons(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all comparison IDs for the user
      final comparisonIds = prefs.getStringList('${_comparisonPrefix}${userId}_list') ?? [];
      
      // Get comparisons
      final comparisons = <ProgramComparisonModel>[];
      for (final id in comparisonIds) {
        final comparison = await getComparisonById(id);
        if (comparison != null) {
          comparisons.add(comparison);
        }
      }
      
      // Sort by creation date (newest first)
      comparisons.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return comparisons;
    } catch (e) {
      debugPrint('Error getting user comparisons: $e');
      return [];
    }
  }
  
  /// Get a comparison by ID
  Future<ProgramComparisonModel?> getComparisonById(String comparisonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get comparison from SharedPreferences
      final comparisonJson = prefs.getString('${_comparisonPrefix}$comparisonId');
      if (comparisonJson == null) {
        return null;
      }
      
      // Parse comparison
      final comparisonMap = jsonDecode(comparisonJson) as Map<String, dynamic>;
      
      // Get program IDs
      final programIds = List<String>.from(comparisonMap['programIds'] ?? []);
      
      // Get programs
      final programs = <ProgramModel>[];
      for (final id in programIds) {
        final program = await _programService.getProgramById(id);
        if (program != null) {
          programs.add(program);
        }
      }
      
      return ProgramComparisonModel(
        id: comparisonId,
        programs: programs,
        comparisonCriteria: List<String>.from(comparisonMap['comparisonCriteria'] ?? []),
        createdAt: DateTime.parse(comparisonMap['createdAt'] ?? DateTime.now().toIso8601String()),
        userId: comparisonMap['userId'],
        title: comparisonMap['title'],
        isSaved: true,
      );
    } catch (e) {
      debugPrint('Error getting comparison: $e');
      return null;
    }
  }
  
  /// Save a comparison
  Future<ProgramComparisonModel> saveComparison(ProgramComparisonModel comparison) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generate a new comparison ID if not provided
      final comparisonId = comparison.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create a map to save
      final comparisonMap = {
        'programIds': comparison.programs.map((p) => p.id).toList(),
        'comparisonCriteria': comparison.comparisonCriteria,
        'createdAt': comparison.createdAt.toIso8601String(),
        'userId': comparison.userId,
        'title': comparison.title ?? 'Comparison ${comparisonId.substring(0, 8)}',
      };
      
      // Save comparison to SharedPreferences
      await prefs.setString('${_comparisonPrefix}$comparisonId', jsonEncode(comparisonMap));
      
      // Add comparison ID to user's comparison list if it has a userId
      if (comparison.userId != null) {
        final comparisonIds = prefs.getStringList('${_comparisonPrefix}${comparison.userId}_list') ?? [];
        if (!comparisonIds.contains(comparisonId)) {
          comparisonIds.add(comparisonId);
          await prefs.setStringList('${_comparisonPrefix}${comparison.userId}_list', comparisonIds);
        }
      }
      
      // Return updated comparison with ID and saved status
      return comparison.copyWith(
        id: comparisonId,
        isSaved: true,
        title: comparison.title ?? 'Comparison ${comparisonId.substring(0, 8)}',
      );
    } catch (e) {
      debugPrint('Error saving comparison: $e');
      rethrow;
    }
  }
  
  /// Delete a comparison
  Future<void> deleteComparison(String comparisonId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove comparison from SharedPreferences
      await prefs.remove('${_comparisonPrefix}$comparisonId');
      
      // Remove comparison ID from user's comparison list
      final comparisonIds = prefs.getStringList('${_comparisonPrefix}${userId}_list') ?? [];
      comparisonIds.remove(comparisonId);
      await prefs.setStringList('${_comparisonPrefix}${userId}_list', comparisonIds);
    } catch (e) {
      debugPrint('Error deleting comparison: $e');
      rethrow;
    }
  }
  
  /// Create a new comparison with selected programs
  Future<ProgramComparisonModel> createComparison(List<String> programIds, String userId) async {
    try {
      // Get programs
      final programs = <ProgramModel>[];
      for (final id in programIds) {
        final program = await _programService.getProgramById(id);
        if (program != null) {
          programs.add(program);
        }
      }
      
      // Create comparison
      final comparison = ProgramComparisonModel(
        programs: programs,
        comparisonCriteria: ProgramComparisonModel.getAllCriteria(),
        createdAt: DateTime.now(),
        userId: userId,
      );
      
      return comparison;
    } catch (e) {
      debugPrint('Error creating comparison: $e');
      rethrow;
    }
  }
  
  /// Generate sample comparisons for demo purposes
  Future<List<ProgramComparisonModel>> generateSampleComparisons(String userId) async {
    try {
      // Get some sample programs
      final programs = await _programService.getAllPrograms();
      if (programs.length < 3) {
        throw Exception('Not enough programs to create sample comparisons');
      }
      
      // Create sample comparison 1
      final comparison1 = ProgramComparisonModel(
        id: 'sample1',
        programs: [programs[0], programs[1]],
        comparisonCriteria: ['university', 'duration', 'tuitionFee', 'degreeType'],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        userId: userId,
        title: 'Computer Science Programs',
        isSaved: true,
      );
      
      // Create sample comparison 2
      final comparison2 = ProgramComparisonModel(
        id: 'sample2',
        programs: [programs[1], programs[2]],
        comparisonCriteria: ProgramComparisonModel.getAllCriteria(),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        userId: userId,
        title: 'Business Programs',
        isSaved: true,
      );
      
      // Save sample comparisons
      await saveComparison(comparison1);
      await saveComparison(comparison2);
      
      return [comparison1, comparison2];
    } catch (e) {
      debugPrint('Error generating sample comparisons: $e');
      return [];
    }
  }
}
