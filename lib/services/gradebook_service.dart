import 'dart:math';
import '../models/gradebook_model.dart';

class GradebookService {
  // Simulate a database with some sample data
  final List<GradeModel> _grades = [];
  final List<AssignmentModel> _assignments = [];
  
  GradebookService() {
    // Initialize with some sample data
    _generateSampleData();
  }
  
  void _generateSampleData() {
    final random = Random();
    
    // Sample courses
    final courses = [
      {'id': 'course1', 'name': 'Mathematics'},
      {'id': 'course2', 'name': 'Science'},
      {'id': 'course3', 'name': 'English'},
      {'id': 'course4', 'name': 'History'},
    ];
    
    // Sample students
    final students = [
      {'id': 'student1', 'name': 'John Smith'},
      {'id': 'student2', 'name': 'Emily Johnson'},
      {'id': 'student3', 'name': 'Michael Brown'},
      {'id': 'student4', 'name': 'Sarah Davis'},
      {'id': 'student5', 'name': 'David Wilson'},
    ];
    
    // Sample assignment types
    final assignmentTypes = ['quiz', 'exam', 'homework', 'project', 'participation'];
    
    // Sample teachers
    final teachers = [
      {'id': 'teacher1', 'name': 'Dr. Anderson'},
      {'id': 'teacher2', 'name': 'Prof. Martinez'},
    ];
    
    // Generate assignments
    for (final course in courses) {
      for (int i = 0; i < 5; i++) {
        final assignmentType = assignmentTypes[random.nextInt(assignmentTypes.length)];
        final teacher = teachers[random.nextInt(teachers.length)];
        final daysAgo = random.nextInt(30);
        final dueInDays = random.nextInt(14) + 1;
        
        final assignment = AssignmentModel(
          id: 'assignment_${_assignments.length + 1}',
          courseId: course['id'] as String,
          courseName: course['name'] as String,
          title: '${course['name']} ${assignmentType.capitalize()} ${i + 1}',
          description: 'This is a ${assignmentType} for ${course['name']}',
          type: assignmentType,
          maxScore: assignmentType == 'participation' ? 10.0 : 100.0,
          dueDate: DateTime.now().add(Duration(days: dueInDays)),
          createdDate: DateTime.now().subtract(Duration(days: daysAgo)),
          createdById: teacher['id'] as String,
          createdByName: teacher['name'] as String,
          isPublished: random.nextBool(),
        );
        
        _assignments.add(assignment);
      }
    }
    
    // Generate grades for past assignments
    for (final assignment in _assignments.where((a) => a.isPublished && a.createdDate.isBefore(DateTime.now().subtract(const Duration(days: 7))))) {
      for (final student in students) {
        // Not every student has a grade for every assignment
        if (random.nextDouble() > 0.1) {
          final scorePercentage = random.nextDouble() * 0.4 + 0.6; // 60% to 100%
          final score = assignment.maxScore * scorePercentage;
          final daysAgo = random.nextInt(7);
          final submittedDaysAgo = daysAgo + random.nextInt(3) + 1;
          
          final grade = GradeModel(
            id: 'grade_${_grades.length + 1}',
            studentId: student['id'] as String,
            studentName: student['name'] as String,
            courseId: assignment.courseId,
            courseName: assignment.courseName,
            assignmentId: assignment.id,
            assignmentName: assignment.title,
            assignmentType: assignment.type,
            score: score,
            maxScore: assignment.maxScore,
            feedback: random.nextBool() ? 'Good job!' : null,
            submittedDate: DateTime.now().subtract(Duration(days: submittedDaysAgo)),
            gradedDate: DateTime.now().subtract(Duration(days: daysAgo)),
            gradedById: assignment.createdById,
            gradedByName: assignment.createdByName,
          );
          
          _grades.add(grade);
        }
      }
    }
  }
  
  // Get all assignments
  Future<List<AssignmentModel>> getAllAssignments() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    return _assignments;
  }
  
  // Get assignments for a specific course
  Future<List<AssignmentModel>> getAssignmentsForCourse(String courseId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    return _assignments.where((a) => a.courseId == courseId).toList();
  }
  
  // Get assignment by ID
  Future<AssignmentModel> getAssignmentById(String id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    final assignment = _assignments.firstWhere(
      (a) => a.id == id,
      orElse: () => throw Exception('Assignment not found'),
    );
    
    return assignment;
  }
  
  // Create a new assignment
  Future<AssignmentModel> createAssignment(AssignmentModel assignment) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
    final newAssignment = AssignmentModel(
      id: 'assignment_${_assignments.length + 1}',
      courseId: assignment.courseId,
      courseName: assignment.courseName,
      title: assignment.title,
      description: assignment.description,
      type: assignment.type,
      maxScore: assignment.maxScore,
      dueDate: assignment.dueDate,
      createdDate: DateTime.now(),
      createdById: assignment.createdById,
      createdByName: assignment.createdByName,
      isPublished: assignment.isPublished,
    );
    
    _assignments.add(newAssignment);
    return newAssignment;
  }
  
  // Update an existing assignment
  Future<AssignmentModel> updateAssignment(AssignmentModel assignment) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    final index = _assignments.indexWhere((a) => a.id == assignment.id);
    if (index == -1) {
      throw Exception('Assignment not found');
    }
    
    _assignments[index] = assignment;
    return assignment;
  }
  
  // Delete an assignment
  Future<void> deleteAssignment(String id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    _assignments.removeWhere((a) => a.id == id);
    // Also remove associated grades
    _grades.removeWhere((g) => g.assignmentId == id);
  }
  
  // Get all grades
  Future<List<GradeModel>> getAllGrades() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    return _grades;
  }
  
  // Get grades for a specific student
  Future<List<GradeModel>> getGradesForStudent(String studentId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    return _grades.where((g) => g.studentId == studentId).toList();
  }
  
  // Get grades for a specific course
  Future<List<GradeModel>> getGradesForCourse(String courseId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    return _grades.where((g) => g.courseId == courseId).toList();
  }
  
  // Get grades for a specific assignment
  Future<List<GradeModel>> getGradesForAssignment(String assignmentId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    return _grades.where((g) => g.assignmentId == assignmentId).toList();
  }
  
  // Get a specific grade
  Future<GradeModel> getGradeById(String id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    final grade = _grades.firstWhere(
      (g) => g.id == id,
      orElse: () => throw Exception('Grade not found'),
    );
    
    return grade;
  }
  
  // Create a new grade
  Future<GradeModel> createGrade(GradeModel grade) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
    final newGrade = GradeModel(
      id: 'grade_${_grades.length + 1}',
      studentId: grade.studentId,
      studentName: grade.studentName,
      courseId: grade.courseId,
      courseName: grade.courseName,
      assignmentId: grade.assignmentId,
      assignmentName: grade.assignmentName,
      assignmentType: grade.assignmentType,
      score: grade.score,
      maxScore: grade.maxScore,
      feedback: grade.feedback,
      submittedDate: grade.submittedDate,
      gradedDate: DateTime.now(),
      gradedById: grade.gradedById,
      gradedByName: grade.gradedByName,
    );
    
    _grades.add(newGrade);
    return newGrade;
  }
  
  // Update an existing grade
  Future<GradeModel> updateGrade(GradeModel grade) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    final index = _grades.indexWhere((g) => g.id == grade.id);
    if (index == -1) {
      throw Exception('Grade not found');
    }
    
    _grades[index] = grade.copyWith(gradedDate: DateTime.now());
    return _grades[index];
  }
  
  // Delete a grade
  Future<void> deleteGrade(String id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    _grades.removeWhere((g) => g.id == id);
  }
  
  // Get student grade summary for a course
  Future<StudentGradeSummary> getStudentGradeSummary(String studentId, String courseId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
    final grades = _grades.where((g) => g.studentId == studentId && g.courseId == courseId).toList();
    
    if (grades.isEmpty) {
      throw Exception('No grades found for this student in this course');
    }
    
    return StudentGradeSummary(
      studentId: studentId,
      studentName: grades.first.studentName,
      courseId: courseId,
      courseName: grades.first.courseName,
      grades: grades,
    );
  }
  
  // Get all student grade summaries for a course
  Future<List<StudentGradeSummary>> getAllStudentGradeSummariesForCourse(String courseId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1200));
    
    final courseGrades = _grades.where((g) => g.courseId == courseId).toList();
    final studentIds = courseGrades.map((g) => g.studentId).toSet().toList();
    
    final summaries = <StudentGradeSummary>[];
    
    for (final studentId in studentIds) {
      final studentGrades = courseGrades.where((g) => g.studentId == studentId).toList();
      
      if (studentGrades.isNotEmpty) {
        summaries.add(StudentGradeSummary(
          studentId: studentId,
          studentName: studentGrades.first.studentName,
          courseId: courseId,
          courseName: studentGrades.first.courseName,
          grades: studentGrades,
        ));
      }
    }
    
    return summaries;
  }
}

// Extension method to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
