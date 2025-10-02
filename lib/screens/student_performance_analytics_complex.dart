import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/student_performance_model.dart';
import '../services/student_performance_service.dart';
import '../services/auth_service.dart';

class StudentPerformanceAnalyticsScreen extends StatefulWidget {
  final String? studentId;
  final String? className;
  
  const StudentPerformanceAnalyticsScreen({
    super.key,
    this.studentId,
    this.className,
  });

  @override
  State<StudentPerformanceAnalyticsScreen> createState() => _StudentPerformanceAnalyticsScreenState();
}

class _StudentPerformanceAnalyticsScreenState extends State<StudentPerformanceAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final StudentPerformanceService _performanceService = StudentPerformanceService();
  final AuthService _authService = AuthService();
  
  late TabController _tabController;
  bool _isLoading = true;
  
  StudentAnalyticsSummary? _studentAnalytics;
  List<StudentPerformanceModel> _recentPerformances = [];
  Map<String, double> _subjectAverages = {};
  List<StudentAnalyticsSummary> _topPerformers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if we have any performance data, if not generate sample data
      final allPerformances = await _performanceService.getAllPerformances();
      if (allPerformances.isEmpty) {
        await _performanceService.generateSamplePerformances();
      }

      // Load student-specific analytics
      if (widget.studentId != null) {
        _studentAnalytics = await _performanceService.getStudentAnalytics(widget.studentId!);
        _recentPerformances = await _performanceService.getStudentPerformances(widget.studentId!);
      } else {
        // Load current user's analytics
        final currentUser = await _authService.getCurrentUser();
        if (currentUser != null) {
          _studentAnalytics = await _performanceService.getStudentAnalytics(currentUser.id);
          _recentPerformances = await _performanceService.getStudentPerformances(currentUser.id);
        }
      }

      // Load class analytics if className is provided
      if (widget.className != null) {
        _subjectAverages = await _performanceService.getSubjectAverages(widget.className!);
        _topPerformers = await _performanceService.getTopPerformers(widget.className!);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Analytics'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 20)),
            Tab(text: 'Subjects', icon: Icon(Icons.subject, size: 20)),
            Tab(text: 'Progress', icon: Icon(Icons.trending_up, size: 20)),
            Tab(text: 'Reports', icon: Icon(Icons.assessment, size: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildSubjectsTab(),
                _buildProgressTab(),
                _buildReportsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_studentAnalytics == null) {
      return const Center(
        child: Text('No analytics data available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Info Card
          _buildStudentInfoCard(),
          const SizedBox(height: 16),
          
          // Performance Summary Cards
          Row(
            children: [
              Expanded(child: _buildSummaryCard('Overall GPA', _studentAnalytics!.overallGPA.toStringAsFixed(2), Icons.grade, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard('Overall %', '${_studentAnalytics!.overallPercentage.toStringAsFixed(1)}%', Icons.percent, Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSummaryCard('Grade', _studentAnalytics!.overallGrade, Icons.star, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard('Assessments', _studentAnalytics!.totalAssessments.toString(), Icons.assignment, Colors.purple)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Recent Performances
          _buildSectionHeader('Recent Performances'),
          const SizedBox(height: 12),
          _buildRecentPerformancesList(),
        ],
      ),
    );
  }

  Widget _buildSubjectsTab() {
    if (_studentAnalytics == null) {
      return const Center(child: Text('No subject data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Subject-wise Performance'),
          const SizedBox(height: 16),
          
          // Subject Performance Cards
          for (var entry in _studentAnalytics!.subjectGPAs.entries) ...[
            () {
              final subject = entry.key;
              final gpa = entry.value;
              final grade = _studentAnalytics!.subjectGrades[subject] ?? 'F';
              final assessmentCount = _studentAnalytics!.subjectAssessmentCounts[subject] ?? 0;
              
              return _buildSubjectCard(subject, gpa, grade, assessmentCount);
            }(),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Performance Trends'),
          const SizedBox(height: 16),
          
          // Monthly Progress Chart Placeholder
          Container(
            width: double.infinity,
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text(
                  'Performance Trend Chart',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Visual chart showing performance over time',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Improvement Areas
          _buildSectionHeader('Areas for Improvement'),
          const SizedBox(height: 12),
          _buildImprovementAreas(),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Performance Reports'),
          const SizedBox(height: 16),
          
          // Report Options
          _buildReportOption('Detailed Performance Report', 'Complete academic performance summary', Icons.description),
          _buildReportOption('Subject-wise Analysis', 'Individual subject performance breakdown', Icons.subject),
          _buildReportOption('Monthly Progress Report', 'Month-by-month performance tracking', Icons.calendar_month),
          _buildReportOption('Parent Report Card', 'Summary for parent communication', Icons.family_restroom),
          
          const SizedBox(height: 24),
          
          // Class Comparison (if available)
          if (widget.className != null) ...[
            _buildSectionHeader('Class Comparison'),
            const SizedBox(height: 12),
            _buildClassComparison(),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  _studentAnalytics!.studentName.isNotEmpty 
                      ? _studentAnalytics!.studentName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _studentAnalytics!.studentName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _studentAnalytics!.className,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${_studentAnalytics!.semester} ${_studentAnalytics!.academicYear}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildRecentPerformancesList() {
    if (_recentPerformances.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No recent performances available'),
        ),
      );
    }

    return Column(
      children: _recentPerformances.take(5).map((performance) {
        return _buildPerformanceItem(performance);
      }).toList(),
    );
  }

  Widget _buildPerformanceItem(StudentPerformanceModel performance) {
    Color gradeColor = _getGradeColor(performance.grade);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: gradeColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  performance.subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  performance.assessmentType,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${performance.assessmentDate.day}/${performance.assessmentDate.month}/${performance.assessmentDate.year}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: gradeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  performance.grade,
                  style: TextStyle(
                    color: gradeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${performance.marksObtained.toStringAsFixed(0)}/${performance.totalMarks.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                '${performance.percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(String subject, double gpa, String grade, int assessmentCount) {
    Color gradeColor = _getGradeColor(grade);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: gradeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$assessmentCount assessments',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: gradeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  grade,
                  style: TextStyle(
                    color: gradeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'GPA: ${gpa.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementAreas() {
    if (_studentAnalytics == null) return const SizedBox();
    
    // Find subjects with lowest performance
    var sortedSubjects = _studentAnalytics!.subjectGPAs.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    var improvementSubjects = sortedSubjects.take(3).toList();
    
    return Column(
      children: improvementSubjects.map((entry) {
        String subject = entry.key;
        double gpa = entry.value;
        String grade = _studentAnalytics!.subjectGrades[subject] ?? 'F';
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.trending_down, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Focus on improving this subject',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$grade (${gpa.toStringAsFixed(2)})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReportOption(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Generating $title...')),
          );
        },
      ),
    );
  }

  Widget _buildClassComparison() {
    if (_topPerformers.isEmpty) {
      return const Text('No class data available for comparison');
    }
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top Performers in Class',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ..._topPerformers.take(3).map((student) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          student.studentName.isNotEmpty 
                              ? student.studentName[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          student.studentName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '${student.overallGrade} (${student.overallGPA.toStringAsFixed(2)})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return Colors.green;
      case 'B+':
      case 'B':
        return Colors.blue;
      case 'C+':
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.red[300]!;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
