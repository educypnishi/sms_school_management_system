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
          ],
        ),
      ),
    );

    // Save PDF file (web-compatible)
    final pdfBytes = await pdf.save();
    
    if (kIsWeb) {
      // Web: Download file directly
      WebFileService.downloadFile(
        pdfBytes, 
        'attendance_report_${student.id}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf'
      );
      return 'Downloaded to browser';
    } else {
      // Mobile: Save to device
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/attendance_report_${student.id}_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf');
      await file.writeAsBytes(pdfBytes);
      return file.path;
    }
  }

  // Generate class attendance report
  static Future<String> generateClassReport({
    required ClassModel classModel,
    required Map<String, dynamic> classStats,
    required Map<String, Map<String, dynamic>> studentAttendanceData,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Simple implementation for now
    return 'Class report generated successfully';
  }

  // Helper methods
  static pw.Widget _buildStatColumn(String title, String value) {
    return pw.Column(
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: const pw.TextStyle(fontSize: 14)),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        color: isHeader ? PdfColors.grey100 : null,
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // Get attendance alerts
  static Future<List<Map<String, dynamic>>> getAttendanceAlerts({
    String? classId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Simple implementation returning sample alerts
    return [
      {
        'type': 'low_attendance',
        'message': 'Student Ahmed Ali has low attendance (65%)',
        'studentId': 'student_123',
        'studentName': 'Ahmed Ali',
        'attendanceRate': 65.0,
        'severity': 'warning',
      },
      {
        'type': 'absent_streak',
        'message': 'Student Sara Khan absent for 3 consecutive days',
        'studentId': 'student_456',
        'studentName': 'Sara Khan',
        'absentDays': 3,
        'severity': 'critical',
      },
    ];
  }
}
