class AttendanceModel {
  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseName;
  final String teacherId;
  final String teacherName;
  final String subject;
  final DateTime date;
  final String status; // present, absent, late, excused
  final String? reason;
  final String? notes;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final DateTime markedAt;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseName,
    required this.teacherId,
    required this.teacherName,
    required this.subject,
    required this.date,
    required this.status,
    this.reason,
    this.notes,
    this.checkInTime,
    this.checkOutTime,
    required this.markedAt,
  });

  // Create an AttendanceModel from a map (e.g., from Firestore)
  factory AttendanceModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      courseId: map['courseId'] ?? '',
      courseName: map['courseName'] ?? '',
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      subject: map['subject'] ?? '',
      date: map['date'] != null 
          ? DateTime.parse(map['date']) 
          : DateTime.now(),
      status: map['status'] ?? 'absent',
      reason: map['reason'],
      notes: map['notes'],
      checkInTime: map['checkInTime'] != null 
          ? DateTime.parse(map['checkInTime']) 
          : null,
      checkOutTime: map['checkOutTime'] != null 
          ? DateTime.parse(map['checkOutTime']) 
          : null,
      markedAt: map['markedAt'] != null 
          ? DateTime.parse(map['markedAt']) 
          : DateTime.now(),
    );
  }

  // Convert AttendanceModel to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'courseName': courseName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'subject': subject,
      'date': date.toIso8601String(),
      'status': status,
      'reason': reason,
      'notes': notes,
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'markedAt': markedAt.toIso8601String(),
    };
  }

  // Create a copy of AttendanceModel with some fields changed
  AttendanceModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? courseId,
    String? courseName,
    String? teacherId,
    String? teacherName,
    String? subject,
    DateTime? date,
    String? status,
    String? reason,
    String? notes,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    DateTime? markedAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      subject: subject ?? this.subject,
      date: date ?? this.date,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      markedAt: markedAt ?? this.markedAt,
    );
  }
}
