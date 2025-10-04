import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIPredictiveAnalyticsService {
  static final AIPredictiveAnalyticsService _instance = AIPredictiveAnalyticsService._internal();
  factory AIPredictiveAnalyticsService() => _instance;
  AIPredictiveAnalyticsService._internal();

  static const String _analyticsDataKey = 'predictive_analytics_data';
  static const String _predictionsKey = 'student_predictions';

  /// Predict student performance based on historical data
  Future<PerformancePrediction> predictStudentPerformance({
    required String studentId,
    required List<StudentDataPoint> historicalData,
    int futureDays = 30,
  }) async {
    try {
      if (historicalData.length < 3) {
        return PerformancePrediction(
          studentId: studentId,
          predictedGrade: 0.0,
          confidence: 0.0,
          riskLevel: RiskLevel.unknown,
          recommendations: ['Insufficient data for prediction'],
          factors: {},
        );
      }

      // Analyze trends
      final trends = _analyzeTrends(historicalData);
      
      // Calculate weighted prediction
      final prediction = _calculatePrediction(historicalData, trends);
      
      // Determine risk level
      final riskLevel = _assessRiskLevel(prediction, trends);
      
      // Generate recommendations
      final recommendations = _generateRecommendations(prediction, trends, riskLevel);
      
      // Identify key factors
      final factors = _identifyKeyFactors(historicalData, trends);

      final result = PerformancePrediction(
        studentId: studentId,
        predictedGrade: prediction,
        confidence: _calculateConfidence(historicalData, trends),
        riskLevel: riskLevel,
        recommendations: recommendations,
        factors: factors,
        predictionDate: DateTime.now(),
        targetDate: DateTime.now().add(Duration(days: futureDays)),
      );

      await _storePrediction(result);
      return result;
    } catch (e) {
      debugPrint('Error predicting student performance: $e');
      return PerformancePrediction(
        studentId: studentId,
        predictedGrade: 0.0,
        confidence: 0.0,
        riskLevel: RiskLevel.unknown,
        recommendations: ['Error in prediction analysis'],
        factors: {},
      );
    }
  }

  /// Predict class-wide performance trends
  Future<ClassPrediction> predictClassPerformance({
    required String classId,
    required List<StudentDataPoint> classData,
    int futureDays = 30,
  }) async {
    try {
      final studentGroups = <String, List<StudentDataPoint>>{};
      
      // Group data by student
      for (final dataPoint in classData) {
        studentGroups.putIfAbsent(dataPoint.studentId, () => []).add(dataPoint);
      }

      final studentPredictions = <PerformancePrediction>[];
      
      // Predict for each student
      for (final entry in studentGroups.entries) {
        final prediction = await predictStudentPerformance(
          studentId: entry.key,
          historicalData: entry.value,
          futureDays: futureDays,
        );
        studentPredictions.add(prediction);
      }

      // Analyze class trends
      final classAverage = studentPredictions.isNotEmpty
          ? studentPredictions.map((p) => p.predictedGrade).reduce((a, b) => a + b) / studentPredictions.length
          : 0.0;

      final riskDistribution = <RiskLevel, int>{};
      for (final prediction in studentPredictions) {
        riskDistribution[prediction.riskLevel] = (riskDistribution[prediction.riskLevel] ?? 0) + 1;
      }

      final atRiskStudents = studentPredictions.where((p) => 
        p.riskLevel == RiskLevel.high || p.riskLevel == RiskLevel.critical
      ).toList();

      return ClassPrediction(
        classId: classId,
        predictedAverage: classAverage,
        studentPredictions: studentPredictions,
        riskDistribution: riskDistribution,
        atRiskStudents: atRiskStudents,
        classRecommendations: _generateClassRecommendations(studentPredictions, classAverage),
        predictionDate: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error predicting class performance: $e');
      return ClassPrediction(
        classId: classId,
        predictedAverage: 0.0,
        studentPredictions: [],
        riskDistribution: {},
        atRiskStudents: [],
        classRecommendations: ['Error in class prediction analysis'],
        predictionDate: DateTime.now(),
      );
    }
  }

  /// Identify students at risk of dropping out
  Future<List<AtRiskStudent>> identifyAtRiskStudents({
    required List<StudentDataPoint> allStudentData,
  }) async {
    try {
      final studentGroups = <String, List<StudentDataPoint>>{};
      
      // Group data by student
      for (final dataPoint in allStudentData) {
        studentGroups.putIfAbsent(dataPoint.studentId, () => []).add(dataPoint);
      }

      final atRiskStudents = <AtRiskStudent>[];

      for (final entry in studentGroups.entries) {
        final studentData = entry.value;
        final riskFactors = _analyzeRiskFactors(studentData);
        final riskScore = _calculateRiskScore(riskFactors);

        if (riskScore >= 0.6) { // High risk threshold
          atRiskStudents.add(AtRiskStudent(
            studentId: entry.key,
            riskScore: riskScore,
            riskFactors: riskFactors,
            interventions: _suggestInterventions(riskFactors),
            urgency: riskScore >= 0.8 ? InterventionUrgency.immediate : InterventionUrgency.soon,
          ));
        }
      }

      // Sort by risk score (highest first)
      atRiskStudents.sort((a, b) => b.riskScore.compareTo(a.riskScore));

      return atRiskStudents;
    } catch (e) {
      debugPrint('Error identifying at-risk students: $e');
      return [];
    }
  }

  /// Generate learning path recommendations
  Future<LearningPathRecommendation> generateLearningPath({
    required String studentId,
    required List<StudentDataPoint> performanceData,
    required List<String> subjects,
  }) async {
    try {
      final subjectPerformance = <String, double>{};
      final weakAreas = <String>[];
      final strongAreas = <String>[];

      // Analyze performance by subject
      for (final subject in subjects) {
        final subjectData = performanceData.where((d) => d.subject == subject).toList();
        if (subjectData.isNotEmpty) {
          final avgScore = subjectData.map((d) => d.grade).reduce((a, b) => a + b) / subjectData.length;
          subjectPerformance[subject] = avgScore;

          if (avgScore < 60) {
            weakAreas.add(subject);
          } else if (avgScore >= 80) {
            strongAreas.add(subject);
          }
        }
      }

      // Generate personalized recommendations
      final recommendations = _generateLearningRecommendations(subjectPerformance, weakAreas, strongAreas);
      
      // Suggest study schedule
      final studySchedule = _generateStudySchedule(weakAreas, strongAreas);

      return LearningPathRecommendation(
        studentId: studentId,
        subjectPerformance: subjectPerformance,
        weakAreas: weakAreas,
        strongAreas: strongAreas,
        recommendations: recommendations,
        studySchedule: studySchedule,
        estimatedImprovementTime: _estimateImprovementTime(weakAreas.length),
      );
    } catch (e) {
      debugPrint('Error generating learning path: $e');
      return LearningPathRecommendation(
        studentId: studentId,
        subjectPerformance: {},
        weakAreas: [],
        strongAreas: [],
        recommendations: ['Error generating recommendations'],
        studySchedule: {},
        estimatedImprovementTime: 0,
      );
    }
  }

  /// Get predictive analytics dashboard data
  Future<AnalyticsDashboard> getAnalyticsDashboard({
    String? classId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final predictions = await _getAllPredictions();
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final filteredPredictions = predictions.where((p) =>
        p.predictionDate.isAfter(start) && p.predictionDate.isBefore(end)
      ).toList();

      final totalStudents = filteredPredictions.length;
      final averagePredictedGrade = filteredPredictions.isNotEmpty
          ? filteredPredictions.map((p) => p.predictedGrade).reduce((a, b) => a + b) / totalStudents
          : 0.0;

      final riskDistribution = <RiskLevel, int>{};
      for (final prediction in filteredPredictions) {
        riskDistribution[prediction.riskLevel] = (riskDistribution[prediction.riskLevel] ?? 0) + 1;
      }

      final topRiskFactors = _calculateTopRiskFactors(filteredPredictions);
      
      return AnalyticsDashboard(
        totalStudents: totalStudents,
        averagePredictedGrade: averagePredictedGrade,
        riskDistribution: riskDistribution,
        topRiskFactors: topRiskFactors,
        predictionAccuracy: _calculatePredictionAccuracy(filteredPredictions),
        period: DateRange(start, end),
      );
    } catch (e) {
      debugPrint('Error getting analytics dashboard: $e');
      return AnalyticsDashboard(
        totalStudents: 0,
        averagePredictedGrade: 0.0,
        riskDistribution: {},
        topRiskFactors: {},
        predictionAccuracy: 0.0,
        period: DateRange(DateTime.now(), DateTime.now()),
      );
    }
  }

  // Private helper methods

  TrendAnalysis _analyzeTrends(List<StudentDataPoint> data) {
    data.sort((a, b) => a.date.compareTo(b.date));
    
    final grades = data.map((d) => d.grade).toList();
    final attendance = data.map((d) => d.attendanceRate).toList();
    
    return TrendAnalysis(
      gradeTrend: _calculateTrend(grades),
      attendanceTrend: _calculateTrend(attendance),
      recentPerformance: grades.isNotEmpty ? grades.last : 0.0,
      consistency: _calculateConsistency(grades),
    );
  }

  double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0.0;
    
    double sum = 0.0;
    for (int i = 1; i < values.length; i++) {
      sum += values[i] - values[i - 1];
    }
    return sum / (values.length - 1);
  }

  double _calculateConsistency(List<double> values) {
    if (values.length < 2) return 1.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    final standardDeviation = sqrt(variance);
    
    return 1.0 - (standardDeviation / 100.0).clamp(0.0, 1.0);
  }

  double _calculatePrediction(List<StudentDataPoint> data, TrendAnalysis trends) {
    final recentGrades = data.length >= 3 ? data.sublist(data.length - 3) : data;
    final weightedAverage = recentGrades.isNotEmpty
        ? recentGrades.map((d) => d.grade).reduce((a, b) => a + b) / recentGrades.length
        : 0.0;
    
    // Apply trend adjustment
    final trendAdjustment = trends.gradeTrend * 2; // Amplify trend effect
    final prediction = (weightedAverage + trendAdjustment).clamp(0.0, 100.0);
    
    return prediction;
  }

  RiskLevel _assessRiskLevel(double prediction, TrendAnalysis trends) {
    if (prediction < 40 || trends.gradeTrend < -5) {
      return RiskLevel.critical;
    } else if (prediction < 60 || trends.gradeTrend < -2) {
      return RiskLevel.high;
    } else if (prediction < 75 || trends.gradeTrend < 0) {
      return RiskLevel.medium;
    } else {
      return RiskLevel.low;
    }
  }

  double _calculateConfidence(List<StudentDataPoint> data, TrendAnalysis trends) {
    double confidence = 0.5; // Base confidence
    
    // More data points increase confidence
    confidence += (data.length / 10.0).clamp(0.0, 0.3);
    
    // Consistency increases confidence
    confidence += trends.consistency * 0.2;
    
    return confidence.clamp(0.0, 1.0);
  }

  List<String> _generateRecommendations(double prediction, TrendAnalysis trends, RiskLevel riskLevel) {
    final recommendations = <String>[];
    
    switch (riskLevel) {
      case RiskLevel.critical:
        recommendations.addAll([
          'Immediate intervention required',
          'Schedule parent-teacher meeting',
          'Consider additional tutoring',
          'Review learning disabilities assessment',
        ]);
        break;
      case RiskLevel.high:
        recommendations.addAll([
          'Increase monitoring and support',
          'Provide additional practice materials',
          'Consider peer tutoring',
          'Schedule regular check-ins',
        ]);
        break;
      case RiskLevel.medium:
        recommendations.addAll([
          'Monitor progress closely',
          'Provide targeted practice',
          'Encourage consistent study habits',
        ]);
        break;
      case RiskLevel.low:
        recommendations.addAll([
          'Continue current approach',
          'Consider advanced challenges',
          'Maintain good study habits',
        ]);
        break;
      case RiskLevel.unknown:
        recommendations.add('Collect more data for analysis');
        break;
    }
    
    if (trends.gradeTrend < 0) {
      recommendations.add('Address declining performance trend');
    }
    
    return recommendations;
  }

  Map<String, double> _identifyKeyFactors(List<StudentDataPoint> data, TrendAnalysis trends) {
    final factors = <String, double>{};
    
    // Attendance factor
    final avgAttendance = data.map((d) => d.attendanceRate).reduce((a, b) => a + b) / data.length;
    factors['Attendance'] = avgAttendance;
    
    // Assignment completion factor
    final avgAssignments = data.map((d) => d.assignmentCompletion).reduce((a, b) => a + b) / data.length;
    factors['Assignment Completion'] = avgAssignments;
    
    // Consistency factor
    factors['Performance Consistency'] = trends.consistency * 100;
    
    // Trend factor
    factors['Performance Trend'] = (trends.gradeTrend + 10) * 5; // Normalize to 0-100
    
    return factors;
  }

  Map<String, double> _analyzeRiskFactors(List<StudentDataPoint> data) {
    final factors = <String, double>{};
    
    if (data.isEmpty) return factors;
    
    final avgGrade = data.map((d) => d.grade).reduce((a, b) => a + b) / data.length;
    final avgAttendance = data.map((d) => d.attendanceRate).reduce((a, b) => a + b) / data.length;
    final avgAssignments = data.map((d) => d.assignmentCompletion).reduce((a, b) => a + b) / data.length;
    
    factors['Low Grades'] = avgGrade < 60 ? 1.0 : 0.0;
    factors['Poor Attendance'] = avgAttendance < 75 ? 1.0 : 0.0;
    factors['Incomplete Assignments'] = avgAssignments < 80 ? 1.0 : 0.0;
    factors['Declining Performance'] = _calculateTrend(data.map((d) => d.grade).toList()) < -2 ? 1.0 : 0.0;
    
    return factors;
  }

  double _calculateRiskScore(Map<String, double> riskFactors) {
    if (riskFactors.isEmpty) return 0.0;
    return riskFactors.values.reduce((a, b) => a + b) / riskFactors.length;
  }

  List<String> _suggestInterventions(Map<String, double> riskFactors) {
    final interventions = <String>[];
    
    if (riskFactors['Low Grades'] == 1.0) {
      interventions.add('Provide academic tutoring');
    }
    if (riskFactors['Poor Attendance'] == 1.0) {
      interventions.add('Address attendance issues');
    }
    if (riskFactors['Incomplete Assignments'] == 1.0) {
      interventions.add('Implement assignment tracking system');
    }
    if (riskFactors['Declining Performance'] == 1.0) {
      interventions.add('Investigate causes of performance decline');
    }
    
    return interventions;
  }

  List<String> _generateLearningRecommendations(
    Map<String, double> subjectPerformance,
    List<String> weakAreas,
    List<String> strongAreas,
  ) {
    final recommendations = <String>[];
    
    if (weakAreas.isNotEmpty) {
      recommendations.add('Focus on improving: ${weakAreas.join(', ')}');
      recommendations.add('Allocate 60% of study time to weak subjects');
    }
    
    if (strongAreas.isNotEmpty) {
      recommendations.add('Maintain excellence in: ${strongAreas.join(', ')}');
      recommendations.add('Use strong subjects to boost confidence');
    }
    
    recommendations.add('Practice regularly with short, focused sessions');
    recommendations.add('Seek help from teachers for difficult topics');
    
    return recommendations;
  }

  Map<String, int> _generateStudySchedule(List<String> weakAreas, List<String> strongAreas) {
    final schedule = <String, int>{}; // Subject -> minutes per day
    
    for (final subject in weakAreas) {
      schedule[subject] = 45; // 45 minutes for weak subjects
    }
    
    for (final subject in strongAreas) {
      schedule[subject] = 20; // 20 minutes for strong subjects
    }
    
    return schedule;
  }

  int _estimateImprovementTime(int weakAreasCount) {
    return weakAreasCount * 4; // 4 weeks per weak area
  }

  List<String> _generateClassRecommendations(List<PerformancePrediction> predictions, double classAverage) {
    final recommendations = <String>[];
    
    final atRiskCount = predictions.where((p) => 
      p.riskLevel == RiskLevel.high || p.riskLevel == RiskLevel.critical
    ).length;
    
    if (classAverage < 70) {
      recommendations.add('Class average below target - review teaching methods');
    }
    
    if (atRiskCount > predictions.length * 0.2) {
      recommendations.add('High number of at-risk students - implement class-wide interventions');
    }
    
    recommendations.add('Provide differentiated instruction based on individual needs');
    
    return recommendations;
  }

  Map<String, int> _calculateTopRiskFactors(List<PerformancePrediction> predictions) {
    final factorCounts = <String, int>{};
    
    for (final prediction in predictions) {
      for (final factor in prediction.factors.keys) {
        if (prediction.factors[factor]! < 60) { // Below threshold
          factorCounts[factor] = (factorCounts[factor] ?? 0) + 1;
        }
      }
    }
    
    return factorCounts;
  }

  double _calculatePredictionAccuracy(List<PerformancePrediction> predictions) {
    // Simplified accuracy calculation
    final confidenceSum = predictions.map((p) => p.confidence).reduce((a, b) => a + b);
    return predictions.isNotEmpty ? confidenceSum / predictions.length : 0.0;
  }

  Future<void> _storePrediction(PerformancePrediction prediction) async {
    try {
      final predictions = await _getAllPredictions();
      predictions.add(prediction);
      
      final prefs = await SharedPreferences.getInstance();
      final predictionsJson = predictions.map((p) => p.toJson()).toList();
      await prefs.setString(_predictionsKey, jsonEncode(predictionsJson));
    } catch (e) {
      debugPrint('Error storing prediction: $e');
    }
  }

  Future<List<PerformancePrediction>> _getAllPredictions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final predictionsData = prefs.getString(_predictionsKey);
      
      if (predictionsData == null) return [];
      
      final predictionsJson = jsonDecode(predictionsData) as List;
      return predictionsJson.map((json) => PerformancePrediction.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting all predictions: $e');
      return [];
    }
  }
}

// Data Models and Enums

enum RiskLevel { low, medium, high, critical, unknown }
enum InterventionUrgency { immediate, soon, monitor }

class StudentDataPoint {
  final String studentId;
  final String subject;
  final double grade;
  final double attendanceRate;
  final double assignmentCompletion;
  final DateTime date;

  StudentDataPoint({
    required this.studentId,
    required this.subject,
    required this.grade,
    required this.attendanceRate,
    required this.assignmentCompletion,
    required this.date,
  });
}

class TrendAnalysis {
  final double gradeTrend;
  final double attendanceTrend;
  final double recentPerformance;
  final double consistency;

  TrendAnalysis({
    required this.gradeTrend,
    required this.attendanceTrend,
    required this.recentPerformance,
    required this.consistency,
  });
}

class PerformancePrediction {
  final String studentId;
  final double predictedGrade;
  final double confidence;
  final RiskLevel riskLevel;
  final List<String> recommendations;
  final Map<String, double> factors;
  final DateTime predictionDate;
  final DateTime? targetDate;

  PerformancePrediction({
    required this.studentId,
    required this.predictedGrade,
    required this.confidence,
    required this.riskLevel,
    required this.recommendations,
    required this.factors,
    DateTime? predictionDate,
    this.targetDate,
  }) : predictionDate = predictionDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'predictedGrade': predictedGrade,
    'confidence': confidence,
    'riskLevel': riskLevel.toString(),
    'recommendations': recommendations,
    'factors': factors,
    'predictionDate': predictionDate.toIso8601String(),
    'targetDate': targetDate?.toIso8601String(),
  };

  factory PerformancePrediction.fromJson(Map<String, dynamic> json) => PerformancePrediction(
    studentId: json['studentId'],
    predictedGrade: json['predictedGrade'],
    confidence: json['confidence'],
    riskLevel: RiskLevel.values.firstWhere(
      (r) => r.toString() == json['riskLevel'],
      orElse: () => RiskLevel.unknown,
    ),
    recommendations: List<String>.from(json['recommendations']),
    factors: Map<String, double>.from(json['factors']),
    predictionDate: DateTime.parse(json['predictionDate']),
    targetDate: json['targetDate'] != null ? DateTime.parse(json['targetDate']) : null,
  );
}

class ClassPrediction {
  final String classId;
  final double predictedAverage;
  final List<PerformancePrediction> studentPredictions;
  final Map<RiskLevel, int> riskDistribution;
  final List<PerformancePrediction> atRiskStudents;
  final List<String> classRecommendations;
  final DateTime predictionDate;

  ClassPrediction({
    required this.classId,
    required this.predictedAverage,
    required this.studentPredictions,
    required this.riskDistribution,
    required this.atRiskStudents,
    required this.classRecommendations,
    required this.predictionDate,
  });
}

class AtRiskStudent {
  final String studentId;
  final double riskScore;
  final Map<String, double> riskFactors;
  final List<String> interventions;
  final InterventionUrgency urgency;

  AtRiskStudent({
    required this.studentId,
    required this.riskScore,
    required this.riskFactors,
    required this.interventions,
    required this.urgency,
  });
}

class LearningPathRecommendation {
  final String studentId;
  final Map<String, double> subjectPerformance;
  final List<String> weakAreas;
  final List<String> strongAreas;
  final List<String> recommendations;
  final Map<String, int> studySchedule;
  final int estimatedImprovementTime;

  LearningPathRecommendation({
    required this.studentId,
    required this.subjectPerformance,
    required this.weakAreas,
    required this.strongAreas,
    required this.recommendations,
    required this.studySchedule,
    required this.estimatedImprovementTime,
  });
}

class AnalyticsDashboard {
  final int totalStudents;
  final double averagePredictedGrade;
  final Map<RiskLevel, int> riskDistribution;
  final Map<String, int> topRiskFactors;
  final double predictionAccuracy;
  final DateRange period;

  AnalyticsDashboard({
    required this.totalStudents,
    required this.averagePredictedGrade,
    required this.riskDistribution,
    required this.topRiskFactors,
    required this.predictionAccuracy,
    required this.period,
  });
}

class DateRange {
  final DateTime start;
  final DateTime end;
  DateRange(this.start, this.end);
}
