import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/event_model.dart';
import '../services/calendar_service.dart';
import '../theme/app_theme.dart';
import '../widgets/event_card.dart';

class CalendarScreen extends StatefulWidget {
  final String userId;

  const CalendarScreen({
    super.key,
    required this.userId,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  final CalendarService _calendarService = CalendarService();
  bool _isLoading = true;
  List<EventModel> _events = [];
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // For demo purposes, generate sample data if it doesn't exist
      await _calendarService.generateSampleEvents(widget.userId);
      
      // Get events for this user
      final events = await _calendarService.getUserEvents(widget.userId);
      
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading events: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    return _events.where((event) {
      final eventDate = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
      final selectedDate = DateTime(day.year, day.month, day.day);
      return eventDate.isAtSameMomentAs(selectedDate);
    }).toList();
  }

  List<EventModel> _getUpcomingEvents() {
    final now = DateTime.now();
    return _events.where((event) => 
      event.startDate.isAfter(now) && 
      !event.isCompleted
    ).toList()
    ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  List<EventModel> _getOverdueEvents() {
    final now = DateTime.now();
    return _events.where((event) => 
      event.startDate.isBefore(now) && 
      !event.isCompleted
    ).toList()
    ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  Future<void> _markEventAsCompleted(String eventId) async {
    try {
      await _calendarService.markEventAsCompleted(eventId);
      
      // Refresh events
      await _loadEvents();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking event as completed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      await _calendarService.deleteEvent(eventId);
      
      // Refresh events
      await _loadEvents();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewEventDetails(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildEventDetailsSheet(event),
    );
  }

  Widget _buildEventDetailsSheet(EventModel event) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event title and type
          Row(
            children: [
              Icon(
                event.typeIcon,
                color: event.priorityColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      event.typeText,
                      style: TextStyle(
                        color: event.priorityColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Event details
          const Text(
            'Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(event.description),
          const SizedBox(height: 16),
          
          // Date and time
          const Text(
            'Date & Time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: AppTheme.lightTextColor,
              ),
              const SizedBox(width: 8),
              Text(
                event.formattedDate,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Location if available
          if (event.location != null) ...[
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppTheme.lightTextColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.location!,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // Reminder info
          const Text(
            'Reminder',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.notifications,
                size: 16,
                color: AppTheme.lightTextColor,
              ),
              const SizedBox(width: 8),
              Text(
                event.hasReminder
                    ? 'Reminder set for ${_formatReminderTime(event.reminderBefore)}'
                    : 'No reminder set',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!event.isCompleted)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _markEventAsCompleted(event.id);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Mark Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteEvent(event.id);
                },
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatReminderTime(Duration? duration) {
    if (duration == null) return 'the event time';
    
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''} before';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} before';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''} before';
    }
  }

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    bool isAllDay = false;
    EventType selectedType = EventType.applicationDeadline;
    EventPriority selectedPriority = EventPriority.medium;
    final locationController = TextEditingController();
    bool hasReminder = true;
    Duration reminderBefore = const Duration(days: 1);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'Enter event title',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Enter event description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                
                // Date picker
                Row(
                  children: [
                    const Text('Date: '),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                          });
                        }
                      },
                      child: Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        style: const TextStyle(color: AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
                
                // All day switch
                Row(
                  children: [
                    const Text('All day: '),
                    Switch(
                      value: isAllDay,
                      onChanged: (value) {
                        setState(() {
                          isAllDay = value;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
                
                // Time picker (only if not all day)
                if (!isAllDay)
                  Row(
                    children: [
                      const Text('Time: '),
                      TextButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setState(() {
                              selectedTime = time;
                            });
                          }
                        },
                        child: Text(
                          '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                
                // Event type
                const Text('Event Type:'),
                DropdownButton<EventType>(
                  value: selectedType,
                  isExpanded: true,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                      });
                    }
                  },
                  items: EventType.values.map((type) {
                    return DropdownMenuItem<EventType>(
                      value: type,
                      child: Text(_getEventTypeText(type)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Priority
                const Text('Priority:'),
                DropdownButton<EventPriority>(
                  value: selectedPriority,
                  isExpanded: true,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedPriority = value;
                      });
                    }
                  },
                  items: EventPriority.values.map((priority) {
                    return DropdownMenuItem<EventPriority>(
                      value: priority,
                      child: Text(_getEventPriorityText(priority)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Location
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location (optional)',
                    hintText: 'Enter event location',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Reminder
                Row(
                  children: [
                    const Text('Reminder: '),
                    Switch(
                      value: hasReminder,
                      onChanged: (value) {
                        setState(() {
                          hasReminder = value;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
                
                // Reminder time
                if (hasReminder)
                  DropdownButton<Duration>(
                    value: reminderBefore,
                    isExpanded: true,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          reminderBefore = value;
                        });
                      }
                    },
                    items: [
                      const DropdownMenuItem<Duration>(
                        value: Duration(minutes: 15),
                        child: Text('15 minutes before'),
                      ),
                      const DropdownMenuItem<Duration>(
                        value: Duration(hours: 1),
                        child: Text('1 hour before'),
                      ),
                      const DropdownMenuItem<Duration>(
                        value: Duration(hours: 3),
                        child: Text('3 hours before'),
                      ),
                      const DropdownMenuItem<Duration>(
                        value: Duration(days: 1),
                        child: Text('1 day before'),
                      ),
                      const DropdownMenuItem<Duration>(
                        value: Duration(days: 3),
                        child: Text('3 days before'),
                      ),
                      const DropdownMenuItem<Duration>(
                        value: Duration(days: 7),
                        child: Text('1 week before'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Create event
                _createEvent(
                  title: titleController.text,
                  description: descriptionController.text,
                  startDate: isAllDay
                      ? DateTime(selectedDate.year, selectedDate.month, selectedDate.day)
                      : DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        ),
                  isAllDay: isAllDay,
                  type: selectedType,
                  priority: selectedPriority,
                  location: locationController.text.isNotEmpty ? locationController.text : null,
                  hasReminder: hasReminder,
                  reminderBefore: reminderBefore,
                );
                
                Navigator.pop(context);
              },
              child: const Text('Add Event'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar & Deadlines'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Calendar'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Overdue'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCalendarTab(),
                _buildUpcomingTab(),
                _buildOverdueTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendarTab() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          eventLoader: _getEventsForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: const CalendarStyle(
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
        const Divider(),
        Expanded(
          child: _buildEventsForSelectedDay(),
        ),
      ],
    );
  }

  Widget _buildEventsForSelectedDay() {
    final events = _getEventsForDay(_selectedDay);
    
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No events on ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.lightTextColor,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return EventCard(
          event: event,
          onTap: () => _viewEventDetails(event),
          onDelete: () => _deleteEvent(event.id),
          onComplete: !event.isCompleted ? () => _markEventAsCompleted(event.id) : null,
        );
      },
    );
  }

  Widget _buildUpcomingTab() {
    final events = _getUpcomingEvents();
    
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No upcoming events',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.lightTextColor,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return EventCard(
          event: event,
          onTap: () => _viewEventDetails(event),
          onDelete: () => _deleteEvent(event.id),
          onComplete: () => _markEventAsCompleted(event.id),
        );
      },
    );
  }

  Widget _buildOverdueTab() {
    final events = _getOverdueEvents();
    
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'No overdue events',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.lightTextColor,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return EventCard(
          event: event,
          onTap: () => _viewEventDetails(event),
          onDelete: () => _deleteEvent(event.id),
          onComplete: () => _markEventAsCompleted(event.id),
        );
      },
    );
  }

  String _getEventTypeText(EventType type) {
    switch (type) {
      case EventType.applicationDeadline:
        return 'Application Deadline';
      case EventType.documentDeadline:
        return 'Document Deadline';
      case EventType.interview:
        return 'Interview';
      case EventType.orientation:
        return 'Orientation';
      case EventType.registration:
        return 'Registration';
      case EventType.exam:
        return 'Exam';
      case EventType.result:
        return 'Result';
      case EventType.other:
        return 'Other Event';
    }
  }

  String _getEventPriorityText(EventPriority priority) {
    switch (priority) {
      case EventPriority.low:
        return 'Low Priority';
      case EventPriority.medium:
        return 'Medium Priority';
      case EventPriority.high:
        return 'High Priority';
      case EventPriority.urgent:
        return 'Urgent';
    }
  }

  Future<void> _createEvent({
    required String title,
    required String description,
    required DateTime startDate,
    required bool isAllDay,
    required EventType type,
    required EventPriority priority,
    String? location,
    required bool hasReminder,
    required Duration reminderBefore,
  }) async {
    try {
      await _calendarService.createEvent(
        title: title,
        description: description,
        startDate: startDate,
        isAllDay: isAllDay,
        type: type,
        priority: priority,
        location: location,
        userId: widget.userId,
        hasReminder: hasReminder,
        reminderBefore: reminderBefore,
      );
      
      // Refresh events
      await _loadEvents();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calendar & Deadlines Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to use Calendar & Deadlines:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• View your events in the Calendar tab'),
              Text('• See upcoming events in the Upcoming tab'),
              Text('• Check overdue events in the Overdue tab'),
              Text('• Tap on any event to view details'),
              Text('• Mark events as completed when done'),
              SizedBox(height: 16),
              Text(
                'Event Colors:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Green border: Completed events'),
              Text('• Red border: Overdue events'),
              Text('• Orange border: Events due soon (within 3 days)'),
              SizedBox(height: 16),
              Text(
                'Priority Levels:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Low: Green'),
              Text('• Medium: Blue'),
              Text('• High: Orange'),
              Text('• Urgent: Red'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
