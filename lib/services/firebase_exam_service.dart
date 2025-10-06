import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/exam_model.dart';
import '../services/auth_service.dart';
import 'dart:math' as math;

class FirebaseExamService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _examsCollection = 'exams';
  static const String _attemptsCollection = 'exam_attempts';
  static const String _resultsCollection = 'exam_results';

  // Create a new exam
  static Future<String> createExam(ExamModel exam) async {
    try {
      final docRef = await _firestore.collection(_examsCollection).add(exam.toMap());
      debugPrint('✅ Exam created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating exam: $e');
      rethrow;
    }
  }

  // Get all exams
  static Future<List<ExamModel>> getAllExams() async {
    try {
      final querySnapshot = await _firestore
          .collection(_examsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ExamModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting exams: $e');
      return [];
    }
  }

  // Get exams by teacher
  static Future<List<ExamModel>> getExamsByTeacher(String teacherId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_examsCollection)
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ExamModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting teacher exams: $e');
      return [];
    }
  }

  // Get exams by class
  static Future<List<ExamModel>> getExamsByClass(String classId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_examsCollection)
          .where('classId', isEqualTo: classId)
          .orderBy('startTime', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => ExamModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting class exams: $e');
      return [];
    }
  }

  // Get exams for student
  static Future<List<ExamModel>> getExamsForStudent(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_examsCollection)
          .where('eligibleStudents', arrayContains: studentId)
          .orderBy('startTime', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => ExamModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting student exams: $e');
      return [];
    }
  }

  // Get exam by ID
  static Future<ExamModel?> getExamById(String examId) async {
    try {
      final doc = await _firestore.collection(_examsCollection).doc(examId).get();
      
      if (doc.exists) {
        return ExamModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting exam: $e');
      return null;
    }
  }

  // Update exam
  static Future<void> updateExam(String examId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore.collection(_examsCollection).doc(examId).update(updates);
      debugPrint('✅ Exam updated: $examId');
    } catch (e) {
      debugPrint('❌ Error updating exam: $e');
      rethrow;
    }
  }

  // Delete exam
  static Future<void> deleteExam(String examId) async {
    try {
      // Delete exam attempts and results first
      await _deleteExamAttempts(examId);
      await _deleteExamResults(examId);
      
      // Delete the exam
      await _firestore.collection(_examsCollection).doc(examId).delete();
      debugPrint('✅ Exam deleted: $examId');
    } catch (e) {
      debugPrint('❌ Error deleting exam: $e');
      rethrow;
    }
  }

  // Start exam attempt
  static Future<String> startExamAttempt({
    required String examId,
    required String studentId,
    required String studentName,
  }) async {
    try {
      // Check if student is eligible
      final exam = await getExamById(examId);
      if (exam == null) {
        throw Exception('Exam not found');
      }

      if (!exam.eligibleStudents.contains(studentId)) {
        throw Exception('Student not eligible for this exam');
      }

      // Check if exam is active
      if (!exam.isOngoing) {
        throw Exception('Exam is not currently active');
      }

      // Check previous attempts
      final previousAttempts = await getStudentAttempts(examId, studentId);
      if (previousAttempts.length >= exam.maxAttempts) {
        throw Exception('Maximum attempts exceeded');
      }

      // Create new attempt
      final attempt = ExamAttempt(
        id: '', // Will be set by Firestore
        examId: examId,
        studentId: studentId,
        studentName: studentName,
        startTime: DateTime.now(),
        attemptNumber: previousAttempts.length + 1,
      );

      final docRef = await _firestore.collection(_attemptsCollection).add(attempt.toMap());
      debugPrint('✅ Exam attempt started: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error starting exam attempt: $e');
      rethrow;
    }
  }

  // Submit exam attempt
  static Future<ExamResult> submitExamAttempt({
    required String attemptId,
    required Map<String, dynamic> answers,
  }) async {
    try {
      // Get the attempt
      final attemptDoc = await _firestore.collection(_attemptsCollection).doc(attemptId).get();
      if (!attemptDoc.exists) {
        throw Exception('Attempt not found');
      }

      final attempt = ExamAttempt.fromFirestore(attemptDoc);
      final exam = await getExamById(attempt.examId);
      if (exam == null) {
        throw Exception('Exam not found');
      }

      // Calculate score
      final result = await _calculateScore(exam, answers);
      final endTime = DateTime.now();
      final timeSpent = endTime.difference(attempt.startTime);

      // Update attempt
      await _firestore.collection(_attemptsCollection).doc(attemptId).update({
        'endTime': endTime.toIso8601String(),
        'answers': answers,
        'score': result['score'],
        'percentage': result['percentage'],
        'isCompleted': true,
        'isSubmitted': true,
        'timeSpent': timeSpent.inMilliseconds,
      });

      // Create result record
      final examResult = ExamResult(
        id: '', // Will be set by Firestore
        examId: attempt.examId,
        studentId: attempt.studentId,
        studentName: attempt.studentName,
        score: result['score'],
        percentage: result['percentage'],
        grade: _calculateGrade(result['percentage']),
        passed: result['percentage'] >= exam.passingScore,
        completedAt: endTime,
        timeSpent: timeSpent,
        questionResults: result['questionResults'],
      );

      final resultDoc = await _firestore.collection(_resultsCollection).add(examResult.toMap());
      debugPrint('✅ Exam submitted and graded: ${resultDoc.id}');
      
      return examResult.copyWith(id: resultDoc.id);
    } catch (e) {
      debugPrint('❌ Error submitting exam: $e');
      rethrow;
    }
  }

  // Get student attempts for an exam
  static Future<List<ExamAttempt>> getStudentAttempts(String examId, String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_attemptsCollection)
          .where('examId', isEqualTo: examId)
          .where('studentId', isEqualTo: studentId)
          .orderBy('startTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ExamAttempt.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting student attempts: $e');
      return [];
    }
  }

  // Get exam results
  static Future<List<ExamResult>> getExamResults(String examId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_resultsCollection)
          .where('examId', isEqualTo: examId)
          .orderBy('percentage', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ExamResult.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting exam results: $e');
      return [];
    }
  }

  // Get student results
  static Future<List<ExamResult>> getStudentResults(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_resultsCollection)
          .where('studentId', isEqualTo: studentId)
          .orderBy('completedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ExamResult.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting student results: $e');
      return [];
    }
  }

  // Generate exam analytics
  static Future<Map<String, dynamic>> getExamAnalytics(String examId) async {
    try {
      final results = await getExamResults(examId);
      final exam = await getExamById(examId);
      
      if (results.isEmpty || exam == null) {
        return {};
      }

      final scores = results.map((r) => r.percentage).toList();
      final passedCount = results.where((r) => r.passed).length;
      
      return {
        'totalAttempts': results.length,
        'passedCount': passedCount,
        'failedCount': results.length - passedCount,
        'passRate': (passedCount / results.length) * 100,
        'averageScore': scores.reduce((a, b) => a + b) / scores.length,
        'highestScore': scores.reduce(math.max),
        'lowestScore': scores.reduce(math.min),
        'medianScore': _calculateMedian(scores),
        'standardDeviation': _calculateStandardDeviation(scores),
        'gradeDistribution': _calculateGradeDistribution(scores),
        'questionAnalytics': await _getQuestionAnalytics(examId, exam.questions),
      };
    } catch (e) {
      debugPrint('❌ Error generating analytics: $e');
      return {};
    }
  }

  // AI-powered exam generation
  static Future<List<ExamQuestion>> generateAIQuestions({
    required String subject,
    required String topic,
    required int questionCount,
    required QuestionType type,
    String difficulty = 'medium',
  }) async {
    try {
      // Simulate AI generation with sample questions
      final questions = <ExamQuestion>[];
      
      for (int i = 0; i < questionCount; i++) {
        questions.add(ExamQuestion(
          id: 'ai_q_${DateTime.now().millisecondsSinceEpoch}_$i',
          question: _generateSampleQuestion(subject, topic, type, i + 1),
          type: type,
          options: type == QuestionType.multipleChoice 
              ? _generateSampleOptions(subject, topic, i)
              : [],
          correctAnswer: type == QuestionType.multipleChoice ? 'A' : 'Sample answer',
          points: 1.0,
          explanation: 'AI-generated explanation for this question.',
        ));
      }

      debugPrint('✅ AI generated ${questions.length} questions');
      return questions;
    } catch (e) {
      debugPrint('❌ Error generating AI questions: $e');
      return [];
    }
  }

  // Auto-grading service
  static Future<Map<String, dynamic>> autoGradeExam(
    ExamModel exam,
    Map<String, dynamic> studentAnswers,
  ) async {
    try {
      double totalScore = 0.0;
      double maxScore = 0.0;
      final questionResults = <String, dynamic>{};

      for (final question in exam.questions) {
        maxScore += question.points;
        final studentAnswer = studentAnswers[question.id]?.toString().trim().toLowerCase();
        final correctAnswer = question.correctAnswer.trim().toLowerCase();
        
        bool isCorrect = false;
        double questionScore = 0.0;

        switch (question.type) {
          case QuestionType.multipleChoice:
          case QuestionType.trueFalse:
            isCorrect = studentAnswer == correctAnswer;
            questionScore = isCorrect ? question.points : 0.0;
            break;
            
          case QuestionType.fillInTheBlank:
            // Simple string matching (can be enhanced with fuzzy matching)
            isCorrect = studentAnswer == correctAnswer;
            questionScore = isCorrect ? question.points : 0.0;
            break;
            
          case QuestionType.shortAnswer:
            // Basic keyword matching (can be enhanced with NLP)
            final keywords = correctAnswer.split(' ');
            final studentWords = studentAnswer?.split(' ') ?? [];
            final matchCount = keywords.where((k) => studentWords.contains(k)).length;
            final matchRatio = matchCount / keywords.length;
            
            if (matchRatio >= 0.7) {
              isCorrect = true;
              questionScore = question.points;
            } else if (matchRatio >= 0.4) {
              questionScore = question.points * 0.5; // Partial credit
            }
            break;
            
          case QuestionType.essay:
            // For essays, manual grading is typically required
            // This is a placeholder for AI-powered essay grading
            questionScore = question.points * 0.8; // Placeholder score
            break;
            
          case QuestionType.matching:
            // Implementation depends on the matching format
            isCorrect = studentAnswer == correctAnswer;
            questionScore = isCorrect ? question.points : 0.0;
            break;
        }

        totalScore += questionScore;
        questionResults[question.id] = {
          'studentAnswer': studentAnswers[question.id],
          'correctAnswer': question.correctAnswer,
          'isCorrect': isCorrect,
          'score': questionScore,
          'maxScore': question.points,
          'explanation': question.explanation,
        };
      }

      final percentage = maxScore > 0 ? (totalScore / maxScore) * 100 : 0.0;

      return {
        'score': totalScore,
        'maxScore': maxScore,
        'percentage': percentage,
        'questionResults': questionResults,
      };
    } catch (e) {
      debugPrint('❌ Error auto-grading exam: $e');
      rethrow;
    }
  }

  // Private helper methods
  static Future<void> _deleteExamAttempts(String examId) async {
    final attempts = await _firestore
        .collection(_attemptsCollection)
        .where('examId', isEqualTo: examId)
        .get();
    
    for (final doc in attempts.docs) {
      await doc.reference.delete();
    }
  }

  static Future<void> _deleteExamResults(String examId) async {
    final results = await _firestore
        .collection(_resultsCollection)
        .where('examId', isEqualTo: examId)
        .get();
    
    for (final doc in results.docs) {
      await doc.reference.delete();
    }
  }

  static Future<Map<String, dynamic>> _calculateScore(
    ExamModel exam,
    Map<String, dynamic> answers,
  ) async {
    return await autoGradeExam(exam, answers);
  }

  static String _calculateGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 85) return 'A';
    if (percentage >= 80) return 'B+';
    if (percentage >= 75) return 'B';
    if (percentage >= 70) return 'C+';
    if (percentage >= 65) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }

  static double _calculateMedian(List<double> scores) {
    final sorted = List<double>.from(scores)..sort();
    final middle = sorted.length ~/ 2;
    
    if (sorted.length % 2 == 0) {
      return (sorted[middle - 1] + sorted[middle]) / 2;
    } else {
      return sorted[middle];
    }
  }

  static double _calculateStandardDeviation(List<double> scores) {
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final variance = scores.map((s) => math.pow(s - mean, 2)).reduce((a, b) => a + b) / scores.length;
    return math.sqrt(variance);
  }

  static Map<String, int> _calculateGradeDistribution(List<double> scores) {
    final distribution = <String, int>{
      'A+': 0, 'A': 0, 'B+': 0, 'B': 0, 'C+': 0, 'C': 0, 'D': 0, 'F': 0,
    };
    
    for (final score in scores) {
      final grade = _calculateGrade(score);
      distribution[grade] = (distribution[grade] ?? 0) + 1;
    }
    
    return distribution;
  }

  static Future<Map<String, dynamic>> _getQuestionAnalytics(
    String examId,
    List<ExamQuestion> questions,
  ) async {
    // This would analyze how students performed on each question
    // For now, return placeholder data
    return {
      'averageScorePerQuestion': {},
      'mostDifficultQuestions': [],
      'easiestQuestions': [],
    };
  }

  static String _generateSampleQuestion(String subject, String topic, QuestionType type, int number) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'What is the main concept of $topic in $subject? (Question $number)';
      case QuestionType.trueFalse:
        return '$topic is a fundamental concept in $subject. (Question $number)';
      case QuestionType.shortAnswer:
        return 'Explain the importance of $topic in $subject. (Question $number)';
      case QuestionType.essay:
        return 'Write a detailed essay about $topic and its applications in $subject. (Question $number)';
      case QuestionType.fillInTheBlank:
        return 'The main principle of $topic in $subject is _______. (Question $number)';
      case QuestionType.matching:
        return 'Match the following concepts related to $topic in $subject. (Question $number)';
    }
  }

  static List<String> _generateSampleOptions(String subject, String topic, int index) {
    return [
      'Option A: Correct answer for $topic',
      'Option B: Incorrect option',
      'Option C: Another incorrect option',
      'Option D: Final incorrect option',
    ];
  }
}

// Extension for ExamResult to add copyWith method
extension ExamResultExtension on ExamResult {
  ExamResult copyWith({String? id}) {
    return ExamResult(
      id: id ?? this.id,
      examId: examId,
      studentId: studentId,
      studentName: studentName,
      score: score,
      percentage: percentage,
      grade: grade,
      passed: passed,
      completedAt: completedAt,
      timeSpent: timeSpent,
      questionResults: questionResults,
      analytics: analytics,
    );
  }
}
