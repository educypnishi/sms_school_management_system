import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/gradebook_model.dart';
import '../services/gradebook_service.dart';
import '../theme/app_theme.dart';

class GradeAnalyticsScreen extends StatefulWidget {
  final String courseId;
  final String courseName;
  final bool isTeacher;

  const GradeAnalyticsScreen({
    super.key,
    required this.courseId,
    required this.courseName,
    this.isTeacher = false,
  });

  @override
  State<GradeAnalyticsScreen> createState() => _GradeAnalyticsScreenState();
}

class _GradeAnalyticsScreenState extends State<GradeAnalyticsScreen> {
  final GradebookService _gradebookService = GradebookService();
  bool _isLoading = true;
  List<StudentGradeSummary> _studentSummaries = [];
  List<AssignmentModel> _assignments = [];
  Map<String, Map<String, int>> _gradeDistribution = {};
  Map<String, double> _assignmentAverages = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final studentSummaries = await _gradebookService.getAllStudentGradeSummariesForCourse(widget.courseId);
      final assignments = await _gradebookService.getAssignmentsForCourse(widget.courseId);
      
      // Calculate grade distribution
      final gradeDistribution = <String, Map<String, int>>{};
      gradeDistribution['overall'] = {'A': 0, 'B': 0, 'C': 0, 'D': 0, 'F': 0};
      
      for (final summary in studentSummaries) {
        final letterGrade = summary.overallLetterGrade;
        gradeDistribution['overall']![letterGrade] = (gradeDistribution['overall']![letterGrade] ?? 0) + 1;
      }
      
      // Calculate assignment averages
      final assignmentAverages = <String, double>{};
      for (final assignment in assignments) {
        double totalScore = 0;
        int count = 0;
        
        for (final summary in studentSummaries) {
          for (final grade in summary.grades) {
            if (grade.assignmentId == assignment.id) {
              totalScore += grade.percentageScore;
              count++;
            }
          }
        }
        
        if (count > 0) {
          assignmentAverages[assignment.id] = totalScore / count;
        }
      }

      setState(() {
        _studentSummaries = studentSummaries;
        _assignments = assignments;
        _gradeDistribution = gradeDistribution;
        _assignmentAverages = assignmentAverages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics data: $e'),
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
        title: Text('${widget.isTeacher ? "Class" : "My"} Analytics: ${widget.courseName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _studentSummaries.isEmpty
              ? _buildEmptyState()
              : _buildAnalyticsContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.analytics,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No analytics data available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Analytics will be available once grades are recorded',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 24),
          _buildGradeDistributionSection(),
          const SizedBox(height: 24),
          _buildAssignmentPerformanceSection(),
          if (widget.isTeacher) ...[
            const SizedBox(height: 24),
            _buildStudentPerformanceSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    // Calculate class average
    double totalPercentage = 0;
    for (final summary in _studentSummaries) {
      totalPercentage += summary.overallPercentage;
    }
    final classAverage = _studentSummaries.isNotEmpty ? totalPercentage / _studentSummaries.length : 0;
    
    // Calculate highest and lowest scores
    double highestScore = 0;
    double lowestScore = 100;
    String highestStudent = '';
    String lowestStudent = '';
    
    for (final summary in _studentSummaries) {
      if (summary.overallPercentage > highestScore) {
        highestScore = summary.overallPercentage;
        highestStudent = summary.studentName;
      }
      if (summary.overallPercentage < lowestScore) {
        lowestScore = summary.overallPercentage;
        lowestStudent = summary.studentName;
      }
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Course Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSummaryItem(
                  'Class Average',
                  '${classAverage.toStringAsFixed(1)}%',
                  _getGradeColor(classAverage),
                ),
                _buildSummaryItem(
                  'Total Students',
                  _studentSummaries.length.toString(),
                  AppTheme.primaryColor,
                ),
                _buildSummaryItem(
                  'Assignments',
                  _assignments.length.toString(),
                  AppTheme.secondaryColor,
                ),
              ],
            ),
            if (widget.isTeacher && _studentSummaries.length > 1) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Highest Score',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${highestScore.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getGradeColor(highestScore),
                          ),
                        ),
                        Text(
                          highestStudent,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lowest Score',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${lowestScore.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getGradeColor(lowestScore),
                          ),
                        ),
                        Text(
                          lowestStudent,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
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

  Widget _buildGradeDistributionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grade Distribution',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _buildGradeDistributionChart(),
        ),
        const SizedBox(height: 16),
        _buildGradeDistributionLegend(),
      ],
    );
  }

  Widget _buildGradeDistributionChart() {
    final distribution = _gradeDistribution['overall']!;
    final totalStudents = _studentSummaries.length;
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: totalStudents.toDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.shade800,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final grade = ['A', 'B', 'C', 'D', 'F'][groupIndex];
              final count = distribution[grade] ?? 0;
              final percentage = totalStudents > 0 ? (count / totalStudents * 100).toStringAsFixed(1) : '0.0';
              return BarTooltipItem(
                '$grade: $count students\n$percentage%',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final grades = ['A', 'B', 'C', 'D', 'F'];
                return Text(
                  grades[value.toInt()],
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('');
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          _buildBarGroup(0, distribution['A'] ?? 0, Colors.green),
          _buildBarGroup(1, distribution['B'] ?? 0, Colors.lightGreen),
          _buildBarGroup(2, distribution['C'] ?? 0, Colors.amber),
          _buildBarGroup(3, distribution['D'] ?? 0, Colors.orange),
          _buildBarGroup(4, distribution['F'] ?? 0, Colors.red),
        ],
        gridData: FlGridData(show: false),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, int y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y.toDouble(),
          color: color,
          width: 22,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildGradeDistributionLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('A (90-100%)', Colors.green),
        _buildLegendItem('B (80-89%)', Colors.lightGreen),
        _buildLegendItem('C (70-79%)', Colors.amber),
        _buildLegendItem('D (60-69%)', Colors.orange),
        _buildLegendItem('F (<60%)', Colors.red),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentPerformanceSection() {
    if (_assignments.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Sort assignments by date
    final sortedAssignments = List<AssignmentModel>.from(_assignments)
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assignment Performance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: _buildAssignmentPerformanceChart(sortedAssignments),
        ),
      ],
    );
  }

  Widget _buildAssignmentPerformanceChart(List<AssignmentModel> sortedAssignments) {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.shade800,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final assignment = sortedAssignments[spot.x.toInt()];
                return LineTooltipItem(
                  '${assignment.title}\n${spot.y.toStringAsFixed(1)}%',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= sortedAssignments.length) {
                  return const Text('');
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'A${value.toInt() + 1}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: sortedAssignments.length - 1.0,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(sortedAssignments.length, (index) {
              final assignment = sortedAssignments[index];
              final average = _assignmentAverages[assignment.id] ?? 0;
              return FlSpot(index.toDouble(), average);
            }),
            isCurved: true,
            color: AppTheme.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primaryColor.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentPerformanceSection() {
    if (_studentSummaries.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Sort students by overall percentage (highest first)
    final sortedSummaries = List<StudentGradeSummary>.from(_studentSummaries)
      ..sort((a, b) => b.overallPercentage.compareTo(a.overallPercentage));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Student Performance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedSummaries.length,
          itemBuilder: (context, index) {
            final summary = sortedSummaries[index];
            return _buildStudentPerformanceCard(summary, index + 1);
          },
        ),
      ],
    );
  }

  Widget _buildStudentPerformanceCard(StudentGradeSummary summary, int rank) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                rank.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Completed: ${summary.grades.length}/${_assignments.length} assignments',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getGradeColor(summary.overallPercentage),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${summary.overallLetterGrade} (${summary.overallPercentage.toStringAsFixed(1)}%)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.lightGreen;
    if (percentage >= 70) return Colors.amber;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }
}
