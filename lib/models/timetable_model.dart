import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableSlot {
  final String timeSlot;
  final String subject;
  final String teacher;
  final String room;
  final bool isBreak;

  TimetableSlot({
    required this.timeSlot,
    required this.subject,
    required this.teacher,
    required this.room,
    this.isBreak = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'timeSlot': timeSlot,
      'subject': subject,
      'teacher': teacher,
      'room': room,
      'isBreak': isBreak,
    };
  }

  factory TimetableSlot.fromMap(Map<String, dynamic> map) {
    return TimetableSlot(
      timeSlot: map['timeSlot'] ?? '',
      subject: map['subject'] ?? '',
      teacher: map['teacher'] ?? '',
      room: map['room'] ?? '',
      isBreak: map['isBreak'] ?? false,
    );
  }

  TimetableSlot copyWith({
    String? timeSlot,
    String? subject,
    String? teacher,
    String? room,
    bool? isBreak,
  }) {
    return TimetableSlot(
      timeSlot: timeSlot ?? this.timeSlot,
      subject: subject ?? this.subject,
      teacher: teacher ?? this.teacher,
      room: room ?? this.room,
      isBreak: isBreak ?? this.isBreak,
    );
  }
}

class TimetableModel {
  final String id;
  final String className;
  final String term;
  final String academicYear;
  final Map<String, Map<String, TimetableSlot>> schedule;
  final DateTime createdAt;
  final String createdBy;
  final bool isActive;
  final DateTime? lastModified;
  final String? notes;

  TimetableModel({
    required this.id,
    required this.className,
    required this.term,
    required this.academicYear,
    required this.schedule,
    required this.createdAt,
    required this.createdBy,
    this.isActive = true,
    this.lastModified,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    // Convert schedule to serializable format
    final scheduleMap = <String, Map<String, Map<String, dynamic>>>{};
    for (final day in schedule.keys) {
      scheduleMap[day] = {};
      for (final timeSlot in schedule[day]!.keys) {
        scheduleMap[day]![timeSlot] = schedule[day]![timeSlot]!.toMap();
      }
    }

    return {
      'id': id,
      'className': className,
      'term': term,
      'academicYear': academicYear,
      'schedule': scheduleMap,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'isActive': isActive,
      'lastModified': lastModified?.toIso8601String(),
      'notes': notes,
    };
  }

  factory TimetableModel.fromMap(Map<String, dynamic> map) {
    // Convert schedule from serializable format
    final scheduleMap = <String, Map<String, TimetableSlot>>{};
    final rawSchedule = map['schedule'] as Map<String, dynamic>? ?? {};
    
    for (final day in rawSchedule.keys) {
      scheduleMap[day] = {};
      final daySchedule = rawSchedule[day] as Map<String, dynamic>? ?? {};
      
      for (final timeSlot in daySchedule.keys) {
        final slotData = daySchedule[timeSlot] as Map<String, dynamic>? ?? {};
        scheduleMap[day]![timeSlot] = TimetableSlot.fromMap(slotData);
      }
    }

    return TimetableModel(
      id: map['id'] ?? '',
      className: map['className'] ?? '',
      term: map['term'] ?? '',
      academicYear: map['academicYear'] ?? '',
      schedule: scheduleMap,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      isActive: map['isActive'] ?? true,
      lastModified: map['lastModified'] != null 
          ? DateTime.parse(map['lastModified']) 
          : null,
      notes: map['notes'],
    );
  }

  String toJsonString() {
    return jsonEncode(toMap());
  }

  factory TimetableModel.fromJsonString(String jsonString) {
    return TimetableModel.fromMap(jsonDecode(jsonString));
  }

  TimetableModel copyWith({
    String? id,
    String? className,
    String? term,
    String? academicYear,
    Map<String, Map<String, TimetableSlot>>? schedule,
    DateTime? createdAt,
    String? createdBy,
    bool? isActive,
    DateTime? lastModified,
    String? notes,
  }) {
    return TimetableModel(
      id: id ?? this.id,
      className: className ?? this.className,
      term: term ?? this.term,
      academicYear: academicYear ?? this.academicYear,
      schedule: schedule ?? this.schedule,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      lastModified: lastModified ?? this.lastModified,
      notes: notes ?? this.notes,
    );
  }

  // Get total periods for a subject
  int getSubjectPeriods(String subject) {
    int count = 0;
    for (final day in schedule.values) {
      for (final slot in day.values) {
        if (slot.subject == subject && !slot.isBreak) {
          count++;
        }
      }
    }
    return count;
  }

  // Get all subjects in the timetable
  Set<String> getAllSubjects() {
    final subjects = <String>{};
    for (final day in schedule.values) {
      for (final slot in day.values) {
        if (!slot.isBreak && slot.subject.isNotEmpty) {
          subjects.add(slot.subject);
        }
      }
    }
    return subjects;
  }

  // Get all teachers in the timetable
  Set<String> getAllTeachers() {
    final teachers = <String>{};
    for (final day in schedule.values) {
      for (final slot in day.values) {
        if (!slot.isBreak && slot.teacher.isNotEmpty) {
          teachers.add(slot.teacher);
        }
      }
    }
    return teachers;
  }

  // Get all rooms in the timetable
  Set<String> getAllRooms() {
    final rooms = <String>{};
    for (final day in schedule.values) {
      for (final slot in day.values) {
        if (!slot.isBreak && slot.room.isNotEmpty) {
          rooms.add(slot.room);
        }
      }
    }
    return rooms;
  }

  // Get teacher's schedule for a specific day
  List<TimetableSlot> getTeacherDaySchedule(String teacherName, String day) {
    final daySchedule = schedule[day] ?? {};
    return daySchedule.values
        .where((slot) => slot.teacher == teacherName && !slot.isBreak)
        .toList();
  }

  // Check if a time slot is free for a teacher
  bool isTeacherFree(String teacherName, String day, String timeSlot) {
    final slot = schedule[day]?[timeSlot];
    return slot == null || slot.teacher != teacherName || slot.isBreak;
  }

  // Check if a room is free at a specific time
  bool isRoomFree(String roomName, String day, String timeSlot) {
    final slot = schedule[day]?[timeSlot];
    return slot == null || slot.room != roomName || slot.isBreak;
  }

  // Get statistics about the timetable
  Map<String, dynamic> getStatistics() {
    final subjects = getAllSubjects();
    final teachers = getAllTeachers();
    final rooms = getAllRooms();
    
    int totalPeriods = 0;
    int breakPeriods = 0;
    
    for (final day in schedule.values) {
      for (final slot in day.values) {
        if (slot.isBreak) {
          breakPeriods++;
        } else if (slot.subject.isNotEmpty) {
          totalPeriods++;
        }
      }
    }

    return {
      'totalSubjects': subjects.length,
      'totalTeachers': teachers.length,
      'totalRooms': rooms.length,
      'totalPeriods': totalPeriods,
      'breakPeriods': breakPeriods,
      'subjects': subjects.toList(),
      'teachers': teachers.toList(),
      'rooms': rooms.toList(),
    };
  }

  // Add Firebase factory method
  factory TimetableModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TimetableModel.fromMap({...data, 'id': doc.id});
  }
}

// Enhanced Firebase-compatible models
class EnhancedTimetableModel {
  final String id;
  final String name;
  final String academicYear;
  final String semester;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> workingDays;
  final Map<String, String> timeSlots;
  final String? description;
  final String status;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> schedules;
  final List<Map<String, dynamic>> conflicts;
  final bool isActive;

  EnhancedTimetableModel({
    required this.id,
    required this.name,
    required this.academicYear,
    required this.semester,
    required this.startDate,
    required this.endDate,
    required this.workingDays,
    required this.timeSlots,
    this.description,
    this.status = 'draft',
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.schedules = const [],
    this.conflicts = const [],
    this.isActive = false,
  });

  factory EnhancedTimetableModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return EnhancedTimetableModel(
      id: doc.id,
      name: data['name'] ?? '',
      academicYear: data['academicYear'] ?? '',
      semester: data['semester'] ?? '',
      startDate: data['startDate'] != null 
          ? DateTime.parse(data['startDate']) 
          : DateTime.now(),
      endDate: data['endDate'] != null 
          ? DateTime.parse(data['endDate']) 
          : DateTime.now(),
      workingDays: List<String>.from(data['workingDays'] ?? []),
      timeSlots: Map<String, String>.from(data['timeSlots'] ?? {}),
      description: data['description'],
      status: data['status'] ?? 'draft',
      createdBy: data['createdBy'],
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
      schedules: List<String>.from(data['schedules'] ?? []),
      conflicts: List<Map<String, dynamic>>.from(data['conflicts'] ?? []),
      isActive: data['isActive'] ?? false,
    );
  }
}

class ClassScheduleModel {
  final String id;
  final String timetableId;
  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;
  final String teacherId;
  final String teacherName;
  final String roomId;
  final String roomName;
  final String day;
  final String timeSlot;
  final String startTime;
  final String endTime;
  final String? notes;
  final List<Map<String, dynamic>> conflicts;
  final String status;

  ClassScheduleModel({
    required this.id,
    required this.timetableId,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    required this.roomId,
    required this.roomName,
    required this.day,
    required this.timeSlot,
    required this.startTime,
    required this.endTime,
    this.notes,
    this.conflicts = const [],
    this.status = 'confirmed',
  });

  factory ClassScheduleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ClassScheduleModel(
      id: doc.id,
      timetableId: data['timetableId'] ?? '',
      classId: data['classId'] ?? '',
      className: data['className'] ?? '',
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      teacherId: data['teacherId'] ?? '',
      teacherName: data['teacherName'] ?? '',
      roomId: data['roomId'] ?? '',
      roomName: data['roomName'] ?? '',
      day: data['day'] ?? '',
      timeSlot: data['timeSlot'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      notes: data['notes'],
      conflicts: List<Map<String, dynamic>>.from(data['conflicts'] ?? []),
      status: data['status'] ?? 'confirmed',
    );
  }

  bool get hasConflicts => conflicts.isNotEmpty;
}
