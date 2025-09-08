import 'package:flutter/material.dart';
import '../models/grade_model.dart';
import '../services/grade_service.dart';
import '../theme/app_theme.dart';

class StudentGradebookScreen extends StatefulWidget {
  final String studentId;

  const StudentGradebookScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<StudentGradebookScreen> createState() => _StudentGradebookScreenState();
}

class _StudentGradebookScreenState extends State<StudentGradebookScreen> with SingleTickerProviderStateMixin {
  final GradeService _gradeService = GradeService();
  bool _isLoading = true;
  Map<String, List<GradeModel>> _gradesByTerm = {};
  Map<String, double> _gpaByTerm = {};
  double _overallGPA = 0.0;
  late TabController _tabController;
  List<String> _terms = [];

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
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
      
      // Get sorted list of terms
      final terms = gradesByTerm.keys.toList()
        ..sort((a, b) {
          // Extract term number for sorting
          final aNum = int.tryParse(a.split(' ').last) ?? 0;
          final bNum = int.tryParse(b.split(' ').last) ?? 0;
          return aNum.compareTo(bNum);
        });
      
      setState(() {
        _gradesByTerm = gradesByTerm;
        _gpaByTerm = gpaByTerm;
        _overallGPA = overallGPA;
        _terms = terms;
        _tabController = TabController(length: terms.length + 1, vsync: this);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading grades: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Gradebook'),
        bottom: _isLoading
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: [
                  const Tab(text: 'All Terms'),
                  ..._terms.map((term) => Tab(text: term)),
                ],
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllTermsTab(),
                ..._terms.map((term) => _buildTermTab(term)),
              ],
            ),
    );
  }

  Widget _buildAllTermsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall GPA Card
          _buildGPACard(_overallGPA, 'Overall GPA'),
          const SizedBox(height: 24),
          
          // Term GPAs
          const Text(
            'Term Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Term GPA Cards
          ..._terms.map((term) => Column(
            children: [
              _buildTermGPACard(term, _gpaByTerm[term] ?? 0.0),
              const SizedBox(height: 16),
            ],
          )),
          
          const SizedBox(height: 24),
          
          // Course Performance
          const Text(
            'Course Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Course Performance Cards
          _buildCoursePerformanceCards(),
        ],
      ),
    );
  }

  Widget _buildTermTab(String term) {
    final grades = _gradesByTerm[term] ?? [];
    
    // Group grades by course
    final gradesByCourse = <String, List<GradeModel>>{};
    for (final grade in grades) {
      if (!gradesByCourse.containsKey(grade.courseName)) {
        gradesByCourse[grade.courseName] = [];
      }
      gradesByCourse[grade.courseName]!.add(grade);
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Term GPA Card
          _buildGPACard(_gpaByTerm[term] ?? 0.0, '$term GPA'),
          const SizedBox(height: 24),
          
          // Courses
          ...gradesByCourse.entries.map((entry) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildGradeTable(entry.value),
              const SizedBox(height: 24),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildGPACard(double gpa, String title) {
    final Color color = _getGPAColor(gpa);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 120,
              height: 120,
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
                  gpa.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getGPADescription(gpa),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermGPACard(String term, double gpa) {
    final Color color = _getGPAColor(gpa);
    
    return Card(
      child: InkWell(
        onTap: () {
          // Find the index of the term tab
          final termIndex = _terms.indexOf(term) + 1; // +1 because the first tab is "All Terms"
          _tabController.animateTo(termIndex);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                  border: Border.all(
                    color: color,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    gpa.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      term,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getGPADescription(gpa),
                      style: TextStyle(
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoursePerformanceCards() {
    // Get all courses across all terms
    final allCourses = <String>{};
    for (final grades in _gradesByTerm.values) {
      for (final grade in grades) {
        allCourses.add(grade.courseName);
      }
    }
    
    // Sort courses alphabetically
    final sortedCourses = allCourses.toList()..sort();
    
    return Column(
      children: sortedCourses.map((course) {
        // Calculate average score for this course across all terms
        double totalScore = 0;
        int count = 0;
        
        for (final grades in _gradesByTerm.values) {
          for (final grade in grades) {
            if (grade.courseName == course) {
              totalScore += grade.score;
              count++;
            }
          }
        }
        
        final averageScore = count > 0 ? totalScore / count : 0.0;
        final letterGrade = _calculateLetterGrade(averageScore.toDouble());
        final color = _getGradeColor(letterGrade);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                    border: Border.all(
                      color: color,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      letterGrade,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Average: ${averageScore.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: AppTheme.lightTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGradeTable(List<GradeModel> grades) {
    // Sort grades by assessment type
    grades.sort((a, b) => a.assessmentType.compareTo(b.assessmentType));
    
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Assessment')),
            DataColumn(label: Text('Score')),
            DataColumn(label: Text('Grade')),
            DataColumn(label: Text('Weight')),
            DataColumn(label: Text('Date')),
          ],
          rows: grades.map((grade) {
            final color = _getGradeColor(grade.letterGrade);
            
            return DataRow(
              cells: [
                DataCell(Text(grade.assessmentType)),
                DataCell(Text('${grade.score.toStringAsFixed(1)}%')),
                DataCell(
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
                ),
                DataCell(Text('${(grade.weightage * 100).toStringAsFixed(0)}%')),
                DataCell(Text(_formatDate(grade.gradedDate))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

  String _calculateLetterGrade(double score) {
    if (score >= 90) {
      return 'A';
    } else if (score >= 80) {
      return 'B';
    } else if (score >= 70) {
      return 'C';
    } else if (score >= 60) {
      return 'D';
    } else {
      return 'F';
    }
  }
}
