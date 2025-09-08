import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../theme/app_theme.dart';
import 'attendance_record_detail_screen.dart';

class AttendanceRecordListScreen extends StatefulWidget {
  final String userId;

  const AttendanceRecordListScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AttendanceRecordListScreen> createState() => _AttendanceRecordListScreenState();
}

class _AttendanceRecordListScreenState extends State<AttendanceRecordListScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  List<AttendanceModel> _attendanceRecords = [];
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};

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
      final records = await _attendanceService.getAttendanceForStudent(widget.userId);
      final stats = await _attendanceService.getAttendanceStatistics(widget.userId);
      
      setState(() {
        _attendanceRecords = records;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading attendance records: $e');
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
        title: const Text('Attendance Records'),
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
          : RefreshIndicator(
              onRefresh: _loadAttendanceRecords,
              child: Column(
                children: [
                  // Statistics Card
                  _buildStatisticsCard(),
                  
                  // Attendance Records List
                  Expanded(
                    child: _attendanceRecords.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _attendanceRecords.length,
                            itemBuilder: (context, index) {
                              final record = _attendanceRecords[index];
                              return _buildAttendanceCard(record);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatisticsCard() {
    final attendancePercentage = _statistics['attendancePercentage'] ?? 0.0;
    final presentDays = _statistics['presentDays'] ?? 0;
    final absentDays = _statistics['absentDays'] ?? 0;
    final lateDays = _statistics['lateDays'] ?? 0;
    final totalDays = _statistics['totalDays'] ?? 0;
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  'Present',
                  presentDays.toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
                _buildStatItem(
                  'Absent',
                  absentDays.toString(),
                  Colors.red,
                  Icons.cancel,
                ),
                _buildStatItem(
                  'Late',
                  lateDays.toString(),
                  Colors.orange,
                  Icons.access_time,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance Rate: ${attendancePercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: attendancePercentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          attendancePercentage >= 90
                              ? Colors.green
                              : attendancePercentage >= 75
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$totalDays\nDays',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Attendance Records',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your attendance records will appear here',
            style: TextStyle(color: AppTheme.lightTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceModel record) {
    Color statusColor;
    IconData statusIcon;
    
    switch (record.status) {
      case 'present':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'absent':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'late':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceRecordDetailScreen(
                attendanceRecordId: record.id,
              ),
            ),
          ).then((_) => _loadAttendanceRecords());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course and Date
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.courseName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${record.date.day}/${record.date.month}/${record.date.year}',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          record.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              
              // Time and Room
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${record.startTime.hour}:${record.startTime.minute.toString().padLeft(2, '0')} - ${record.endTime.hour}:${record.endTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const Spacer(),
                  const Icon(Icons.room, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Room ${record.roomNumber}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Teacher
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Teacher: ${record.teacherName}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              
              // Reason (if absent or late)
              if (record.reason != null && record.reason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.note, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Reason: ${record.reason}',
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
