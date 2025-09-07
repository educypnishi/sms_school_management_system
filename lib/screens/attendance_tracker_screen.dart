import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../theme/app_theme.dart';
import 'attendance_detail_screen.dart';

class AttendanceTrackerScreen extends StatefulWidget {
  final String userId;
  
  const AttendanceTrackerScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AttendanceTrackerScreen> createState() => _AttendanceTrackerScreenState();
}

class _AttendanceTrackerScreenState extends State<AttendanceTrackerScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isLoading = true;
  List<AttendanceModel> _attendanceRecords = [];
  
  @override
  void initState() {
    super.initState();
    _loadAttendanceRecords();
  }
  
  Future<void> _loadAttendanceRecords() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final attendanceRecords = await _attendanceService.getAttendanceForStudent(widget.userId);
      
      setState(() {
        _attendanceRecords = attendanceRecords;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading attendance records: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendanceRecords,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _attendanceRecords.isEmpty
              ? _buildEmptyState()
              : _buildAttendanceList(),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_today,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No attendance records found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your attendance records will appear here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAttendanceList() {
    // Group attendance records by month
    final Map<String, List<AttendanceModel>> groupedRecords = {};
    
    for (final record in _attendanceRecords) {
      final month = '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
      if (!groupedRecords.containsKey(month)) {
        groupedRecords[month] = [];
      }
      groupedRecords[month]!.add(record);
    }
    
    // Sort months in descending order
    final sortedMonths = groupedRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    return ListView.builder(
      itemCount: sortedMonths.length,
      itemBuilder: (context, index) {
        final month = sortedMonths[index];
        final records = groupedRecords[month]!;
        
        // Calculate attendance percentage for the month
        final totalDays = records.length;
        final presentDays = records.where((r) => r.status == 'present').length;
        final attendancePercentage = totalDays > 0 ? (presentDays / totalDays * 100).toStringAsFixed(1) : '0.0';
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            title: Text(
              _formatMonth(month),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Attendance: $attendancePercentage%'),
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: records.length,
                itemBuilder: (context, recordIndex) {
                  final record = records[recordIndex];
                  return ListTile(
                    leading: Icon(
                      record.status == 'present'
                          ? Icons.check_circle
                          : record.status == 'absent'
                              ? Icons.cancel
                              : Icons.access_time,
                      color: record.status == 'present'
                          ? Colors.green
                          : record.status == 'absent'
                              ? Colors.red
                              : Colors.orange,
                    ),
                    title: Text(
                      '${record.date.day}/${record.date.month}/${record.date.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(record.courseName),
                    trailing: Text(
                      record.status.toUpperCase(),
                      style: TextStyle(
                        color: record.status == 'present'
                            ? Colors.green
                            : record.status == 'absent'
                                ? Colors.red
                                : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AttendanceDetailScreen(
                            attendanceId: record.id,
                          ),
                        ),
                      ).then((_) => _loadAttendanceRecords());
                    },
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildAttendanceSummary(records),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildAttendanceSummary(List<AttendanceModel> records) {
    final totalDays = records.length;
    final presentDays = records.where((r) => r.status == 'present').length;
    final absentDays = records.where((r) => r.status == 'absent').length;
    final lateDays = records.where((r) => r.status == 'late').length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Summary',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSummaryItem('Present', presentDays, Colors.green),
            ),
            Expanded(
              child: _buildSummaryItem('Absent', absentDays, Colors.red),
            ),
            Expanded(
              child: _buildSummaryItem('Late', lateDays, Colors.orange),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: totalDays > 0 ? presentDays / totalDays : 0,
          backgroundColor: Colors.grey[300],
          color: Colors.green,
          minHeight: 10,
        ),
        const SizedBox(height: 8),
        Text(
          'Attendance: ${totalDays > 0 ? (presentDays / totalDays * 100).toStringAsFixed(1) : '0.0'}%',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
          ),
        ),
      ],
    );
  }
  
  String _formatMonth(String month) {
    final parts = month.split('-');
    final year = parts[0];
    final monthNum = int.parse(parts[1]);
    
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${monthNames[monthNum - 1]} $year';
  }
}
