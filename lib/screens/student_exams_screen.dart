import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exam_model.dart';
import '../services/firebase_exam_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class StudentExamsScreen extends StatefulWidget {
  const StudentExamsScreen({super.key});

  @override
  State<StudentExamsScreen> createState() => _StudentExamsScreenState();
}

class _StudentExamsScreenState extends State<StudentExamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ExamModel> _availableExams = [];
  List<ExamModel> _upcomingExams = [];
  List<ExamModel> _completedExams = [];
  List<ExamResult> _myResults = [];
  bool _isLoading = true;
  String? _currentStudentId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStudentExams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentExams() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current student ID
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      _currentStudentId = currentUser?.id ?? 'demo_student';

      // Load student's exams
      final allExams = await FirebaseExamService.getExamsForStudent(_currentStudentId!);
      final results = await FirebaseExamService.getStudentResults(_currentStudentId!);
      
      final now = DateTime.now();
      
      setState(() {
        _availableExams = allExams.where((exam) {
          return exam.isOngoing || (exam.isScheduled && exam.startTime.isAfter(now));
        }).toList();
        
        _upcomingExams = allExams.where((exam) {
          return exam.isScheduled && exam.startTime.isAfter(now);
        }).toList();
        
        _completedExams = allExams.where((exam) {
          return exam.isCompleted || exam.hasEnded;
        }).toList();
        
        _myResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading exams: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Exams'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.play_circle), text: 'Available'),
            Tab(icon: Icon(Icons.schedule), text: 'Upcoming'),
            Tab(icon: Icon(Icons.history), text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableExamsTab(),
                _buildUpcomingExamsTab(),
                _buildCompletedExamsTab(),
              ],
            ),
    );
  }

  Widget _buildAvailableExamsTab() {
    if (_availableExams.isEmpty) {
      return _buildEmptyState(
        icon: Icons.quiz_outlined,
        title: 'No Available Exams',
        subtitle: 'Check back later for new exams',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStudentExams,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableExams.length,
        itemBuilder: (context, index) {
          return _buildAvailableExamCard(_availableExams[index]);
        },
      ),
    );
  }

  Widget _buildUpcomingExamsTab() {
    if (_upcomingExams.isEmpty) {
      return _buildEmptyState(
        icon: Icons.schedule,
        title: 'No Upcoming Exams',
        subtitle: 'Your exam schedule is clear',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStudentExams,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _upcomingExams.length,
        itemBuilder: (context, index) {
          return _buildUpcomingExamCard(_upcomingExams[index]);
        },
      ),
    );
  }

  Widget _buildCompletedExamsTab() {
    if (_completedExams.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No Completed Exams',
        subtitle: 'Your exam history will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStudentExams,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _completedExams.length,
        itemBuilder: (context, index) {
          return _buildCompletedExamCard(_completedExams[index]);
        },
      ),
    );
  }

  Widget _buildAvailableExamCard(ExamModel exam) {
    final isActive = exam.isOngoing;
    final timeRemaining = exam.timeRemaining;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: InkWell(
        onTap: isActive ? () => _startExam(exam) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isActive 
                ? Border.all(color: Colors.green, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${exam.subject} • ${exam.className}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive ? Colors.green : Colors.orange,
                      ),
                    ),
                    child: Text(
                      isActive ? 'ACTIVE' : 'SCHEDULED',
                      style: TextStyle(
                        color: isActive ? Colors.green : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy • HH:mm').format(exam.startTime),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    exam.formattedDuration,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.quiz, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${exam.questions.length} questions',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              if (isActive && timeRemaining.inMinutes > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Time remaining: ${timeRemaining.inHours}h ${timeRemaining.inMinutes % 60}m',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isActive ? () => _startExam(exam) : null,
                  icon: Icon(isActive ? Icons.play_arrow : Icons.schedule),
                  label: Text(isActive ? 'Start Exam' : 'Not Started Yet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? Colors.green : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingExamCard(ExamModel exam) {
    final daysUntil = exam.startTime.difference(DateTime.now()).inDays;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${exam.subject} • ${exam.className}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    daysUntil == 0 ? 'Today' : '$daysUntil days',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy • HH:mm').format(exam.startTime),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  exam.formattedDuration,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            if (exam.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                exam.description,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedExamCard(ExamModel exam) {
    final result = _myResults.firstWhere(
      (r) => r.examId == exam.id,
      orElse: () => ExamResult(
        id: '',
        examId: exam.id,
        studentId: _currentStudentId!,
        studentName: 'Student',
        score: 0,
        percentage: 0,
        grade: 'N/A',
        passed: false,
        completedAt: DateTime.now(),
        timeSpent: Duration.zero,
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _viewExamResult(exam, result),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${exam.subject} • ${exam.className}',
                          style: TextStyle(
                            color: Colors.grey[600],
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getGradeColor(result.grade).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          result.grade,
                          style: TextStyle(
                            color: _getGradeColor(result.grade),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${result.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _getGradeColor(result.grade),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    result.passed ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: result.passed ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    result.passed ? 'Passed' : 'Failed',
                    style: TextStyle(
                      color: result.passed ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(result.completedAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
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

  void _startExam(ExamModel exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start ${exam.title}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject: ${exam.subject}'),
            Text('Duration: ${exam.formattedDuration}'),
            Text('Questions: ${exam.questions.length}'),
            const SizedBox(height: 8),
            const Text(
              'Once you start, the timer will begin. Make sure you have a stable internet connection.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToExam(exam);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Exam'),
          ),
        ],
      ),
    );
  }

  void _navigateToExam(ExamModel exam) {
    // Navigate to exam taking screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting exam: ${exam.title}'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Navigate to actual exam taking screen
    // Navigator.pushNamed(context, '/take_exam', arguments: exam.id);
  }

  void _viewExamResult(ExamModel exam, ExamResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${exam.title} - Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: ${result.score}/${exam.totalPoints}'),
            Text('Percentage: ${result.percentage.toStringAsFixed(1)}%'),
            Text('Grade: ${result.grade}'),
            Text('Status: ${result.passed ? "Passed" : "Failed"}'),
            Text('Completed: ${DateFormat('MMM dd, yyyy HH:mm').format(result.completedAt)}'),
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
}
