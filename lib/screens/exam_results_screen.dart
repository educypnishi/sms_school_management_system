import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/exam_model.dart';
import '../services/firebase_exam_service.dart';
import '../theme/app_theme.dart';

class ExamResultsScreen extends StatefulWidget {
  final String examId;
  
  const ExamResultsScreen({super.key, required this.examId});

  @override
  State<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends State<ExamResultsScreen> {
  ExamModel? _exam;
  List<ExamResult> _results = [];
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final exam = await FirebaseExamService.getExamById(widget.examId);
      final results = await FirebaseExamService.getExamResults(widget.examId);
      final analytics = await FirebaseExamService.getExamAnalytics(widget.examId);
      
      setState(() {
        _exam = exam;
        _results = results;
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_exam?.title ?? 'Exam Results'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _exportResults,
            icon: const Icon(Icons.download),
            tooltip: 'Export Results',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_exam == null) {
      return const Center(child: Text('Exam not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExamInfo(),
          const SizedBox(height: 24),
          _buildAnalyticsCards(),
          const SizedBox(height: 24),
          _buildChartsSection(),
          const SizedBox(height: 24),
          _buildResultsList(),
        ],
      ),
    );
  }

  Widget _buildExamInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.quiz, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  _exam!.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip('Subject', _exam!.subject),
                const SizedBox(width: 12),
                _buildInfoChip('Class', _exam!.className),
                const SizedBox(width: 12),
                _buildInfoChip('Questions', '${_exam!.questions.length}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildAnalyticsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildAnalyticsCard(
            'Total Attempts',
            '${_analytics['totalAttempts'] ?? 0}',
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAnalyticsCard(
            'Pass Rate',
            '${(_analytics['passRate'] ?? 0).toStringAsFixed(1)}%',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAnalyticsCard(
            'Average Score',
            '${(_analytics['averageScore'] ?? 0).toStringAsFixed(1)}%',
            Icons.analytics,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
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
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Analytics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildGradeDistributionChart()),
            const SizedBox(width: 16),
            Expanded(child: _buildScoreDistributionChart()),
          ],
        ),
      ],
    );
  }

  Widget _buildGradeDistributionChart() {
    final gradeDistribution = _analytics['gradeDistribution'] as Map<String, int>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Grade Distribution',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(gradeDistribution),
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDistributionChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Score Range Distribution',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: _buildBarChartGroups(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const ranges = ['0-20', '21-40', '41-60', '61-80', '81-100'];
                          return Text(ranges[value.toInt()]);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Student Results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _exportResults,
              icon: const Icon(Icons.download),
              label: const Text('Export'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: Text('Student', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Score', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _results.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(result.studentName),
                        ),
                        Expanded(
                          child: Text('${result.percentage.toStringAsFixed(1)}%'),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getGradeColor(result.grade).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              result.grade,
                              style: TextStyle(
                                color: _getGradeColor(result.grade),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Icon(
                            result.passed ? Icons.check_circle : Icons.cancel,
                            color: result.passed ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _viewDetailedResult(result),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, int> gradeDistribution) {
    final colors = [
      Colors.green,
      Colors.lightGreen,
      Colors.yellow,
      Colors.orange,
      Colors.red,
    ];
    
    return gradeDistribution.entries.map((entry) {
      final index = gradeDistribution.keys.toList().indexOf(entry.key);
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value.toDouble(),
        title: '${entry.key}\n${entry.value}',
        radius: 60,
      );
    }).toList();
  }

  List<BarChartGroupData> _buildBarChartGroups() {
    // Sample data for score ranges
    final scoreRanges = [2, 5, 8, 15, 10]; // Students in each range
    
    return List.generate(scoreRanges.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: scoreRanges[index].toDouble(),
            color: AppTheme.primaryColor,
            width: 20,
          ),
        ],
      );
    });
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return Colors.green;
      case 'B+':
      case 'B':
        return Colors.lightGreen;
      case 'C+':
      case 'C':
        return Colors.yellow[700]!;
      case 'D':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  void _viewDetailedResult(ExamResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.studentName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: ${result.score}/${_exam!.totalPoints}'),
            Text('Percentage: ${result.percentage.toStringAsFixed(1)}%'),
            Text('Grade: ${result.grade}'),
            Text('Status: ${result.passed ? "Passed" : "Failed"}'),
            Text('Time Spent: ${result.timeSpent.inMinutes} minutes'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting results...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
