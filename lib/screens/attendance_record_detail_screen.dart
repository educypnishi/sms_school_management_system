import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../theme/app_theme.dart';

class AttendanceRecordDetailScreen extends StatefulWidget {
  final String attendanceRecordId;

  const AttendanceRecordDetailScreen({
    super.key,
    required this.attendanceRecordId,
  });

  @override
  State<AttendanceRecordDetailScreen> createState() => _AttendanceRecordDetailScreenState();
}

class _AttendanceRecordDetailScreenState extends State<AttendanceRecordDetailScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  bool _isLoading = true;
  AttendanceModel? _attendanceRecord;

  @override
  void initState() {
    super.initState();
    _loadAttendanceRecord();
  }

  Future<void> _loadAttendanceRecord() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final record = await _attendanceService.getAttendanceById(widget.attendanceRecordId);
      
      setState(() {
        _attendanceRecord = record;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading attendance record: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading attendance record: $e'),
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
          : _attendanceRecord == null
              ? _buildErrorState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Card
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      
                      // Course Details
                      _buildDetailsCard(
                        'Course Details',
                        [
                          _buildDetailRow('Course', _attendanceRecord!.courseName),
                          _buildDetailRow('Class', _attendanceRecord!.className),
                          _buildDetailRow('Room', _attendanceRecord!.roomNumber),
                          _buildDetailRow('Teacher', _attendanceRecord!.teacherName),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Time Details
                      _buildDetailsCard(
                        'Time Details',
                        [
                          _buildDetailRow('Date', '${_attendanceRecord!.date.day}/${_attendanceRecord!.date.month}/${_attendanceRecord!.date.year}'),
                          _buildDetailRow('Start Time', '${_attendanceRecord!.startTime.hour}:${_attendanceRecord!.startTime.minute.toString().padLeft(2, '0')}'),
                          _buildDetailRow('End Time', '${_attendanceRecord!.endTime.hour}:${_attendanceRecord!.endTime.minute.toString().padLeft(2, '0')}'),
                          _buildDetailRow('Duration', '${_attendanceRecord!.endTime.difference(_attendanceRecord!.startTime).inMinutes} minutes'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Additional Information
                      if (_attendanceRecord!.reason != null || _attendanceRecord!.notes != null)
                        _buildDetailsCard(
                          'Additional Information',
                          [
                            if (_attendanceRecord!.reason != null)
                              _buildDetailRow('Reason', _attendanceRecord!.reason!),
                            if (_attendanceRecord!.notes != null)
                              _buildDetailRow('Notes', _attendanceRecord!.notes!),
                          ],
                        ),
                      const SizedBox(height: 16),
                      
                      // Record Information
                      _buildDetailsCard(
                        'Record Information',
                        [
                          _buildDetailRow('Marked By', _attendanceRecord!.markedByName),
                          _buildDetailRow('Created At', '${_formatDateTime(_attendanceRecord!.createdAt)}'),
                          if (_attendanceRecord!.updatedAt != null)
                            _buildDetailRow('Updated At', '${_formatDateTime(_attendanceRecord!.updatedAt!)}'),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Record Not Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The attendance record you are looking for does not exist',
            style: TextStyle(color: AppTheme.lightTextColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (_attendanceRecord!.status) {
      case 'present':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Present';
        break;
      case 'absent':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Absent';
        break;
      case 'late':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        statusText = 'Late';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = _attendanceRecord!.status.toUpperCase();
    }

    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 48,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    _attendanceRecord!.courseName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_attendanceRecord!.date.day}/${_attendanceRecord!.date.month}/${_attendanceRecord!.date.year}',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
