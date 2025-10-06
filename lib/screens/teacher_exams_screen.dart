import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exam_model.dart';
import '../services/firebase_exam_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class TeacherExamsScreen extends StatefulWidget {
  const TeacherExamsScreen({super.key});

  @override
  State<TeacherExamsScreen> createState() => _TeacherExamsScreenState();
}

class _TeacherExamsScreenState extends State<TeacherExamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ExamModel> _myExams = [];
  List<ExamModel> _activeExams = [];
  List<ExamModel> _draftExams = [];
  bool _isLoading = true;
  String? _currentTeacherId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTeacherExams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherExams() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current teacher ID
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      _currentTeacherId = currentUser?.id ?? 'demo_teacher';

      // Load teacher's exams
      final allExams = await FirebaseExamService.getExamsByTeacher(_currentTeacherId!);
      
      setState(() {
        _myExams = allExams;
        _activeExams = allExams.where((exam) => exam.isActive || exam.isOngoing).toList();
        _draftExams = allExams.where((exam) => exam.isDraft).toList();
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
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.quiz), text: 'All Exams'),
            Tab(icon: Icon(Icons.play_circle), text: 'Active'),
            Tab(icon: Icon(Icons.edit), text: 'Drafts'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllExamsTab(),
                _buildActiveExamsTab(),
                _buildDraftsTab(),
                _buildAnalyticsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewExam,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Exam'),
      ),
    );
  }

  Widget _buildAllExamsTab() {
    if (_myExams.isEmpty) {
      return _buildEmptyState(
        icon: Icons.quiz_outlined,
        title: 'No Exams Created',
        subtitle: 'Create your first exam to get started',
        actionText: 'Create Exam',
        onAction: _createNewExam,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTeacherExams,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myExams.length,
        itemBuilder: (context, index) {
          return _buildExamCard(_myExams[index]);
        },
      ),
    );
  }

  Widget _buildActiveExamsTab() {
    if (_activeExams.isEmpty) {
      return _buildEmptyState(
        icon: Icons.play_circle_outline,
        title: 'No Active Exams',
        subtitle: 'No exams are currently running',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTeacherExams,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeExams.length,
        itemBuilder: (context, index) {
          return _buildExamCard(_activeExams[index], showActiveIndicator: true);
        },
      ),
    );
  }

  Widget _buildDraftsTab() {
    if (_draftExams.isEmpty) {
      return _buildEmptyState(
        icon: Icons.edit_outlined,
        title: 'No Draft Exams',
        subtitle: 'All your exams have been published',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTeacherExams,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _draftExams.length,
        itemBuilder: (context, index) {
          return _buildExamCard(_draftExams[index], isDraft: true);
        },
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exam Statistics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Exams',
                  '${_myExams.length}',
                  Icons.quiz,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Active Exams',
                  '${_activeExams.length}',
                  Icons.play_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Draft Exams',
                  '${_draftExams.length}',
                  Icons.edit,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  '${_myExams.where((e) => e.isCompleted).length}',
                  Icons.check_circle,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.add_circle, color: Colors.green),
                    title: const Text('Create New Exam'),
                    subtitle: const Text('Start building a new exam'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _createNewExam,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.auto_awesome, color: Colors.purple),
                    title: const Text('AI Exam Generator'),
                    subtitle: const Text('Generate exam with AI assistance'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _generateAIExam,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.analytics, color: Colors.blue),
                    title: const Text('View All Analytics'),
                    subtitle: const Text('Detailed performance reports'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _viewDetailedAnalytics,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(ExamModel exam, {bool showActiveIndicator = false, bool isDraft = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: showActiveIndicator ? 4 : 2,
      child: InkWell(
        onTap: () => _viewExamDetails(exam),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: showActiveIndicator 
                ? Border.all(color: Colors.green, width: 2)
                : isDraft 
                    ? Border.all(color: Colors.orange, width: 1)
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
                      color: exam.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: exam.statusColor),
                    ),
                    child: Text(
                      exam.statusText,
                      style: TextStyle(
                        color: exam.statusColor,
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
              if (exam.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  exam.description,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${exam.eligibleStudents.length} students',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _editExam(exam),
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: 'Edit Exam',
                      ),
                      IconButton(
                        onPressed: () => _viewResults(exam),
                        icon: const Icon(Icons.analytics, size: 20),
                        tooltip: 'View Results',
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleExamAction(exam, value),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy),
                                SizedBox(width: 8),
                                Text('Duplicate'),
                              ],
                            ),
                          ),
                          if (exam.isDraft)
                            const PopupMenuItem(
                              value: 'publish',
                              child: Row(
                                children: [
                                  Icon(Icons.publish, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Publish'),
                                ],
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'export',
                            child: Row(
                              children: [
                                Icon(Icons.download),
                                SizedBox(width: 8),
                                Text('Export'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
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
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionText),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _createNewExam() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Exam'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose how you want to create your exam:'),
            SizedBox(height: 16),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _createManualExam();
            },
            icon: const Icon(Icons.edit),
            label: const Text('Manual'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _generateAIExam();
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI Generate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _createManualExam() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening exam creation form...'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Navigate to exam creation form
  }

  void _generateAIExam() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening AI exam generator...'),
        backgroundColor: Colors.purple,
      ),
    );
    // TODO: Navigate to AI exam generator
  }

  void _editExam(ExamModel exam) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editing exam: ${exam.title}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _viewExamDetails(ExamModel exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exam.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject: ${exam.subject}'),
            Text('Class: ${exam.className}'),
            Text('Status: ${exam.statusText}'),
            Text('Duration: ${exam.formattedDuration}'),
            Text('Questions: ${exam.questions.length}'),
            Text('Students: ${exam.eligibleStudents.length}'),
            Text('Total Points: ${exam.totalPoints}'),
            const SizedBox(height: 8),
            const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(exam.description.isNotEmpty ? exam.description : 'No description'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _viewResults(exam);
            },
            child: const Text('View Results'),
          ),
        ],
      ),
    );
  }

  void _viewResults(ExamModel exam) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing results for: ${exam.title}'),
        backgroundColor: Colors.green,
      ),
    );
    // TODO: Navigate to exam results screen
  }

  void _viewDetailedAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening detailed analytics...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _handleExamAction(ExamModel exam, String action) {
    switch (action) {
      case 'duplicate':
        _duplicateExam(exam);
        break;
      case 'publish':
        _publishExam(exam);
        break;
      case 'export':
        _exportExam(exam);
        break;
      case 'delete':
        _confirmDeleteExam(exam);
        break;
    }
  }

  void _duplicateExam(ExamModel exam) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Duplicating: ${exam.title}')),
    );
  }

  void _publishExam(ExamModel exam) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Publishing: ${exam.title}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportExam(ExamModel exam) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exporting: ${exam.title}')),
    );
  }

  void _confirmDeleteExam(ExamModel exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exam'),
        content: Text('Are you sure you want to delete "${exam.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseExamService.deleteExam(exam.id);
                _loadTeacherExams();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Exam deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting exam: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
