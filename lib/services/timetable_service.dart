import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timetable_model.dart';

class TimetableService {
  // Time slots for the timetable
  static const List<String> timeSlots = [
    '08:00 - 08:45',
    '08:45 - 09:30',
    '09:30 - 10:15',
    '10:15 - 10:30', // Break
    '10:30 - 11:15',
    '11:15 - 12:00',
    '12:00 - 12:45',
    '12:45 - 13:30', // Lunch Break
    '13:30 - 14:15',
    '14:15 - 15:00',
    '15:00 - 15:45',
  ];

  static const List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  // Sample subjects and teachers
  static const Map<String, List<Map<String, String>>> subjectTeachers = {
    'Class 9-A': [
      {'subject': 'Mathematics', 'teacher': 'Dr. Ahmad Hassan', 'room': 'A101', 'periods': '5'},
      {'subject': 'Physics', 'teacher': 'Prof. Zara Ahmed', 'room': 'B202', 'periods': '4'},
      {'subject': 'Chemistry', 'teacher': 'Dr. Sana Malik', 'room': 'C303', 'periods': '4'},
      {'subject': 'English', 'teacher': 'Ms. Rabia Iqbal', 'room': 'D404', 'periods': '3'},
      {'subject': 'Urdu', 'teacher': 'Prof. Farah Khan', 'room': 'E505', 'periods': '3'},
      {'subject': 'Islamic Studies', 'teacher': 'Maulana Abdul Rahman', 'room': 'F606', 'periods': '2'},
      {'subject': 'Computer Science', 'teacher': 'Mr. Asif Rahman', 'room': 'Lab-1', 'periods': '3'},
      {'subject': 'Biology', 'teacher': 'Dr. Nadia Hussain', 'room': 'Lab-2', 'periods': '3'},
      {'subject': 'Pakistan Studies', 'teacher': 'Prof. Tariq Mahmood', 'room': 'G707', 'periods': '2'},
    ],
    'Class 9-B': [
      {'subject': 'Mathematics', 'teacher': 'Dr. Imran Shah', 'room': 'A102', 'periods': '5'},
      {'subject': 'Physics', 'teacher': 'Prof. Zara Ahmed', 'room': 'B202', 'periods': '4'},
      {'subject': 'Chemistry', 'teacher': 'Dr. Amna Siddique', 'room': 'C304', 'periods': '4'},
      {'subject': 'English', 'teacher': 'Ms. Khadija Malik', 'room': 'D405', 'periods': '3'},
      {'subject': 'Urdu', 'teacher': 'Prof. Farah Khan', 'room': 'E505', 'periods': '3'},
      {'subject': 'Islamic Studies', 'teacher': 'Maulana Abdul Rahman', 'room': 'F606', 'periods': '2'},
      {'subject': 'Computer Science', 'teacher': 'Mr. Ali Raza', 'room': 'Lab-1', 'periods': '3'},
      {'subject': 'Biology', 'teacher': 'Dr. Nadia Hussain', 'room': 'Lab-2', 'periods': '3'},
      {'subject': 'Pakistan Studies', 'teacher': 'Prof. Tariq Mahmood', 'room': 'G707', 'periods': '2'},
    ],
    'Class 10-A': [
      {'subject': 'Mathematics', 'teacher': 'Dr. Ahmad Hassan', 'room': 'A103', 'periods': '6'},
      {'subject': 'Physics', 'teacher': 'Prof. Zara Ahmed', 'room': 'B203', 'periods': '5'},
      {'subject': 'Chemistry', 'teacher': 'Dr. Sana Malik', 'room': 'C305', 'periods': '5'},
      {'subject': 'English', 'teacher': 'Ms. Rabia Iqbal', 'room': 'D406', 'periods': '4'},
      {'subject': 'Urdu', 'teacher': 'Prof. Farah Khan', 'room': 'E506', 'periods': '3'},
      {'subject': 'Islamic Studies', 'teacher': 'Maulana Abdul Rahman', 'room': 'F607', 'periods': '2'},
      {'subject': 'Computer Science', 'teacher': 'Mr. Asif Rahman', 'room': 'Lab-3', 'periods': '4'},
      {'subject': 'Biology', 'teacher': 'Dr. Nadia Hussain', 'room': 'Lab-4', 'periods': '4'},
    ],
  };

  // Generate automatic timetable
  Future<TimetableModel> generateAutoTimetable({
    required String className,
    required String term,
    Map<String, dynamic>? constraints,
  }) async {
    try {
      debugPrint('Generating timetable for $className, $term');
      
      // Get subjects for the class
      final subjects = subjectTeachers[className] ?? subjectTeachers['Class 9-A']!;
      
      // Create timetable grid
      final timetableGrid = <String, Map<String, TimetableSlot>>{};
      
      // Initialize empty grid
      for (final day in weekDays) {
        timetableGrid[day] = {};
        for (int i = 0; i < timeSlots.length; i++) {
          if (timeSlots[i].contains('Break') || timeSlots[i].contains('Lunch')) {
            timetableGrid[day]![timeSlots[i]] = TimetableSlot(
              timeSlot: timeSlots[i],
              subject: timeSlots[i].contains('Lunch') ? 'Lunch Break' : 'Break',
              teacher: '',
              room: '',
              isBreak: true,
            );
          } else {
            timetableGrid[day]![timeSlots[i]] = TimetableSlot(
              timeSlot: timeSlots[i],
              subject: '',
              teacher: '',
              room: '',
              isBreak: false,
            );
          }
        }
      }

      // Apply constraints
      final teacherSchedule = <String, Map<String, Set<String>>>{};
      final roomSchedule = <String, Map<String, Set<String>>>{};
      
      // Initialize teacher and room schedules
      for (final subject in subjects) {
        final teacher = subject['teacher']!;
        final room = subject['room']!;
        
        teacherSchedule[teacher] = {};
        roomSchedule[room] = {};
        
        for (final day in weekDays) {
          teacherSchedule[teacher]![day] = <String>{};
          roomSchedule[room]![day] = <String>{};
        }
      }

      // Distribute subjects across the week
      final random = Random();
      
      for (final subjectInfo in subjects) {
        final subject = subjectInfo['subject']!;
        final teacher = subjectInfo['teacher']!;
        final room = subjectInfo['room']!;
        final periodsNeeded = int.parse(subjectInfo['periods']!);
        
        int periodsAssigned = 0;
        int attempts = 0;
        const maxAttempts = 100;
        
        while (periodsAssigned < periodsNeeded && attempts < maxAttempts) {
          attempts++;
          
          // Pick a random day and time slot
          final day = weekDays[random.nextInt(weekDays.length)];
          final availableSlots = timeSlots
              .where((slot) => !slot.contains('Break') && !slot.contains('Lunch'))
              .toList();
          final timeSlot = availableSlots[random.nextInt(availableSlots.length)];
          
          // Check if slot is available
          final currentSlot = timetableGrid[day]![timeSlot]!;
          if (currentSlot.subject.isEmpty &&
              !teacherSchedule[teacher]![day]!.contains(timeSlot) &&
              !roomSchedule[room]![day]!.contains(timeSlot)) {
            
            // Assign the slot
            timetableGrid[day]![timeSlot] = TimetableSlot(
              timeSlot: timeSlot,
              subject: subject,
              teacher: teacher,
              room: room,
              isBreak: false,
            );
            
            // Update schedules
            teacherSchedule[teacher]![day]!.add(timeSlot);
            roomSchedule[room]![day]!.add(timeSlot);
            
            periodsAssigned++;
          }
        }
        
        if (periodsAssigned < periodsNeeded) {
          debugPrint('Warning: Could not assign all periods for $subject. Assigned: $periodsAssigned/$periodsNeeded');
        }
      }

      // Create the timetable model
      final timetable = TimetableModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        className: className,
        term: term,
        academicYear: '2024-2025',
        schedule: timetableGrid,
        createdAt: DateTime.now(),
        createdBy: 'System Auto-Generator',
        isActive: true,
      );

      // Save to local storage
      await _saveTimetable(timetable);
      
      debugPrint('Timetable generated successfully for $className');
      return timetable;
      
    } catch (e) {
      debugPrint('Error generating timetable: $e');
      rethrow;
    }
  }

  // Save timetable to local storage
  Future<void> _saveTimetable(TimetableModel timetable) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timetablesJson = prefs.getStringList('timetables') ?? [];
      
      // Convert timetable to JSON string
      timetablesJson.add(timetable.toJsonString());
      
      // Save back to preferences
      await prefs.setStringList('timetables', timetablesJson);
      
      debugPrint('Timetable saved to local storage');
    } catch (e) {
      debugPrint('Error saving timetable: $e');
    }
  }

  // Get all timetables
  Future<List<TimetableModel>> getAllTimetables() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timetablesJson = prefs.getStringList('timetables') ?? [];
      
      return timetablesJson
          .map((json) => TimetableModel.fromJsonString(json))
          .toList();
    } catch (e) {
      debugPrint('Error loading timetables: $e');
      return [];
    }
  }

  // Get timetable by class
  Future<TimetableModel?> getTimetableByClass(String className) async {
    try {
      final timetables = await getAllTimetables();
      return timetables
          .where((t) => t.className == className && t.isActive)
          .firstOrNull;
    } catch (e) {
      debugPrint('Error getting timetable for class: $e');
      return null;
    }
  }

  // Validate timetable for conflicts
  Map<String, List<String>> validateTimetable(TimetableModel timetable) {
    final conflicts = <String, List<String>>{};
    final teacherSchedule = <String, Map<String, String>>{};
    final roomSchedule = <String, Map<String, String>>{};

    // Check for teacher and room conflicts
    for (final day in timetable.schedule.keys) {
      for (final timeSlot in timetable.schedule[day]!.keys) {
        final slot = timetable.schedule[day]![timeSlot]!;
        
        if (slot.isBreak || slot.subject.isEmpty) continue;

        final teacher = slot.teacher;
        final room = slot.room;
        final key = '$day-$timeSlot';

        // Check teacher conflicts
        if (teacherSchedule.containsKey(teacher)) {
          if (teacherSchedule[teacher]!.containsKey(key)) {
            conflicts['Teacher Conflicts'] ??= [];
            conflicts['Teacher Conflicts']!.add(
              '$teacher has conflict on $day at $timeSlot'
            );
          }
        } else {
          teacherSchedule[teacher] = {};
        }
        teacherSchedule[teacher]![key] = slot.subject;

        // Check room conflicts
        if (roomSchedule.containsKey(room)) {
          if (roomSchedule[room]!.containsKey(key)) {
            conflicts['Room Conflicts'] ??= [];
            conflicts['Room Conflicts']!.add(
              '$room has conflict on $day at $timeSlot'
            );
          }
        } else {
          roomSchedule[room] = {};
        }
        roomSchedule[room]![key] = slot.subject;
      }
    }

    return conflicts;
  }

  // Get teacher timetable
  Future<Map<String, Map<String, TimetableSlot>>> getTeacherTimetable(String teacherName) async {
    try {
      final allTimetables = await getAllTimetables();
      final teacherSchedule = <String, Map<String, TimetableSlot>>{};

      // Initialize empty schedule
      for (final day in weekDays) {
        teacherSchedule[day] = {};
      }

      // Collect all slots for the teacher
      for (final timetable in allTimetables.where((t) => t.isActive)) {
        for (final day in timetable.schedule.keys) {
          for (final timeSlot in timetable.schedule[day]!.keys) {
            final slot = timetable.schedule[day]![timeSlot]!;
            
            if (slot.teacher == teacherName && !slot.isBreak) {
              teacherSchedule[day]![timeSlot] = TimetableSlot(
                timeSlot: timeSlot,
                subject: '${slot.subject} (${timetable.className})',
                teacher: slot.teacher,
                room: slot.room,
                isBreak: false,
              );
            }
          }
        }
      }

      return teacherSchedule;
    } catch (e) {
      debugPrint('Error getting teacher timetable: $e');
      return {};
    }
  }

  // Get room timetable
  Future<Map<String, Map<String, TimetableSlot>>> getRoomTimetable(String roomName) async {
    try {
      final allTimetables = await getAllTimetables();
      final roomSchedule = <String, Map<String, TimetableSlot>>{};

      // Initialize empty schedule
      for (final day in weekDays) {
        roomSchedule[day] = {};
      }

      // Collect all slots for the room
      for (final timetable in allTimetables.where((t) => t.isActive)) {
        for (final day in timetable.schedule.keys) {
          for (final timeSlot in timetable.schedule[day]!.keys) {
            final slot = timetable.schedule[day]![timeSlot]!;
            
            if (slot.room == roomName && !slot.isBreak) {
              roomSchedule[day]![timeSlot] = TimetableSlot(
                timeSlot: timeSlot,
                subject: '${slot.subject} (${timetable.className})',
                teacher: slot.teacher,
                room: slot.room,
                isBreak: false,
              );
            }
          }
        }
      }

      return roomSchedule;
    } catch (e) {
      debugPrint('Error getting room timetable: $e');
      return {};
    }
  }

  // Delete timetable
  Future<void> deleteTimetable(String timetableId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timetablesJson = prefs.getStringList('timetables') ?? [];
      
      // Remove the timetable
      timetablesJson.removeWhere((json) {
        final timetable = TimetableModel.fromJsonString(json);
        return timetable.id == timetableId;
      });
      
      // Save back to preferences
      await prefs.setStringList('timetables', timetablesJson);
      
      debugPrint('Timetable deleted successfully');
    } catch (e) {
      debugPrint('Error deleting timetable: $e');
    }
  }
}
