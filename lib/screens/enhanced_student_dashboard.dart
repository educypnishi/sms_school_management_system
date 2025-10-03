import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/fee_model.dart';
import '../services/fee_service.dart';
import '../services/push_notification_service.dart';
import '../utils/responsive_helper.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

class EnhancedStudentDashboard extends StatefulWidget {
  const EnhancedStudentDashboard({super.key});

  @override
  State<EnhancedStudentDashboard> createState() => _EnhancedStudentDashboardState();
}

class _EnhancedStudentDashboardState extends State<EnhancedStudentDashboard> {
  String _userName = 'Ahmed Ali';
  bool _isLoading = true;
  
  // Services
  final _feeService = FeeService();
  final _notificationService = PushNotificationService();
  
  // Enhanced dashboard data
  List<FeeModel> _fees = [];
  double _totalDue = 0.0;
  double _totalPaid = 0.0;
  int _pendingFeesCount = 0;
  int _notificationCount = 3; // Sample notification count
  List<Map<String, dynamic>> _todayClasses = [];
  List<Map<String, dynamic>> _upcomingExams = [];

  @override
  void initState() {
    super.initState();
    _loadEnhancedData();
  }

  Future<void> _loadEnhancedData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadFeeData();
      await _loadTodayClasses();
      await _loadUpcomingExams();
    } catch (e) {
      debugPrint('Error loading enhanced data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFeeData() async {
    try {
      // Generate sample fees if needed
      await _feeService.generateSampleFees();
      
      // Get fees for current user
      final fees = await _feeService.getFeesForStudent('demo_user_123');
      
      double totalDue = 0.0;
      double totalPaid = 0.0;
      int pendingCount = 0;
      
      for (final fee in fees) {
        totalDue += fee.remainingAmount;
        totalPaid += fee.amountPaid;
        
        if (fee.status == PaymentStatus.pending || fee.status == PaymentStatus.partiallyPaid) {
          pendingCount++;
        }
      }
      
      setState(() {
        _fees = fees;
        _totalDue = totalDue;
        _totalPaid = totalPaid;
        _pendingFeesCount = pendingCount;
      });
    } catch (e) {
      debugPrint('Error loading fee data: $e');
    }
  }

  Future<void> _loadTodayClasses() async {
    setState(() {
      _todayClasses = [
        {
          'subject': 'Mathematics',
          'time': '9:00 AM - 10:00 AM',
          'room': 'Room 101',
          'teacher': 'Mr. Khan'
        },
        {
          'subject': 'Physics',
          'time': '11:00 AM - 12:00 PM',
          'room': 'Lab 1',
          'teacher': 'Dr. Ahmed'
        },
        {
          'subject': 'English',
          'time': '2:00 PM - 3:00 PM',
          'room': 'Room 205',
          'teacher': 'Ms. Fatima'
        },
      ];
    });
  }

  Future<void> _loadUpcomingExams() async {
    setState(() {
      _upcomingExams = [
        {
          'subject': 'Mathematics',
          'date': DateTime.now().add(const Duration(days: 5)),
          'type': 'Mid Term'
        },
        {
          'subject': 'Physics',
          'date': DateTime.now().add(const Duration(days: 12)),
          'type': 'Quiz'
        },
        {
          'subject': 'Chemistry',
          'date': DateTime.now().add(const Duration(days: 18)),
          'type': 'Final'
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Enhanced Notification Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
                tooltip: 'Notifications',
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ResponsiveLayout(
                mobile: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeeSummaryCard(),
                    const SizedBox(height: 16),
                    _buildTodayClassesCard(),
                    const SizedBox(height: 16),
                    _buildUpcomingExamsCard(),
                    const SizedBox(height: 16),
                    _buildQuickActionsCard(),
                  ],
                ),
                tablet: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildFeeSummaryCard(),
                          const SizedBox(height: 16),
                          _buildTodayClassesCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildUpcomingExamsCard(),
                          const SizedBox(height: 16),
                          _buildQuickActionsCard(),
                        ],
                      ),
                    ),
                  ],
                ),
                desktop: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildFeeSummaryCard()),
                              const SizedBox(width: 16),
                              Expanded(child: _buildTodayClassesCard()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildQuickActionsCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: _buildUpcomingExamsCard(),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFeeSummaryCard() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Fee Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_pendingFeesCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_pendingFeesCount pending',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFeeStatCard(
                  'Total Due',
                  'PKR ${NumberFormat('#,##0').format(_totalDue)}',
                  Colors.red,
                  Icons.payment,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeeStatCard(
                  'Total Paid',
                  'PKR ${NumberFormat('#,##0').format(_totalPaid)}',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/student_fee_dashboard');
              },
              icon: const Icon(Icons.payment),
              label: const Text('Pay Fees'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeStatCard(String title, String amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayClassesCard() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: AppTheme.secondaryColor),
              const SizedBox(width: 8),
              Text(
                'Today\'s Classes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM dd').format(DateTime.now()),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_todayClasses.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'No classes scheduled for today',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Column(
              children: _todayClasses.take(3).map((classInfo) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: const Border(
                      left: BorderSide(
                        color: AppTheme.secondaryColor,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classInfo['subject'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${classInfo['room']} • ${classInfo['teacher']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        classInfo['time'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/timetable_viewer');
            },
            icon: const Icon(Icons.calendar_view_day),
            label: const Text('View Full Timetable'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingExamsCard() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.quiz, color: AppTheme.accentColor),
              const SizedBox(width: 8),
              Text(
                'Upcoming Exams',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_upcomingExams.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'No upcoming exams',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Column(
              children: _upcomingExams.take(3).map((exam) {
                final daysUntil = exam['date'].difference(DateTime.now()).inDays;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: const Border(
                      left: BorderSide(
                        color: AppTheme.accentColor,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exam['subject'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              exam['type'],
                              style: TextStyle(
                                color: Colors.grey[600],
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
                              color: daysUntil <= 7 ? Colors.red : AppTheme.accentColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$daysUntil days',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd').format(exam['date']),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/exam_scheduler');
            },
            icon: const Icon(Icons.event_note),
            label: const Text('View All Exams'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: ResponsiveHelper.getScreenType(context) == ScreenType.mobile ? 2 : 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildActionCard(
                'My Assignments',
                Icons.assignment,
                AppTheme.secondaryColor,
                () => Navigator.pushNamed(context, '/assignments'),
              ),
              _buildActionCard(
                'My Documents',
                Icons.folder,
                AppTheme.accentColor,
                () => Navigator.pushNamed(context, '/documents'),
              ),
              _buildActionCard(
                'Messages',
                Icons.chat,
                Colors.green,
                () => Navigator.pushNamed(context, '/messages'),
              ),
              _buildActionCard(
                'Performance',
                Icons.analytics,
                Colors.purple,
                () => Navigator.pushNamed(context, '/performance'),
              ),
              _buildActionCard(
                'Attendance',
                Icons.fact_check,
                Colors.teal,
                () => Navigator.pushNamed(context, '/attendance'),
              ),
              _buildActionCard(
                'Calendar',
                Icons.calendar_today,
                Colors.orange,
                () => Navigator.pushNamed(context, '/calendar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(76)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: ResponsiveHelper.getResponsiveValue(
                context,
                mobile: 32.0,
                tablet: 36.0,
                desktop: 40.0,
              ),
              color: color,
            ),
            const SizedBox(height: 8),
            ResponsiveText(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: ResponsiveHelper.getResponsiveValue(
                  context,
                  mobile: 12.0,
                  tablet: 14.0,
                  desktop: 16.0,
                ),
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
