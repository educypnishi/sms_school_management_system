import 'dart:math';
import 'package:flutter/material.dart';
import '../models/class_model.dart';

class ClassService {
  // Simulate a database with some sample data
  final List<ClassModel> _classes = [];
  final List<String> _comparisonList = [];
  
  ClassService() {
    // Initialize with some sample data
    _generateSampleData();
  }
  
  void _generateSampleData() {
    final random = Random();
    
    // Sample class data
    final classData = [
      {
        'id': 'class1',
        'name': 'Class 1-A',
        'grade': 'Grade 1',
        'subject': 'General',
        'teacherName': 'Ms. Khadija Malik',
        'room': 'Room 101',
        'schedule': 'Mon-Fri, 8:00 AM - 2:30 PM',
        'capacity': 25,
        'currentStudents': 22,
        'averageGrade': 85.5,
      },
      {
        'id': 'class2',
        'name': 'Class 2-B',
        'grade': 'Grade 2',
        'subject': 'General',
        'teacherName': 'Mr. Tariq Ahmed',
        'room': 'Room 102',
        'schedule': 'Mon-Fri, 8:30 AM - 3:00 PM',
        'capacity': 28,
        'currentStudents': 24,
        'averageGrade': 82.0,
      },
      {
        'id': 'class3',
        'name': 'Class 3-C',
        'grade': 'Grade 3',
        'subject': 'General',
        'teacherName': 'Mrs. Sadia Khan',
        'room': 'Room 103',
        'schedule': 'Mon-Fri, 8:00 AM - 3:00 PM',
        'capacity': 30,
        'currentStudents': 28,
        'averageGrade': 79.5,
      },
      {
        'id': 'class4',
        'name': 'Math Advanced',
        'grade': 'Grade 4',
        'subject': 'Mathematics',
        'teacherName': 'Dr. Imran Shah',
        'room': 'Room 201',
        'schedule': 'Mon/Wed/Fri, 9:00 AM - 10:30 AM',
        'capacity': 20,
        'currentStudents': 18,
        'averageGrade': 88.0,
      },
      {
        'id': 'class5',
        'name': 'Physics Lab',
        'grade': 'Grade 5',
        'subject': 'Physics',
        'teacherName': 'Prof. Nadia Hussain',
        'room': 'Lab 101',
        'schedule': 'Tue/Thu, 10:00 AM - 12:00 PM',
        'capacity': 24,
        'currentStudents': 20,
        'averageGrade': 84.5,
      },
      {
        'id': 'class6',
        'name': 'English Literature',
        'grade': 'Grade 6',
        'subject': 'English',
        'teacherName': 'Ms. Rabia Iqbal',
        'room': 'Room 205',
        'schedule': 'Mon/Wed/Fri, 11:00 AM - 12:30 PM',
        'capacity': 26,
        'currentStudents': 22,
        'averageGrade': 81.0,
      },
      {
        'id': 'class7',
        'name': 'Computer Science',
        'grade': 'Grade 7',
        'subject': 'Technology',
        'teacherName': 'Mr. Asif Rahman',
        'room': 'Lab 202',
        'schedule': 'Tue/Thu, 1:00 PM - 3:00 PM',
        'capacity': 22,
        'currentStudents': 20,
        'averageGrade': 90.5,
      },
      {
        'id': 'class8',
        'name': 'Art Studio',
        'grade': 'Grade 8',
        'subject': 'Art',
        'teacherName': 'Mrs. Amna Siddique',
        'room': 'Art Room',
        'schedule': 'Mon/Wed, 1:30 PM - 3:30 PM',
        'capacity': 18,
        'currentStudents': 15,
        'averageGrade': 87.0,
      },
    ];
    
    // Create class models
    for (final data in classData) {
      _classes.add(ClassModel(
        id: data['id'] as String,
        name: data['name'] as String,
        grade: data['grade'] as String,
        subject: data['subject'] as String,
        teacherName: data['teacherName'] as String,
        room: data['room'] as String,
        schedule: data['schedule'] as String,
        capacity: data['capacity'] as int,
        currentStudents: data['currentStudents'] as int,
        averageGrade: data['averageGrade'] as double,
      ));
    }
  }
  
  // Get all classes
  Future<List<ClassModel>> getAllClasses() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    return _classes;
  }
  
  // Get class by ID
  Future<ClassModel> getClassById(String id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final classItem = _classes.firstWhere(
      (c) => c.id == id,
      orElse: () => throw Exception('Class not found'),
    );
    
    return classItem;
  }
  
  // Get comparison list
  Future<List<ClassModel>> getComparisonList() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 600));
    
    return _classes
        .where((c) => _comparisonList.contains(c.id))
        .toList();
  }
  
  // Add class to comparison
  Future<bool> addToComparison(String classId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Check if class exists
    final classExists = _classes.any((c) => c.id == classId);
    if (!classExists) {
      throw Exception('Class not found');
    }
    
    // Check if already in comparison
    if (_comparisonList.contains(classId)) {
      return true;
    }
    
    // Check if comparison list is full
    if (_comparisonList.length >= 3) {
      return false;
    }
    
    // Add to comparison list
    _comparisonList.add(classId);
    return true;
  }
  
  // Remove class from comparison
  Future<void> removeFromComparison(String classId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    _comparisonList.remove(classId);
  }
}

