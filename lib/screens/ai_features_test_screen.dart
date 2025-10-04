import 'package:flutter/material.dart';
import '../services/ai_chatbot_service.dart';
import '../services/ai_grading_service.dart';
import '../services/ai_predictive_analytics_service.dart';
import '../utils/enhanced_responsive_helper.dart';
import '../theme/app_theme.dart';

class AIFeaturesTestScreen extends StatefulWidget {
  const AIFeaturesTestScreen({super.key});

  @override
  State<AIFeaturesTestScreen> createState() => _AIFeaturesTestScreenState();
}

class _AIFeaturesTestScreenState extends State<AIFeaturesTestScreen> {
  final _chatbotService = AIChatbotService();
  final _gradingService = AIGradingService();
  final _analyticsService = AIPredictiveAnalyticsService();

  final List<AITestResult> _testResults = [];
  bool _isRunningTests = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Features Test'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: EnhancedResponsiveLayout(
        smallMobile: _buildMobileLayout(),
        mobile: _buildMobileLayout(),
        largeMobile: _buildTabletLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTestHeader(),
          const SizedBox(height: 20),
          _buildTestControls(),
          const SizedBox(height: 20),
          _buildTestResults(),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTestHeader(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildTestControls(),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _buildTestResults(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTestHeader(),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildTestControls(),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 3,
                child: _buildTestResults(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestHeader() {
    return EnhancedResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppTheme.primaryColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI-Powered Features',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Intelligent systems for Pakistani school management',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFeatureChip('AI Chatbot', Icons.chat_bubble_outline),
              _buildFeatureChip('Auto Grading', Icons.grade),
              _buildFeatureChip('Predictive Analytics', Icons.trending_up),
              _buildFeatureChip('Performance Insights', Icons.insights),
              _buildFeatureChip('Risk Assessment', Icons.warning_amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppTheme.primaryColor),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: AppTheme.primaryColor.withAlpha(25),
    );
  }

  Widget _buildTestControls() {
    return EnhancedResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Test Controls',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: EnhancedResponsiveButton(
              text: _isRunningTests ? 'Running AI Tests...' : 'Run All AI Tests',
              icon: Icon(_isRunningTests ? Icons.hourglass_empty : Icons.play_arrow),
              onPressed: _isRunningTests ? null : _runAllTests,
              isLoading: _isRunningTests,
              enableHapticFeedback: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: EnhancedResponsiveButton(
              text: 'Clear Results',
              icon: const Icon(Icons.clear),
              onPressed: _clearResults,
              enableHapticFeedback: true,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Individual AI Tests',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildIndividualTestButton('AI Chatbot', _testChatbot),
          _buildIndividualTestButton('Auto Grading', _testGrading),
          _buildIndividualTestButton('Predictive Analytics', _testAnalytics),
          const SizedBox(height: 20),
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton('Open AI Chatbot', Icons.chat, () {
            Navigator.pushNamed(context, '/ai_chatbot');
          }),
          _buildQuickActionButton('View Analytics', Icons.analytics, () {
            // Navigate to analytics dashboard
          }),
        ],
      ),
    );
  }

  Widget _buildIndividualTestButton(String testName, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _isRunningTests ? null : onPressed,
          child: Text(testName),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: Icon(icon, size: 16),
          label: Text(title),
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTestResults() {
    return EnhancedResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'AI Test Results',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_testResults.isNotEmpty) ...[
                Text(
                  '${_testResults.where((r) => r.passed).length}/${_testResults.length} Passed',
                  style: TextStyle(
                    color: _testResults.every((r) => r.passed) ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (_testResults.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.psychology, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No AI tests run yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Click "Run All AI Tests" to start testing',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _testResults.map((result) => _buildTestResultCard(result)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTestResultCard(AITestResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: result.passed ? Colors.green.withAlpha(25) : Colors.red.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.passed ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.passed ? Icons.check_circle : Icons.error,
                color: result.passed ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.testName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: result.passed ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
              if (result.confidence != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(result.confidence!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(result.confidence! * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Text(
                '${result.duration.inMilliseconds}ms',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.description,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          if (result.details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                result.details,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults.clear();
    });

    try {
      await _testChatbot();
      await _testGrading();
      await _testAnalytics();
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  void _clearResults() {
    setState(() {
      _testResults.clear();
    });
  }

  Future<void> _testChatbot() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Test chatbot response
      final response = await _chatbotService.sendMessage(
        userId: 'test_user_ai',
        message: 'Hello, what are my grades?',
        language: 'en',
      );

      // Test Urdu support
      final urduResponse = await _chatbotService.sendMessage(
        userId: 'test_user_ai',
        message: 'السلام علیکم',
        language: 'ur',
      );

      // Test analytics
      final analytics = await _chatbotService.getChatbotAnalytics(
        userId: 'test_user_ai',
      );

      _addTestResult(AITestResult(
        testName: 'AI Chatbot System',
        description: 'Multi-language chatbot with Pakistani context',
        passed: response.confidence > 0.5 && urduResponse.confidence > 0.5,
        duration: stopwatch.elapsed,
        confidence: (response.confidence + urduResponse.confidence) / 2,
        details: 'English confidence: ${(response.confidence * 100).toInt()}%, Urdu confidence: ${(urduResponse.confidence * 100).toInt()}%, Total messages: ${analytics.totalMessages}',
      ));
    } catch (e) {
      _addTestResult(AITestResult(
        testName: 'AI Chatbot System',
        description: 'Chatbot test failed',
        passed: false,
        duration: stopwatch.elapsed,
        details: 'Exception: $e',
      ));
    }
  }

  Future<void> _testGrading() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Test multiple choice grading
      final mcqResult = await _gradingService.gradeMultipleChoice(
        questionId: 'test_mcq_001',
        studentAnswers: ['A', 'B', 'C', 'A'],
        correctAnswers: ['A', 'B', 'D', 'A'],
        scorePerQuestion: 25.0,
      );

      // Test essay grading
      final essayResult = await _gradingService.gradeEssay(
        essayId: 'test_essay_001',
        studentEssay: 'Pakistan is a beautiful country with rich culture and history. The education system is improving with technology integration.',
        keywords: ['Pakistan', 'education', 'technology', 'culture'],
        rubric: GradingRubric.defaultRubric(),
      );

      // Test analytics
      final analytics = await _gradingService.getGradingAnalytics();

      _addTestResult(AITestResult(
        testName: 'AI Automated Grading',
        description: 'Multi-format grading with Pakistani context',
        passed: mcqResult.confidence > 0.8 && essayResult.confidence > 0.5,
        duration: stopwatch.elapsed,
        confidence: (mcqResult.confidence + essayResult.confidence) / 2,
        details: 'MCQ Score: ${mcqResult.score}/${mcqResult.maxScore}, Essay Score: ${essayResult.score.toStringAsFixed(1)}/100, Total graded: ${analytics.totalGraded}',
      ));
    } catch (e) {
      _addTestResult(AITestResult(
        testName: 'AI Automated Grading',
        description: 'Grading test failed',
        passed: false,
        duration: stopwatch.elapsed,
        details: 'Exception: $e',
      ));
    }
  }

  Future<void> _testAnalytics() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Create sample student data
      final sampleData = [
        StudentDataPoint(
          studentId: 'student_001',
          subject: 'Mathematics',
          grade: 85.0,
          attendanceRate: 95.0,
          assignmentCompletion: 90.0,
          date: DateTime.now().subtract(const Duration(days: 30)),
        ),
        StudentDataPoint(
          studentId: 'student_001',
          subject: 'Mathematics',
          grade: 78.0,
          attendanceRate: 88.0,
          assignmentCompletion: 85.0,
          date: DateTime.now().subtract(const Duration(days: 15)),
        ),
        StudentDataPoint(
          studentId: 'student_001',
          subject: 'Mathematics',
          grade: 72.0,
          attendanceRate: 82.0,
          assignmentCompletion: 80.0,
          date: DateTime.now(),
        ),
      ];

      // Test performance prediction
      final prediction = await _analyticsService.predictStudentPerformance(
        studentId: 'student_001',
        historicalData: sampleData,
      );

      // Test at-risk identification
      final atRiskStudents = await _analyticsService.identifyAtRiskStudents(
        allStudentData: sampleData,
      );

      // Test learning path generation
      final learningPath = await _analyticsService.generateLearningPath(
        studentId: 'student_001',
        performanceData: sampleData,
        subjects: ['Mathematics', 'Physics', 'English'],
      );

      // Test dashboard analytics
      final dashboard = await _analyticsService.getAnalyticsDashboard();

      _addTestResult(AITestResult(
        testName: 'AI Predictive Analytics',
        description: 'Student performance prediction and risk assessment',
        passed: prediction.confidence > 0.5 && prediction.predictedGrade > 0,
        duration: stopwatch.elapsed,
        confidence: prediction.confidence,
        details: 'Predicted Grade: ${prediction.predictedGrade.toStringAsFixed(1)}, Risk Level: ${prediction.riskLevel.name}, At-risk Students: ${atRiskStudents.length}, Learning Recommendations: ${learningPath.recommendations.length}',
      ));
    } catch (e) {
      _addTestResult(AITestResult(
        testName: 'AI Predictive Analytics',
        description: 'Analytics test failed',
        passed: false,
        duration: stopwatch.elapsed,
        details: 'Exception: $e',
      ));
    }
  }

  void _addTestResult(AITestResult result) {
    setState(() {
      _testResults.add(result);
    });
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

class AITestResult {
  final String testName;
  final String description;
  final bool passed;
  final Duration duration;
  final double? confidence;
  final String details;

  AITestResult({
    required this.testName,
    required this.description,
    required this.passed,
    required this.duration,
    this.confidence,
    required this.details,
  });
}
