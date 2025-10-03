import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class EnhancedExamService {
  // Create exam with online capabilities
  Future<ExamModel> createExam({
    required String title,
    required String subject,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    required int durationMinutes,
    required List<String> eligibleStudents,
    required List<ExamQuestion> questions,
    bool shuffleQuestions = true,
    bool showResultsImmediately = false,
    int maxAttempts = 1,
    double passingScore = 60.0,
  }) async {
    try {
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      final examId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final exam = ExamModel(
        id: examId,
        title: title,
        subject: subject,
        description: description,
        startTime: startTime,
        endTime: endTime,
        durationMinutes: durationMinutes,
        eligibleStudents: eligibleStudents,
        questions: questions,
        shuffleQuestions: shuffleQuestions,
        showResultsImmediately: showResultsImmediately,
        maxAttempts: maxAttempts,
        passingScore: passingScore,
        createdBy: currentUser.id,
        createdByName: currentUser.name,
        createdAt: DateTime.now(),
        status: ExamStatus.draft,
        totalMarks: _calculateTotalMarks(questions),
      );
      
      await _saveExam(exam);
      return exam;
    } catch (e) {
      debugPrint('Error creating exam: $e');
      rethrow;
    }
  }
  
  // Start exam session for student
  Future<ExamSession> startExamSession({
    required String examId,
    required String studentId,
  }) async {
    try {
      final exam = await getExamById(examId);
      if (exam == null) {
        throw Exception('Exam not found');
      }
      
      await _validateExamEligibility(exam, studentId);
      
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      final session = ExamSession(
        id: sessionId,
        examId: examId,
        studentId: studentId,
        startTime: DateTime.now(),
        endTime: DateTime.now().add(Duration(minutes: exam.durationMinutes)),
        questions: exam.shuffleQuestions ? _shuffleQuestions(exam.questions) : exam.questions,
        answers: {},
        status: ExamSessionStatus.inProgress,
        attemptNumber: 1,
      );
      
      await _saveExamSession(session);
      return session;
    } catch (e) {
      debugPrint('Error starting exam session: $e');
      rethrow;
    }
  }
  
  // Submit exam and calculate results
  Future<ExamResult> submitExam(String sessionId) async {
    try {
      final session = await getExamSession(sessionId);
      if (session == null) {
        throw Exception('Exam session not found');
      }
      
      final exam = await getExamById(session.examId);
      if (exam == null) {
        throw Exception('Exam not found');
      }
      
      final completedSession = session.copyWith(
        status: ExamSessionStatus.completed,
        submittedAt: DateTime.now(),
      );
      await _saveExamSession(completedSession);
      
      final result = await _calculateExamResult(exam, completedSession);
      await _saveExamResult(result);
      
      return result;
    } catch (e) {
      debugPrint('Error submitting exam: $e');
      rethrow;
    }
  }
  
  // Get exam analytics
  Future<Map<String, dynamic>> getExamAnalytics(String examId) async {
    try {
      final results = await _getExamResults(examId);
      
      if (results.isEmpty) {
        return {'totalStudents': 0, 'completedStudents': 0, 'averageScore': 0.0};
      }
      
      final scores = results.map((r) => r.scorePercentage).toList();
      
      return {
        'completedStudents': results.length,
        'averageScore': scores.reduce((a, b) => a + b) / scores.length,
        'highestScore': scores.reduce(math.max),
        'lowestScore': scores.reduce(math.min),
      };
    } catch (e) {
      debugPrint('Error getting exam analytics: $e');
      return {};
    }
  }
  
  // Helper methods
  Future<ExamModel?> getExamById(String examId) async {
    final prefs = await SharedPreferences.getInstance();
    final examJson = prefs.getString('exam_$examId');
    if (examJson == null) return null;
    
    final examMap = jsonDecode(examJson) as Map<String, dynamic>;
    return ExamModel.fromMap(examMap, examId);
  }
  
  Future<ExamSession?> getExamSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString('exam_session_$sessionId');
    if (sessionJson == null) return null;
    
    final sessionMap = jsonDecode(sessionJson) as Map<String, dynamic>;
    return ExamSession.fromMap(sessionMap, sessionId);
  }
  
  Future<void> _saveExam(ExamModel exam) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('exam_${exam.id}', jsonEncode(exam.toMap()));
  }
  
  Future<void> _saveExamSession(ExamSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('exam_session_${session.id}', jsonEncode(session.toMap()));
  }
  
  Future<void> _saveExamResult(ExamResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('exam_result_${result.sessionId}', jsonEncode(result.toMap()));
  }
  
  double _calculateTotalMarks(List<ExamQuestion> questions) {
    return questions.fold(0.0, (sum, question) => sum + question.marks);
  }
  
  List<ExamQuestion> _shuffleQuestions(List<ExamQuestion> questions) {
    final shuffled = List<ExamQuestion>.from(questions);
    shuffled.shuffle();
    return shuffled;
  }
  
  Future<void> _validateExamEligibility(ExamModel exam, String studentId) async {
    if (exam.status != ExamStatus.published) {
      throw Exception('Exam is not available');
    }
    if (!exam.eligibleStudents.contains(studentId)) {
      throw Exception('You are not eligible for this exam');
    }
    if (DateTime.now().isBefore(exam.startTime)) {
      throw Exception('Exam has not started yet');
    }
    if (DateTime.now().isAfter(exam.endTime)) {
      throw Exception('Exam has ended');
    }
  }
  
  Future<ExamResult> _calculateExamResult(ExamModel exam, ExamSession session) async {
    double totalMarks = 0;
    double obtainedMarks = 0;
    
    for (final question in exam.questions) {
      totalMarks += question.marks;
      final studentAnswer = session.answers[question.id]?['answer'];
      final isCorrect = _checkAnswer(question, studentAnswer);
      if (isCorrect) obtainedMarks += question.marks;
    }
    
    final scorePercentage = totalMarks > 0 ? (obtainedMarks / totalMarks) * 100 : 0.0;
    
    return ExamResult(
      sessionId: session.id,
      examId: exam.id,
      studentId: session.studentId,
      totalMarks: totalMarks,
      obtainedMarks: obtainedMarks,
      scorePercentage: scorePercentage,
      isPassed: scorePercentage >= exam.passingScore,
      completedAt: DateTime.now(),
      timeTaken: session.submittedAt!.difference(session.startTime).inMinutes,
    );
  }
  
  bool _checkAnswer(ExamQuestion question, dynamic studentAnswer) {
    if (studentAnswer == null) return false;
    return studentAnswer == question.correctAnswer;
  }
  
  Future<List<ExamResult>> _getExamResults(String examId) async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final resultKeys = allKeys.where((key) => key.startsWith('exam_result_')).toList();
    
    final results = <ExamResult>[];
    for (final key in resultKeys) {
      final resultJson = prefs.getString(key);
      if (resultJson != null) {
        final resultMap = jsonDecode(resultJson) as Map<String, dynamic>;
        final result = ExamResult.fromMap(resultMap, key.substring('exam_result_'.length));
        if (result.examId == examId) results.add(result);
      }
    }
    return results;
  }
}

// Models
class ExamModel {
  final String id;
  final String title;
  final String subject;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final List<String> eligibleStudents;
  final List<ExamQuestion> questions;
  final bool shuffleQuestions;
  final bool showResultsImmediately;
  final int maxAttempts;
  final double passingScore;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final ExamStatus status;
  final double totalMarks;
  
  ExamModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.eligibleStudents,
    required this.questions,
    required this.shuffleQuestions,
    required this.showResultsImmediately,
    required this.maxAttempts,
    required this.passingScore,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.status,
    required this.totalMarks,
  });
  
  factory ExamModel.fromMap(Map<String, dynamic> map, String id) {
    return ExamModel(
      id: id,
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      description: map['description'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      durationMinutes: map['durationMinutes'] ?? 60,
      eligibleStudents: List<String>.from(map['eligibleStudents'] ?? []),
      questions: (map['questions'] as List?)?.map((q) => ExamQuestion.fromMap(q, q['id'])).toList() ?? [],
      shuffleQuestions: map['shuffleQuestions'] ?? true,
      showResultsImmediately: map['showResultsImmediately'] ?? false,
      maxAttempts: map['maxAttempts'] ?? 1,
      passingScore: map['passingScore']?.toDouble() ?? 60.0,
      createdBy: map['createdBy'] ?? '',
      createdByName: map['createdByName'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      status: ExamStatus.values.firstWhere(
        (s) => s.toString().split('.').last == map['status'],
        orElse: () => ExamStatus.draft,
      ),
      totalMarks: map['totalMarks']?.toDouble() ?? 0.0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subject': subject,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'eligibleStudents': eligibleStudents,
      'questions': questions.map((q) => q.toMap()).toList(),
      'shuffleQuestions': shuffleQuestions,
      'showResultsImmediately': showResultsImmediately,
      'maxAttempts': maxAttempts,
      'passingScore': passingScore,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'totalMarks': totalMarks,
    };
  }
  
  ExamModel copyWith({ExamStatus? status}) {
    return ExamModel(
      id: id,
      title: title,
      subject: subject,
      description: description,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      eligibleStudents: eligibleStudents,
      questions: questions,
      shuffleQuestions: shuffleQuestions,
      showResultsImmediately: showResultsImmediately,
      maxAttempts: maxAttempts,
      passingScore: passingScore,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
      status: status ?? this.status,
      totalMarks: totalMarks,
    );
  }
}

class ExamQuestion {
  final String id;
  final String questionText;
  final QuestionType type;
  final List<String> options;
  final dynamic correctAnswer;
  final double marks;
  final String? explanation;
  
  ExamQuestion({
    required this.id,
    required this.questionText,
    required this.type,
    required this.options,
    required this.correctAnswer,
    required this.marks,
    this.explanation,
  });
  
  factory ExamQuestion.fromMap(Map<String, dynamic> map, String id) {
    return ExamQuestion(
      id: id,
      questionText: map['questionText'] ?? '',
      type: QuestionType.values.firstWhere(
        (t) => t.toString().split('.').last == map['type'],
        orElse: () => QuestionType.multipleChoice,
      ),
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'],
      marks: map['marks']?.toDouble() ?? 1.0,
      explanation: map['explanation'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionText': questionText,
      'type': type.toString().split('.').last,
      'options': options,
      'correctAnswer': correctAnswer,
      'marks': marks,
      'explanation': explanation,
    };
  }
}

class ExamSession {
  final String id;
  final String examId;
  final String studentId;
  final DateTime startTime;
  final DateTime endTime;
  final List<ExamQuestion> questions;
  final Map<String, dynamic> answers;
  final ExamSessionStatus status;
  final int attemptNumber;
  final DateTime? submittedAt;
  
  ExamSession({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.startTime,
    required this.endTime,
    required this.questions,
    required this.answers,
    required this.status,
    required this.attemptNumber,
    this.submittedAt,
  });
  
  factory ExamSession.fromMap(Map<String, dynamic> map, String id) {
    return ExamSession(
      id: id,
      examId: map['examId'] ?? '',
      studentId: map['studentId'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      questions: (map['questions'] as List?)?.map((q) => ExamQuestion.fromMap(q, q['id'])).toList() ?? [],
      answers: Map<String, dynamic>.from(map['answers'] ?? {}),
      status: ExamSessionStatus.values.firstWhere(
        (s) => s.toString().split('.').last == map['status'],
        orElse: () => ExamSessionStatus.inProgress,
      ),
      attemptNumber: map['attemptNumber'] ?? 1,
      submittedAt: map['submittedAt'] != null ? DateTime.parse(map['submittedAt']) : null,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'examId': examId,
      'studentId': studentId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'questions': questions.map((q) => q.toMap()).toList(),
      'answers': answers,
      'status': status.toString().split('.').last,
      'attemptNumber': attemptNumber,
      'submittedAt': submittedAt?.toIso8601String(),
    };
  }
  
  ExamSession copyWith({
    ExamSessionStatus? status,
    DateTime? submittedAt,
  }) {
    return ExamSession(
      id: id,
      examId: examId,
      studentId: studentId,
      startTime: startTime,
      endTime: endTime,
      questions: questions,
      answers: answers,
      status: status ?? this.status,
      attemptNumber: attemptNumber,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
}

class ExamResult {
  final String sessionId;
  final String examId;
  final String studentId;
  final double totalMarks;
  final double obtainedMarks;
  final double scorePercentage;
  final bool isPassed;
  final DateTime completedAt;
  final int timeTaken;
  
  ExamResult({
    required this.sessionId,
    required this.examId,
    required this.studentId,
    required this.totalMarks,
    required this.obtainedMarks,
    required this.scorePercentage,
    required this.isPassed,
    required this.completedAt,
    required this.timeTaken,
  });
  
  factory ExamResult.fromMap(Map<String, dynamic> map, String sessionId) {
    return ExamResult(
      sessionId: sessionId,
      examId: map['examId'] ?? '',
      studentId: map['studentId'] ?? '',
      totalMarks: map['totalMarks']?.toDouble() ?? 0.0,
      obtainedMarks: map['obtainedMarks']?.toDouble() ?? 0.0,
      scorePercentage: map['scorePercentage']?.toDouble() ?? 0.0,
      isPassed: map['isPassed'] ?? false,
      completedAt: DateTime.parse(map['completedAt']),
      timeTaken: map['timeTaken'] ?? 0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'examId': examId,
      'studentId': studentId,
      'totalMarks': totalMarks,
      'obtainedMarks': obtainedMarks,
      'scorePercentage': scorePercentage,
      'isPassed': isPassed,
      'completedAt': completedAt.toIso8601String(),
      'timeTaken': timeTaken,
    };
  }
}

enum ExamStatus { draft, published, completed, archived }
enum ExamSessionStatus { inProgress, completed, expired }
enum QuestionType { multipleChoice, trueFalse, shortAnswer, essay }
