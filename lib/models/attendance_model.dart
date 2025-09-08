class AttendanceModel {
  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseName;
  final String classId;
  final String className;
  final DateTime date;
  final String status; // present, absent, late, excused
  final String? reason;
  final String? notes;
  final String markedById;
  final String markedByName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime startTime;
  final DateTime endTime;
  final String roomNumber;
  final String teacherName;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseName,
    required this.classId,
    required this.className,
    required this.date,
    required this.status,
    this.reason,
    this.notes,
    required this.markedById,
    required this.markedByName,
    required this.createdAt,
    this.updatedAt,
    required this.startTime,
    required this.endTime,
    required this.roomNumber,
    required this.teacherName,
  });

  // Create an AttendanceModel from a map (e.g., from Firestore)
  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      classId: map['classId'] ?? '',
      className: map['className'] ?? '',
      date: map['date'] != null 
          ? DateTime.parse(map['date']) 
          : DateTime.now(),
      status: map['status'] ?? 'absent',
      reason: map['reason'],
      notes: map['notes'],
      markedById: map['markedById'] ?? '',
      markedByName: map['markedByName'] ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
      startTime: map['startTime'] != null 
          ? DateTime.parse(map['startTime']) 
          : DateTime.now(),
      endTime: map['endTime'] != null 
          ? DateTime.parse(map['endTime']) 
          : DateTime.now().add(const Duration(hours: 1)),
      roomNumber: map['roomNumber'] ?? '',
      teacherName: map['teacherName'] ?? '',
    );
  }

  // Convert AttendanceModel to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'courseName': courseName,
      'classId': classId,
      'className': className,
      'date': date.toIso8601String(),
      'status': status,
      'reason': reason,
      'notes': notes,
      'markedById': markedById,
      'markedByName': markedByName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'roomNumber': roomNumber,
      'teacherName': teacherName,
    };
  }

  // Create a copy of AttendanceModel with some fields changed
  AttendanceModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? courseId,
    String? courseName,
    String? classId,
    String? className,
    DateTime? date,
    String? status,
    String? reason,
    String? notes,
    String? markedById,
    String? markedByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startTime,
    DateTime? endTime,
    String? roomNumber,
    String? teacherName,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      date: date ?? this.date,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      markedById: markedById ?? this.markedById,
      markedByName: markedByName ?? this.markedByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      roomNumber: roomNumber ?? this.roomNumber,
      teacherName: teacherName ?? this.teacherName,
    );
  }
}
