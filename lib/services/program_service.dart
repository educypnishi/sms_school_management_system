import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/program_model.dart';

class ProgramService {
  // Program prefix for SharedPreferences keys
  static const String _programPrefix = 'program_';
  
  // Get all programs
  Future<List<ProgramModel>> getAllPrograms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we have any programs stored
      final programsJson = prefs.getString('${_programPrefix}list');
      
      // If no programs exist, create sample programs
      if (programsJson == null) {
        await _createSamplePrograms();
      }
      
      // Get all program IDs
      final programIds = prefs.getStringList('${_programPrefix}list') ?? [];
      
      // Get programs
      final programs = <ProgramModel>[];
      for (final id in programIds) {
        final program = await getProgramById(id);
        if (program != null) {
          programs.add(program);
        }
      }
      
      return programs;
    } catch (e) {
      debugPrint('Error getting all programs: $e');
      return [];
    }
  }
  
  // Get program by ID
  Future<ProgramModel?> getProgramById(String programId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get program from SharedPreferences
      final programJson = prefs.getString('${_programPrefix}$programId');
      if (programJson == null) {
        return null;
      }
      
      // Parse program
      final programMap = jsonDecode(programJson) as Map<String, dynamic>;
      return ProgramModel.fromMap(programMap, programId);
    } catch (e) {
      debugPrint('Error getting program: $e');
      return null;
    }
  }
  
  // Create a new program
  Future<ProgramModel> createProgram({
    required String title,
    required String description,
    required String university,
    required String duration,
    required String degreeType,
    required String tuitionFee,
    required String imageUrl,
    required List<String> requirements,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generate a new program ID
      final programId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create program model
      final program = ProgramModel(
        id: programId,
        title: title,
        description: description,
        university: university,
        duration: duration,
        degreeType: degreeType,
        tuitionFee: tuitionFee,
        imageUrl: imageUrl,
        requirements: requirements,
        createdAt: DateTime.now(),
      );
      
      // Save program to SharedPreferences
      await prefs.setString('${_programPrefix}$programId', jsonEncode(program.toMap()));
      
      // Add program ID to program list
      final programIds = prefs.getStringList('${_programPrefix}list') ?? [];
      programIds.add(programId);
      await prefs.setStringList('${_programPrefix}list', programIds);
      
      return program;
    } catch (e) {
      debugPrint('Error creating program: $e');
      rethrow;
    }
  }
  
  // Update an existing program
  Future<ProgramModel> updateProgram({
    required String id,
    String? title,
    String? description,
    String? university,
    String? duration,
    String? degreeType,
    String? tuitionFee,
    String? imageUrl,
    List<String>? requirements,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get program from SharedPreferences
      final programJson = prefs.getString('${_programPrefix}$id');
      if (programJson == null) {
        throw Exception('Program not found');
      }
      
      // Parse program
      final programMap = jsonDecode(programJson) as Map<String, dynamic>;
      final program = ProgramModel.fromMap(programMap, id);
      
      // Update program
      final updatedProgram = program.copyWith(
        title: title,
        description: description,
        university: university,
        duration: duration,
        degreeType: degreeType,
        tuitionFee: tuitionFee,
        imageUrl: imageUrl,
        requirements: requirements,
        updatedAt: DateTime.now(),
      );
      
      // Save updated program to SharedPreferences
      await prefs.setString('${_programPrefix}$id', jsonEncode(updatedProgram.toMap()));
      
      return updatedProgram;
    } catch (e) {
      debugPrint('Error updating program: $e');
      rethrow;
    }
  }
  
  // Delete a program
  Future<void> deleteProgram(String programId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove program from SharedPreferences
      await prefs.remove('${_programPrefix}$programId');
      
      // Remove program ID from program list
      final programIds = prefs.getStringList('${_programPrefix}list') ?? [];
      programIds.remove(programId);
      await prefs.setStringList('${_programPrefix}list', programIds);
    } catch (e) {
      debugPrint('Error deleting program: $e');
      rethrow;
    }
  }
  
  // Create sample programs for testing
  Future<void> _createSamplePrograms() async {
    try {
      // Create sample programs
      await createProgram(
        title: 'Bachelor of Computer Science',
        description: 'A comprehensive program covering all aspects of computer science, including programming, algorithms, data structures, and software engineering.',
        university: 'University of Cyprus',
        duration: '4 years',
        degreeType: 'Bachelor',
        tuitionFee: '€3,500 per year',
        imageUrl: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97',
        requirements: [
          'High school diploma',
          'Mathematics proficiency',
          'English language proficiency',
        ],
      );
      
      await createProgram(
        title: 'Master of Business Administration',
        description: 'An advanced degree program designed to develop the skills required for careers in business and management.',
        university: 'Cyprus International University',
        duration: '2 years',
        degreeType: 'Master',
        tuitionFee: '€5,000 per year',
        imageUrl: 'https://images.unsplash.com/photo-1507679799987-c73779587ccf',
        requirements: [
          'Bachelor\'s degree',
          'Work experience (preferred)',
          'English language proficiency',
          'GMAT or GRE scores',
        ],
      );
      
      await createProgram(
        title: 'PhD in Environmental Science',
        description: 'A research-focused program exploring environmental issues, sustainability, and conservation strategies.',
        university: 'Eastern Mediterranean University',
        duration: '3-5 years',
        degreeType: 'Doctorate',
        tuitionFee: '€4,200 per year',
        imageUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b',
        requirements: [
          'Master\'s degree in related field',
          'Research proposal',
          'English language proficiency',
          'Academic references',
        ],
      );
    } catch (e) {
      debugPrint('Error creating sample programs: $e');
    }
  }
}
