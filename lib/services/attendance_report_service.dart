import 'dart:io';
import 'package:flutter/foundation.dart';
// import 'package:open_file/open_file.dart';  // Disabled for web
// import 'package:file_picker/file_picker.dart';  // Disabled for web
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'web_file_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../services/firebase_attendance_service.dart';
import '../services/firebase_class_service.dart';
import '../models/attendance_model.dart';
import '../models/class_model.dart';

class AttendanceReportService {
  // Generate student attendance report
  static Future<String> generateStudentReport({
    required String studentId,
    required String studentName,
    DateTime? startDate,
    DateTime? endDate,
    String format = 'pdf', // 'pdf', 'csv'
  }) async {
    try {
      // Get attendance data
      final attendanceRecords = await FirebaseAttendanceService.getStudentAttendance(
        studentId: studentId,
        startDate: startDate,
        endDate: endDate,
      );

      final stats = await FirebaseAttendanceService.getStudentAttendanceStats(
        studentId: studentId,
        startDate: startDate,
        endDate: endDate,
      );

      if (format == 'pdf') {
        return await _generateStudentPDFReport(
          studentName: studentName,
          attendanceRecords: attendanceRecords,
          stats: stats,
          startDate: startDate,
          endDate: endDate,
        );
      } else {
        return await _generateStudentCSVReport(
          studentName: studentName,
          attendanceRecords: attendanceRecords,
          stats: stats,
        );
      }
    } catch (e) {
      debugPrint('❌ Error generating student report: $e');
      rethrow;
    }
  }

  // Generate class attendance report
  static Future<String> generateClassReport({
    required String classId,
    required String className,
    DateTime? startDate,
    DateTime? endDate,
    String format = 'pdf',
  }) async {
    try {
      // Get class data
      final classModel = await FirebaseClassService.getClassById(classId);
      final students = await FirebaseClassService.getClassStudents(classId);
      
      // Get attendance statistics for the class
      final classStats = await FirebaseAttendanceService.getClassAttendanceStats(
        classId: classId,
        startDate: startDate,
        endDate: endDate,
      );

      // Get individual student attendance
      final studentAttendanceData = <String, Map<String, dynamic>>{};
      for (final student in students) {
        final studentId = student['studentId'];
        final studentStats = await FirebaseAttendanceService.getStudentAttendanceStats(
          studentId: studentId,
          startDate: startDate,
          endDate: endDate,
        );
        studentAttendanceData[studentId] = {
          'name': student['studentName'],
          'stats': studentStats,
        };
      }

      if (format == 'pdf') {
        return await _generateClassPDFReport(
          classModel: classModel,
          classStats: classStats,
          studentAttendanceData: studentAttendanceData,
          startDate: startDate,
          endDate: endDate,
        );
      } else {
        return await _generateClassCSVReport(
          className: className,
          classStats: classStats,
          studentAttendanceData: studentAttendanceData,
        );
      }
    } catch (e) {
      debugPrint('❌ Error generating class report: $e');
      rethrow;
    }
  }

  // Generate monthly attendance summary
  static Future<String> generateMonthlySummary({
    required String classId,
    required String className,
    required int year,
    required int month,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0); // Last day of month

      return await generateClassReport(
        classId: classId,
        className: className,
        startDate: startDate,
        endDate: endDate,
        format: 'pdf',
      );
    } catch (e) {
      debugPrint('❌ Error generating monthly summary: $e');
      rethrow;
    }
  }

  // Private methods for PDF generation
  static Future<String> _generateStudentPDFReport({
    required String studentName,
    required List<AttendanceModel> attendanceRecords,
    required Map<String, dynamic> stats,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ATTENDANCE REPORT',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Student: $studentName',
                        style: pw.TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Generated: ${DateFormat('dd/MM/yyyy').format(now)}'),
                      if (startDate != null && endDate != null)
                        pw.Text(
                          'Period: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Summary Statistics
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ATTENDANCE SUMMARY',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('Total Days', '${stats['totalDays'] ?? 0}'),
                      _buildStatColumn('Present', '${stats['presentDays'] ?? 0}'),
                      _buildStatColumn('Absent', '${stats['absentDays'] ?? 0}'),
                      _buildStatColumn('Late', '${stats['lateDays'] ?? 0}'),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Center(
                    child: pw.Text(
                      'Attendance Percentage: ${(stats['attendancePercentage'] ?? 0.0).toStringAsFixed(1)}%',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Attendance Records Table
            pw.Text(
              'DETAILED RECORDS',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Date', isHeader: true),
                    _buildTableCell('Class/Subject', isHeader: true),
                    _buildTableCell('Status', isHeader: true),
                    _buildTableCell('Time', isHeader: true),
                    _buildTableCell('Notes', isHeader: true),
                  ],
                ),
                // Data rows
                ...attendanceRecords.map((record) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(DateFormat('dd/MM/yyyy').format(record.date)),
                      _buildTableCell('${record.courseName}\n${record.subject}'),
                      _buildTableCell(record.status.toUpperCase()),
                      _buildTableCell(
                        record.checkInTime != null 
                          ? DateFormat('HH:mm').format(record.checkInTime!)
                          : '-'
                      ),
                      _buildTableCell(record.notes ?? ''),
                    ],
                  );
                }).toList(),
              ],
            ),
    required Map<String, dynamic> classStats,
    required Map<String, Map<String, dynamic>> studentAttendanceData,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final className = classModel?.name ?? 'Unknown Class';
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CLASS ATTENDANCE REPORT',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Class: $className',
                        style: pw.TextStyle(fontSize: 16),
                      ),
                      if (classModel != null)
                        pw.Text(
                          'Teacher: ${classModel.teacherName}',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Generated: ${DateFormat('dd/MM/yyyy').format(now)}'),
                      if (startDate != null && endDate != null)
                        pw.Text(
                          'Period: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Class Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CLASS SUMMARY',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Total Students: ${studentAttendanceData.length}'),
                  pw.Text('Average Attendance: ${(classStats['averageAttendance'] ?? 0.0).toStringAsFixed(1)}%'),
                  pw.Text('Total Records: ${classStats['totalRecords'] ?? 0}'),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Student Attendance Summary Table
            pw.Text(
              'STUDENT ATTENDANCE SUMMARY',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
                5: const pw.FlexColumnWidth(1),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Student Name', isHeader: true),
                    _buildTableCell('Total', isHeader: true),
                    _buildTableCell('Present', isHeader: true),
                    _buildTableCell('Absent', isHeader: true),
                    _buildTableCell('Late', isHeader: true),
                    _buildTableCell('Percentage', isHeader: true),
                  ],
                ),
                // Data rows
                ...studentAttendanceData.entries.map((entry) {
                  final studentData = entry.value;
                  final stats = studentData['stats'] as Map<String, dynamic>;
                  return pw.TableRow(
                    children: [
                      _buildTableCell(studentData['name']),
                      _buildTableCell('${stats['totalDays'] ?? 0}'),
                      _buildTableCell('${stats['presentDays'] ?? 0}'),
                      _buildTableCell('${stats['absentDays'] ?? 0}'),
                      _buildTableCell('${stats['lateDays'] ?? 0}'),
                      _buildTableCell('${(stats['attendancePercentage'] ?? 0.0).toStringAsFixed(1)}%'),
                    ],
                  );
                }).toList(),
              ],
            ),
          ];
        },
      ),
    );

    // Save PDF
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/class_attendance_report_${className.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(now)}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    debugPrint('✅ Class PDF report generated: ${file.path}');
    return file.path;
  }

  // CSV Generation methods
  static Future<String> _generateStudentCSVReport({
    required String studentName,
    required List<AttendanceModel> attendanceRecords,
    required Map<String, dynamic> stats,
  }) async {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Student Attendance Report');
    buffer.writeln('Student Name,$studentName');
    buffer.writeln('Generated,${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
    buffer.writeln('');
    
    // Summary
    buffer.writeln('SUMMARY');
    buffer.writeln('Total Days,${stats['totalDays'] ?? 0}');
    buffer.writeln('Present Days,${stats['presentDays'] ?? 0}');
    buffer.writeln('Absent Days,${stats['absentDays'] ?? 0}');
    buffer.writeln('Late Days,${stats['lateDays'] ?? 0}');
    buffer.writeln('Attendance Percentage,${(stats['attendancePercentage'] ?? 0.0).toStringAsFixed(1)}%');
    buffer.writeln('');
    
    // Detailed records
    buffer.writeln('DETAILED RECORDS');
    buffer.writeln('Date,Class,Subject,Status,Check In Time,Notes');
    
    for (final record in attendanceRecords) {
      buffer.writeln([
        DateFormat('dd/MM/yyyy').format(record.date),
        record.courseName,
        record.subject,
        record.status.toUpperCase(),
        record.checkInTime != null ? DateFormat('HH:mm').format(record.checkInTime!) : '',
        record.notes ?? '',
      ].join(','));
    }

    // Save CSV
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/attendance_report_${studentName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
    await file.writeAsString(buffer.toString());
    
    debugPrint('✅ Student CSV report generated: ${file.path}');
    return file.path;
  }

  static Future<String> _generateClassCSVReport({
    required String className,
    required Map<String, dynamic> classStats,
    required Map<String, Map<String, dynamic>> studentAttendanceData,
  }) async {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Class Attendance Report');
    buffer.writeln('Class Name,$className');
    buffer.writeln('Generated,${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
    buffer.writeln('');
    
    // Class Summary
    buffer.writeln('CLASS SUMMARY');
    buffer.writeln('Total Students,${studentAttendanceData.length}');
    buffer.writeln('Average Attendance,${(classStats['averageAttendance'] ?? 0.0).toStringAsFixed(1)}%');
    buffer.writeln('Total Records,${classStats['totalRecords'] ?? 0}');
    buffer.writeln('');
    
    // Student Summary
    buffer.writeln('STUDENT ATTENDANCE SUMMARY');
    buffer.writeln('Student Name,Total Days,Present,Absent,Late,Percentage');
    
    studentAttendanceData.forEach((studentId, studentData) {
      final stats = studentData['stats'] as Map<String, dynamic>;
      buffer.writeln([
        studentData['name'],
        stats['totalDays'] ?? 0,
        stats['presentDays'] ?? 0,
        stats['absentDays'] ?? 0,
        stats['lateDays'] ?? 0,
        '${(stats['attendancePercentage'] ?? 0.0).toStringAsFixed(1)}%',
      ].join(','));
    });

    // Save CSV
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/class_attendance_report_${className.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv');
    await file.writeAsString(buffer.toString());
    
    debugPrint('✅ Class CSV report generated: ${file.path}');
    return file.path;
  }

  // Helper methods for PDF formatting
  static pw.Widget _buildStatColumn(String title, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(title),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 10,
        ),
      ),
    );
  }

  // Get attendance alerts for low attendance students
  static Future<List<Map<String, dynamic>>> getAttendanceAlerts({
    required String classId,
    double threshold = 75.0,
  }) async {
    try {
      final students = await FirebaseClassService.getClassStudents(classId);
      final alerts = <Map<String, dynamic>>[];

      for (final student in students) {
        final studentId = student['studentId'];
        final stats = await FirebaseAttendanceService.getStudentAttendanceStats(
          studentId: studentId,
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now(),
        );

        final attendancePercentage = stats['attendancePercentage'] ?? 0.0;
        if (attendancePercentage < threshold) {
          alerts.add({
            'studentId': studentId,
            'studentName': student['studentName'],
            'attendancePercentage': attendancePercentage,
            'totalDays': stats['totalDays'] ?? 0,
            'absentDays': stats['absentDays'] ?? 0,
            'alertLevel': attendancePercentage < 50 ? 'critical' : 'warning',
          });
        }
      }

      return alerts;
    } catch (e) {
      debugPrint('❌ Error getting attendance alerts: $e');
      return [];
    }
  }
}
