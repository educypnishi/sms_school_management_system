import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/firebase_attendance_service.dart';
import '../services/firebase_class_service.dart';
import '../services/attendance_report_service.dart';
import '../models/class_model.dart';
import '../theme/app_theme.dart';
import '../widgets/attendance_alerts_widget.dart';

class AdminAttendanceOverviewScreen extends StatefulWidget {
  const AdminAttendanceOverviewScreen({super.key});

  @override
  State<AdminAttendanceOverviewScreen> createState() => _AdminAttendanceOverviewScreenState();
}

class _AdminAttendanceOverviewScreenState extends State<AdminAttendanceOverviewScreen> {
  bool _isLoading = true;
  List<ClassModel> _allClasses = [];
  Map<String, Map<String, dynamic>> _classAttendanceStats = {};
  Map<String, List<Map<String, dynamic>>> _classAlerts = {};
  String _selectedPeriod = 'month';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadOverviewData();
  }

  Future<void> _loadOverviewData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load all classes
      final classes = await FirebaseClassService.getAllClasses();
      
      // Load attendance stats for each class
      final classStats = <String, Map<String, dynamic>>{};
      final classAlerts = <String, List<Map<String, dynamic>>>{};
      
      for (final classModel in classes) {
        final stats = await FirebaseAttendanceService.getClassAttendanceStats(
          classId: classModel.id,
          startDate: _startDate,
          endDate: _endDate,
        );
        
        final alerts = await AttendanceReportService.getAttendanceAlerts(
          classId: classModel.id,
          threshold: 75.0,
        );
        
        classStats[classModel.id] = stats;
        classAlerts[classModel.id] = alerts;
      }

      setState(() {
        _allClasses = classes;
        _classAttendanceStats = classStats;
        _classAlerts = classAlerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading attendance overview: $e');
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
        title: const Text('Attendance Overview'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (period) {
              setState(() => _selectedPeriod = period);
              _setDateRange();
              _loadOverviewData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'week', child: Text('This Week')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
              const PopupMenuItem(value: 'term', child: Text('This Term')),
              const PopupMenuItem(value: 'year', child: Text('This Year')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOverviewData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildOverviewContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateSchoolReport,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.file_download),
        label: const Text('Generate Report'),
      ),
    );
  }

  Widget _buildOverviewContent() {
    if (_allClasses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No classes found',
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
          _buildSchoolSummary(),
          const SizedBox(height: 20),
          _buildAttendanceChart(),
          const SizedBox(height: 20),
          _buildAlertsSection(),
          const SizedBox(height: 20),
          _buildClassesList(),
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
            const Spacer(),
            Text(
              '${_allClasses.length} Classes',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolSummary() {
    // Calculate overall school statistics
    double totalAttendance = 0.0;
    int totalAlerts = 0;
    int totalStudents = 0;
    
    for (final classModel in _allClasses) {
      final stats = _classAttendanceStats[classModel.id] ?? {};
      final alerts = _classAlerts[classModel.id] ?? [];
      
      totalAttendance += (stats['averageAttendance'] ?? 0.0);
      totalAlerts += alerts.length;
      totalStudents += classModel.currentStudents;
    }
    
    final averageAttendance = _allClasses.isNotEmpty ? totalAttendance / _allClasses.length : 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'School Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSummaryCard('Average Attendance', '${averageAttendance.toStringAsFixed(1)}%', Icons.school, _getAttendanceColor(averageAttendance))),
                const SizedBox(width: 8),
                Expanded(child: _buildSummaryCard('Total Students', totalStudents.toString(), Icons.people, Colors.blue)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildSummaryCard('Active Classes', _allClasses.length.toString(), Icons.class_, Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _buildSummaryCard('Attendance Alerts', totalAlerts.toString(), Icons.warning, totalAlerts > 0 ? Colors.red : Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    if (_classAttendanceStats.isEmpty) {
      return const SizedBox.shrink();
    }

    final chartData = _allClasses.map((classModel) {
      final stats = _classAttendanceStats[classModel.id] ?? {};
      final attendance = (stats['averageAttendance'] ?? 0.0);
      return FlSpot(
        _allClasses.indexOf(classModel).toDouble(),
        attendance,
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Class Attendance Comparison',
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
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _allClasses.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _allClasses[index].name,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData,
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

  Widget _buildAlertsSection() {
    final totalAlerts = _classAlerts.values.fold(0, (sum, alerts) => sum + alerts.length);
    
    if (totalAlerts == 0) {
      return Card(
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'All students have good attendance across all classes',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red[700]),
                const SizedBox(width: 8),
                Text(
                  'Attendance Alerts ($totalAlerts)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._classAlerts.entries.where((entry) => entry.value.isNotEmpty).map((entry) {
              final classModel = _allClasses.firstWhere((c) => c.id == entry.key);
              final alerts = entry.value;
              
              return ExpansionTile(
                title: Text('${classModel.name} (${alerts.length} alerts)'),
                children: alerts.map((alert) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: alert['alertLevel'] == 'critical' ? Colors.red : Colors.orange,
                    child: Icon(
                      alert['alertLevel'] == 'critical' ? Icons.error : Icons.warning,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  title: Text(alert['studentName']),
                  subtitle: Text('${alert['attendancePercentage'].toStringAsFixed(1)}% attendance'),
                  trailing: Text(
                    alert['alertLevel'].toString().toUpperCase(),
                    style: TextStyle(
                      color: alert['alertLevel'] == 'critical' ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )).toList(),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Class Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...(_allClasses.map((classModel) => _buildClassTile(classModel)).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildClassTile(ClassModel classModel) {
    final stats = _classAttendanceStats[classModel.id] ?? {};
    final alerts = _classAlerts[classModel.id] ?? [];
    final attendance = (stats['averageAttendance'] ?? 0.0);
    final attendanceColor = _getAttendanceColor(attendance);
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: attendanceColor,
        child: Text(
          '${attendance.toStringAsFixed(0)}%',
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(classModel.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Teacher: ${classModel.teacherName}'),
          Text('Students: ${classModel.currentStudents}'),
          if (alerts.isNotEmpty)
            Text(
              '${alerts.length} attendance alert${alerts.length > 1 ? 's' : ''}',
              style: const TextStyle(color: Colors.red),
            ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.file_download),
        onPressed: () => _generateClassReport(classModel),
        tooltip: 'Generate Report',
      ),
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }

  Future<void> _generateClassReport(ClassModel classModel) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating report...'),
            ],
          ),
        ),
      );

      final reportPath = await AttendanceReportService.generateClassReport(
        classId: classModel.id,
        className: classModel.name,
        startDate: _startDate,
        endDate: _endDate,
        format: 'pdf',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report generated for ${classModel.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar('Error generating report: $e');
      }
    }
  }

  Future<void> _generateSchoolReport() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating school report...'),
            ],
          ),
        ),
      );

      // Generate reports for all classes
      for (final classModel in _allClasses) {
        await AttendanceReportService.generateClassReport(
          classId: classModel.id,
          className: classModel.name,
          startDate: _startDate,
          endDate: _endDate,
          format: 'pdf',
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('School attendance report generated for ${_allClasses.length} classes'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar('Error generating school report: $e');
      }
    }
  }
}
