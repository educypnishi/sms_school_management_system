import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Enum for exam types
enum ExamType {
  quiz,
  midterm,
  final_exam,
  assignment,
  project,
  practical,
}

/// Enum for exam status
enum ExamStatus {
  draft,
  scheduled,
  active,
  completed,
  cancelled,
}

/// Enum for question types
enum QuestionType {
  multipleChoice,
  trueFalse,
  shortAnswer,
  essay,
  fillInTheBlank,
  matching,
}

/// Model for exam questions
class ExamQuestion {
  final String id;
  final String question;
  final QuestionType type;
  final List<String> options; // For multiple choice
  final String correctAnswer;
  final List<String> correctAnswers; // For multiple correct answers
  final double points;
  final String? explanation;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  ExamQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.options = const [],
    this.correctAnswer = '',
    this.correctAnswers = const [],
    required this.points,
    this.explanation,
    this.imageUrl,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'type': type.toString(),
      'options': options,
      'correctAnswer': correctAnswer,
      'correctAnswers': correctAnswers,
      'points': points,
      'explanation': explanation,
      'imageUrl': imageUrl,
      'metadata': metadata,
    };
  }

  factory ExamQuestion.fromMap(Map<String, dynamic> map) {
    return ExamQuestion(
      id: map['id'] ?? '',
      question: map['question'] ?? '',
      type: QuestionType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => QuestionType.multipleChoice,
      ),
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? '',
      correctAnswers: List<String>.from(map['correctAnswers'] ?? []),
      points: (map['points'] ?? 0.0).toDouble(),
      explanation: map['explanation'],
      imageUrl: map['imageUrl'],
      metadata: map['metadata'],
    );
  }

  factory ExamQuestion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExamQuestion.fromMap({...data, 'id': doc.id});
  }
}

/// Model for student exam attempts
class ExamAttempt {
  final String id;
  final String examId;
  final String studentId;
  final String studentName;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, dynamic> answers; // questionId -> answer
  final double? score;
  final double? percentage;
  final bool isCompleted;
  final bool isSubmitted;
  final int attemptNumber;
  final Duration timeSpent;
  final Map<String, dynamic>? metadata;

  ExamAttempt({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.studentName,
    required this.startTime,
    this.endTime,
    this.answers = const {},
    this.score,
    this.percentage,
    this.isCompleted = false,
    this.isSubmitted = false,
    this.attemptNumber = 1,
    this.timeSpent = Duration.zero,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'examId': examId,
      'studentId': studentId,
      'studentName': studentName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'answers': answers,
      'score': score,
      'percentage': percentage,
      'isCompleted': isCompleted,
      'isSubmitted': isSubmitted,
      'attemptNumber': attemptNumber,
      'timeSpent': timeSpent.inMilliseconds,
      'metadata': metadata,
    };
  }

  factory ExamAttempt.fromMap(Map<String, dynamic> map) {
    return ExamAttempt(
      id: map['id'] ?? '',
      examId: map['examId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      answers: Map<String, dynamic>.from(map['answers'] ?? {}),
      score: map['score']?.toDouble(),
      percentage: map['percentage']?.toDouble(),
      isCompleted: map['isCompleted'] ?? false,
      isSubmitted: map['isSubmitted'] ?? false,
      attemptNumber: map['attemptNumber'] ?? 1,
      timeSpent: Duration(milliseconds: map['timeSpent'] ?? 0),
      metadata: map['metadata'],
    );
  }

  factory ExamAttempt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExamAttempt.fromMap({...data, 'id': doc.id});
  }
}

/// Main exam model
class ExamModel {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String classId;
  final String className;
  final String teacherId;
  final String teacherName;
  final ExamType type;
  final ExamStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final double totalPoints;
  final double passingScore;
  final int maxAttempts;
  final bool shuffleQuestions;
  final bool showResultsImmediately;
  final bool allowReview;
  final List<String> eligibleStudents;
  final List<ExamQuestion> questions;
  final Map<String, dynamic>? settings;
  final Map<String, dynamic>? metadata;

  ExamModel({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.classId,
    required this.className,
    required this.teacherId,
    required this.teacherName,
    required this.type,
    this.status = ExamStatus.draft,
    required this.createdAt,
    this.updatedAt,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.totalPoints,
    this.passingScore = 60.0,
    this.maxAttempts = 1,
    this.shuffleQuestions = false,
    this.showResultsImmediately = false,
    this.allowReview = true,
    this.eligibleStudents = const [],
    this.questions = const [],
    this.settings,
    this.metadata,
  });

  // Getters
  bool get isActive => status == ExamStatus.active;
  bool get isCompleted => status == ExamStatus.completed;
  bool get isScheduled => status == ExamStatus.scheduled;
  bool get isDraft => status == ExamStatus.draft;
  
  Duration get duration => Duration(minutes: durationMinutes);
  Duration get timeRemaining => endTime.difference(DateTime.now());
  bool get isOngoing => DateTime.now().isAfter(startTime) && DateTime.now().isBefore(endTime);
  bool get hasStarted => DateTime.now().isAfter(startTime);
  bool get hasEnded => DateTime.now().isAfter(endTime);

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get statusText {
    switch (status) {
      case ExamStatus.draft:
        return 'Draft';
      case ExamStatus.scheduled:
        return 'Scheduled';
      case ExamStatus.active:
        return 'Active';
      case ExamStatus.completed:
        return 'Completed';
      case ExamStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get statusColor {
    switch (status) {
      case ExamStatus.draft:
        return Colors.grey;
      case ExamStatus.scheduled:
        return Colors.blue;
      case ExamStatus.active:
        return Colors.green;
      case ExamStatus.completed:
        return Colors.purple;
      case ExamStatus.cancelled:
        return Colors.red;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subject': subject,
      'classId': classId,
      'className': className,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'type': type.toString(),
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'totalPoints': totalPoints,
      'passingScore': passingScore,
      'maxAttempts': maxAttempts,
      'shuffleQuestions': shuffleQuestions,
      'showResultsImmediately': showResultsImmediately,
      'allowReview': allowReview,
      'eligibleStudents': eligibleStudents,
      'questions': questions.map((q) => q.toMap()).toList(),
      'settings': settings,
      'metadata': metadata,
    };
  }

  factory ExamModel.fromMap(Map<String, dynamic> map) {
    return ExamModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      subject: map['subject'] ?? '',
      classId: map['classId'] ?? '',
      className: map['className'] ?? '',
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      type: ExamType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => ExamType.quiz,
      ),
      status: ExamStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => ExamStatus.draft,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      durationMinutes: map['durationMinutes'] ?? 60,
      totalPoints: (map['totalPoints'] ?? 0.0).toDouble(),
      passingScore: (map['passingScore'] ?? 60.0).toDouble(),
      maxAttempts: map['maxAttempts'] ?? 1,
      shuffleQuestions: map['shuffleQuestions'] ?? false,
      showResultsImmediately: map['showResultsImmediately'] ?? false,
      allowReview: map['allowReview'] ?? true,
      eligibleStudents: List<String>.from(map['eligibleStudents'] ?? []),
      questions: (map['questions'] as List<dynamic>?)
          ?.map((q) => ExamQuestion.fromMap(q))
          .toList() ?? [],
      settings: map['settings'],
      metadata: map['metadata'],
    );
  }

  factory ExamModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExamModel.fromMap({...data, 'id': doc.id});
  }

  ExamModel copyWith({
    String? title,
    String? description,
    String? subject,
    String? classId,
    String? className,
    String? teacherId,
    String? teacherName,
    ExamType? type,
    ExamStatus? status,
    DateTime? updatedAt,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    double? totalPoints,
    double? passingScore,
    int? maxAttempts,
    bool? shuffleQuestions,
    bool? showResultsImmediately,
    bool? allowReview,
    List<String>? eligibleStudents,
    List<ExamQuestion>? questions,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? metadata,
  }) {
    return ExamModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalPoints: totalPoints ?? this.totalPoints,
      passingScore: passingScore ?? this.passingScore,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      showResultsImmediately: showResultsImmediately ?? this.showResultsImmediately,
      allowReview: allowReview ?? this.allowReview,
      eligibleStudents: eligibleStudents ?? this.eligibleStudents,
      questions: questions ?? this.questions,
      settings: settings ?? this.settings,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Model for exam results and analytics
class ExamResult {
  final String id;
  final String examId;
  final String studentId;
  final String studentName;
  final double score;
  final double percentage;
  final String grade;
  final bool passed;
  final DateTime completedAt;
  final Duration timeSpent;
  final Map<String, dynamic> questionResults; // questionId -> result details
  final Map<String, dynamic>? analytics;

  ExamResult({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.studentName,
    required this.score,
    required this.percentage,
    required this.grade,
    required this.passed,
    required this.completedAt,
    required this.timeSpent,
    this.questionResults = const {},
    this.analytics,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'examId': examId,
      'studentId': studentId,
      'studentName': studentName,
      'score': score,
      'percentage': percentage,
      'grade': grade,
      'passed': passed,
      'completedAt': completedAt.toIso8601String(),
      'timeSpent': timeSpent.inMilliseconds,
      'questionResults': questionResults,
      'analytics': analytics,
    };
  }

  factory ExamResult.fromMap(Map<String, dynamic> map) {
    return ExamResult(
      id: map['id'] ?? '',
      examId: map['examId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      score: (map['score'] ?? 0.0).toDouble(),
      percentage: (map['percentage'] ?? 0.0).toDouble(),
      grade: map['grade'] ?? 'F',
      passed: map['passed'] ?? false,
      completedAt: DateTime.parse(map['completedAt']),
      timeSpent: Duration(milliseconds: map['timeSpent'] ?? 0),
      questionResults: Map<String, dynamic>.from(map['questionResults'] ?? {}),
      analytics: map['analytics'],
    );
  }

  factory ExamResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExamResult.fromMap({...data, 'id': doc.id});
  }
}
