import 'package:flutter/material.dart';

/// Represents a data point for analytics charts
class DataPoint {
  final String label;
  final double value;
  final Color? color;

  DataPoint({
    required this.label,
    required this.value,
    this.color,
  });
}

/// Represents a series of data points for analytics charts
class DataSeries {
  final String name;
  final List<DataPoint> dataPoints;
  final Color color;

  DataSeries({
    required this.name,
    required this.dataPoints,
    required this.color,
  });
}

/// Represents a time period for analytics
enum TimePeriod {
  day,
  week,
  month,
  quarter,
  year,
  all
}

/// Represents the type of chart
enum ChartType {
  bar,
  line,
  pie,
  donut,
  area
}

/// Represents application statistics
class ApplicationStats {
  final int totalApplications;
  final int pendingApplications;
  final int approvedApplications;
  final int rejectedApplications;
  final double approvalRate;
  final Map<String, int> applicationsByProgram;
  final Map<String, int> applicationsByUniversity;
  final Map<String, int> applicationsByCountry;
  final List<DataPoint> applicationTrend;

  ApplicationStats({
    required this.totalApplications,
    required this.pendingApplications,
    required this.approvedApplications,
    required this.rejectedApplications,
    required this.approvalRate,
    required this.applicationsByProgram,
    required this.applicationsByUniversity,
    required this.applicationsByCountry,
    required this.applicationTrend,
  });
}

/// Represents user statistics
class UserStats {
  final int totalUsers;
  final int activeUsers;
  final int newUsers;
  final Map<String, int> usersByRole;
  final Map<String, int> usersByCountry;
  final List<DataPoint> userGrowthTrend;

  UserStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsers,
    required this.usersByRole,
    required this.usersByCountry,
    required this.userGrowthTrend,
  });
}

/// Represents program statistics
class ProgramStats {
  final int totalPrograms;
  final Map<String, int> programsByUniversity;
  final Map<String, int> programsByDegreeType;
  final Map<String, double> programsByTuitionRange;
  final List<DataPoint> popularPrograms;

  ProgramStats({
    required this.totalPrograms,
    required this.programsByUniversity,
    required this.programsByDegreeType,
    required this.programsByTuitionRange,
    required this.popularPrograms,
  });
}

/// Represents a dashboard metric
class DashboardMetric {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final double? changePercentage;
  final bool isPositiveChange;

  DashboardMetric({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.changePercentage,
    this.isPositiveChange = true,
  });
}

/// Represents a complete analytics dashboard
class AnalyticsDashboard {
  final ApplicationStats applicationStats;
  final UserStats userStats;
  final ProgramStats programStats;
  final DateTime lastUpdated;
  final TimePeriod currentPeriod;

  AnalyticsDashboard({
    required this.applicationStats,
    required this.userStats,
    required this.programStats,
    required this.lastUpdated,
    required this.currentPeriod,
  });

  /// Get key metrics for the dashboard
  List<DashboardMetric> getKeyMetrics() {
    return [
      DashboardMetric(
        title: 'Total Applications',
        value: applicationStats.totalApplications.toString(),
        icon: Icons.school,
        color: Colors.blue,
        changePercentage: 5.2,
        isPositiveChange: true,
      ),
      DashboardMetric(
        title: 'Approval Rate',
        value: '${(applicationStats.approvalRate * 100).toStringAsFixed(1)}%',
        icon: Icons.check_circle,
        color: Colors.green,
        changePercentage: 2.3,
        isPositiveChange: true,
      ),
      DashboardMetric(
        title: 'Active Users',
        value: userStats.activeUsers.toString(),
        icon: Icons.people,
        color: Colors.purple,
        changePercentage: 12.7,
        isPositiveChange: true,
      ),
      DashboardMetric(
        title: 'Popular Programs',
        value: programStats.totalPrograms.toString(),
        subtitle: 'Total Programs',
        icon: Icons.trending_up,
        color: Colors.orange,
        changePercentage: 3.5,
        isPositiveChange: true,
      ),
    ];
  }
}
