import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/firebase_attendance_service.dart';
import '../services/firebase_auth_service.dart';
import '../models/attendance_model.dart';
import '../theme/app_theme.dart';

class AttendanceCalendarScreen extends StatefulWidget {
  final String? studentId;
  final bool isTeacherView;
  
  const AttendanceCalendarScreen({
    super.key,
    this.studentId,
    this.isTeacherView = false,
  });

  @override
  State<AttendanceCalendarScreen> createState() => _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState extends State<AttendanceCalendarScreen> {
  late final ValueNotifier<List<AttendanceModel>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<AttendanceModel>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadAttendanceData();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceData() async {
    setState(() => _isLoading = true);
    
    try {
      final targetStudentId = widget.studentId ?? FirebaseAuthService.currentUserId!;
      
      // Load attendance for the current month
      final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
      
      final attendanceRecords = await FirebaseAttendanceService.getStudentAttendance(
        studentId: targetStudentId,
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      // Group attendance by date
      final events = <DateTime, List<AttendanceModel>>{};
      for (final record in attendanceRecords) {
        final date = DateTime(record.date.year, record.date.month, record.date.day);
        events[date] = (events[date] ?? [])..add(record);
      }

      setState(() {
        _events = events;
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading attendance data: $e');
    }
  }

  List<AttendanceModel> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
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
        title: const Text('Attendance Calendar'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
              _loadAttendanceData();
            },
            tooltip: 'Go to Today',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendar
                Card(
                  margin: const EdgeInsets.all(8),
                  child: TableCalendar<AttendanceModel>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    eventLoader: _getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        _selectedEvents.value = _getEventsForDay(selectedDay);
                      }
                    },
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                      _loadAttendanceData();
                    },
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      weekendTextStyle: TextStyle(color: Colors.red[400]),
                      holidayTextStyle: TextStyle(color: Colors.red[400]),
                      selectedDecoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 1,
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isNotEmpty) {
                          final attendance = events.first as AttendanceModel;
                          return _buildAttendanceMarker(attendance.status);
                        }
                        return null;
                      },
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      formatButtonShowsNext: false,
                      formatButtonDecoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.all(Radius.circular(12.0)),
                      ),
                      formatButtonTextStyle: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Legend
                _buildLegend(),
                
                const SizedBox(height: 8),
                
                // Selected day events
                Expanded(
                  child: ValueListenableBuilder<List<AttendanceModel>>(
                    valueListenable: _selectedEvents,
                    builder: (context, value, _) {
                      return _buildEventsList(value);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAttendanceMarker(String status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case 'present':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'absent':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case 'late':
        color = Colors.orange;
        icon = Icons.access_time;
        break;
      case 'excused':
        color = Colors.blue;
        icon = Icons.event_available;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(top: 5),
      child: Icon(
        icon,
        color: color,
        size: 16,
      ),
    );
  }

  Widget _buildLegend() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Legend',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(Icons.check_circle, 'Present', Colors.green),
                _buildLegendItem(Icons.cancel, 'Absent', Colors.red),
                _buildLegendItem(Icons.access_time, 'Late', Colors.orange),
                _buildLegendItem(Icons.event_available, 'Excused', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }

  Widget _buildEventsList(List<AttendanceModel> events) {
    if (events.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedDay != null
                      ? 'No attendance records for ${DateFormat('dd MMM yyyy').format(_selectedDay!)}'
                      : 'Select a date to view attendance',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Attendance for ${DateFormat('dd MMM yyyy').format(_selectedDay!)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final attendance = events[index];
                return _buildAttendanceListTile(attendance);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceListTile(AttendanceModel attendance) {
    final statusColor = _getStatusColor(attendance.status);
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor,
        child: Icon(
          _getStatusIcon(attendance.status),
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(attendance.courseName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subject: ${attendance.subject}'),
          Text('Teacher: ${attendance.teacherName}'),
          if (attendance.checkInTime != null)
            Text('Check-in: ${DateFormat('HH:mm').format(attendance.checkInTime!)}'),
          if (attendance.notes?.isNotEmpty == true)
            Text('Notes: ${attendance.notes}'),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor),
        ),
        child: Text(
          attendance.status.toUpperCase(),
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
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
