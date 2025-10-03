import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/fee_model.dart';
import '../models/payment_model.dart';
import '../services/fee_service.dart';
import '../services/auth_service.dart';

class ExcelExportService {
  static const String _reportsDir = 'reports';
  
  // Export fee reports to CSV (Excel-compatible)
  Future<String> exportFeeReport({
    String? studentId,
    String? academicYear,
    String? term,
    DateTime? fromDate,
    DateTime? toDate,
    PaymentStatus? status,
  }) async {
    try {
      final feeService = FeeService();
      List<FeeModel> fees;
      
      if (studentId != null) {
        fees = await feeService.getFeesForStudent(studentId);
      } else if (academicYear != null && term != null) {
        fees = await feeService.getFeesForTerm(academicYear, term);
      } else {
        fees = await feeService.getAllFees();
      }
      
      // Apply filters
      fees = fees.where((fee) {
        if (fromDate != null && fee.createdAt.isBefore(fromDate)) return false;
        if (toDate != null && fee.createdAt.isAfter(toDate)) return false;
        if (status != null && fee.status != status) return false;
        return true;
      }).toList();
      
      // Generate CSV content
      final csvContent = _generateFeeReportCSV(fees);
      
      // Save to file
      final fileName = 'fee_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = await _saveReportFile(fileName, csvContent);
      
      return filePath;
    } catch (e) {
      debugPrint('Error exporting fee report: $e');
      rethrow;
    }
  }
  
  // Export payment reports to CSV
  Future<String> exportPaymentReport({
    String? studentId,
    DateTime? fromDate,
    DateTime? toDate,
    PaymentMethod? method,
  }) async {
    try {
      final feeService = FeeService();
      List<PaymentModel> payments;
      
      if (studentId != null) {
        payments = await feeService.getPaymentsForStudent(studentId);
      } else {
        // Get all payments
        payments = await _getAllPayments();
      }
      
      // Apply filters
      payments = payments.where((payment) {
        if (fromDate != null && payment.paymentDate.isBefore(fromDate)) return false;
        if (toDate != null && payment.paymentDate.isAfter(toDate)) return false;
        if (method != null && payment.paymentMethod != method) return false;
        return true;
      }).toList();
      
      // Generate CSV content
      final csvContent = _generatePaymentReportCSV(payments);
      
      // Save to file
      final fileName = 'payment_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = await _saveReportFile(fileName, csvContent);
      
      return filePath;
    } catch (e) {
      debugPrint('Error exporting payment report: $e');
      rethrow;
    }
  }
  
  // Export student fee summary
  Future<String> exportStudentFeeSummary({
    List<String>? studentIds,
    String? academicYear,
  }) async {
    try {
      final feeService = FeeService();
      final summaries = <Map<String, dynamic>>[];
      
      // Get student IDs to process
      List<String> studentsToProcess = studentIds ?? await _getAllStudentIds();
      
      for (final studentId in studentsToProcess) {
        final summary = await feeService.calculateFeesSummary(studentId);
        summary['studentId'] = studentId;
        summary['studentName'] = await _getStudentName(studentId);
        summaries.add(summary);
      }
      
      // Generate CSV content
      final csvContent = _generateFeeSummaryCSV(summaries);
      
      // Save to file
      final fileName = 'student_fee_summary_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = await _saveReportFile(fileName, csvContent);
      
      return filePath;
    } catch (e) {
      debugPrint('Error exporting student fee summary: $e');
      rethrow;
    }
  }
  
  // Export overdue fees report
  Future<String> exportOverdueFees() async {
    try {
      final feeService = FeeService();
      final overdueFees = await feeService.getOverdueFees();
      
      // Generate CSV content with additional overdue information
      final csvContent = _generateOverdueFeesCSV(overdueFees);
      
      // Save to file
      final fileName = 'overdue_fees_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = await _saveReportFile(fileName, csvContent);
      
      return filePath;
    } catch (e) {
      debugPrint('Error exporting overdue fees: $e');
      rethrow;
    }
  }
  
  // Export financial summary report
  Future<String> exportFinancialSummary({
    String? academicYear,
    String? term,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final feeService = FeeService();
      List<FeeModel> fees;
      
      if (academicYear != null && term != null) {
        fees = await feeService.getFeesForTerm(academicYear, term);
      } else {
        fees = await feeService.getAllFees();
      }
      
      // Apply date filters
      if (fromDate != null || toDate != null) {
        fees = fees.where((fee) {
          if (fromDate != null && fee.createdAt.isBefore(fromDate)) return false;
          if (toDate != null && fee.createdAt.isAfter(toDate)) return false;
          return true;
        }).toList();
      }
      
      // Calculate financial summary
      final summary = _calculateFinancialSummary(fees);
      
      // Generate CSV content
      final csvContent = _generateFinancialSummaryCSV(summary, fees);
      
      // Save to file
      final fileName = 'financial_summary_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = await _saveReportFile(fileName, csvContent);
      
      return filePath;
    } catch (e) {
      debugPrint('Error exporting financial summary: $e');
      rethrow;
    }
  }
  
  // Custom report export
  Future<String> exportCustomReport({
    required String reportName,
    required List<Map<String, dynamic>> data,
    required List<String> columns,
  }) async {
    try {
      // Generate CSV content
      final csvContent = _generateCustomReportCSV(data, columns);
      
      // Save to file
      final fileName = '${reportName.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = await _saveReportFile(fileName, csvContent);
      
      return filePath;
    } catch (e) {
      debugPrint('Error exporting custom report: $e');
      rethrow;
    }
  }
  
  // CSV Generation Methods
  
  String _generateFeeReportCSV(List<FeeModel> fees) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Student ID,Student Name,Academic Year,Term,Fee Title,Fee Type,Amount,Amount Paid,Discount,Remaining Amount,Due Date,Status,Days Overdue,Created At,Description');
    
    // Data rows
    for (final fee in fees) {
      final row = [
        _escapeCsvField(fee.studentId),
        _escapeCsvField(fee.studentName),
        _escapeCsvField(fee.academicYear),
        _escapeCsvField(fee.term),
        _escapeCsvField(fee.feeTitle),
        _escapeCsvField(fee.feeType.toString().split('.').last),
        fee.amount.toStringAsFixed(2),
        fee.amountPaid.toStringAsFixed(2),
        fee.discount.toStringAsFixed(2),
        fee.remainingAmount.toStringAsFixed(2),
        DateFormat('yyyy-MM-dd').format(fee.dueDate),
        _escapeCsvField(fee.status.toString().split('.').last),
        fee.daysOverdue.toString(),
        DateFormat('yyyy-MM-dd HH:mm:ss').format(fee.createdAt),
        _escapeCsvField(fee.description ?? ''),
      ];
      buffer.writeln(row.join(','));
    }
    
    return buffer.toString();
  }
  
  String _generatePaymentReportCSV(List<PaymentModel> payments) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Payment ID,Fee ID,Student ID,Student Name,Amount,Payment Method,Status,Payment Date,Transaction ID,Receipt Number,Notes,Verified');
    
    // Data rows
    for (final payment in payments) {
      final row = [
        _escapeCsvField(payment.id),
        _escapeCsvField(payment.feeId),
        _escapeCsvField(payment.studentId),
        _escapeCsvField(payment.studentName),
        payment.amount.toStringAsFixed(2),
        _escapeCsvField(payment.paymentMethod.toString().split('.').last),
        _escapeCsvField(payment.status),
        DateFormat('yyyy-MM-dd HH:mm:ss').format(payment.paymentDate),
        _escapeCsvField(payment.transactionId ?? ''),
        _escapeCsvField(payment.receiptNumber ?? ''),
        _escapeCsvField(payment.notes ?? ''),
        payment.isVerified.toString(),
      ];
      buffer.writeln(row.join(','));
    }
    
    return buffer.toString();
  }
  
  String _generateFeeSummaryCSV(List<Map<String, dynamic>> summaries) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Student ID,Student Name,Total Amount,Total Paid,Total Discount,Total Remaining,Total Overdue,Total Pending,Paid Count,Pending Count,Overdue Count,Total Fees Count,Payment Percentage');
    
    // Data rows
    for (final summary in summaries) {
      final row = [
        _escapeCsvField(summary['studentId']?.toString() ?? ''),
        _escapeCsvField(summary['studentName']?.toString() ?? ''),
        (summary['totalAmount'] as double?)?.toStringAsFixed(2) ?? '0.00',
        (summary['totalPaid'] as double?)?.toStringAsFixed(2) ?? '0.00',
        (summary['totalDiscount'] as double?)?.toStringAsFixed(2) ?? '0.00',
        (summary['totalRemaining'] as double?)?.toStringAsFixed(2) ?? '0.00',
        (summary['totalOverdue'] as double?)?.toStringAsFixed(2) ?? '0.00',
        (summary['totalPending'] as double?)?.toStringAsFixed(2) ?? '0.00',
        (summary['paidCount'] as int?)?.toString() ?? '0',
        (summary['pendingCount'] as int?)?.toString() ?? '0',
        (summary['overdueCount'] as int?)?.toString() ?? '0',
        (summary['totalFeesCount'] as int?)?.toString() ?? '0',
        (summary['paymentPercentage'] as double?)?.toStringAsFixed(2) ?? '0.00',
      ];
      buffer.writeln(row.join(','));
    }
    
    return buffer.toString();
  }
  
  String _generateOverdueFeesCSV(List<FeeModel> overdueFees) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Student ID,Student Name,Fee Title,Amount,Amount Paid,Remaining Amount,Due Date,Days Overdue,Late Fee Amount,Contact Info');
    
    // Data rows
    for (final fee in overdueFees) {
      final lateFeeAmount = (fee.remainingAmount * 0.05).clamp(500.0, double.infinity);
      final row = [
        _escapeCsvField(fee.studentId),
        _escapeCsvField(fee.studentName),
        _escapeCsvField(fee.feeTitle),
        fee.amount.toStringAsFixed(2),
        fee.amountPaid.toStringAsFixed(2),
        fee.remainingAmount.toStringAsFixed(2),
        DateFormat('yyyy-MM-dd').format(fee.dueDate),
        fee.daysOverdue.toString(),
        lateFeeAmount.toStringAsFixed(2),
        '', // Contact info would be fetched from student records
      ];
      buffer.writeln(row.join(','));
    }
    
    return buffer.toString();
  }
  
  String _generateFinancialSummaryCSV(Map<String, dynamic> summary, List<FeeModel> fees) {
    final buffer = StringBuffer();
    
    // Summary section
    buffer.writeln('FINANCIAL SUMMARY');
    buffer.writeln('Generated On,${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buffer.writeln('');
    
    buffer.writeln('OVERVIEW');
    buffer.writeln('Total Fees,${summary['totalFees']}');
    buffer.writeln('Total Amount,${summary['totalAmount'].toStringAsFixed(2)}');
    buffer.writeln('Total Collected,${summary['totalCollected'].toStringAsFixed(2)}');
    buffer.writeln('Total Outstanding,${summary['totalOutstanding'].toStringAsFixed(2)}');
    buffer.writeln('Total Overdue,${summary['totalOverdue'].toStringAsFixed(2)}');
    buffer.writeln('Collection Rate,${summary['collectionRate'].toStringAsFixed(2)}%');
    buffer.writeln('');
    
    // Fee type breakdown
    buffer.writeln('FEE TYPE BREAKDOWN');
    buffer.writeln('Fee Type,Count,Total Amount,Collected Amount,Outstanding Amount');
    
    final feeTypeBreakdown = summary['feeTypeBreakdown'] as Map<String, Map<String, dynamic>>;
    for (final entry in feeTypeBreakdown.entries) {
      final data = entry.value;
      final row = [
        _escapeCsvField(entry.key),
        data['count'].toString(),
        data['totalAmount'].toStringAsFixed(2),
        data['collectedAmount'].toStringAsFixed(2),
        data['outstandingAmount'].toStringAsFixed(2),
      ];
      buffer.writeln(row.join(','));
    }
    
    buffer.writeln('');
    
    // Monthly breakdown
    buffer.writeln('MONTHLY BREAKDOWN');
    buffer.writeln('Month,Fees Created,Amount Created,Amount Collected');
    
    final monthlyBreakdown = summary['monthlyBreakdown'] as Map<String, Map<String, dynamic>>;
    for (final entry in monthlyBreakdown.entries) {
      final data = entry.value;
      final row = [
        _escapeCsvField(entry.key),
        data['feesCreated'].toString(),
        data['amountCreated'].toStringAsFixed(2),
        data['amountCollected'].toStringAsFixed(2),
      ];
      buffer.writeln(row.join(','));
    }
    
    return buffer.toString();
  }
  
  String _generateCustomReportCSV(List<Map<String, dynamic>> data, List<String> columns) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln(columns.map(_escapeCsvField).join(','));
    
    // Data rows
    for (final row in data) {
      final values = columns.map((column) => _escapeCsvField(row[column]?.toString() ?? '')).toList();
      buffer.writeln(values.join(','));
    }
    
    return buffer.toString();
  }
  
  // Helper Methods
  
  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
  
  Future<String> _saveReportFile(String fileName, String content) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${appDir.path}/$_reportsDir');
      
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }
      
      final file = File('${reportsDir.path}/$fileName');
      await file.writeAsString(content);
      
      return file.path;
    } catch (e) {
      debugPrint('Error saving report file: $e');
      rethrow;
    }
  }
  
  Future<List<PaymentModel>> _getAllPayments() async {
    // Implementation would get all payments from storage
    // For now, return empty list
    return [];
  }
  
  Future<List<String>> _getAllStudentIds() async {
    // Implementation would get all student IDs from storage
    // For now, return demo student IDs
    return ['student_1', 'student_2', 'student_3'];
  }
  
  Future<String> _getStudentName(String studentId) async {
    // Implementation would get student name from storage
    // For now, return demo names
    switch (studentId) {
      case 'student_1':
        return 'Ahmad Ali Khan';
      case 'student_2':
        return 'Fatima Sheikh';
      case 'student_3':
        return 'Hassan Ahmed';
      default:
        return 'Unknown Student';
    }
  }
  
  Map<String, dynamic> _calculateFinancialSummary(List<FeeModel> fees) {
    double totalAmount = 0;
    double totalCollected = 0;
    double totalOutstanding = 0;
    double totalOverdue = 0;
    
    final feeTypeBreakdown = <String, Map<String, dynamic>>{};
    final monthlyBreakdown = <String, Map<String, dynamic>>{};
    
    for (final fee in fees) {
      totalAmount += fee.amount;
      totalCollected += fee.amountPaid;
      totalOutstanding += fee.remainingAmount;
      
      if (fee.isOverdue) {
        totalOverdue += fee.remainingAmount;
      }
      
      // Fee type breakdown
      final feeType = fee.feeType.toString().split('.').last;
      if (!feeTypeBreakdown.containsKey(feeType)) {
        feeTypeBreakdown[feeType] = {
          'count': 0,
          'totalAmount': 0.0,
          'collectedAmount': 0.0,
          'outstandingAmount': 0.0,
        };
      }
      
      feeTypeBreakdown[feeType]!['count']++;
      feeTypeBreakdown[feeType]!['totalAmount'] += fee.amount;
      feeTypeBreakdown[feeType]!['collectedAmount'] += fee.amountPaid;
      feeTypeBreakdown[feeType]!['outstandingAmount'] += fee.remainingAmount;
      
      // Monthly breakdown
      final monthKey = DateFormat('yyyy-MM').format(fee.createdAt);
      if (!monthlyBreakdown.containsKey(monthKey)) {
        monthlyBreakdown[monthKey] = {
          'feesCreated': 0,
          'amountCreated': 0.0,
          'amountCollected': 0.0,
        };
      }
      
      monthlyBreakdown[monthKey]!['feesCreated']++;
      monthlyBreakdown[monthKey]!['amountCreated'] += fee.amount;
      monthlyBreakdown[monthKey]!['amountCollected'] += fee.amountPaid;
    }
    
    final collectionRate = totalAmount > 0 ? (totalCollected / totalAmount) * 100 : 0.0;
    
    return {
      'totalFees': fees.length,
      'totalAmount': totalAmount,
      'totalCollected': totalCollected,
      'totalOutstanding': totalOutstanding,
      'totalOverdue': totalOverdue,
      'collectionRate': collectionRate,
      'feeTypeBreakdown': feeTypeBreakdown,
      'monthlyBreakdown': monthlyBreakdown,
    };
  }
  
  // Get list of available reports
  Future<List<String>> getAvailableReports() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${appDir.path}/$_reportsDir');
      
      if (!await reportsDir.exists()) {
        return [];
      }
      
      final files = await reportsDir.list().toList();
      return files
          .where((file) => file is File && file.path.endsWith('.csv'))
          .map((file) => file.path)
          .toList();
    } catch (e) {
      debugPrint('Error getting available reports: $e');
      return [];
    }
  }
  
  // Delete old reports
  Future<void> cleanupOldReports({int daysToKeep = 30}) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${appDir.path}/$_reportsDir');
      
      if (!await reportsDir.exists()) {
        return;
      }
      
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final files = await reportsDir.list().toList();
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old reports: $e');
    }
  }
}
