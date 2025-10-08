class ClassSchedule {
  final String id;
  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;
  final String teacherId;
  final String teacherName;
  final String roomNumber;
  final DateTime startTime;
  final DateTime endTime;
  final String dayOfWeek; // monday, tuesday, etc.
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ClassSchedule({
    required this.id,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    required this.roomNumber,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
    this.description,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory ClassSchedule.fromMap(Map<String, dynamic> map, String id) {
    return ClassSchedule(
      id: id,
      classId: map['classId'] ?? '',
      className: map['className'] ?? '',
      subjectId: map['subjectId'] ?? '',
      subjectName: map['subjectName'] ?? '',
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      roomNumber: map['roomNumber'] ?? '',
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      dayOfWeek: map['dayOfWeek'] ?? '',
      description: map['description'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'className': className,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'roomNumber': roomNumber,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'dayOfWeek': dayOfWeek,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get timeRange {
    final startTimeStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startTimeStr - $endTimeStr';
  }

  Duration get duration {
    return endTime.difference(startTime);
  }

  bool get isCurrentlyActive {
    final now = DateTime.now();
    final currentTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    final classStart = DateTime(now.year, now.month, now.day, startTime.hour, startTime.minute);
    final classEnd = DateTime(now.year, now.month, now.day, endTime.hour, endTime.minute);
    
    return currentTime.isAfter(classStart) && currentTime.isBefore(classEnd);
  }
}

class StudentClassEnrollment {
  final String id;
  final String studentId;
  final String classId;
  final String className;
  final String grade;
  final String section;
  final String academicYear;
  final DateTime enrollmentDate;
  final EnrollmentStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  StudentClassEnrollment({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.className,
    required this.grade,
    required this.section,
    required this.academicYear,
    required this.enrollmentDate,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory StudentClassEnrollment.fromMap(Map<String, dynamic> map, String id) {
    return StudentClassEnrollment(
      id: id,
      studentId: map['studentId'] ?? '',
      classId: map['classId'] ?? '',
      className: map['className'] ?? '',
      grade: map['grade'] ?? '',
      section: map['section'] ?? '',
      academicYear: map['academicYear'] ?? '',
      enrollmentDate: DateTime.parse(map['enrollmentDate']),
      status: EnrollmentStatus.values.firstWhere(
        (e) => e.toString() == 'EnrollmentStatus.${map['status']}',
        orElse: () => EnrollmentStatus.active,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'classId': classId,
      'className': className,
      'grade': grade,
      'section': section,
      'academicYear': academicYear,
      'enrollmentDate': enrollmentDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

enum EnrollmentStatus {
  active,
  inactive,
  transferred,
  graduated,
  dropped
}

class TodayClassSchedule {
  final String studentId;
  final DateTime date;
  final List<ClassSchedule> classes;
  final ClassSchedule? currentClass;
  final ClassSchedule? nextClass;

  TodayClassSchedule({
    required this.studentId,
    required this.date,
    required this.classes,
    this.currentClass,
    this.nextClass,
  });

  factory TodayClassSchedule.fromSchedules(String studentId, List<ClassSchedule> allSchedules) {
    final today = DateTime.now();
    final dayOfWeek = _getDayOfWeek(today.weekday);
    
    // Filter classes for today
    final todayClasses = allSchedules
        .where((schedule) => schedule.dayOfWeek.toLowerCase() == dayOfWeek.toLowerCase())
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    // Find current and next class
    ClassSchedule? currentClass;
    ClassSchedule? nextClass;
    
    final now = DateTime.now();
    final currentTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    
    for (final classSchedule in todayClasses) {
      final classStart = DateTime(now.year, now.month, now.day, classSchedule.startTime.hour, classSchedule.startTime.minute);
      final classEnd = DateTime(now.year, now.month, now.day, classSchedule.endTime.hour, classSchedule.endTime.minute);
      
      if (currentTime.isAfter(classStart) && currentTime.isBefore(classEnd)) {
        currentClass = classSchedule;
      } else if (currentTime.isBefore(classStart) && nextClass == null) {
        nextClass = classSchedule;
      }
    }

    return TodayClassSchedule(
      studentId: studentId,
      date: today,
      classes: todayClasses,
      currentClass: currentClass,
      nextClass: nextClass,
    );
  }

  static String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      case 7: return 'sunday';
      default: return 'monday';
    }
  }

  int get totalClassesToday => classes.length;
  
  int get completedClasses {
    final now = DateTime.now();
    final currentTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    
    return classes.where((classSchedule) {
      final classEnd = DateTime(now.year, now.month, now.day, classSchedule.endTime.hour, classSchedule.endTime.minute);
      return currentTime.isAfter(classEnd);
    }).length;
  }
  
  int get remainingClasses => totalClassesToday - completedClasses;
}
