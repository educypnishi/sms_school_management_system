import '../models/event_model.dart';

/// Service to manage events in the calendar system
class CalendarService {
  // In a real app, this would be stored in Firebase or another database
  // For now, we'll use an in-memory map for demo purposes
  final Map<String, EventModel> _events = {};
  
  /// Get all events
  Future<List<EventModel>> getAllEvents() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _events.values.toList();
  }

  /// Get events for a specific user
  Future<List<EventModel>> getUserEvents(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _events.values.where((event) => event.userId == userId).toList();
  }

  /// Get events for a specific application
  Future<List<EventModel>> getApplicationEvents(String applicationId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _events.values.where((event) => event.applicationId == applicationId).toList();
  }

  /// Get events for a specific program
  Future<List<EventModel>> getProgramEvents(String programId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _events.values.where((event) => event.programId == programId).toList();
  }

  /// Get events for a specific date range
  Future<List<EventModel>> getEventsInRange(DateTime start, DateTime end) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _events.values.where((event) => 
      (event.startDate.isAfter(start) || event.startDate.isAtSameMomentAs(start)) && 
      (event.startDate.isBefore(end) || event.startDate.isAtSameMomentAs(end))
    ).toList();
  }

  /// Get events for a specific month
  Future<List<EventModel>> getEventsForMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return getEventsInRange(start, end);
  }

  /// Get events for today
  Future<List<EventModel>> getTodayEvents() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return getEventsInRange(start, end);
  }

  /// Get upcoming events (next 7 days)
  Future<List<EventModel>> getUpcomingEvents() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 7));
    return getEventsInRange(start, end);
  }

  /// Get overdue events
  Future<List<EventModel>> getOverdueEvents() async {
    final now = DateTime.now();
    final events = await getAllEvents();
    return events.where((event) => 
      event.startDate.isBefore(now) && !event.isCompleted
    ).toList();
  }

  /// Get a specific event
  Future<EventModel?> getEvent(String eventId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _events[eventId];
  }

  /// Create a new event
  Future<EventModel> createEvent({
    required String title,
    required String description,
    required DateTime startDate,
    DateTime? endDate,
    bool isAllDay = false,
    required EventType type,
    required EventPriority priority,
    String? location,
    String? applicationId,
    String? programId,
    String? userId,
    bool hasReminder = true,
    Duration? reminderBefore = const Duration(days: 1),
    List<String>? attendees,
    Map<String, dynamic>? additionalInfo,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    final event = EventModel(
      id: 'EVENT${_events.length + 1}',
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      isAllDay: isAllDay,
      type: type,
      priority: priority,
      location: location,
      applicationId: applicationId,
      programId: programId,
      userId: userId,
      hasReminder: hasReminder,
      reminderBefore: reminderBefore,
      attendees: attendees,
      additionalInfo: additionalInfo,
    );
    
    _events[event.id] = event;
    
    return event;
  }

  /// Update an existing event
  Future<EventModel> updateEvent(EventModel event) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    _events[event.id] = event;
    
    return event;
  }

  /// Mark an event as completed
  Future<EventModel> markEventAsCompleted(String eventId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    final event = _events[eventId];
    if (event == null) {
      throw Exception('Event not found');
    }
    
    final updatedEvent = event.copyWith(isCompleted: true);
    _events[eventId] = updatedEvent;
    
    return updatedEvent;
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    _events.remove(eventId);
  }

  /// Get events that need reminders
  Future<List<EventModel>> getEventsNeedingReminders() async {
    final now = DateTime.now();
    final events = await getAllEvents();
    
    return events.where((event) => 
      event.hasReminder && 
      event.reminderBefore != null &&
      !event.isCompleted &&
      event.reminderTime != null &&
      event.reminderTime!.isAfter(now) &&
      event.reminderTime!.isBefore(now.add(const Duration(minutes: 15)))
    ).toList();
  }

  /// Generate sample events for demo purposes
  Future<void> generateSampleEvents(String userId) async {
    // Sample event 1 - Application Deadline
    final event1 = EventModel(
      id: 'EVENT001',
      title: 'Application Deadline - Fall Semester',
      description: 'Last day to submit your application for the Fall semester',
      startDate: DateTime.now().add(const Duration(days: 14)),
      isAllDay: true,
      type: EventType.applicationDeadline,
      priority: EventPriority.urgent,
      userId: userId,
      applicationId: 'APP001',
    );
    
    // Sample event 2 - Document Deadline
    final event2 = EventModel(
      id: 'EVENT002',
      title: 'Submit Academic Transcripts',
      description: 'Deadline to submit your academic transcripts',
      startDate: DateTime.now().add(const Duration(days: 7)),
      isAllDay: true,
      type: EventType.documentDeadline,
      priority: EventPriority.high,
      userId: userId,
      applicationId: 'APP001',
    );
    
    // Sample event 3 - Interview
    final interviewDate = DateTime.now().add(const Duration(days: 21));
    final event3 = EventModel(
      id: 'EVENT003',
      title: 'Admission Interview',
      description: 'Online interview with the admissions committee',
      startDate: DateTime(
        interviewDate.year,
        interviewDate.month,
        interviewDate.day,
        10,
        0,
      ),
      endDate: DateTime(
        interviewDate.year,
        interviewDate.month,
        interviewDate.day,
        11,
        0,
      ),
      isAllDay: false,
      type: EventType.interview,
      priority: EventPriority.high,
      location: 'Zoom Meeting (Link will be provided)',
      userId: userId,
      applicationId: 'APP001',
      hasReminder: true,
      reminderBefore: const Duration(days: 1),
    );
    
    // Sample event 4 - Orientation
    final orientationDate = DateTime.now().add(const Duration(days: 45));
    final event4 = EventModel(
      id: 'EVENT004',
      title: 'New Student Orientation',
      description: 'Orientation for new students',
      startDate: DateTime(
        orientationDate.year,
        orientationDate.month,
        orientationDate.day,
        9,
        0,
      ),
      endDate: DateTime(
        orientationDate.year,
        orientationDate.month,
        orientationDate.day,
        16,
        0,
      ),
      isAllDay: false,
      type: EventType.orientation,
      priority: EventPriority.medium,
      location: 'University Campus, Main Hall',
      userId: userId,
      programId: 'PROG001',
    );
    
    // Sample event 5 - Registration
    final registrationDate = DateTime.now().add(const Duration(days: 30));
    final event5 = EventModel(
      id: 'EVENT005',
      title: 'Course Registration Deadline',
      description: 'Last day to register for courses',
      startDate: DateTime(
        registrationDate.year,
        registrationDate.month,
        registrationDate.day,
        23,
        59,
      ),
      isAllDay: false,
      type: EventType.registration,
      priority: EventPriority.high,
      userId: userId,
      programId: 'PROG001',
    );
    
    // Add the sample events to the map
    _events[event1.id] = event1;
    _events[event2.id] = event2;
    _events[event3.id] = event3;
    _events[event4.id] = event4;
    _events[event5.id] = event5;
  }
}
