import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';

import '../models/grade_model.dart';

class PdfExportService {
  // Generate a PDF report for a student's grades
  Future<Uint8List> generateGradeReportPdf({
    required String studentName,
    required String studentId,
    required double overallGPA,
    required Map<String, List<GradeModel>> gradesByTerm,
    required Map<String, double> gpaByTerm,
  }) async {
    // Create a PDF document
    final pdf = pw.Document();
    
    // Load fonts
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final fontItalic = await PdfGoogleFonts.nunitoItalic();
    
    // Add pages to the PDF document
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          studentName: studentName,
          studentId: studentId,
          font: font,
          fontBold: fontBold,
        ),
        footer: (context) => _buildFooter(
          context,
          font: font,
        ),
        build: (context) => [
          // Summary section
          _buildSummarySection(
            overallGPA: overallGPA,
            gpaByTerm: gpaByTerm,
            font: font,
            fontBold: fontBold,
            fontItalic: fontItalic,
          ),
          
          pw.SizedBox(height: 20),
          
          // Grades by term
          ...gradesByTerm.entries.map((entry) => _buildTermSection(
            term: entry.key,
            grades: entry.value,
            gpa: gpaByTerm[entry.key] ?? 0.0,
            font: font,
            fontBold: fontBold,
            fontItalic: fontItalic,
          )),
        ],
      ),
    );
    
    // Return the PDF document as bytes
    return pdf.save();
  }
  
  // Build the header section of the PDF
  pw.Widget _buildHeader({
    required String studentName,
    required String studentId,
    required pw.Font font,
    required pw.Font fontBold,
  }) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 1, color: PdfColors.grey300)),
      ),
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ACADEMIC TRANSCRIPT',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 20,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Generated on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                studentName,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 16,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Student ID: $studentId',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Build the footer section of the PDF
  pw.Widget _buildFooter(
    pw.Context context, {
    required pw.Font font,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'School Management System',
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }
  
  // Build the summary section of the PDF
  pw.Widget _buildSummarySection({
    required double overallGPA,
    required Map<String, double> gpaByTerm,
    required pw.Font font,
    required pw.Font fontBold,
    required pw.Font fontItalic,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ACADEMIC SUMMARY',
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 16,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),
        
        // Overall GPA
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(5),
            border: pw.Border.all(color: PdfColors.blue200),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Overall GPA',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 14,
                ),
              ),
              pw.Text(
                overallGPA.toStringAsFixed(2),
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 14,
                  color: _getGPAColor(overallGPA),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
        
        // GPA by term
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Term',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'GPA',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Performance',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            // Data rows
            ...gpaByTerm.entries.map((entry) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    entry.key,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 12,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    entry.value.toStringAsFixed(2),
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 12,
                      color: _getGPAColor(entry.value),
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    _getGPADescription(entry.value),
                    style: pw.TextStyle(
                      font: fontItalic,
                      fontSize: 12,
                      color: _getGPAColor(entry.value),
                    ),
                  ),
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }
  
  // Build a term section of the PDF
  pw.Widget _buildTermSection({
    required String term,
    required List<GradeModel> grades,
    required double gpa,
    required pw.Font font,
    required pw.Font fontBold,
    required pw.Font fontItalic,
  }) {
    // Group grades by course
    final gradesByCourse = <String, List<GradeModel>>{};
    for (final grade in grades) {
      if (!gradesByCourse.containsKey(grade.courseName)) {
        gradesByCourse[grade.courseName] = [];
      }
      gradesByCourse[grade.courseName]!.add(grade);
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          term.toUpperCase(),
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 16,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'GPA: ${gpa.toStringAsFixed(2)} - ${_getGPADescription(gpa)}',
          style: pw.TextStyle(
            font: fontItalic,
            fontSize: 12,
            color: _getGPAColor(gpa),
          ),
        ),
        pw.SizedBox(height: 10),
        
        // Courses
        ...gradesByCourse.entries.map((entry) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              entry.key,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 14,
              ),
            ),
            pw.SizedBox(height: 5),
            _buildGradesTable(
              grades: entry.value,
              font: font,
              fontBold: fontBold,
            ),
            pw.SizedBox(height: 10),
          ],
        )),
        
        pw.SizedBox(height: 20),
      ],
    );
  }
  
  // Build a grades table for a course
  pw.Widget _buildGradesTable({
    required List<GradeModel> grades,
    required pw.Font font,
    required pw.Font fontBold,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Assessment',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Score',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Grade',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Weight',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                'Date',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        
        // Data rows
        ...grades.map((grade) => pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                grade.assessmentType,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                '${grade.score.toStringAsFixed(1)}/${grade.maxScore.toStringAsFixed(1)}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                grade.letterGrade,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 10,
                  color: _getLetterGradeColor(grade.letterGrade),
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                '${(grade.weightage * 100).toStringAsFixed(0)}%',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                _formatDate(grade.gradedDate),
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        )),
      ],
    );
  }
  
  // Save PDF to file and open it
  Future<void> savePdfFile(Uint8List pdfBytes, String fileName) async {
    try {
      // For web platform
      if (Platform.isAndroid || Platform.isIOS) {
        // Get the documents directory
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        
        // Write the file
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);
        
        // Open the file
        await OpenFile.open(filePath);
      } else {
        // For web or desktop platforms
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Grade Report',
          fileName: fileName,
        );
        
        if (result != null) {
          final file = File(result);
          await file.writeAsBytes(pdfBytes);
        }
      }
    } catch (e) {
      debugPrint('Error saving PDF file: $e');
      rethrow;
    }
  }
  
  // Print PDF
  Future<void> printPdf(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }
  
  // Share PDF
  Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }
  
  // Helper methods
  PdfColor _getGPAColor(double gpa) {
    if (gpa >= 3.5) {
      return PdfColors.green700;
    } else if (gpa >= 2.5) {
      return PdfColors.blue700;
    } else if (gpa >= 1.5) {
      return PdfColors.orange700;
    } else {
      return PdfColors.red700;
    }
  }
  
  String _getGPADescription(double gpa) {
    if (gpa >= 3.5) {
      return 'Excellent';
    } else if (gpa >= 2.5) {
      return 'Good';
    } else if (gpa >= 1.5) {
      return 'Satisfactory';
    } else {
      return 'Needs Improvement';
    }
  }
  
  PdfColor _getLetterGradeColor(String letterGrade) {
    switch (letterGrade) {
      case 'A':
        return PdfColors.green700;
      case 'B':
        return PdfColors.blue700;
      case 'C':
        return PdfColors.orange700;
      case 'D':
        return PdfColors.deepOrange700;
      case 'F':
        return PdfColors.red700;
      default:
        return PdfColors.grey700;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
