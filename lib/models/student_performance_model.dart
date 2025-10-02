class StudentPerformanceModel {
  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final String subject;
  final String assessmentType; // Quiz, Assignment, Exam, Test
  final double marksObtained;
  final double totalMarks;
  final double percentage;
  final String grade; // A+, A, B+, B, C+, C, D, F
  final DateTime assessmentDate;
  final String teacherId;
  final String teacherName;
  final String semester; // Spring, Fall
  final int academicYear;
  final Map<String, dynamic>? additionalData;

  StudentPerformanceModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.subject,
    required this.assessmentType,
    required this.marksObtained,
    required this.totalMarks,
    required this.percentage,
    required this.grade,
    required this.assessmentDate,
    required this.teacherId,
    required this.teacherName,
    required this.semester,
    required this.academicYear,
    this.additionalData,
  });

  // Calculate grade based on Pakistani grading system
  static String calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C+';
    if (percentage >= 40) return 'C';
    if (percentage >= 33) return 'D';
    return 'F';
  }

  // Calculate GPA based on Pakistani system
  static double calculateGPA(String grade) {
    switch (grade) {
      case 'A+': return 4.0;
      case 'A': return 3.7;
      case 'B+': return 3.3;
      case 'B': return 3.0;
      case 'C+': return 2.7;
      case 'C': return 2.3;
      case 'D': return 2.0;
      case 'F': return 0.0;
      default: return 0.0;
    }
  }

  // Create from map
  factory StudentPerformanceModel.fromMap(Map<String, dynamic> map, String id) {
    return StudentPerformanceModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      className: map['className'] ?? '',
      subject: map['subject'] ?? '',
      assessmentType: map['assessmentType'] ?? '',
      marksObtained: (map['marksObtained'] ?? 0).toDouble(),
      totalMarks: (map['totalMarks'] ?? 0).toDouble(),
      percentage: (map['percentage'] ?? 0).toDouble(),
      grade: map['grade'] ?? 'F',
      assessmentDate: map['assessmentDate'] != null 
          ? DateTime.parse(map['assessmentDate']) 
          : DateTime.now(),
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      semester: map['semester'] ?? 'Spring',
      academicYear: map['academicYear'] ?? DateTime.now().year,
      additionalData: map['additionalData'],
    );
  }

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'className': className,
      'subject': subject,
      'assessmentType': assessmentType,
      'marksObtained': marksObtained,
      'totalMarks': totalMarks,
      'percentage': percentage,
      'grade': grade,
      'assessmentDate': assessmentDate.toIso8601String(),
      'teacherId': teacherId,
      'teacherName': teacherName,
      'semester': semester,
      'academicYear': academicYear,
      'additionalData': additionalData,
    };
  }

  // Copy with modifications
  StudentPerformanceModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? className,
    String? subject,
    String? assessmentType,
    double? marksObtained,
    double? totalMarks,
    double? percentage,
    String? grade,
    DateTime? assessmentDate,
    String? teacherId,
    String? teacherName,
    String? semester,
    int? academicYear,
    Map<String, dynamic>? additionalData,
  }) {
    return StudentPerformanceModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      className: className ?? this.className,
      subject: subject ?? this.subject,
      assessmentType: assessmentType ?? this.assessmentType,
      marksObtained: marksObtained ?? this.marksObtained,
      totalMarks: totalMarks ?? this.totalMarks,
      percentage: percentage ?? this.percentage,
      grade: grade ?? this.grade,
      assessmentDate: assessmentDate ?? this.assessmentDate,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      semester: semester ?? this.semester,
      academicYear: academicYear ?? this.academicYear,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}

// Student Analytics Summary Model
class StudentAnalyticsSummary {
  final String studentId;
  final String studentName;
  final String className;
  final double overallGPA;
  final double overallPercentage;
  final String overallGrade;
  final int totalAssessments;
  final Map<String, double> subjectGPAs;
  final Map<String, String> subjectGrades;
  final Map<String, int> subjectAssessmentCounts;
  final List<StudentPerformanceModel> recentPerformances;
  final Map<String, double> monthlyAverages;
  final String semester;
  final int academicYear;

  StudentAnalyticsSummary({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.overallGPA,
    required this.overallPercentage,
    required this.overallGrade,
    required this.totalAssessments,
    required this.subjectGPAs,
    required this.subjectGrades,
    required this.subjectAssessmentCounts,
    required this.recentPerformances,
    required this.monthlyAverages,
    required this.semester,
    required this.academicYear,
  });

  // Create from performances list
  factory StudentAnalyticsSummary.fromPerformances(
    String studentId,
    String studentName,
    String className,
    List<StudentPerformanceModel> performances,
    String semester,
    int academicYear,
  ) {
    if (performances.isEmpty) {
      return StudentAnalyticsSummary(
        studentId: studentId,
        studentName: studentName,
        className: className,
        overallGPA: 0.0,
        overallPercentage: 0.0,
        overallGrade: 'F',
        totalAssessments: 0,
        subjectGPAs: {},
        subjectGrades: {},
        subjectAssessmentCounts: {},
        recentPerformances: [],
        monthlyAverages: {},
        semester: semester,
        academicYear: academicYear,
      );
    }

    // Calculate overall statistics
    double totalPercentage = 0;
    double totalGPA = 0;
    Map<String, List<double>> subjectPercentages = {};
    Map<String, int> subjectCounts = {};

    for (var performance in performances) {
      totalPercentage += performance.percentage;
      totalGPA += StudentPerformanceModel.calculateGPA(performance.grade);

      // Subject-wise calculations
      if (!subjectPercentages.containsKey(performance.subject)) {
        subjectPercentages[performance.subject] = [];
        subjectCounts[performance.subject] = 0;
      }
      subjectPercentages[performance.subject]!.add(performance.percentage);
      subjectCounts[performance.subject] = subjectCounts[performance.subject]! + 1;
    }

    double overallPercentage = totalPercentage / performances.length;
    double overallGPA = totalGPA / performances.length;
    String overallGrade = StudentPerformanceModel.calculateGrade(overallPercentage);

    // Calculate subject GPAs and grades
    Map<String, double> subjectGPAs = {};
    Map<String, String> subjectGrades = {};
    
    subjectPercentages.forEach((subject, percentages) {
      double avgPercentage = percentages.reduce((a, b) => a + b) / percentages.length;
      subjectGPAs[subject] = StudentPerformanceModel.calculateGPA(
        StudentPerformanceModel.calculateGrade(avgPercentage)
      );
      subjectGrades[subject] = StudentPerformanceModel.calculateGrade(avgPercentage);
    });

    // Calculate monthly averages (last 6 months)
    Map<String, double> monthlyAverages = {};
    DateTime now = DateTime.now();
    for (int i = 0; i < 6; i++) {
      DateTime monthStart = DateTime(now.year, now.month - i, 1);
      DateTime monthEnd = DateTime(now.year, now.month - i + 1, 0);
      
      List<StudentPerformanceModel> monthPerformances = performances.where((p) =>
        p.assessmentDate.isAfter(monthStart) && p.assessmentDate.isBefore(monthEnd)
      ).toList();

      if (monthPerformances.isNotEmpty) {
        double monthAvg = monthPerformances
          .map((p) => p.percentage)
          .reduce((a, b) => a + b) / monthPerformances.length;
        monthlyAverages['${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}'] = monthAvg;
      }
    }

    // Get recent performances (last 10)
    List<StudentPerformanceModel> recentPerformances = List.from(performances)
      ..sort((a, b) => b.assessmentDate.compareTo(a.assessmentDate))
      ..take(10).toList();

    return StudentAnalyticsSummary(
      studentId: studentId,
      studentName: studentName,
      className: className,
      overallGPA: overallGPA,
      overallPercentage: overallPercentage,
      overallGrade: overallGrade,
      totalAssessments: performances.length,
      subjectGPAs: subjectGPAs,
      subjectGrades: subjectGrades,
      subjectAssessmentCounts: subjectCounts,
      recentPerformances: recentPerformances,
      monthlyAverages: monthlyAverages,
      semester: semester,
      academicYear: academicYear,
    );
  }
}
