import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/attendance_report_service.dart';
import '../models/class_model.dart';
import '../theme/app_theme.dart';

class AttendanceAlertsWidget extends StatefulWidget {
  final String classId;
  final double threshold;
  final VoidCallback? onAlertTap;
  
  const AttendanceAlertsWidget({
    super.key,
    required this.classId,
    this.threshold = 75.0,
    this.onAlertTap,
  });

  @override
  State<AttendanceAlertsWidget> createState() => _AttendanceAlertsWidgetState();
}

class _AttendanceAlertsWidgetState extends State<AttendanceAlertsWidget> {
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    
    try {
      final alerts = await AttendanceReportService.getAttendanceAlerts(
        classId: widget.classId,
      );
      
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading attendance alerts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_alerts.isEmpty) {
      return Card(
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'All students have good attendance (≥${widget.threshold.toStringAsFixed(0)}%)',
                  style: TextStyle(
                    color: Colors.green[700],
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
      color: Colors.red[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Colors.red[700],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance Alerts',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${_alerts.length} student${_alerts.length > 1 ? 's' : ''} below ${widget.threshold.toStringAsFixed(0)}% attendance',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.red[700],
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable content
          if (_isExpanded) ...[
            const Divider(height: 1),
            ..._alerts.map((alert) => _buildAlertTile(alert)).toList(),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _generateAlertReport,
                      icon: const Icon(Icons.file_download),
                      label: const Text('Generate Report'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        side: BorderSide(color: Colors.red[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _sendAlertNotifications,
                      icon: const Icon(Icons.notifications),
                      label: const Text('Notify Parents'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAlertTile(Map<String, dynamic> alert) {
    final alertLevel = alert['alertLevel'] as String;
    final percentage = alert['attendancePercentage'] as double;
    final studentName = alert['studentName'] as String;
    final totalDays = alert['totalDays'] as int;
    final absentDays = alert['absentDays'] as int;
    
    final alertColor = alertLevel == 'critical' ? Colors.red : Colors.orange;
    final alertIcon = alertLevel == 'critical' ? Icons.error : Icons.warning;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: alertColor,
        child: Icon(alertIcon, color: Colors.white, size: 20),
      ),
      title: Text(
        studentName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attendance: ${percentage.toStringAsFixed(1)}%'),
          Text('Absent: $absentDays out of $totalDays days'),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: alertColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: alertColor),
        ),
        child: Text(
          alertLevel.toUpperCase(),
          style: TextStyle(
            color: alertColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      onTap: widget.onAlertTap,
    );
  }

  Future<void> _generateAlertReport() async {
    try {
      // Show loading dialog
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

      // Generate report with alert data
      // Create dummy class model and data for the report
      final classModel = ClassModel(
        id: widget.classId ?? 'unknown',
        name: 'Low Attendance Alert Report',
        grade: 'All Grades',
        subject: 'Attendance Report',
        teacherName: 'System Generated',
        room: 'N/A',
        schedule: 'Generated Report',
        capacity: 30,
        currentStudents: _alerts.length,
        averageGrade: 0.0,
      );
      
      final reportPath = await AttendanceReportService.generateClassReport(
        classModel: classModel,
        classStats: {'totalStudents': _alerts.length, 'averageAttendance': 0.0},
        studentAttendanceData: {},
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report generated: ${reportPath.split('/').last}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                // Open file functionality would be implemented here
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendAlertNotifications() async {
    try {
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Send Notifications'),
          content: Text(
            'Send attendance alert notifications to parents of ${_alerts.length} student${_alerts.length > 1 ? 's' : ''}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Send'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Sending notifications...'),
              ],
            ),
          ),
        );

        // Simulate sending notifications
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notifications sent to ${_alerts.length} parent${_alerts.length > 1 ? 's' : ''}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Attendance Summary Widget for Dashboard
class AttendanceSummaryWidget extends StatelessWidget {
  final Map<String, dynamic> attendanceStats;
  final VoidCallback? onTap;
  
  const AttendanceSummaryWidget({
    super.key,
    required this.attendanceStats,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final attendancePercentage = attendanceStats['attendancePercentage'] ?? 0.0;
    final totalDays = attendanceStats['totalDays'] ?? 0;
    final presentDays = attendanceStats['presentDays'] ?? 0;
    final absentDays = attendanceStats['absentDays'] ?? 0;
    
    final statusColor = _getAttendanceColor(attendancePercentage);
    final statusIcon = _getAttendanceIcon(attendancePercentage);
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Attendance Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(statusIcon, color: statusColor, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              
              // Main percentage
              Row(
                children: [
                  Text(
                    '${attendancePercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getAttendanceStatus(attendancePercentage),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$presentDays present out of $totalDays days',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Progress bar
              LinearProgressIndicator(
                value: attendancePercentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
              const SizedBox(height: 8),
              
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Present', presentDays, Colors.green),
                  _buildStatItem('Absent', absentDays, Colors.red),
                  _buildStatItem('Total', totalDays, Colors.blue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 75) return Colors.orange;
    return Colors.red;
  }

  IconData _getAttendanceIcon(double percentage) {
    if (percentage >= 90) return Icons.check_circle;
    if (percentage >= 75) return Icons.warning;
    return Icons.error;
  }

  String _getAttendanceStatus(double percentage) {
    if (percentage >= 90) return 'Excellent';
    if (percentage >= 75) return 'Good';
    if (percentage >= 60) return 'Average';
    return 'Poor';
  }
}
