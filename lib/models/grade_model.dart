class GradeModel {
  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseName;
  final String teacherId;
  final String teacherName;
  final String academicYear;
  final String term;
  final double score;
  final double maxScore;
  final String letterGrade;
  final String? comments;
  final DateTime gradedDate;
  final String assessmentType; // exam, quiz, assignment, project, etc.
  final double weightage;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime? updatedAt;
  String get title => assessmentType; // Add title getter that returns assessmentType

  GradeModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseName,
    required this.teacherId,
    required this.teacherName,
    required this.academicYear,
    required this.term,
    required this.score,
    required this.maxScore,
    required this.letterGrade,
    this.comments,
    required this.gradedDate,
    required this.assessmentType,
    required this.weightage,
    required this.isPublished,
    required this.createdAt,
    this.updatedAt,
  });

  // Create a GradeModel from a map (e.g., from Firestore)
  factory GradeModel.fromMap(Map<String, dynamic> map, String id) {
    return GradeModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      academicYear: map['academicYear'] ?? '',
      term: map['term'] ?? '',
      score: map['score']?.toDouble() ?? 0.0,
      maxScore: map['maxScore']?.toDouble() ?? 100.0,
      letterGrade: map['letterGrade'] ?? '',
      comments: map['comments'],
      gradedDate: map['gradedDate'] != null 
          ? DateTime.parse(map['gradedDate']) 
          : DateTime.now(),
      assessmentType: map['assessmentType'] ?? '',
      weightage: map['weightage']?.toDouble() ?? 0.0,
      isPublished: map['isPublished'] ?? false,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
    );
  }

  // Convert GradeModel to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'courseName': courseName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'academicYear': academicYear,
      'term': term,
      'score': score,
      'maxScore': maxScore,
      'letterGrade': letterGrade,
      'comments': comments,
      'gradedDate': gradedDate.toIso8601String(),
      'assessmentType': assessmentType,
      'weightage': weightage,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create a copy of GradeModel with some fields changed
  GradeModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? courseId,
    String? courseName,
    String? teacherId,
    String? teacherName,
    String? academicYear,
    String? term,
    double? score,
    double? maxScore,
    String? letterGrade,
    String? comments,
    DateTime? gradedDate,
    String? assessmentType,
    double? weightage,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GradeModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      academicYear: academicYear ?? this.academicYear,
      term: term ?? this.term,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      letterGrade: letterGrade ?? this.letterGrade,
      comments: comments ?? this.comments,
      gradedDate: gradedDate ?? this.gradedDate,
      assessmentType: assessmentType ?? this.assessmentType,
      weightage: weightage ?? this.weightage,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
