class AttendanceRecord {
  final String id;
  final String studentId;
  final String classId;
  final String subjectId;
  final DateTime date;
  final AttendanceStatus status;
  final String? teacherId;
  final String? remarks;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.subjectId,
    required this.date,
    required this.status,
    this.teacherId,
    this.remarks,
    required this.createdAt,
    this.updatedAt,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceRecord(
      id: id,
      studentId: map['studentId'] ?? '',
      classId: map['classId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      date: DateTime.parse(map['date']),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString() == 'AttendanceStatus.${map['status']}',
        orElse: () => AttendanceStatus.absent,
      ),
      teacherId: map['teacherId'],
      remarks: map['remarks'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'classId': classId,
      'subjectId': subjectId,
      'date': date.toIso8601String(),
      'status': status.toString().split('.').last,
      'teacherId': teacherId,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

enum AttendanceStatus {
  present,
  absent,
  late,
  excused,
  sick,
  holiday
}

class AttendanceSummary {
  final String studentId;
  final String period; // monthly, weekly, daily
  final int totalClasses;
  final int presentClasses;
  final int absentClasses;
  final int lateClasses;
  final int excusedClasses;
  final double attendancePercentage;
  final DateTime startDate;
  final DateTime endDate;

  AttendanceSummary({
    required this.studentId,
    required this.period,
    required this.totalClasses,
    required this.presentClasses,
    required this.absentClasses,
    required this.lateClasses,
    required this.excusedClasses,
    required this.attendancePercentage,
    required this.startDate,
    required this.endDate,
  });

  factory AttendanceSummary.fromRecords(
    String studentId,
    List<AttendanceRecord> records,
    String period,
    DateTime startDate,
    DateTime endDate,
  ) {
    final totalClasses = records.length;
    final presentClasses = records.where((r) => r.status == AttendanceStatus.present).length;
    final absentClasses = records.where((r) => r.status == AttendanceStatus.absent).length;
    final lateClasses = records.where((r) => r.status == AttendanceStatus.late).length;
    final excusedClasses = records.where((r) => r.status == AttendanceStatus.excused).length;
    
    final attendancePercentage = totalClasses > 0 
        ? (presentClasses / totalClasses) * 100 
        : 0.0;

    return AttendanceSummary(
      studentId: studentId,
      period: period,
      totalClasses: totalClasses,
      presentClasses: presentClasses,
      absentClasses: absentClasses,
      lateClasses: lateClasses,
      excusedClasses: excusedClasses,
      attendancePercentage: attendancePercentage,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
