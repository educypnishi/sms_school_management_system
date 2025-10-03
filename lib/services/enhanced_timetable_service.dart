import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class EnhancedTimetableService {
  // Create timetable entry with conflict detection
  Future<TimetableEntry> createTimetableEntry({
    required String subject,
    required String teacherId,
    required String teacherName,
    required String classId,
    required String className,
    required String roomId,
    required String roomName,
    required DayOfWeek dayOfWeek,
    required TimeSlot timeSlot,
    required String academicYear,
    required String term,
    String? notes,
  }) async {
    try {
      // Check for conflicts before creating
      final conflicts = await checkConflicts(
        teacherId: teacherId,
        classId: classId,
        roomId: roomId,
        dayOfWeek: dayOfWeek,
        timeSlot: timeSlot,
        academicYear: academicYear,
        term: term,
      );
      
      if (conflicts.isNotEmpty) {
        throw TimetableConflictException('Conflicts detected', conflicts);
      }
      
      final entryId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final entry = TimetableEntry(
        id: entryId,
        subject: subject,
        teacherId: teacherId,
        teacherName: teacherName,
        classId: classId,
        className: className,
        roomId: roomId,
        roomName: roomName,
        dayOfWeek: dayOfWeek,
        timeSlot: timeSlot,
        academicYear: academicYear,
        term: term,
        notes: notes,
        createdAt: DateTime.now(),
        isActive: true,
      );
      
      await _saveTimetableEntry(entry);
      return entry;
    } catch (e) {
      debugPrint('Error creating timetable entry: $e');
      rethrow;
    }
  }
  
  // Check for scheduling conflicts
  Future<List<TimetableConflict>> checkConflicts({
    required String teacherId,
    required String classId,
    required String roomId,
    required DayOfWeek dayOfWeek,
    required TimeSlot timeSlot,
    required String academicYear,
    required String term,
    String? excludeEntryId,
  }) async {
    try {
      final conflicts = <TimetableConflict>[];
      final existingEntries = await getTimetableEntries(
        academicYear: academicYear,
        term: term,
        dayOfWeek: dayOfWeek,
      );
      
      for (final entry in existingEntries) {
        if (excludeEntryId != null && entry.id == excludeEntryId) {
          continue;
        }
        
        if (_timeSlotOverlaps(entry.timeSlot, timeSlot)) {
          // Teacher conflict
          if (entry.teacherId == teacherId) {
            conflicts.add(TimetableConflict(
              type: ConflictType.teacher,
              message: 'Teacher ${entry.teacherName} is already scheduled at this time',
              conflictingEntry: entry,
            ));
          }
          
          // Class conflict
          if (entry.classId == classId) {
            conflicts.add(TimetableConflict(
              type: ConflictType.class_,
              message: 'Class ${entry.className} is already scheduled at this time',
              conflictingEntry: entry,
            ));
          }
          
          // Room conflict
          if (entry.roomId == roomId) {
            conflicts.add(TimetableConflict(
              type: ConflictType.room,
              message: 'Room ${entry.roomName} is already booked at this time',
              conflictingEntry: entry,
            ));
          }
        }
      }
      
      return conflicts;
    } catch (e) {
      debugPrint('Error checking conflicts: $e');
      return [];
    }
  }
  
  // Generate optimal timetable automatically
  Future<List<TimetableEntry>> generateOptimalTimetable({
    required String academicYear,
    required String term,
    required List<TimetableRequirement> requirements,
    TimetableConstraints? constraints,
  }) async {
    try {
      final generatedEntries = <TimetableEntry>[];
      final usedSlots = <String, Set<String>>{};
      
      // Sort requirements by priority
      requirements.sort((a, b) => b.priority.compareTo(a.priority));
      
      for (final requirement in requirements) {
        final bestSlot = await _findBestTimeSlot(
          requirement: requirement,
          usedSlots: usedSlots,
          constraints: constraints,
          academicYear: academicYear,
          term: term,
        );
        
        if (bestSlot != null) {
          final entry = await createTimetableEntry(
            subject: requirement.subject,
            teacherId: requirement.teacherId,
            teacherName: requirement.teacherName,
            classId: requirement.classId,
            className: requirement.className,
            roomId: requirement.preferredRoomId ?? 'room_1',
            roomName: requirement.preferredRoomName ?? 'Room 1',
            dayOfWeek: bestSlot.dayOfWeek,
            timeSlot: bestSlot.timeSlot,
            academicYear: academicYear,
            term: term,
            notes: 'Auto-generated',
          );
          
          generatedEntries.add(entry);
          
          // Mark slot as used
          final slotKey = '${bestSlot.dayOfWeek}_${bestSlot.timeSlot.startTime}';
          usedSlots[slotKey] ??= <String>{};
          usedSlots[slotKey]!.addAll([
            requirement.teacherId,
            requirement.classId,
            requirement.preferredRoomId ?? 'room_1'
          ]);
        }
      }
      
      return generatedEntries;
    } catch (e) {
      debugPrint('Error generating optimal timetable: $e');
      return [];
    }
  }
  
  // Get timetable for a specific class
  Future<List<TimetableEntry>> getClassTimetable({
    required String classId,
    required String academicYear,
    required String term,
    DayOfWeek? dayOfWeek,
  }) async {
    try {
      final allEntries = await getTimetableEntries(
        academicYear: academicYear,
        term: term,
        dayOfWeek: dayOfWeek,
      );
      
      return allEntries.where((entry) => entry.classId == classId).toList();
    } catch (e) {
      debugPrint('Error getting class timetable: $e');
      return [];
    }
  }
  
  // Get timetable for a specific teacher
  Future<List<TimetableEntry>> getTeacherTimetable({
    required String teacherId,
    required String academicYear,
    required String term,
    DayOfWeek? dayOfWeek,
  }) async {
    try {
      final allEntries = await getTimetableEntries(
        academicYear: academicYear,
        term: term,
        dayOfWeek: dayOfWeek,
      );
      
      return allEntries.where((entry) => entry.teacherId == teacherId).toList();
    } catch (e) {
      debugPrint('Error getting teacher timetable: $e');
      return [];
    }
  }
  
  // Get room utilization
  Future<Map<String, dynamic>> getRoomUtilization({
    required String roomId,
    required String academicYear,
    required String term,
  }) async {
    try {
      final allEntries = await getTimetableEntries(
        academicYear: academicYear,
        term: term,
      );
      
      final roomEntries = allEntries.where((entry) => entry.roomId == roomId).toList();
      
      // Calculate utilization per day
      final utilizationByDay = <DayOfWeek, int>{};
      for (final day in DayOfWeek.values) {
        utilizationByDay[day] = roomEntries.where((entry) => entry.dayOfWeek == day).length;
      }
      
      // Calculate total possible slots (assuming 8 periods per day, 5 days a week)
      const totalSlotsPerWeek = 40;
      final usedSlots = roomEntries.length;
      final utilizationPercentage = (usedSlots / totalSlotsPerWeek) * 100;
      
      return {
        'roomId': roomId,
        'totalSlots': totalSlotsPerWeek,
        'usedSlots': usedSlots,
        'utilizationPercentage': utilizationPercentage,
        'utilizationByDay': utilizationByDay.map((k, v) => MapEntry(k.toString().split('.').last, v)),
        'peakDay': utilizationByDay.entries.reduce((a, b) => a.value > b.value ? a : b).key.toString().split('.').last,
      };
    } catch (e) {
      debugPrint('Error getting room utilization: $e');
      return {};
    }
  }
  
  // Get teacher workload
  Future<Map<String, dynamic>> getTeacherWorkload({
    required String teacherId,
    required String academicYear,
    required String term,
  }) async {
    try {
      final teacherEntries = await getTeacherTimetable(
        teacherId: teacherId,
        academicYear: academicYear,
        term: term,
      );
      
      // Calculate workload per day
      final workloadByDay = <DayOfWeek, int>{};
      for (final day in DayOfWeek.values) {
        workloadByDay[day] = teacherEntries.where((entry) => entry.dayOfWeek == day).length;
      }
      
      // Calculate subject distribution
      final subjectDistribution = <String, int>{};
      for (final entry in teacherEntries) {
        subjectDistribution[entry.subject] = (subjectDistribution[entry.subject] ?? 0) + 1;
      }
      
      return {
        'teacherId': teacherId,
        'totalPeriods': teacherEntries.length,
        'workloadByDay': workloadByDay.map((k, v) => MapEntry(k.toString().split('.').last, v)),
        'subjectDistribution': subjectDistribution,
        'averagePeriodsPerDay': teacherEntries.length / 5,
        'busiestDay': workloadByDay.entries.reduce((a, b) => a.value > b.value ? a : b).key.toString().split('.').last,
      };
    } catch (e) {
      debugPrint('Error getting teacher workload: $e');
      return {};
    }
  }
  
  // Validate timetable completeness
  Future<TimetableValidationResult> validateTimetable({
    required String academicYear,
    required String term,
  }) async {
    try {
      final allEntries = await getTimetableEntries(
        academicYear: academicYear,
        term: term,
      );
      
      final issues = <String>[];
      final warnings = <String>[];
      
      // Check for gaps in class schedules
      final classesByDay = <DayOfWeek, Set<String>>{};
      for (final entry in allEntries) {
        classesByDay[entry.dayOfWeek] ??= <String>{};
        classesByDay[entry.dayOfWeek]!.add(entry.classId);
      }
      
      // Check for teacher overload
      final teacherWorkloads = <String, int>{};
      for (final entry in allEntries) {
        teacherWorkloads[entry.teacherId] = (teacherWorkloads[entry.teacherId] ?? 0) + 1;
      }
      
      for (final entry in teacherWorkloads.entries) {
        if (entry.value > 30) { // More than 30 periods per week
          warnings.add('Teacher ${entry.key} has ${entry.value} periods per week (high workload)');
        }
      }
      
      // Check for room conflicts (this should not happen if conflict detection works)
      final roomConflicts = await _findRoomConflicts(allEntries);
      issues.addAll(roomConflicts);
      
      return TimetableValidationResult(
        isValid: issues.isEmpty,
        issues: issues,
        warnings: warnings,
        totalEntries: allEntries.length,
        validatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error validating timetable: $e');
      return TimetableValidationResult(
        isValid: false,
        issues: ['Validation failed: $e'],
        warnings: [],
        totalEntries: 0,
        validatedAt: DateTime.now(),
      );
    }
  }
  
  // Helper methods
  
  Future<TimetableEntry?> getTimetableEntryById(String entryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entryJson = prefs.getString('timetable_entry_$entryId');
      
      if (entryJson == null) {
        return null;
      }
      
      final entryMap = jsonDecode(entryJson) as Map<String, dynamic>;
      return TimetableEntry.fromMap(entryMap, entryId);
    } catch (e) {
      debugPrint('Error getting timetable entry: $e');
      return null;
    }
  }
  
  Future<List<TimetableEntry>> getTimetableEntries({
    required String academicYear,
    required String term,
    DayOfWeek? dayOfWeek,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      final entryKeys = allKeys.where((key) => key.startsWith('timetable_entry_')).toList();
      
      final entries = <TimetableEntry>[];
      
      for (final key in entryKeys) {
        final entryJson = prefs.getString(key);
        if (entryJson != null) {
          final entryMap = jsonDecode(entryJson) as Map<String, dynamic>;
          final entry = TimetableEntry.fromMap(entryMap, key.substring('timetable_entry_'.length));
          
          if (entry.academicYear == academicYear && 
              entry.term == term && 
              entry.isActive &&
              (dayOfWeek == null || entry.dayOfWeek == dayOfWeek)) {
            entries.add(entry);
          }
        }
      }
      
      // Sort by day and time
      entries.sort((a, b) {
        final dayComparison = a.dayOfWeek.index.compareTo(b.dayOfWeek.index);
        if (dayComparison != 0) return dayComparison;
        return a.timeSlot.startTime.compareTo(b.timeSlot.startTime);
      });
      
      return entries;
    } catch (e) {
      debugPrint('Error getting timetable entries: $e');
      return [];
    }
  }
  
  Future<void> _saveTimetableEntry(TimetableEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('timetable_entry_${entry.id}', jsonEncode(entry.toMap()));
  }
  
  bool _timeSlotOverlaps(TimeSlot slot1, TimeSlot slot2) {
    return slot1.startTime.isBefore(slot2.endTime) && slot2.startTime.isBefore(slot1.endTime);
  }
  
  Future<OptimalSlot?> _findBestTimeSlot({
    required TimetableRequirement requirement,
    required Map<String, Set<String>> usedSlots,
    TimetableConstraints? constraints,
    required String academicYear,
    required String term,
  }) async {
    // Simple algorithm to find the best available slot
    for (final day in DayOfWeek.values) {
      for (int hour = 9; hour < 17; hour++) {
        final timeSlot = TimeSlot(
          startTime: DateTime(2024, 1, 1, hour, 0),
          endTime: DateTime(2024, 1, 1, hour + 1, 0),
        );
        
        final slotKey = '${day}_${timeSlot.startTime}';
        final usedResources = usedSlots[slotKey] ?? <String>{};
        
        // Check if resources are available
        if (!usedResources.contains(requirement.teacherId) &&
            !usedResources.contains(requirement.classId) &&
            !usedResources.contains(requirement.preferredRoomId ?? 'room_1')) {
          
          return OptimalSlot(dayOfWeek: day, timeSlot: timeSlot);
        }
      }
    }
    
    return null;
  }
  
  Future<List<String>> _findRoomConflicts(List<TimetableEntry> entries) async {
    final conflicts = <String>[];
    final roomSlots = <String, List<TimetableEntry>>{};
    
    // Group entries by room and time slot
    for (final entry in entries) {
      final slotKey = '${entry.roomId}_${entry.dayOfWeek}_${entry.timeSlot.startTime}';
      roomSlots[slotKey] ??= [];
      roomSlots[slotKey]!.add(entry);
    }
    
    // Check for conflicts
    for (final entry in roomSlots.entries) {
      if (entry.value.length > 1) {
        conflicts.add('Room conflict: ${entry.value.first.roomName} has ${entry.value.length} classes scheduled at the same time');
      }
    }
    
    return conflicts;
  }
}

// Models and Classes

class TimetableEntry {
  final String id;
  final String subject;
  final String teacherId;
  final String teacherName;
  final String classId;
  final String className;
  final String roomId;
  final String roomName;
  final DayOfWeek dayOfWeek;
  final TimeSlot timeSlot;
  final String academicYear;
  final String term;
  final String? notes;
  final DateTime createdAt;
  final bool isActive;
  
  TimetableEntry({
    required this.id,
    required this.subject,
    required this.teacherId,
    required this.teacherName,
    required this.classId,
    required this.className,
    required this.roomId,
    required this.roomName,
    required this.dayOfWeek,
    required this.timeSlot,
    required this.academicYear,
    required this.term,
    this.notes,
    required this.createdAt,
    required this.isActive,
  });
  
  factory TimetableEntry.fromMap(Map<String, dynamic> map, String id) {
    return TimetableEntry(
      id: id,
      subject: map['subject'] ?? '',
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      classId: map['classId'] ?? '',
      className: map['className'] ?? '',
      roomId: map['roomId'] ?? '',
      roomName: map['roomName'] ?? '',
      dayOfWeek: DayOfWeek.values.firstWhere(
        (d) => d.toString().split('.').last == map['dayOfWeek'],
        orElse: () => DayOfWeek.monday,
      ),
      timeSlot: TimeSlot.fromMap(map['timeSlot']),
      academicYear: map['academicYear'] ?? '',
      term: map['term'] ?? '',
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      isActive: map['isActive'] ?? true,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'classId': classId,
      'className': className,
      'roomId': roomId,
      'roomName': roomName,
      'dayOfWeek': dayOfWeek.toString().split('.').last,
      'timeSlot': timeSlot.toMap(),
      'academicYear': academicYear,
      'term': term,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}

class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;
  
  TimeSlot({
    required this.startTime,
    required this.endTime,
  });
  
  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
  }
}

class TimetableConflict {
  final ConflictType type;
  final String message;
  final TimetableEntry conflictingEntry;
  
  TimetableConflict({
    required this.type,
    required this.message,
    required this.conflictingEntry,
  });
}

class TimetableRequirement {
  final String subject;
  final String teacherId;
  final String teacherName;
  final String classId;
  final String className;
  final String? preferredRoomId;
  final String? preferredRoomName;
  final int periodsPerWeek;
  final int priority;
  
  TimetableRequirement({
    required this.subject,
    required this.teacherId,
    required this.teacherName,
    required this.classId,
    required this.className,
    this.preferredRoomId,
    this.preferredRoomName,
    required this.periodsPerWeek,
    required this.priority,
  });
}

class TimetableConstraints {
  final List<DayOfWeek> workingDays;
  final TimeSlot workingHours;
  final int maxPeriodsPerDay;
  final int minBreakBetweenPeriods;
  
  TimetableConstraints({
    required this.workingDays,
    required this.workingHours,
    required this.maxPeriodsPerDay,
    required this.minBreakBetweenPeriods,
  });
}

class TimetableValidationResult {
  final bool isValid;
  final List<String> issues;
  final List<String> warnings;
  final int totalEntries;
  final DateTime validatedAt;
  
  TimetableValidationResult({
    required this.isValid,
    required this.issues,
    required this.warnings,
    required this.totalEntries,
    required this.validatedAt,
  });
}

class OptimalSlot {
  final DayOfWeek dayOfWeek;
  final TimeSlot timeSlot;
  
  OptimalSlot({
    required this.dayOfWeek,
    required this.timeSlot,
  });
}

class TimetableConflictException implements Exception {
  final String message;
  final List<TimetableConflict> conflicts;
  
  TimetableConflictException(this.message, this.conflicts);
  
  @override
  String toString() => 'TimetableConflictException: $message';
}

enum DayOfWeek { monday, tuesday, wednesday, thursday, friday, saturday, sunday }
enum ConflictType { teacher, class_, room }
