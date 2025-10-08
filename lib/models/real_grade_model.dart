class RealGradeModel {
  final String id;
  final String studentId;
  final String subjectId;
  final String subjectName;
  final String assessmentType; // quiz, assignment, midterm, final, project
  final String assessmentName;
  final double marksObtained;
  final double totalMarks;
  final double percentage;
  final String letterGrade;
  final double gradePoints;
  final String? teacherId;
  final String? comments;
  final DateTime assessmentDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RealGradeModel({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.subjectName,
    required this.assessmentType,
    required this.assessmentName,
    required this.marksObtained,
    required this.totalMarks,
    required this.percentage,
    required this.letterGrade,
    required this.gradePoints,
    this.teacherId,
    this.comments,
    required this.assessmentDate,
    required this.createdAt,
    this.updatedAt,
  });

  factory RealGradeModel.fromMap(Map<String, dynamic> map, String id) {
    return RealGradeModel(
      id: id,
      studentId: map['studentId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      subjectName: map['subjectName'] ?? '',
      assessmentType: map['assessmentType'] ?? '',
      assessmentName: map['assessmentName'] ?? '',
      marksObtained: (map['marksObtained'] ?? 0).toDouble(),
      totalMarks: (map['totalMarks'] ?? 0).toDouble(),
      percentage: (map['percentage'] ?? 0).toDouble(),
      letterGrade: map['letterGrade'] ?? '',
      gradePoints: (map['gradePoints'] ?? 0).toDouble(),
      teacherId: map['teacherId'],
      comments: map['comments'],
      assessmentDate: DateTime.parse(map['assessmentDate']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'assessmentType': assessmentType,
      'assessmentName': assessmentName,
      'marksObtained': marksObtained,
      'totalMarks': totalMarks,
      'percentage': percentage,
      'letterGrade': letterGrade,
      'gradePoints': gradePoints,
      'teacherId': teacherId,
      'comments': comments,
      'assessmentDate': assessmentDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static String calculateLetterGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 85) return 'A';
    if (percentage >= 80) return 'A-';
    if (percentage >= 75) return 'B+';
    if (percentage >= 70) return 'B';
    if (percentage >= 65) return 'B-';
    if (percentage >= 60) return 'C+';
    if (percentage >= 55) return 'C';
    if (percentage >= 50) return 'C-';
    return 'F';
  }

  static double calculateGradePoints(String letterGrade) {
    switch (letterGrade) {
      case 'A+': return 4.0;
      case 'A': return 3.7;
      case 'A-': return 3.3;
      case 'B+': return 3.0;
      case 'B': return 2.7;
      case 'B-': return 2.3;
      case 'C+': return 2.0;
      case 'C': return 1.7;
      case 'C-': return 1.3;
      case 'F': return 0.0;
      default: return 0.0;
    }
  }
}

class SubjectGradeSummary {
  final String subjectId;
  final String subjectName;
  final List<RealGradeModel> grades;
  final double averagePercentage;
  final String overallLetterGrade;
  final double overallGradePoints;
  final int totalAssessments;

  SubjectGradeSummary({
    required this.subjectId,
    required this.subjectName,
    required this.grades,
    required this.averagePercentage,
    required this.overallLetterGrade,
    required this.overallGradePoints,
    required this.totalAssessments,
  });

  factory SubjectGradeSummary.fromGrades(String subjectId, String subjectName, List<RealGradeModel> grades) {
    final totalAssessments = grades.length;
    final averagePercentage = totalAssessments > 0 
        ? grades.map((g) => g.percentage).reduce((a, b) => a + b) / totalAssessments
        : 0.0;
    
    final overallLetterGrade = RealGradeModel.calculateLetterGrade(averagePercentage);
    final overallGradePoints = RealGradeModel.calculateGradePoints(overallLetterGrade);

    return SubjectGradeSummary(
      subjectId: subjectId,
      subjectName: subjectName,
      grades: grades,
      averagePercentage: averagePercentage,
      overallLetterGrade: overallLetterGrade,
      overallGradePoints: overallGradePoints,
      totalAssessments: totalAssessments,
    );
  }
}

class StudentGPA {
  final String studentId;
  final String term; // semester, quarter, year
  final double gpa;
  final double cgpa; // cumulative GPA
  final List<SubjectGradeSummary> subjects;
  final DateTime calculatedAt;

  StudentGPA({
    required this.studentId,
    required this.term,
    required this.gpa,
    required this.cgpa,
    required this.subjects,
    required this.calculatedAt,
  });

  factory StudentGPA.calculate(String studentId, String term, List<SubjectGradeSummary> subjects) {
    final totalGradePoints = subjects.map((s) => s.overallGradePoints).reduce((a, b) => a + b);
    final totalSubjects = subjects.length;
    final gpa = totalSubjects > 0 ? totalGradePoints / totalSubjects : 0.0;

    return StudentGPA(
      studentId: studentId,
      term: term,
      gpa: gpa,
      cgpa: gpa, // For now, same as GPA - would need historical data for true CGPA
      subjects: subjects,
      calculatedAt: DateTime.now(),
    );
  }
}
