import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../theme/app_theme.dart';

class AttendanceDetailScreen extends StatefulWidget {
  final String attendanceId;
  
  const AttendanceDetailScreen({
    super.key,
    required this.attendanceId,
  });

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isLoading = true;
  AttendanceModel? _attendance;
  
  @override
  void initState() {
    super.initState();
    _loadAttendanceDetail();
  }
  
  Future<void> _loadAttendanceDetail() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final attendance = await _attendanceService.getAttendanceById(widget.attendanceId);
      
      setState(() {
        _attendance = attendance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading attendance details: $e'),
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
        title: const Text('Attendance Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _attendance == null
              ? const Center(child: Text('Attendance record not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 24),
                      _buildDetailsCard(),
                      const SizedBox(height: 24),
                      _buildNotesCard(),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildStatusCard() {
    final statusColor = _attendance!.status == 'present'
        ? Colors.green
        : _attendance!.status == 'absent'
            ? Colors.red
            : Colors.orange;
            
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _attendance!.status == 'present'
                      ? Icons.check_circle
                      : _attendance!.status == 'absent'
                          ? Icons.cancel
                          : Icons.access_time,
                  color: statusColor,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _attendance!.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      '${_attendance!.date.day}/${_attendance!.date.month}/${_attendance!.date.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Course Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Course', _attendance!.courseName),
            _buildDetailRow('Teacher', _attendance!.teacherName),
            _buildDetailRow('Subject', _attendance!.subject),
            if (_attendance!.checkInTime != null)
              _buildDetailRow('Check-in Time', _formatTime(_attendance!.checkInTime!)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _attendance!.notes?.isNotEmpty == true
                  ? _attendance!.notes!
                  : 'No notes available for this attendance record.',
              style: TextStyle(
                color: _attendance!.notes?.isNotEmpty == true ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
