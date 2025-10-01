import 'package:flutter/material.dart';
import '../models/gradebook_model.dart' show AssignmentModel, StudentGradeSummary;
import '../models/grade_model.dart';
import '../models/class_model.dart';
import '../services/gradebook_service.dart';
import '../services/grade_service.dart';
import '../services/class_service.dart';
import '../theme/app_theme.dart';

class TeacherGradebookScreen extends StatefulWidget {
  const TeacherGradebookScreen({super.key});
  @override
  State<TeacherGradebookScreen> createState() => _TeacherGradebookScreenState();
}

class _TeacherGradebookScreenState extends State<TeacherGradebookScreen> with SingleTickerProviderStateMixin {
  final GradebookService _gradebookService = GradebookService();
  final GradeService _gradeService = GradeService();
  final ClassService _classService = ClassService();
  
  bool _isLoading = true;
  List<AssignmentModel> _assignments = [];
  List<StudentGradeSummary> _studentSummaries = [];
  List<GradeModel> _allGrades = [];
  List<ClassModel> _classes = [];
  String? _selectedCourseId;
  String _selectedCourseName = 'All Courses';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Generate sample grades if needed
      await _gradeService.generateSampleGrades();
      
      // Load all data
      final classes = await _classService.getAllClasses();
      final allGrades = await _gradeService.getAllGrades();
      final assignments = await _gradebookService.getAllAssignments();
      
      // Filter grades for selected course if any
      List<GradeModel> filteredGrades = allGrades;
      if (_selectedCourseId != null) {
        filteredGrades = allGrades.where((grade) => grade.courseId == _selectedCourseId).toList();
      }
      
      // Generate student summaries from grades
      final studentSummaries = _generateStudentSummaries(filteredGrades);

      setState(() {
        _classes = classes;
        _allGrades = allGrades;
        _assignments = assignments;
        _studentSummaries = studentSummaries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading gradebook data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  List<StudentGradeSummary> _generateStudentSummaries(List<GradeModel> grades) {
    final Map<String, List<GradeModel>> studentGrades = {};
    
    // Group grades by student
    for (final grade in grades) {
      if (!studentGrades.containsKey(grade.studentId)) {
        studentGrades[grade.studentId] = [];
      }
      studentGrades[grade.studentId]!.add(grade);
    }
    
    // Create summaries
    return studentGrades.entries.map((entry) {
      final studentId = entry.key;
      final studentGradeList = entry.value;
      final studentName = studentGradeList.isNotEmpty ? studentGradeList.first.studentName : 'Unknown Student';
      
      // Calculate overall percentage
      final totalScore = studentGradeList.fold(0.0, (sum, grade) => sum + grade.score);
      final totalMaxScore = studentGradeList.fold(0.0, (sum, grade) => sum + grade.maxScore);
      final overallPercentage = totalMaxScore > 0 ? (totalScore / totalMaxScore) * 100 : 0.0;
      
      // Determine letter grade
      String letterGrade = 'F';
      if (overallPercentage >= 90) letterGrade = 'A';
      else if (overallPercentage >= 80) letterGrade = 'B';
      else if (overallPercentage >= 70) letterGrade = 'C';
      else if (overallPercentage >= 60) letterGrade = 'D';
      
      return StudentGradeSummary(
        studentId: studentId,
        studentName: studentName,
        courseId: studentGradeList.isNotEmpty ? studentGradeList.first.courseId : '',
        overallPercentage: overallPercentage,
        overallLetterGrade: letterGrade,
        grades: studentGradeList,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gradebook: $_selectedCourseName'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (courseId) {
              setState(() {
                _selectedCourseId = courseId == 'all' ? null : courseId;
                _selectedCourseName = courseId == 'all' ? 'All Courses' : 
                  _classes.firstWhere((c) => c.id == courseId, orElse: () => ClassModel(
                    id: '', name: 'Unknown', grade: '', subject: '', teacherName: '', 
                    room: '', schedule: '', capacity: 0, currentStudents: 0, averageGrade: 0.0
                  )).name;
              });
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Courses'),
              ),
              ..._classes.map((classModel) => PopupMenuItem(
                value: classModel.id,
                child: Text(classModel.name),
              )).toList(),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Grades', icon: Icon(Icons.grade)),
            Tab(text: 'Students', icon: Icon(Icons.people)),
            Tab(text: 'Assignments', icon: Icon(Icons.assignment)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGradesTab(),
                _buildStudentsTab(),
                _buildAssignmentsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddAssignmentDialog();
          } else {
            _showGradeAllDialog();
          }
        },
        child: Icon(_tabController.index == 2 ? Icons.add : Icons.edit),
      ),
    );
  }

  Widget _buildGradesTab() {
    List<GradeModel> displayGrades = _allGrades;
    if (_selectedCourseId != null) {
      displayGrades = _allGrades.where((grade) => grade.courseId == _selectedCourseId).toList();
    }
    
    if (displayGrades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grade,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No grades available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Grades will appear here once assignments are graded',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.lightTextColor),
            ),
          ],
        ),
      );
    }
    
    // Group grades by course
    final Map<String, List<GradeModel>> gradesByCourse = {};
    for (final grade in displayGrades) {
      if (!gradesByCourse.containsKey(grade.courseName)) {
        gradesByCourse[grade.courseName] = [];
      }
      gradesByCourse[grade.courseName]!.add(grade);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: gradesByCourse.length,
      itemBuilder: (context, index) {
        final courseName = gradesByCourse.keys.elementAt(index);
        final courseGrades = gradesByCourse[courseName]!;
        return _buildCourseGradesCard(courseName, courseGrades);
      },
    );
  }
  
  Widget _buildCourseGradesCard(String courseName, List<GradeModel> grades) {
    // Calculate course statistics
    final avgScore = grades.fold(0.0, (sum, grade) => sum + grade.score) / grades.length;
    final avgMaxScore = grades.fold(0.0, (sum, grade) => sum + grade.maxScore) / grades.length;
    final avgPercentage = (avgScore / avgMaxScore) * 100;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          courseName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${grades.length} grades • Avg: ${avgPercentage.toStringAsFixed(1)}%',
          style: const TextStyle(color: AppTheme.lightTextColor),
        ),
        leading: CircleAvatar(
          backgroundColor: _getGradeColor(avgPercentage),
          child: Text(
            grades.length.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: grades.map((grade) => _buildGradeListItem(grade)).toList(),
      ),
    );
  }
  
  Widget _buildGradeListItem(GradeModel grade) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getGradeColor((grade.score / grade.maxScore) * 100),
        radius: 20,
        child: Text(
          grade.letterGrade,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        grade.studentName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${grade.assessmentType} • ${_formatDate(grade.gradedDate)}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${grade.score.toStringAsFixed(1)}/${grade.maxScore.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            '${((grade.score / grade.maxScore) * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              color: AppTheme.lightTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
      onTap: () => _showEditGradeDialog(grade),
    );
  }

  Widget _buildAssignmentsTab() {
    return _assignments.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.assignment,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No assignments yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your first assignment by clicking the + button',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showAddAssignmentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Assignment'),
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: _assignments.length,
            itemBuilder: (context, index) {
              final assignment = _assignments[index];
              return _buildAssignmentCard(assignment);
            },
          );
  }

  Widget _buildAssignmentCard(AssignmentModel assignment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToAssignmentDetail(assignment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      assignment.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildAssignmentStatusChip(assignment),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Type: ${assignment.type.toUpperCase()}',
                style: TextStyle(
                  color: AppTheme.secondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Max Score: ${assignment.maxScore.toStringAsFixed(1)} points',
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Due: ${_formatDate(assignment.dueDate)}',
                    style: TextStyle(
                      color: assignment.isOverdue()
                          ? Colors.red
                          : AppTheme.lightTextColor,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditAssignmentDialog(assignment),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _showDeleteAssignmentDialog(assignment),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentStatusChip(AssignmentModel assignment) {
    if (!assignment.isPublished) {
      return Chip(
        label: const Text('Draft'),
        backgroundColor: Colors.grey[300],
        labelStyle: const TextStyle(color: Colors.black),
      );
    } else if (assignment.isOverdue()) {
      return const Chip(
        label: Text('Past Due'),
        backgroundColor: Colors.red,
        labelStyle: TextStyle(color: Colors.white),
      );
    } else {
      return Chip(
        label: Text('Due in ${assignment.daysRemaining} days'),
        backgroundColor: AppTheme.primaryColor,
        labelStyle: const TextStyle(color: Colors.white),
      );
    }
  }

  Widget _buildStudentsTab() {
    return _studentSummaries.isEmpty
        ? const Center(
            child: Text('No student data available'),
          )
        : ListView.builder(
            itemCount: _studentSummaries.length,
            itemBuilder: (context, index) {
              final summary = _studentSummaries[index];
              return _buildStudentGradeCard(summary);
            },
          );
  }

  Widget _buildStudentGradeCard(StudentGradeSummary summary) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToStudentDetail(summary),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      summary.studentName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildGradeChip(summary.overallLetterGrade, summary.overallPercentage),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Assignments Completed: ${summary.grades.length}/${_assignments.length}',
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: summary.overallPercentage / 100,
                backgroundColor: Colors.grey[300],
                color: _getGradeColor(summary.overallPercentage),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeChip(String letterGrade, double percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getGradeColor(percentage),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$letterGrade (${percentage.toStringAsFixed(1)}%)',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getGradeColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 80) return Colors.blue;
    if (percentage >= 70) return Colors.orange;
    if (percentage >= 60) return Colors.red;
    return Colors.red[800]!;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  void _showEditGradeDialog(GradeModel grade) {
    final scoreController = TextEditingController(text: grade.score.toString());
    final maxScoreController = TextEditingController(text: grade.maxScore.toString());
    final commentsController = TextEditingController(text: grade.comments ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Grade - ${grade.studentName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: scoreController,
                decoration: const InputDecoration(
                  labelText: 'Score',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxScoreController,
                decoration: const InputDecoration(
                  labelText: 'Max Score',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentsController,
                decoration: const InputDecoration(
                  labelText: 'Comments',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newScore = double.tryParse(scoreController.text) ?? grade.score;
              final newMaxScore = double.tryParse(maxScoreController.text) ?? grade.maxScore;
              final newComments = commentsController.text;
              
              try {
                await _gradeService.updateGrade(
                  id: grade.id,
                  score: newScore,
                  comments: newComments,
                );
                
                Navigator.pop(context);
                _loadData();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Grade updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating grade: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _navigateToAssignmentDetail(AssignmentModel assignment) {
    // Navigate to assignment detail screen
    // This would be implemented in a real app
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing ${assignment.title}'),
      ),
    );
  }

  void _showAddAssignmentDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final maxScoreController = TextEditingController(text: '100');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    String selectedType = 'Assignment';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Assignment Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Assignment', 'Quiz', 'Exam', 'Project', 'Homework']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: maxScoreController,
                  decoration: const InputDecoration(
                    labelText: 'Max Score',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Due Date'),
                  subtitle: Text(_formatDate(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  // In a real app, this would save to the database
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Assignment created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Grade Entry'),
        content: const Text(
          'This feature allows you to quickly enter grades for all students. '
          'Would you like to proceed with bulk grade entry?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showBulkGradeDialog();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
  
  void _showBulkGradeDialog() {
    final Map<String, TextEditingController> controllers = {};
    for (final student in _studentSummaries) {
      controllers[student.studentId] = TextEditingController();
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Grade Entry'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _studentSummaries.length,
            itemBuilder: (context, index) {
              final student = _studentSummaries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        student.studentName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controllers[student.studentId],
                        decoration: const InputDecoration(
                          labelText: 'Score',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Process bulk grades
              int gradesEntered = 0;
              controllers.forEach((studentId, controller) {
                if (controller.text.isNotEmpty) {
                  gradesEntered++;
                }
              });
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$gradesEntered grades would be saved'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save All'),
          ),
        ],
      ),
    );
  }
