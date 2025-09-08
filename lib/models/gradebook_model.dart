class GradeModel {
  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseName;
  final String assignmentId;
  final String assignmentName;
  final String assignmentType; // 'quiz', 'exam', 'homework', 'project', etc.
  final double score;
  final double maxScore;
  final String? feedback;
  final DateTime submittedDate;
  final DateTime gradedDate;
  final String gradedById;
  final String gradedByName;

  GradeModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseName,
    required this.assignmentId,
    required this.assignmentName,
    required this.assignmentType,
    required this.score,
    required this.maxScore,
    this.feedback,
    required this.submittedDate,
    required this.gradedDate,
    required this.gradedById,
    required this.gradedByName,
  });

  // Calculate percentage score
  double get percentageScore => (score / maxScore) * 100;

  // Get letter grade based on percentage
  String get letterGrade {
    final percentage = percentageScore;
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }

  // Create a GradeModel from a map (e.g., from Firestore)
  factory GradeModel.fromMap(Map<String, dynamic> map, String id) {
    return GradeModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      assignmentId: map['assignmentId'] ?? '',
      assignmentName: map['assignmentName'] ?? '',
      assignmentType: map['assignmentType'] ?? '',
      score: map['score']?.toDouble() ?? 0.0,
      maxScore: map['maxScore']?.toDouble() ?? 100.0,
      feedback: map['feedback'],
      submittedDate: map['submittedDate'] != null
          ? DateTime.parse(map['submittedDate'])
          : DateTime.now(),
      gradedDate: map['gradedDate'] != null
          ? DateTime.parse(map['gradedDate'])
          : DateTime.now(),
      gradedById: map['gradedById'] ?? '',
      gradedByName: map['gradedByName'] ?? '',
    );
  }

  // Convert GradeModel to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'courseName': courseName,
      'assignmentId': assignmentId,
      'assignmentName': assignmentName,
      'assignmentType': assignmentType,
      'score': score,
      'maxScore': maxScore,
      'feedback': feedback,
      'submittedDate': submittedDate.toIso8601String(),
      'gradedDate': gradedDate.toIso8601String(),
      'gradedById': gradedById,
      'gradedByName': gradedByName,
    };
  }

  // Create a copy of GradeModel with some fields changed
  GradeModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? courseId,
    String? courseName,
    String? assignmentId,
    String? assignmentName,
    String? assignmentType,
    double? score,
    double? maxScore,
    String? feedback,
    DateTime? submittedDate,
    DateTime? gradedDate,
    String? gradedById,
    String? gradedByName,
  }) {
    return GradeModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      assignmentId: assignmentId ?? this.assignmentId,
      assignmentName: assignmentName ?? this.assignmentName,
      assignmentType: assignmentType ?? this.assignmentType,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      feedback: feedback ?? this.feedback,
      submittedDate: submittedDate ?? this.submittedDate,
      gradedDate: gradedDate ?? this.gradedDate,
      gradedById: gradedById ?? this.gradedById,
      gradedByName: gradedByName ?? this.gradedByName,
    );
  }
}

class AssignmentModel {
  final String id;
  final String courseId;
  final String courseName;
  final String title;
  final String description;
  final String type; // 'quiz', 'exam', 'homework', 'project', etc.
  final double maxScore;
  final DateTime dueDate;
  final DateTime createdDate;
  final String createdById;
  final String createdByName;
  final bool isPublished;

  AssignmentModel({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.title,
    required this.description,
    required this.type,
    required this.maxScore,
    required this.dueDate,
    required this.createdDate,
    required this.createdById,
    required this.createdByName,
    required this.isPublished,
  });

  // Check if assignment is overdue
  bool isOverdue() {
    return DateTime.now().isAfter(dueDate);
  }

  // Calculate days remaining until due date
  int get daysRemaining {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  // Create an AssignmentModel from a map (e.g., from Firestore)
  factory AssignmentModel.fromMap(Map<String, dynamic> map, String id) {
    return AssignmentModel(
      id: id,
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? '',
      maxScore: map['maxScore']?.toDouble() ?? 100.0,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'])
          : DateTime.now().add(const Duration(days: 7)),
      createdDate: map['createdDate'] != null
          ? DateTime.parse(map['createdDate'])
          : DateTime.now(),
      createdById: map['createdById'] ?? '',
      createdByName: map['createdByName'] ?? '',
      isPublished: map['isPublished'] ?? false,
    );
  }

  // Convert AssignmentModel to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'title': title,
      'description': description,
      'type': type,
      'maxScore': maxScore,
      'dueDate': dueDate.toIso8601String(),
      'createdDate': createdDate.toIso8601String(),
      'createdById': createdById,
      'createdByName': createdByName,
      'isPublished': isPublished,
    };
  }

  // Create a copy of AssignmentModel with some fields changed
  AssignmentModel copyWith({
    String? id,
    String? courseId,
    String? courseName,
    String? title,
    String? description,
    String? type,
    double? maxScore,
    DateTime? dueDate,
    DateTime? createdDate,
    String? createdById,
    String? createdByName,
    bool? isPublished,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      maxScore: maxScore ?? this.maxScore,
      dueDate: dueDate ?? this.dueDate,
      createdDate: createdDate ?? this.createdDate,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}

class StudentGradeSummary {
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseName;
  final List<GradeModel> grades;

  StudentGradeSummary({
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseName,
    required this.grades,
  });

  // Calculate overall grade percentage
  double get overallPercentage {
    if (grades.isEmpty) return 0.0;
    
    double totalPoints = 0.0;
    double maxPoints = 0.0;
    
    for (final grade in grades) {
      totalPoints += grade.score;
      maxPoints += grade.maxScore;
    }
    
    return maxPoints > 0 ? (totalPoints / maxPoints) * 100 : 0.0;
  }

  // Get overall letter grade
  String get overallLetterGrade {
    final percentage = overallPercentage;
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }

  // Get grades by assignment type
  Map<String, List<GradeModel>> getGradesByType() {
    final result = <String, List<GradeModel>>{};
    
    for (final grade in grades) {
      if (!result.containsKey(grade.assignmentType)) {
        result[grade.assignmentType] = [];
      }
      result[grade.assignmentType]!.add(grade);
    }
    
    return result;
  }

  // Calculate average by assignment type
  Map<String, double> getAverageByType() {
    final result = <String, double>{};
    final gradesByType = getGradesByType();
    
    gradesByType.forEach((type, typeGrades) {
      double totalPoints = 0.0;
      double maxPoints = 0.0;
      
      for (final grade in typeGrades) {
        totalPoints += grade.score;
        maxPoints += grade.maxScore;
      }
      
      result[type] = maxPoints > 0 ? (totalPoints / maxPoints) * 100 : 0.0;
    });
    
    return result;
  }
}
