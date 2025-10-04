import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/timetable_model.dart';
import '../models/class_model.dart';
import '../models/teacher_model.dart';
import '../models/room_model.dart';
import 'firebase_auth_service.dart';

class FirebaseTimetableService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new timetable
  static Future<String> createTimetable({
    required String name,
    required String academicYear,
    required String semester,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> workingDays,
    required Map<String, String> timeSlots, // slot_id: time_range
    String? description,
  }) async {
    try {
      final timetableData = {
        'name': name,
        'academicYear': academicYear,
        'semester': semester,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'workingDays': workingDays,
        'timeSlots': timeSlots,
        'description': description,
        'status': 'draft',
        'createdBy': FirebaseAuthService.currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'conflicts': [],
        'isActive': false,
      };

      final docRef = await _firestore.collection('timetables').add(timetableData);
      
      debugPrint('✅ Timetable created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error creating timetable: $e');
      rethrow;
    }
  }

  // Add class schedule to timetable
  static Future<String> addClassSchedule({
    required String timetableId,
    required String classId,
    required String className,
    required String subjectId,
    required String subjectName,
    required String teacherId,
    required String teacherName,
    required String roomId,
    required String roomName,
    required String day,
    required String timeSlot,
    required String startTime,
    required String endTime,
    String? notes,
  }) async {
    try {
      // Check for conflicts before adding
      final conflicts = await _checkScheduleConflicts(
        timetableId: timetableId,
        teacherId: teacherId,
        roomId: roomId,
        day: day,
        timeSlot: timeSlot,
        startTime: startTime,
        endTime: endTime,
      );

      final scheduleData = {
        'timetableId': timetableId,
        'classId': classId,
        'className': className,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'roomId': roomId,
        'roomName': roomName,
        'day': day,
        'timeSlot': timeSlot,
        'startTime': startTime,
        'endTime': endTime,
        'notes': notes,
        'conflicts': conflicts,
        'status': conflicts.isEmpty ? 'confirmed' : 'conflict',
        'createdBy': FirebaseAuthService.currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('class_schedules').add(scheduleData);
      
      // Update timetable with schedule reference
      await _firestore.collection('timetables').doc(timetableId).update({
        'schedules': FieldValue.arrayUnion([docRef.id]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log conflicts if any
      if (conflicts.isNotEmpty) {
        await _logConflicts(timetableId, docRef.id, conflicts);
      }

      debugPrint('✅ Class schedule added: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error adding class schedule: $e');
      rethrow;
    }
  }

  // Check for scheduling conflicts
  static Future<List<Map<String, dynamic>>> _checkScheduleConflicts({
    required String timetableId,
    required String teacherId,
    required String roomId,
    required String day,
    required String timeSlot,
    required String startTime,
    required String endTime,
  }) async {
    List<Map<String, dynamic>> conflicts = [];

    try {
      // Check teacher conflicts
      final teacherQuery = await _firestore
          .collection('class_schedules')
          .where('timetableId', isEqualTo: timetableId)
          .where('teacherId', isEqualTo: teacherId)
          .where('day', isEqualTo: day)
          .where('timeSlot', isEqualTo: timeSlot)
          .get();

      if (teacherQuery.docs.isNotEmpty) {
        conflicts.add({
          'type': 'teacher_conflict',
          'message': 'Teacher already assigned to another class at this time',
          'conflictingSchedule': teacherQuery.docs.first.id,
          'details': teacherQuery.docs.first.data(),
        });
      }

      // Check room conflicts
      final roomQuery = await _firestore
          .collection('class_schedules')
          .where('timetableId', isEqualTo: timetableId)
          .where('roomId', isEqualTo: roomId)
          .where('day', isEqualTo: day)
          .where('timeSlot', isEqualTo: timeSlot)
          .get();

      if (roomQuery.docs.isNotEmpty) {
        conflicts.add({
          'type': 'room_conflict',
          'message': 'Room already booked for another class at this time',
          'conflictingSchedule': roomQuery.docs.first.id,
          'details': roomQuery.docs.first.data(),
        });
      }

      // Check time overlap conflicts
      final timeOverlapQuery = await _firestore
          .collection('class_schedules')
          .where('timetableId', isEqualTo: timetableId)
          .where('day', isEqualTo: day)
          .get();

      for (var doc in timeOverlapQuery.docs) {
        final data = doc.data();
        if (_hasTimeOverlap(startTime, endTime, data['startTime'], data['endTime'])) {
          if (data['teacherId'] == teacherId || data['roomId'] == roomId) {
            conflicts.add({
              'type': 'time_overlap',
              'message': 'Time overlap detected with existing schedule',
              'conflictingSchedule': doc.id,
              'details': data,
            });
          }
        }
      }

    } catch (e) {
      debugPrint('❌ Error checking conflicts: $e');
    }

    return conflicts;
  }

  // Check if two time ranges overlap
  static bool _hasTimeOverlap(String start1, String end1, String start2, String end2) {
    try {
      final startTime1 = _parseTime(start1);
      final endTime1 = _parseTime(end1);
      final startTime2 = _parseTime(start2);
      final endTime2 = _parseTime(end2);

      return (startTime1 < endTime2) && (startTime2 < endTime1);
    } catch (e) {
      debugPrint('❌ Error parsing time overlap: $e');
      return false;
    }
  }

  // Parse time string to minutes for comparison
  static int _parseTime(String timeString) {
    final parts = timeString.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  // Log conflicts for tracking
  static Future<void> _logConflicts(
    String timetableId,
    String scheduleId,
    List<Map<String, dynamic>> conflicts,
  ) async {
    try {
      await _firestore.collection('timetable_conflicts').add({
        'timetableId': timetableId,
        'scheduleId': scheduleId,
        'conflicts': conflicts,
        'status': 'unresolved',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuthService.currentUserId,
      });
    } catch (e) {
      debugPrint('❌ Error logging conflicts: $e');
    }
  }

  // Get timetable by ID
  static Future<TimetableModel?> getTimetable(String timetableId) async {
    try {
      final doc = await _firestore.collection('timetables').doc(timetableId).get();
      
      if (doc.exists) {
        return TimetableModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting timetable: $e');
      return null;
    }
  }

  // Get all timetables
  static Future<List<TimetableModel>> getAllTimetables() async {
    try {
      final query = await _firestore
          .collection('timetables')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => TimetableModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ Error getting timetables: $e');
      return [];
    }
  }

  // Get class schedules for a timetable
  static Future<List<ClassScheduleModel>> getClassSchedules(String timetableId) async {
    try {
      final query = await _firestore
          .collection('class_schedules')
          .where('timetableId', isEqualTo: timetableId)
          .orderBy('day')
          .orderBy('startTime')
          .get();

      return query.docs.map((doc) => ClassScheduleModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ Error getting class schedules: $e');
      return [];
    }
  }

  // Get teacher's schedule
  static Future<List<ClassScheduleModel>> getTeacherSchedule(
    String teacherId,
    String timetableId,
  ) async {
    try {
      final query = await _firestore
          .collection('class_schedules')
          .where('timetableId', isEqualTo: timetableId)
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('day')
          .orderBy('startTime')
          .get();

      return query.docs.map((doc) => ClassScheduleModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ Error getting teacher schedule: $e');
      return [];
    }
  }

  // Get room utilization
  static Future<Map<String, dynamic>> getRoomUtilization(
    String roomId,
    String timetableId,
  ) async {
    try {
      final query = await _firestore
          .collection('class_schedules')
          .where('timetableId', isEqualTo: timetableId)
          .where('roomId', isEqualTo: roomId)
          .get();

      final schedules = query.docs.map((doc) => ClassScheduleModel.fromFirestore(doc)).toList();
      
      // Calculate utilization statistics
      final totalSlots = 5 * 8; // 5 days * 8 periods (example)
      final usedSlots = schedules.length;
      final utilizationRate = (usedSlots / totalSlots) * 100;

      return {
        'roomId': roomId,
        'totalSlots': totalSlots,
        'usedSlots': usedSlots,
        'utilizationRate': utilizationRate,
        'schedules': schedules,
      };
    } catch (e) {
      debugPrint('❌ Error getting room utilization: $e');
      return {};
    }
  }

  // Activate timetable
  static Future<void> activateTimetable(String timetableId) async {
    try {
      // Deactivate all other timetables first
      final activeQuery = await _firestore
          .collection('timetables')
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in activeQuery.docs) {
        await doc.reference.update({
          'isActive': false,
          'status': 'inactive',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Activate the selected timetable
      await _firestore.collection('timetables').doc(timetableId).update({
        'isActive': true,
        'status': 'active',
        'activatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Timetable activated: $timetableId');
    } catch (e) {
      debugPrint('❌ Error activating timetable: $e');
      rethrow;
    }
  }

  // Generate optimal timetable using AI algorithm
  static Future<String> generateOptimalTimetable({
    required String name,
    required String academicYear,
    required List<ClassModel> classes,
    required List<TeacherModel> teachers,
    required List<RoomModel> rooms,
    required Map<String, int> subjectHours, // subject_id: hours_per_week
  }) async {
    try {
      debugPrint('🤖 Starting AI timetable generation...');
      
      // Create base timetable
      final timetableId = await createTimetable(
        name: name,
        academicYear: academicYear,
        semester: 'Fall 2024',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 120)),
        workingDays: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
        timeSlots: {
          'slot1': '08:00-08:50',
          'slot2': '08:50-09:40',
          'slot3': '09:40-10:30',
          'slot4': '10:50-11:40',
          'slot5': '11:40-12:30',
          'slot6': '12:30-13:20',
          'slot7': '14:00-14:50',
          'slot8': '14:50-15:40',
        },
        description: 'AI-generated optimal timetable',
      );

      // AI Algorithm: Assign classes optimally
      await _runOptimizationAlgorithm(timetableId, classes, teachers, rooms, subjectHours);

      debugPrint('✅ AI timetable generation completed: $timetableId');
      return timetableId;
    } catch (e) {
      debugPrint('❌ Error generating optimal timetable: $e');
      rethrow;
    }
  }

  // AI optimization algorithm
  static Future<void> _runOptimizationAlgorithm(
    String timetableId,
    List<ClassModel> classes,
    List<TeacherModel> teachers,
    List<RoomModel> rooms,
    Map<String, int> subjectHours,
  ) async {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    final timeSlots = ['slot1', 'slot2', 'slot3', 'slot4', 'slot5', 'slot6', 'slot7', 'slot8'];
    
    // Simple greedy algorithm for demonstration
    for (var classModel in classes) {
      for (var subject in classModel.subjects) {
        final hoursNeeded = subjectHours[subject.id] ?? 3;
        int assignedHours = 0;

        for (var day in days) {
          for (var slot in timeSlots) {
            if (assignedHours >= hoursNeeded) break;

            // Find available teacher
            final availableTeacher = teachers.firstWhere(
              (t) => t.subjects.contains(subject.id),
              orElse: () => teachers.first,
            );

            // Find available room
            final availableRoom = rooms.firstWhere(
              (r) => r.capacity >= classModel.currentStudents,
              orElse: () => rooms.first,
            );

            try {
              await addClassSchedule(
                timetableId: timetableId,
                classId: classModel.id,
                className: classModel.name,
                subjectId: subject.id,
                subjectName: subject.name,
                teacherId: availableTeacher.id,
                teacherName: availableTeacher.name,
                roomId: availableRoom.id,
                roomName: availableRoom.name,
                day: day,
                timeSlot: slot,
                startTime: _getSlotStartTime(slot),
                endTime: _getSlotEndTime(slot),
                notes: 'AI-generated schedule',
              );
              assignedHours++;
            } catch (e) {
              // Skip if conflict, try next slot
              continue;
            }
          }
          if (assignedHours >= hoursNeeded) break;
        }
      }
    }
  }

  static String _getSlotStartTime(String slot) {
    final slotTimes = {
      'slot1': '08:00',
      'slot2': '08:50',
      'slot3': '09:40',
      'slot4': '10:50',
      'slot5': '11:40',
      'slot6': '12:30',
      'slot7': '14:00',
      'slot8': '14:50',
    };
    return slotTimes[slot] ?? '08:00';
  }

  static String _getSlotEndTime(String slot) {
    final slotTimes = {
      'slot1': '08:50',
      'slot2': '09:40',
      'slot3': '10:30',
      'slot4': '11:40',
      'slot5': '12:30',
      'slot6': '13:20',
      'slot7': '14:50',
      'slot8': '15:40',
    };
    return slotTimes[slot] ?? '08:50';
  }

  // Stream timetables for real-time updates
  static Stream<List<TimetableModel>> streamTimetables() {
    return _firestore
        .collection('timetables')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TimetableModel.fromFirestore(doc))
            .toList());
  }

  // Stream class schedules for real-time updates
  static Stream<List<ClassScheduleModel>> streamClassSchedules(String timetableId) {
    return _firestore
        .collection('class_schedules')
        .where('timetableId', isEqualTo: timetableId)
        .orderBy('day')
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassScheduleModel.fromFirestore(doc))
            .toList());
  }
}
