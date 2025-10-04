import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/firebase_attendance_service.dart';
import '../services/firebase_auth_service.dart';
import '../models/attendance_model.dart';
import '../theme/app_theme.dart';

class StudentAttendanceAnalyticsScreen extends StatefulWidget {
  const StudentAttendanceAnalyticsScreen({super.key});

  @override
  State<StudentAttendanceAnalyticsScreen> createState() => _StudentAttendanceAnalyticsScreenState();
}

class _StudentAttendanceAnalyticsScreenState extends State<StudentAttendanceAnalyticsScreen> {
  bool _isLoading = true;
  List<AttendanceModel> _attendanceRecords = [];
  Map<String, dynamic> _attendanceStats = {};
  String _selectedPeriod = 'month'; // 'week', 'month', 'term', 'year'
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    setState(() => _isLoading = true);
    
    try {
      final studentId = FirebaseAuthService.currentUserId!;
      
      // Set date range based on selected period
      _setDateRange();
      
      final records = await FirebaseAttendanceService.getStudentAttendance(
        studentId: studentId,
        startDate: _startDate,
        endDate: _endDate,
      );
      
      final stats = await FirebaseAttendanceService.getStudentAttendanceStats(
        studentId: studentId,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _attendanceRecords = records;
        _attendanceStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading attendance data: $e');
    }
  }

  void _setDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'week':
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        break;
      case 'month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'term':
        // Assuming term starts in September
        _startDate = DateTime(now.year, 9, 1);
        _endDate = now;
        break;
      case 'year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
        break;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (period) {
              setState(() => _selectedPeriod = period);
              _loadAttendanceData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'week', child: Text('This Week')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
              const PopupMenuItem(value: 'term', child: Text('This Term')),
              const PopupMenuItem(value: 'year', child: Text('This Year')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildAnalyticsContent(),
    );
  }

  Widget _buildAnalyticsContent() {
    if (_attendanceRecords.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No attendance records found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodHeader(),
          const SizedBox(height: 20),
          _buildStatsCards(),
          const SizedBox(height: 20),
          _buildAttendanceChart(),
          const SizedBox(height: 20),
          _buildWeeklyPattern(),
          const SizedBox(height: 20),
          _buildRecentRecords(),
        ],
      ),
    );
  }

  Widget _buildPeriodHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.date_range, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Period: ${_selectedPeriod.toUpperCase()}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalDays = _attendanceStats['totalDays'] ?? 0;
    final presentDays = _attendanceStats['presentDays'] ?? 0;
    final absentDays = _attendanceStats['absentDays'] ?? 0;
    final lateDays = _attendanceStats['lateDays'] ?? 0;
    final attendancePercentage = _attendanceStats['attendancePercentage'] ?? 0.0;

    return Column(
      children: [
        // Main Attendance Percentage
        Card(
          color: _getAttendanceColor(attendancePercentage),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  attendancePercentage >= 75 ? Icons.check_circle : Icons.warning,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Attendance',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Text(
                        '${attendancePercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$presentDays present out of $totalDays days',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Stats Grid
        Row(
          children: [
            Expanded(child: _buildStatCard('Present', presentDays, Colors.green, Icons.check_circle)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('Absent', absentDays, Colors.red, Icons.cancel)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildStatCard('Late', lateDays, Colors.orange, Icons.access_time)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('Total', totalDays, Colors.blue, Icons.calendar_today)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceChart() {
    final monthlyStats = _attendanceStats['monthlyStats'] as Map<String, dynamic>? ?? {};
    
    if (monthlyStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Attendance Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                          final index = value.toInt() - 1;
                          if (index >= 0 && index < months.length) {
                            return Text(months[index]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _getChartSpots(monthlyStats),
                      isCurved: true,
                      color: AppTheme.primaryColor,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getChartSpots(Map<String, dynamic> monthlyStats) {
    final spots = <FlSpot>[];
    
    monthlyStats.forEach((monthStr, stats) {
      final month = int.tryParse(monthStr) ?? 1;
      final statsMap = stats as Map<String, dynamic>;
      final present = statsMap['present'] ?? 0;
      final total = (statsMap['present'] ?? 0) + 
                   (statsMap['absent'] ?? 0) + 
                   (statsMap['late'] ?? 0) + 
                   (statsMap['excused'] ?? 0);
      
      if (total > 0) {
        final percentage = (present / total) * 100;
        spots.add(FlSpot(month.toDouble(), percentage));
      }
    });
    
    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }

  Widget _buildWeeklyPattern() {
    final weeklyPattern = _attendanceStats['weeklyPattern'] as Map<String, int>? ?? {};
    
    if (weeklyPattern.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Attendance Pattern',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...weeklyPattern.entries.map((entry) {
              final day = entry.key;
              final count = entry.value;
              final maxCount = weeklyPattern.values.reduce((a, b) => a > b ? a : b);
              final percentage = maxCount > 0 ? (count / maxCount) : 0.0;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(day, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRecords() {
    final recentRecords = _attendanceRecords.take(10).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Attendance Records',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...recentRecords.map((record) => _buildRecordTile(record)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordTile(AttendanceModel record) {
    final statusColor = _getStatusColor(record.status);
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor,
        child: Icon(
          _getStatusIcon(record.status),
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(record.courseName),
      subtitle: Text(
        '${record.subject} • ${DateFormat('dd MMM yyyy').format(record.date)}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            record.status.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          if (record.checkInTime != null)
            Text(
              DateFormat('HH:mm').format(record.checkInTime!),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'excused':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      case 'excused':
        return Icons.event_available;
      default:
        return Icons.help;
    }
  }
}
