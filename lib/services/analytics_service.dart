import 'dart:math';
import 'package:flutter/material.dart';
import '../models/analytics_model.dart';
import '../models/application_model.dart';
import '../models/program_model.dart';
import '../services/application_service.dart';
import '../services/program_service.dart';

/// Service to manage analytics data
class AnalyticsService {
  final ApplicationService _applicationService = ApplicationService();
  final ProgramService _programService = ProgramService();
  
  /// Get analytics dashboard data
  Future<AnalyticsDashboard> getDashboardData(TimePeriod period) async {
    // In a real app, this would fetch data from a backend API
    // For now, we'll generate sample data
    
    // Get applications and programs
    final applications = await _applicationService.getAllApplications();
    final programs = await _programService.getAllPrograms();
    
    // Generate application stats
    final applicationStats = await _generateApplicationStats(applications, period);
    
    // Generate user stats
    final userStats = await _generateUserStats(period);
    
    // Generate program stats
    final programStats = await _generateProgramStats(programs, applications, period);
    
    // Create dashboard
    return AnalyticsDashboard(
      applicationStats: applicationStats,
      userStats: userStats,
      programStats: programStats,
      lastUpdated: DateTime.now(),
      currentPeriod: period,
    );
  }
  
  /// Generate application statistics
  Future<ApplicationStats> _generateApplicationStats(
    List<ApplicationModel> applications,
    TimePeriod period,
  ) async {
    // Filter applications by period
    final filteredApplications = _filterByPeriod(applications, period);
    
    // Count applications by status
    final pendingCount = filteredApplications.where((app) => app.status == 'pending').length;
    final approvedCount = filteredApplications.where((app) => app.status == 'approved').length;
    final rejectedCount = filteredApplications.where((app) => app.status == 'rejected').length;
    final totalCount = filteredApplications.length;
    
    // Calculate approval rate
    final approvalRate = totalCount > 0 ? approvedCount / totalCount : 0.0;
    
    // Count applications by program (using a sample program ID for demo)
    final applicationsByProgram = <String, int>{};
    for (final app in filteredApplications) {
      // In a real app, we would use the actual program ID from the application
      // For now, we'll use a sample program ID for demo purposes
      final programId = 'PROG001'; // Sample program ID
      applicationsByProgram[programId] = (applicationsByProgram[programId] ?? 0) + 1;
    }
    
    // Count applications by university (using sample data)
    final applicationsByUniversity = <String, int>{};
    for (final app in filteredApplications) {
      // In a real app, we would get the program from the application and then get the university
      // For now, we'll use sample universities for demo purposes
      final universities = ['Cyprus University', 'Eastern Mediterranean University', 'University of Nicosia'];
      final random = Random();
      final university = universities[random.nextInt(universities.length)];
      applicationsByUniversity[university] = (applicationsByUniversity[university] ?? 0) + 1;
    }
    
    // Count applications by country (sample data)
    final applicationsByCountry = {
      'Cyprus': 45,
      'Turkey': 23,
      'Greece': 18,
      'United Kingdom': 12,
      'Other': 7,
    };
    
    // Generate application trend data
    final applicationTrend = _generateTrendData(period, 10, 50);
    
    return ApplicationStats(
      totalApplications: totalCount,
      pendingApplications: pendingCount,
      approvedApplications: approvedCount,
      rejectedApplications: rejectedCount,
      approvalRate: approvalRate,
      applicationsByProgram: applicationsByProgram,
      applicationsByUniversity: applicationsByUniversity,
      applicationsByCountry: applicationsByCountry,
      applicationTrend: applicationTrend,
    );
  }
  
  /// Generate user statistics
  Future<UserStats> _generateUserStats(TimePeriod period) async {
    // In a real app, this would fetch user data from a backend API
    // For now, we'll generate sample data
    
    // Sample user counts
    final totalUsers = 250;
    final activeUsers = 180;
    final newUsers = 35;
    
    // Sample user distribution by role
    final usersByRole = {
      'student': 200,
      'partner': 30,
      'admin': 20,
    };
    
    // Sample user distribution by country
    final usersByCountry = {
      'Cyprus': 85,
      'Turkey': 65,
      'Greece': 40,
      'United Kingdom': 25,
      'Other': 35,
    };
    
    // Generate user growth trend data
    final userGrowthTrend = _generateTrendData(period, 5, 20);
    
    return UserStats(
      totalUsers: totalUsers,
      activeUsers: activeUsers,
      newUsers: newUsers,
      usersByRole: usersByRole,
      usersByCountry: usersByCountry,
      userGrowthTrend: userGrowthTrend,
    );
  }
  
  /// Generate program statistics
  Future<ProgramStats> _generateProgramStats(
    List<ProgramModel> programs,
    List<ApplicationModel> applications,
    TimePeriod period,
  ) async {
    // Count programs by university
    final programsByUniversity = <String, int>{};
    for (final program in programs) {
      final university = program.university;
      programsByUniversity[university] = (programsByUniversity[university] ?? 0) + 1;
    }
    
    // Count programs by degree type
    final programsByDegreeType = <String, int>{};
    for (final program in programs) {
      final degreeType = program.degreeType;
      programsByDegreeType[degreeType] = (programsByDegreeType[degreeType] ?? 0) + 1;
    }
    
    // Group programs by tuition fee range
    final programsByTuitionRange = <String, double>{};
    for (final program in programs) {
      final tuitionFee = _parseTuitionFee(program.tuitionFee);
      
      String range;
      if (tuitionFee < 5000) {
        range = 'Under €5,000';
      } else if (tuitionFee < 10000) {
        range = '€5,000 - €10,000';
      } else if (tuitionFee < 15000) {
        range = '€10,000 - €15,000';
      } else if (tuitionFee < 20000) {
        range = '€15,000 - €20,000';
      } else {
        range = 'Over €20,000';
      }
      
      programsByTuitionRange[range] = (programsByTuitionRange[range] ?? 0) + 1;
    }
    
    // Calculate popular programs based on application count (using sample data)
    final programApplicationCounts = <String, int>{};
    // In a real app, we would count applications per program
    // For now, we'll use sample program IDs for demo purposes
    programApplicationCounts['PROG001'] = 25;
    programApplicationCounts['PROG002'] = 18;
    programApplicationCounts['PROG003'] = 15;
    programApplicationCounts['PROG004'] = 12;
    programApplicationCounts['PROG005'] = 8;
    
    // Get top 5 popular programs
    final popularPrograms = <DataPoint>[];
    final sortedPrograms = programApplicationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (int i = 0; i < min(5, sortedPrograms.length); i++) {
      final program = await _programService.getProgramById(sortedPrograms[i].key);
      if (program != null) {
        popularPrograms.add(DataPoint(
          label: program.title,
          value: sortedPrograms[i].value.toDouble(),
          color: _getRandomColor(),
        ));
      }
    }
    
    return ProgramStats(
      totalPrograms: programs.length,
      programsByUniversity: programsByUniversity,
      programsByDegreeType: programsByDegreeType,
      programsByTuitionRange: programsByTuitionRange.map((k, v) => MapEntry(k, v.toDouble())),
      popularPrograms: popularPrograms,
    );
  }
  
  /// Filter applications by time period
  List<ApplicationModel> _filterByPeriod(List<ApplicationModel> applications, TimePeriod period) {
    final now = DateTime.now();
    DateTime cutoffDate;
    
    switch (period) {
      case TimePeriod.day:
        cutoffDate = DateTime(now.year, now.month, now.day);
        break;
      case TimePeriod.week:
        cutoffDate = now.subtract(const Duration(days: 7));
        break;
      case TimePeriod.month:
        cutoffDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case TimePeriod.quarter:
        cutoffDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case TimePeriod.year:
        cutoffDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case TimePeriod.all:
        return applications;
    }
    
    return applications.where((app) => app.createdAt.isAfter(cutoffDate)).toList();
  }
  
  /// Generate trend data for charts
  List<DataPoint> _generateTrendData(TimePeriod period, double minValue, double maxValue) {
    final random = Random();
    final result = <DataPoint>[];
    
    int pointCount;
    String labelFormat;
    
    switch (period) {
      case TimePeriod.day:
        pointCount = 24;
        labelFormat = 'hour';
        break;
      case TimePeriod.week:
        pointCount = 7;
        labelFormat = 'day';
        break;
      case TimePeriod.month:
        pointCount = 30;
        labelFormat = 'day';
        break;
      case TimePeriod.quarter:
        pointCount = 12;
        labelFormat = 'week';
        break;
      case TimePeriod.year:
        pointCount = 12;
        labelFormat = 'month';
        break;
      case TimePeriod.all:
        pointCount = 10;
        labelFormat = 'year';
        break;
    }
    
    for (int i = 0; i < pointCount; i++) {
      String label;
      
      switch (labelFormat) {
        case 'hour':
          label = '${i}:00';
          break;
        case 'day':
          label = 'Day ${i + 1}';
          break;
        case 'week':
          label = 'Week ${i + 1}';
          break;
        case 'month':
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          label = months[i % 12];
          break;
        case 'year':
          final currentYear = DateTime.now().year;
          label = '${currentYear - pointCount + i + 1}';
          break;
        default:
          label = 'Point $i';
      }
      
      result.add(DataPoint(
        label: label,
        value: minValue + random.nextDouble() * (maxValue - minValue),
        color: _getRandomColor(),
      ));
    }
    
    return result;
  }
  
  /// Parse tuition fee from string to double
  double _parseTuitionFee(String tuitionFee) {
    // Remove currency symbols and non-numeric characters
    final numericString = tuitionFee.replaceAll(RegExp(r'[^0-9.]'), '');
    
    try {
      return double.parse(numericString);
    } catch (e) {
      return 0.0;
    }
  }
  
  /// Get a random color for charts
  Color _getRandomColor() {
    final random = Random();
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    
    return colors[random.nextInt(colors.length)];
  }
}
