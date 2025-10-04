import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIGradingService {
  static final AIGradingService _instance = AIGradingService._internal();
  factory AIGradingService() => _instance;
  AIGradingService._internal();

  static const String _gradingHistoryKey = 'ai_grading_history';
  static const String _rubricKey = 'grading_rubrics';

  /// Grade assignment automatically
  Future<GradingResult> gradeAssignment({
    required String assignmentId,
    required String studentAnswer,
    required AssignmentType type,
    required String correctAnswer,
    double? maxScore = 100.0,
    GradingRubric? rubric,
  }) async {
    try {
      final result = await _performGrading(
        assignmentId: assignmentId,
        studentAnswer: studentAnswer,
        type: type,
        correctAnswer: correctAnswer,
        maxScore: maxScore ?? 100.0,
        rubric: rubric,
      );

      await _storeGradingResult(assignmentId, result);
      return result;
    } catch (e) {
      debugPrint('Error grading assignment: $e');
      return GradingResult(
        score: 0.0,
        maxScore: maxScore ?? 100.0,
        feedback: 'Error occurred during grading',
        confidence: 0.0,
        gradingBreakdown: {},
        suggestions: ['Please review manually'],
      );
    }
  }

  /// Grade multiple choice questions
  Future<GradingResult> gradeMultipleChoice({
    required String questionId,
    required List<String> studentAnswers,
    required List<String> correctAnswers,
    double scorePerQuestion = 1.0,
  }) async {
    try {
      int correctCount = 0;
      final breakdown = <String, double>{};
      final feedback = StringBuffer();

      for (int i = 0; i < studentAnswers.length; i++) {
        final isCorrect = i < correctAnswers.length && 
                         studentAnswers[i].toLowerCase() == correctAnswers[i].toLowerCase();
        
        if (isCorrect) {
          correctCount++;
          breakdown['Question ${i + 1}'] = scorePerQuestion;
        } else {
          breakdown['Question ${i + 1}'] = 0.0;
          feedback.writeln('Question ${i + 1}: Incorrect. Correct answer: ${i < correctAnswers.length ? correctAnswers[i] : 'N/A'}');
        }
      }

      final totalScore = correctCount * scorePerQuestion;
      final maxScore = correctAnswers.length * scorePerQuestion;
      final percentage = (totalScore / maxScore) * 100;

      return GradingResult(
        score: totalScore,
        maxScore: maxScore,
        feedback: feedback.toString().trim(),
        confidence: 1.0, // High confidence for objective questions
        gradingBreakdown: breakdown,
        suggestions: percentage >= 80 ? ['Excellent work!'] : ['Review incorrect answers'],
      );
    } catch (e) {
      debugPrint('Error grading multiple choice: $e');
      throw Exception('Failed to grade multiple choice questions');
    }
  }

  /// Grade essay/text responses
  Future<GradingResult> gradeEssay({
    required String essayId,
    required String studentEssay,
    required List<String> keywords,
    required GradingRubric rubric,
  }) async {
    try {
      final breakdown = <String, double>{};
      final feedback = StringBuffer();
      double totalScore = 0.0;

      // Content analysis
      final contentScore = _analyzeContent(studentEssay, keywords);
      breakdown['Content'] = contentScore * (rubric.contentWeight / 100);
      totalScore += breakdown['Content']!;

      // Grammar and structure
      final grammarScore = _analyzeGrammar(studentEssay);
      breakdown['Grammar'] = grammarScore * (rubric.grammarWeight / 100);
      totalScore += breakdown['Grammar']!;

      // Length and completeness
      final lengthScore = _analyzeLength(studentEssay, rubric.minWords, rubric.maxWords);
      breakdown['Length'] = lengthScore * (rubric.lengthWeight / 100);
      totalScore += breakdown['Length']!;

      // Generate feedback
      feedback.writeln('Content Score: ${contentScore.toStringAsFixed(1)}/100');
      feedback.writeln('Grammar Score: ${grammarScore.toStringAsFixed(1)}/100');
      feedback.writeln('Length Score: ${lengthScore.toStringAsFixed(1)}/100');

      return GradingResult(
        score: totalScore,
        maxScore: 100.0,
        feedback: feedback.toString(),
        confidence: 0.75, // Moderate confidence for subjective content
        gradingBreakdown: breakdown,
        suggestions: _generateEssaySuggestions(totalScore),
      );
    } catch (e) {
      debugPrint('Error grading essay: $e');
      throw Exception('Failed to grade essay');
    }
  }

  /// Get grading analytics
  Future<GradingAnalytics> getGradingAnalytics({
    String? teacherId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final history = await _getGradingHistory();
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final filteredResults = history.where((result) =>
        result.timestamp.isAfter(start) && result.timestamp.isBefore(end)
      ).toList();

      final totalGraded = filteredResults.length;
      final averageScore = filteredResults.isNotEmpty
          ? filteredResults.map((r) => r.score / r.maxScore * 100).reduce((a, b) => a + b) / totalGraded
          : 0.0;

      final typeBreakdown = <AssignmentType, int>{};
      for (final result in filteredResults) {
        typeBreakdown[result.type] = (typeBreakdown[result.type] ?? 0) + 1;
      }

      return GradingAnalytics(
        totalGraded: totalGraded,
        averageScore: averageScore,
        typeBreakdown: typeBreakdown,
        period: DateRange(start, end),
      );
    } catch (e) {
      debugPrint('Error getting grading analytics: $e');
      return GradingAnalytics(
        totalGraded: 0,
        averageScore: 0.0,
        typeBreakdown: {},
        period: DateRange(DateTime.now(), DateTime.now()),
      );
    }
  }

  // Private methods
  Future<GradingResult> _performGrading({
    required String assignmentId,
    required String studentAnswer,
    required AssignmentType type,
    required String correctAnswer,
    required double maxScore,
    GradingRubric? rubric,
  }) async {
    switch (type) {
      case AssignmentType.multipleChoice:
        return await gradeMultipleChoice(
          questionId: assignmentId,
          studentAnswers: [studentAnswer],
          correctAnswers: [correctAnswer],
          scorePerQuestion: maxScore,
        );
      
      case AssignmentType.essay:
        return await gradeEssay(
          essayId: assignmentId,
          studentEssay: studentAnswer,
          keywords: correctAnswer.split(','),
          rubric: rubric ?? GradingRubric.defaultRubric(),
        );
      
      case AssignmentType.shortAnswer:
        return _gradeShortAnswer(studentAnswer, correctAnswer, maxScore);
      
      case AssignmentType.math:
        return _gradeMathProblem(studentAnswer, correctAnswer, maxScore);
    }
  }

  GradingResult _gradeShortAnswer(String studentAnswer, String correctAnswer, double maxScore) {
    final similarity = _calculateSimilarity(studentAnswer.toLowerCase(), correctAnswer.toLowerCase());
    final score = similarity * maxScore;
    
    return GradingResult(
      score: score,
      maxScore: maxScore,
      feedback: score >= maxScore * 0.8 ? 'Good answer!' : 'Answer could be improved',
      confidence: 0.8,
      gradingBreakdown: {'Similarity': similarity * 100},
      suggestions: score < maxScore * 0.6 ? ['Review the topic', 'Be more specific'] : ['Well done!'],
    );
  }

  GradingResult _gradeMathProblem(String studentAnswer, String correctAnswer, double maxScore) {
    try {
      final studentNum = double.tryParse(studentAnswer.trim());
      final correctNum = double.tryParse(correctAnswer.trim());
      
      if (studentNum == null || correctNum == null) {
        return GradingResult(
          score: 0.0,
          maxScore: maxScore,
          feedback: 'Invalid number format',
          confidence: 1.0,
          gradingBreakdown: {'Format': 0.0},
          suggestions: ['Check number format'],
        );
      }
      
      final difference = (studentNum - correctNum).abs();
      final tolerance = correctNum.abs() * 0.01; // 1% tolerance
      final isCorrect = difference <= tolerance;
      
      return GradingResult(
        score: isCorrect ? maxScore : 0.0,
        maxScore: maxScore,
        feedback: isCorrect ? 'Correct!' : 'Incorrect. Expected: $correctAnswer',
        confidence: 1.0,
        gradingBreakdown: {'Accuracy': isCorrect ? 100.0 : 0.0},
        suggestions: isCorrect ? ['Excellent!'] : ['Check calculations'],
      );
    } catch (e) {
      return GradingResult(
        score: 0.0,
        maxScore: maxScore,
        feedback: 'Error processing answer',
        confidence: 0.0,
        gradingBreakdown: {},
        suggestions: ['Manual review needed'],
      );
    }
  }

  double _analyzeContent(String essay, List<String> keywords) {
    final lowerEssay = essay.toLowerCase();
    int keywordCount = 0;
    
    for (final keyword in keywords) {
      if (lowerEssay.contains(keyword.toLowerCase())) {
        keywordCount++;
      }
    }
    
    return keywords.isNotEmpty ? (keywordCount / keywords.length) * 100 : 50.0;
  }

  double _analyzeGrammar(String text) {
    // Simple grammar analysis
    final sentences = text.split(RegExp(r'[.!?]')).where((s) => s.trim().isNotEmpty).length;
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    
    if (sentences == 0 || words == 0) return 0.0;
    
    final avgWordsPerSentence = words / sentences;
    final hasCapitalization = RegExp(r'^[A-Z]').hasMatch(text.trim());
    final hasPunctuation = RegExp(r'[.!?]$').hasMatch(text.trim());
    
    double score = 50.0; // Base score
    
    if (avgWordsPerSentence >= 8 && avgWordsPerSentence <= 20) score += 20;
    if (hasCapitalization) score += 15;
    if (hasPunctuation) score += 15;
    
    return score.clamp(0.0, 100.0);
  }

  double _analyzeLength(String text, int minWords, int maxWords) {
    final wordCount = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    
    if (wordCount < minWords) {
      return (wordCount / minWords) * 70; // Penalty for being too short
    } else if (wordCount > maxWords) {
      return 85.0; // Slight penalty for being too long
    } else {
      return 100.0; // Perfect length
    }
  }

  double _calculateSimilarity(String text1, String text2) {
    final words1 = text1.split(RegExp(r'\s+')).toSet();
    final words2 = text2.split(RegExp(r'\s+')).toSet();
    
    final intersection = words1.intersection(words2);
    final union = words1.union(words2);
    
    return union.isNotEmpty ? intersection.length / union.length : 0.0;
  }

  List<String> _generateEssaySuggestions(double score) {
    if (score >= 90) {
      return ['Excellent work!', 'Well structured essay', 'Great use of vocabulary'];
    } else if (score >= 70) {
      return ['Good effort!', 'Consider adding more details', 'Check grammar'];
    } else if (score >= 50) {
      return ['Needs improvement', 'Add more content', 'Review structure'];
    } else {
      return ['Significant revision needed', 'Seek help from teacher', 'Practice writing'];
    }
  }

  Future<void> _storeGradingResult(String assignmentId, GradingResult result) async {
    try {
      final history = await _getGradingHistory();
      history.add(result);
      
      final prefs = await SharedPreferences.getInstance();
      final historyJson = history.map((r) => r.toJson()).toList();
      await prefs.setString(_gradingHistoryKey, jsonEncode(historyJson));
    } catch (e) {
      debugPrint('Error storing grading result: $e');
    }
  }

  Future<List<GradingResult>> _getGradingHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyData = prefs.getString(_gradingHistoryKey);
      
      if (historyData == null) return [];
      
      final historyJson = jsonDecode(historyData) as List;
      return historyJson.map((json) => GradingResult.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting grading history: $e');
      return [];
    }
  }
}

// Data Models
enum AssignmentType { multipleChoice, essay, shortAnswer, math }

class GradingResult {
  final double score;
  final double maxScore;
  final String feedback;
  final double confidence;
  final Map<String, double> gradingBreakdown;
  final List<String> suggestions;
  final DateTime timestamp;
  final AssignmentType type;

  GradingResult({
    required this.score,
    required this.maxScore,
    required this.feedback,
    required this.confidence,
    required this.gradingBreakdown,
    required this.suggestions,
    DateTime? timestamp,
    this.type = AssignmentType.shortAnswer,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'score': score,
    'maxScore': maxScore,
    'feedback': feedback,
    'confidence': confidence,
    'gradingBreakdown': gradingBreakdown,
    'suggestions': suggestions,
    'timestamp': timestamp.toIso8601String(),
    'type': type.toString(),
  };

  factory GradingResult.fromJson(Map<String, dynamic> json) => GradingResult(
    score: json['score'],
    maxScore: json['maxScore'],
    feedback: json['feedback'],
    confidence: json['confidence'],
    gradingBreakdown: Map<String, double>.from(json['gradingBreakdown']),
    suggestions: List<String>.from(json['suggestions']),
    timestamp: DateTime.parse(json['timestamp']),
    type: AssignmentType.values.firstWhere(
      (t) => t.toString() == json['type'],
      orElse: () => AssignmentType.shortAnswer,
    ),
  );
}

class GradingRubric {
  final double contentWeight;
  final double grammarWeight;
  final double lengthWeight;
  final int minWords;
  final int maxWords;

  GradingRubric({
    required this.contentWeight,
    required this.grammarWeight,
    required this.lengthWeight,
    required this.minWords,
    required this.maxWords,
  });

  factory GradingRubric.defaultRubric() => GradingRubric(
    contentWeight: 60.0,
    grammarWeight: 25.0,
    lengthWeight: 15.0,
    minWords: 50,
    maxWords: 500,
  );
}

class GradingAnalytics {
  final int totalGraded;
  final double averageScore;
  final Map<AssignmentType, int> typeBreakdown;
  final DateRange period;

  GradingAnalytics({
    required this.totalGraded,
    required this.averageScore,
    required this.typeBreakdown,
    required this.period,
  });
}

class DateRange {
  final DateTime start;
  final DateTime end;
  DateRange(this.start, this.end);
}
