import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../models/fee_model.dart';
import '../services/fee_service.dart';

class ReceiptService {
  final FeeService _feeService = FeeService();
  
  // Generate a receipt PDF for a payment
  Future<Uint8List> generateReceiptPdf({
    required String paymentId,
    required String receiptNumber,
  }) async {
    // Get payment details
    final payment = await _feeService.getPaymentById(paymentId);
    if (payment == null) {
      throw Exception('Payment not found');
    }
    
    // Get fee details
    final fee = await _feeService.getFeeById(payment.feeId);
    if (fee == null) {
      throw Exception('Fee not found');
    }
    
    // Create a PDF document
    final pdf = pw.Document();
    
    // Load fonts
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final fontItalic = await PdfGoogleFonts.nunitoItalic();
    
    // Format currency
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    // Add page to the PDF document
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PAYMENT RECEIPT',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 24,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Receipt #: $receiptNumber',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 12,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Date: ${DateFormat('MMMM dd, yyyy').format(payment.paymentDate)}',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  width: 80,
                  height: 80,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'SCHOOL\nLOGO',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        font: fontBold,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            // School and Student Info
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // School Info
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FROM',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'School Management System',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 12,
                        ),
                      ),
                      pw.Text(
                        '123 Education Street',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        'Knowledge City, ED 12345',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        'Phone: (123) 456-7890',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        'Email: info@schoolms.edu',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Student Info
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BILL TO',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        payment.studentName,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 12,
                        ),
                      ),
                      pw.Text(
                        'Student ID: ${payment.studentId}',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        'Academic Year: ${fee.academicYear}',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        'Term: ${fee.term}',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            // Payment Details
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              padding: const pw.EdgeInsets.all(16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PAYMENT DETAILS',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 14,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  
                  // Fee Info
                  pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          'Fee Description',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          'Amount',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.Divider(color: PdfColors.grey400),
                  
                  // Fee Item
                  pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              fee.feeTitle,
                              style: pw.TextStyle(
                                font: font,
                                fontSize: 12,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              _getFeeTypeText(fee.feeType),
                              style: pw.TextStyle(
                                font: fontItalic,
                                fontSize: 10,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          currencyFormat.format(payment.amount),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  pw.SizedBox(height: 10),
                  pw.Divider(color: PdfColors.grey400),
                  
                  // Total
                  pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          'Total Payment',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          currencyFormat.format(payment.amount),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Payment Method
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Payment Method',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _getPaymentMethodText(payment.method),
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Transaction ID',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          payment.transactionId ?? 'N/A',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            // Verification Status
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: payment.isVerified ? PdfColors.green50 : PdfColors.orange50,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(
                  color: payment.isVerified ? PdfColors.green300 : PdfColors.orange300,
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 24,
                    height: 24,
                    decoration: pw.BoxDecoration(
                      color: payment.isVerified ? PdfColors.green : PdfColors.orange,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        payment.isVerified ? '✓' : '!',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          font: fontBold,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    payment.isVerified ? 'Payment Verified' : 'Verification Pending',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 12,
                      color: payment.isVerified ? PdfColors.green700 : PdfColors.orange700,
                    ),
                  ),
                ],
              ),
            ),
            
            pw.SizedBox(height: 20),
            
            // Notes
            if (payment.notes != null && payment.notes!.isNotEmpty) ...[
              pw.Text(
                'NOTES',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  payment.notes!,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
            ],
            
            // Footer
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'This is an electronically generated receipt.',
                  style: pw.TextStyle(
                    font: fontItalic,
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Thank you!',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 10,
                    color: PdfColors.blue800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    
    // Return the PDF document as bytes
    return pdf.save();
  }
  
  // Save receipt PDF to file and open it
  Future<void> saveReceiptPdf(Uint8List pdfBytes, String fileName) async {
    try {
      // For mobile platforms
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
          dialogTitle: 'Save Receipt',
          fileName: fileName,
        );
        
        if (result != null) {
          final file = File(result);
          await file.writeAsBytes(pdfBytes);
        }
      }
    } catch (e) {
      debugPrint('Error saving receipt PDF file: $e');
      rethrow;
    }
  }
  
  // Print receipt
  Future<void> printReceipt(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }
  
  // Share receipt
  Future<void> shareReceipt(Uint8List pdfBytes, String fileName) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }
  
  // Generate a unique receipt number
  String generateReceiptNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString();
    final random = timestamp.substring(timestamp.length - 4);
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    
    return 'RCP-$year$month$day-$random';
  }
  
  // Helper methods
  String _getFeeTypeText(FeeType feeType) {
    switch (feeType) {
      case FeeType.tuition:
        return 'Tuition Fee';
      case FeeType.registration:
        return 'Registration Fee';
      case FeeType.examination:
        return 'Examination Fee';
      case FeeType.library:
        return 'Library Fee';
      case FeeType.laboratory:
        return 'Laboratory Fee';
      case FeeType.transportation:
        return 'Transportation Fee';
      case FeeType.hostel:
        return 'Hostel Fee';
      case FeeType.uniform:
        return 'Uniform Fee';
      case FeeType.books:
        return 'Books Fee';
      case FeeType.activities:
        return 'Activities Fee';
      case FeeType.other:
        return 'Miscellaneous Fee';
    }
  }
  
  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.check:
        return 'Check';
      case PaymentMethod.onlineBanking:
        return 'Online Banking';
      case PaymentMethod.mobilePayment:
        return 'Mobile Payment';
      case PaymentMethod.other:
        return 'Other';
    }
  }
}
