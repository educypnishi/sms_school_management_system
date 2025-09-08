import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/grade_model.dart';
import '../services/grade_service.dart';
import '../services/pdf_export_service.dart';
import '../theme/app_theme.dart';
import 'grade_detail_screen.dart';

class GradeReportScreen extends StatefulWidget {
  final String studentId;
  final String? term; // Optional term filter

  const GradeReportScreen({
    super.key,
    required this.studentId,
    this.term,
  });

  @override
  State<GradeReportScreen> createState() => _GradeReportScreenState();
}

class _GradeReportScreenState extends State<GradeReportScreen> {
  final GradeService _gradeService = GradeService();
  final PdfExportService _pdfExportService = PdfExportService();
  bool _isLoading = true;
  bool _isExporting = false;
  List<GradeModel> _grades = [];
  Map<String, List<GradeModel>> _gradesByTerm = {};
  Map<String, double> _gpaByTerm = {};
  double _overallGPA = 0.0;
  Map<String, Map<String, double>> _gradeDistribution = {};

  @override
  void initState() {
    super.initState();
    _loadGradeData();
  }

  Future<void> _loadGradeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // For demo purposes, generate sample grades if needed
      await _gradeService.generateSampleGrades();
      
      // Get grades by term
      final gradesByTerm = await _gradeService.getStudentGradesByTerm(widget.studentId);
      
      // Calculate GPA for each term
      final gpaByTerm = <String, double>{};
      for (final term in gradesByTerm.keys) {
        final gpa = await _gradeService.getStudentGPA(widget.studentId, term: term);
        gpaByTerm[term] = gpa;
      }
      
      // Calculate overall GPA
      final overallGPA = await _gradeService.getStudentGPA(widget.studentId);
      
      // Get all grades
      final allGrades = widget.term != null
          ? gradesByTerm[widget.term] ?? []
          : gradesByTerm.values.expand((grades) => grades).toList();
      
      // Calculate grade distribution
      final gradeDistribution = _calculateGradeDistribution(allGrades);
      
      setState(() {
        _grades = allGrades;
        _gradesByTerm = gradesByTerm;
        _gpaByTerm = gpaByTerm;
        _overallGPA = overallGPA;
        _gradeDistribution = gradeDistribution;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading grade data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, Map<String, double>> _calculateGradeDistribution(List<GradeModel> grades) {
    final result = <String, Map<String, double>>{};
    
    // Group grades by course
    final gradesByCourse = <String, List<GradeModel>>{};
    for (final grade in grades) {
      if (!gradesByCourse.containsKey(grade.courseName)) {
        gradesByCourse[grade.courseName] = [];
      }
      gradesByCourse[grade.courseName]!.add(grade);
    }
    
    // Calculate letter grade distribution for each course
    for (final entry in gradesByCourse.entries) {
      final courseName = entry.key;
      final courseGrades = entry.value;
      
      final letterGradeCounts = <String, int>{
        'A': 0,
        'B': 0,
        'C': 0,
        'D': 0,
        'F': 0,
      };
      
      for (final grade in courseGrades) {
        letterGradeCounts[grade.letterGrade] = (letterGradeCounts[grade.letterGrade] ?? 0) + 1;
      }
      
      // Convert counts to percentages
      final total = courseGrades.length;
      final letterGradePercentages = <String, double>{};
      
      letterGradeCounts.forEach((letter, count) {
        letterGradePercentages[letter] = total > 0 ? (count / total) * 100 : 0;
      });
      
      result[courseName] = letterGradePercentages;
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.term != null ? '${widget.term} Report' : 'Grade Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGradeData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _isExporting ? null : _exportToPdf,
            tooltip: 'Export to PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GPA Card
                  _buildGPACard(),
                  const SizedBox(height: 24),
                  
                  // Grade Distribution
                  const Text(
                    'Grade Distribution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Grade Distribution Charts
                  ..._gradeDistribution.entries.map((entry) => _buildGradeDistributionCard(
                    entry.key,
                    entry.value,
                  )),
                  
                  const SizedBox(height: 24),
                  
                  // Grade List
                  const Text(
                    'All Grades',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Grade List
                  _buildGradeList(),
                ],
              ),
            ),
    );
  }

  Widget _buildGPACard() {
    final Color color = _getGPAColor(_overallGPA);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              widget.term != null ? '${widget.term} GPA' : 'Overall GPA',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                    border: Border.all(
                      color: color,
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _overallGPA.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getGPADescription(_overallGPA),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            if (_gpaByTerm.length > 1) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'GPA by Term',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: _buildGPAChart(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGPAChart() {
    // Sort terms by name
    final sortedTerms = _gpaByTerm.keys.toList()
      ..sort((a, b) {
        // Extract term number for sorting
        final aNum = int.tryParse(a.split(' ').last) ?? 0;
        final bNum = int.tryParse(b.split(' ').last) ?? 0;
        return aNum.compareTo(bNum);
      });
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 4.0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final term = sortedTerms[groupIndex];
              final gpa = _gpaByTerm[term] ?? 0.0;
              return BarTooltipItem(
                '$term: ${gpa.toStringAsFixed(2)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
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
                if (value < 0 || value >= sortedTerms.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    sortedTerms[value.toInt()].split(' ').last,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 1 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: List.generate(
          sortedTerms.length,
          (index) {
            final term = sortedTerms[index];
            final gpa = _gpaByTerm[term] ?? 0.0;
            final color = _getGPAColor(gpa);
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: gpa,
                  color: color,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGradeDistributionCard(String courseName, Map<String, double> distribution) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              courseName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: _buildGradeDistributionChart(distribution),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeDistributionChart(Map<String, double> distribution) {
    // Sort letter grades in descending order (A to F)
    final sortedGrades = ['A', 'B', 'C', 'D', 'F'];
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final grade = sortedGrades[groupIndex];
              final percentage = distribution[grade] ?? 0.0;
              return BarTooltipItem(
                '$grade: ${percentage.toStringAsFixed(1)}%',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
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
                if (value < 0 || value >= sortedGrades.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    sortedGrades[value.toInt()],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 25 != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '${value.toInt()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: List.generate(
          sortedGrades.length,
          (index) {
            final grade = sortedGrades[index];
            final percentage = distribution[grade] ?? 0.0;
            final color = _getGradeColor(grade);
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: percentage,
                  color: color,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGradeList() {
    if (_grades.isEmpty) {
      return const Center(
        child: Text('No grades available'),
      );
    }
    
    // Group grades by course
    final gradesByCourse = <String, List<GradeModel>>{};
    for (final grade in _grades) {
      if (!gradesByCourse.containsKey(grade.courseName)) {
        gradesByCourse[grade.courseName] = [];
      }
      gradesByCourse[grade.courseName]!.add(grade);
    }
    
    // Sort courses alphabetically
    final sortedCourses = gradesByCourse.keys.toList()..sort();
    
    return Column(
      children: sortedCourses.map((course) {
        final courseGrades = gradesByCourse[course]!;
        
        // Sort grades by date (newest first)
        courseGrades.sort((a, b) => b.gradedDate.compareTo(a.gradedDate));
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  course,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Grade List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: courseGrades.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final grade = courseGrades[index];
                  return _buildGradeListItem(grade);
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGradeListItem(GradeModel grade) {
    final color = _getGradeColor(grade.letterGrade);
    
    return ListTile(
      title: Text(grade.assessmentType),
      subtitle: Text(
        '${grade.assessmentType.capitalize()} • ${_formatDate(grade.gradedDate)}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${grade.score.toStringAsFixed(1)}/${grade.maxScore.toStringAsFixed(1)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              grade.letterGrade,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GradeDetailScreen(
              gradeId: grade.id,
            ),
          ),
        );
      },
    );
  }

  Color _getGPAColor(double gpa) {
    if (gpa >= 3.5) {
      return Colors.green;
    } else if (gpa >= 2.5) {
      return Colors.blue;
    } else if (gpa >= 1.5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getGPADescription(double gpa) {
    if (gpa >= 3.5) {
      return 'Excellent';
    } else if (gpa >= 2.5) {
      return 'Good';
    } else if (gpa >= 1.5) {
      return 'Satisfactory';
    } else {
      return 'Needs Improvement';
    }
  }

  Color _getGradeColor(String letterGrade) {
    switch (letterGrade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  // Export grade report to PDF
  Future<void> _exportToPdf() async {
    try {
      setState(() {
        _isExporting = true;
      });
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating PDF report...'),
            ],
          ),
        ),
      );
      
      // Get student name (in a real app, this would come from the user profile)
      const studentName = 'John Doe';
      
      // Generate PDF
      final pdfBytes = await _pdfExportService.generateGradeReportPdf(
        studentName: studentName,
        studentId: widget.studentId,
        overallGPA: _overallGPA,
        gradesByTerm: _gradesByTerm,
        gpaByTerm: _gpaByTerm,
      );
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Show options dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('PDF Generated'),
            content: const Text('What would you like to do with the PDF?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _pdfExportService.savePdfFile(
                    pdfBytes,
                    'grade_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
                  );
                },
                child: const Text('Save'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _pdfExportService.printPdf(pdfBytes);
                },
                child: const Text('Print'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _pdfExportService.sharePdf(
                    pdfBytes,
                    'grade_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
                  );
                },
                child: const Text('Share'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }
}

// Extension method to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
