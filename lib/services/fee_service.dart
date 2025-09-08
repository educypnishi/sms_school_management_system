import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fee_model.dart';
import '../services/auth_service.dart';

class FeeService {
  // Create a new fee
  Future<FeeModel> createFee({
    required String studentId,
    required String studentName,
    required String academicYear,
    required String term,
    required String feeTitle,
    required FeeType feeType,
    required double amount,
    double amountPaid = 0.0,
    double discount = 0.0,
    required DateTime dueDate,
    PaymentStatus status = PaymentStatus.pending,
    String? description,
    bool isRecurring = false,
    String? recurringFrequency,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generate a new ID
      final feeId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create fee model
      final fee = FeeModel(
        id: feeId,
        studentId: studentId,
        studentName: studentName,
        academicYear: academicYear,
        term: term,
        feeTitle: feeTitle,
        feeType: feeType,
        amount: amount,
        amountPaid: amountPaid,
        discount: discount,
        dueDate: dueDate,
        status: status,
        description: description,
        createdAt: DateTime.now(),
        isRecurring: isRecurring,
        recurringFrequency: recurringFrequency,
      );
      
      // Save fee to SharedPreferences
      await prefs.setString('fee_$feeId', jsonEncode(fee.toMap()));
      
      // Add fee ID to student's fees list
      final studentFees = prefs.getStringList('student_fees_$studentId') ?? [];
      studentFees.add(feeId);
      await prefs.setStringList('student_fees_$studentId', studentFees);
      
      // Add fee ID to term's fees list
      final termFees = prefs.getStringList('term_fees_${academicYear}_$term') ?? [];
      termFees.add(feeId);
      await prefs.setStringList('term_fees_${academicYear}_$term', termFees);
      
      return fee;
    } catch (e) {
      debugPrint('Error creating fee: $e');
      rethrow;
    }
  }
  
  // Get fee by ID
  Future<FeeModel?> getFeeById(String feeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get fee from SharedPreferences
      final feeJson = prefs.getString('fee_$feeId');
      if (feeJson == null) {
        return null;
      }
      
      // Parse fee
      final feeMap = jsonDecode(feeJson) as Map<String, dynamic>;
      return FeeModel.fromMap(feeMap, feeId);
    } catch (e) {
      debugPrint('Error getting fee: $e');
      return null;
    }
  }
  
  // Update fee
  Future<FeeModel> updateFee({
    required String feeId,
    String? feeTitle,
    FeeType? feeType,
    double? amount,
    double? discount,
    DateTime? dueDate,
    PaymentStatus? status,
    String? description,
    bool? isRecurring,
    String? recurringFrequency,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing fee
      final existingFeeJson = prefs.getString('fee_$feeId');
      if (existingFeeJson == null) {
        throw Exception('Fee not found');
      }
      
      // Parse existing fee
      final existingFeeMap = jsonDecode(existingFeeJson) as Map<String, dynamic>;
      final existingFee = FeeModel.fromMap(existingFeeMap, feeId);
      
      // Update fee
      final updatedFee = existingFee.copyWith(
        feeTitle: feeTitle,
        feeType: feeType,
        amount: amount,
        discount: discount,
        dueDate: dueDate,
        status: status,
        description: description,
        isRecurring: isRecurring,
        recurringFrequency: recurringFrequency,
        updatedAt: DateTime.now(),
      );
      
      // Save updated fee to SharedPreferences
      await prefs.setString('fee_$feeId', jsonEncode(updatedFee.toMap()));
      
      return updatedFee;
    } catch (e) {
      debugPrint('Error updating fee: $e');
      rethrow;
    }
  }
  
  // Delete fee
  Future<void> deleteFee(String feeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get fee to delete
      final feeJson = prefs.getString('fee_$feeId');
      if (feeJson == null) {
        return;
      }
      
      // Parse fee
      final feeMap = jsonDecode(feeJson) as Map<String, dynamic>;
      final fee = FeeModel.fromMap(feeMap, feeId);
      
      // Remove fee from SharedPreferences
      await prefs.remove('fee_$feeId');
      
      // Remove fee ID from student's fees list
      final studentFees = prefs.getStringList('student_fees_${fee.studentId}') ?? [];
      studentFees.remove(feeId);
      await prefs.setStringList('student_fees_${fee.studentId}', studentFees);
      
      // Remove fee ID from term's fees list
      final termFees = prefs.getStringList('term_fees_${fee.academicYear}_${fee.term}') ?? [];
      termFees.remove(feeId);
      await prefs.setStringList('term_fees_${fee.academicYear}_${fee.term}', termFees);
      
      // Remove associated payments
      final allKeys = prefs.getKeys();
      final paymentKeys = allKeys.where((key) => key.startsWith('payment_')).toList();
      
      for (final key in paymentKeys) {
        final paymentJson = prefs.getString(key);
        if (paymentJson != null) {
          final paymentMap = jsonDecode(paymentJson) as Map<String, dynamic>;
          if (paymentMap['feeId'] == feeId) {
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      debugPrint('Error deleting fee: $e');
      rethrow;
    }
  }
  
  // Get fees for a student
  Future<List<FeeModel>> getFeesForStudent(String studentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get student's fee IDs
      final feeIds = prefs.getStringList('student_fees_$studentId') ?? [];
      
      // Get fees
      final fees = <FeeModel>[];
      for (final id in feeIds) {
        final fee = await getFeeById(id);
        if (fee != null) {
          fees.add(fee);
        }
      }
      
      // Sort by due date (soonest first)
      fees.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      
      return fees;
    } catch (e) {
      debugPrint('Error getting fees for student: $e');
      return [];
    }
  }
  
  // Get fees for a term
  Future<List<FeeModel>> getFeesForTerm(String academicYear, String term) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get term's fee IDs
      final feeIds = prefs.getStringList('term_fees_${academicYear}_$term') ?? [];
      
      // Get fees
      final fees = <FeeModel>[];
      for (final id in feeIds) {
        final fee = await getFeeById(id);
        if (fee != null) {
          fees.add(fee);
        }
      }
      
      return fees;
    } catch (e) {
      debugPrint('Error getting fees for term: $e');
      return [];
    }
  }
  
  // Get all fees
  Future<List<FeeModel>> getAllFees() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all fee keys
      final allKeys = prefs.getKeys();
      final feeKeys = allKeys.where((key) => key.startsWith('fee_')).toList();
      
      // Get fees
      final fees = <FeeModel>[];
      for (final key in feeKeys) {
        final feeId = key.substring('fee_'.length);
        final fee = await getFeeById(feeId);
        if (fee != null) {
          fees.add(fee);
        }
      }
      
      return fees;
    } catch (e) {
      debugPrint('Error getting all fees: $e');
      return [];
    }
  }
  
  // Get overdue fees
  Future<List<FeeModel>> getOverdueFees() async {
    try {
      final fees = await getAllFees();
      return fees.where((fee) => fee.isOverdue).toList();
    } catch (e) {
      debugPrint('Error getting overdue fees: $e');
      return [];
    }
  }
  
  // Get upcoming fees
  Future<List<FeeModel>> getUpcomingFees({int daysThreshold = 7}) async {
    try {
      final fees = await getAllFees();
      final now = DateTime.now();
      final threshold = now.add(Duration(days: daysThreshold));
      
      return fees.where((fee) => 
        fee.status == PaymentStatus.pending && 
        fee.dueDate.isAfter(now) && 
        fee.dueDate.isBefore(threshold)
      ).toList();
    } catch (e) {
      debugPrint('Error getting upcoming fees: $e');
      return [];
    }
  }
  
  // Record a payment
  Future<PaymentModel> recordPayment({
    required String feeId,
    required double amount,
    required PaymentMethod method,
    String? transactionId,
    String? receiptNumber,
    required DateTime paymentDate,
    String? notes,
    String? paymentProofUrl,
    bool isVerified = false,
    String? verifiedById,
    DateTime? verifiedAt,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get fee
      final fee = await getFeeById(feeId);
      if (fee == null) {
        throw Exception('Fee not found');
      }
      
      // Generate a new ID
      final paymentId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create payment model
      final payment = PaymentModel(
        id: paymentId,
        feeId: feeId,
        studentId: fee.studentId,
        studentName: fee.studentName,
        amount: amount,
        method: method,
        transactionId: transactionId,
        receiptNumber: receiptNumber,
        paymentDate: paymentDate,
        notes: notes,
        paymentProofUrl: paymentProofUrl,
        isVerified: isVerified,
        verifiedById: verifiedById,
        verifiedAt: verifiedAt,
        createdAt: DateTime.now(),
      );
      
      // Save payment to SharedPreferences
      await prefs.setString('payment_$paymentId', jsonEncode(payment.toMap()));
      
      // Add payment ID to fee's payments list
      final feePayments = prefs.getStringList('fee_payments_$feeId') ?? [];
      feePayments.add(paymentId);
      await prefs.setStringList('fee_payments_$feeId', feePayments);
      
      // Update fee's amount paid and status
      final newAmountPaid = fee.amountPaid + amount;
      PaymentStatus newStatus;
      
      if (newAmountPaid >= fee.amount - fee.discount) {
        newStatus = PaymentStatus.paid;
      } else if (newAmountPaid > 0) {
        newStatus = PaymentStatus.partiallyPaid;
      } else {
        newStatus = fee.status;
      }
      
      await updateFee(
        feeId: feeId,
        status: newStatus,
      );
      
      // Update fee's amount paid separately to avoid race conditions
      final updatedFeeJson = prefs.getString('fee_$feeId');
      if (updatedFeeJson != null) {
        final updatedFeeMap = jsonDecode(updatedFeeJson) as Map<String, dynamic>;
        final updatedFee = FeeModel.fromMap(updatedFeeMap, feeId);
        
        final finalFee = updatedFee.copyWith(
          amountPaid: newAmountPaid,
          updatedAt: DateTime.now(),
        );
        
        await prefs.setString('fee_$feeId', jsonEncode(finalFee.toMap()));
      }
      
      return payment;
    } catch (e) {
      debugPrint('Error recording payment: $e');
      rethrow;
    }
  }
  
  // Get payment by ID
  Future<PaymentModel?> getPaymentById(String paymentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get payment from SharedPreferences
      final paymentJson = prefs.getString('payment_$paymentId');
      if (paymentJson == null) {
        return null;
      }
      
      // Parse payment
      final paymentMap = jsonDecode(paymentJson) as Map<String, dynamic>;
      return PaymentModel.fromMap(paymentMap, paymentId);
    } catch (e) {
      debugPrint('Error getting payment: $e');
      return null;
    }
  }
  
  // Get payments for a fee
  Future<List<PaymentModel>> getPaymentsForFee(String feeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get fee's payment IDs
      final paymentIds = prefs.getStringList('fee_payments_$feeId') ?? [];
      
      // Get payments
      final payments = <PaymentModel>[];
      for (final id in paymentIds) {
        final payment = await getPaymentById(id);
        if (payment != null) {
          payments.add(payment);
        }
      }
      
      // Sort by payment date (newest first)
      payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      
      return payments;
    } catch (e) {
      debugPrint('Error getting payments for fee: $e');
      return [];
    }
  }
  
  // Get payments for a student
  Future<List<PaymentModel>> getPaymentsForStudent(String studentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all payment keys
      final allKeys = prefs.getKeys();
      final paymentKeys = allKeys.where((key) => key.startsWith('payment_')).toList();
      
      // Get payments
      final payments = <PaymentModel>[];
      for (final key in paymentKeys) {
        final paymentJson = prefs.getString(key);
        if (paymentJson != null) {
          final paymentMap = jsonDecode(paymentJson) as Map<String, dynamic>;
          if (paymentMap['studentId'] == studentId) {
            final paymentId = key.substring('payment_'.length);
            payments.add(PaymentModel.fromMap(paymentMap, paymentId));
          }
        }
      }
      
      // Sort by payment date (newest first)
      payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      
      return payments;
    } catch (e) {
      debugPrint('Error getting payments for student: $e');
      return [];
    }
  }
  
  // Verify payment
  Future<PaymentModel> verifyPayment(String paymentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get payment
      final paymentJson = prefs.getString('payment_$paymentId');
      if (paymentJson == null) {
        throw Exception('Payment not found');
      }
      
      // Parse payment
      final paymentMap = jsonDecode(paymentJson) as Map<String, dynamic>;
      final payment = PaymentModel.fromMap(paymentMap, paymentId);
      
      // Get current user (for verification)
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Create updated payment
      final updatedPayment = PaymentModel(
        id: payment.id,
        feeId: payment.feeId,
        studentId: payment.studentId,
        studentName: payment.studentName,
        amount: payment.amount,
        method: payment.method,
        transactionId: payment.transactionId,
        receiptNumber: payment.receiptNumber,
        paymentDate: payment.paymentDate,
        notes: payment.notes,
        paymentProofUrl: payment.paymentProofUrl,
        isVerified: true,
        verifiedById: currentUser.id,
        verifiedAt: DateTime.now(),
        createdAt: payment.createdAt,
      );
      
      // Save updated payment to SharedPreferences
      await prefs.setString('payment_$paymentId', jsonEncode(updatedPayment.toMap()));
      
      return updatedPayment;
    } catch (e) {
      debugPrint('Error verifying payment: $e');
      rethrow;
    }
  }
  
  // Create fee structure
  Future<FeeStructureModel> createFeeStructure({
    required String academicYear,
    String? term,
    required String title,
    required FeeType feeType,
    required double amount,
    String? gradeLevel,
    String? program,
    required bool isRecurring,
    String? recurringFrequency,
    String? description,
    required DateTime dueDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Generate a new ID
      final structureId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create fee structure model
      final feeStructure = FeeStructureModel(
        id: structureId,
        academicYear: academicYear,
        term: term,
        title: title,
        feeType: feeType,
        amount: amount,
        gradeLevel: gradeLevel,
        program: program,
        isRecurring: isRecurring,
        recurringFrequency: recurringFrequency,
        description: description,
        dueDate: dueDate,
        createdAt: DateTime.now(),
        isActive: true,
      );
      
      // Save fee structure to SharedPreferences
      await prefs.setString('fee_structure_$structureId', jsonEncode(feeStructure.toMap()));
      
      // Add fee structure ID to academic year's fee structures list
      final yearStructures = prefs.getStringList('year_fee_structures_$academicYear') ?? [];
      yearStructures.add(structureId);
      await prefs.setStringList('year_fee_structures_$academicYear', yearStructures);
      
      return feeStructure;
    } catch (e) {
      debugPrint('Error creating fee structure: $e');
      rethrow;
    }
  }
  
  // Get fee structure by ID
  Future<FeeStructureModel?> getFeeStructureById(String structureId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get fee structure from SharedPreferences
      final structureJson = prefs.getString('fee_structure_$structureId');
      if (structureJson == null) {
        return null;
      }
      
      // Parse fee structure
      final structureMap = jsonDecode(structureJson) as Map<String, dynamic>;
      return FeeStructureModel.fromMap(structureMap, structureId);
    } catch (e) {
      debugPrint('Error getting fee structure: $e');
      return null;
    }
  }
  
  // Get fee structures for an academic year
  Future<List<FeeStructureModel>> getFeeStructuresForYear(String academicYear) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get academic year's fee structure IDs
      final structureIds = prefs.getStringList('year_fee_structures_$academicYear') ?? [];
      
      // Get fee structures
      final structures = <FeeStructureModel>[];
      for (final id in structureIds) {
        final structure = await getFeeStructureById(id);
        if (structure != null) {
          structures.add(structure);
        }
      }
      
      return structures;
    } catch (e) {
      debugPrint('Error getting fee structures for year: $e');
      return [];
    }
  }
  
  // Apply fee structure to students
  Future<List<FeeModel>> applyFeeStructureToStudents({
    required String structureId,
    required List<Map<String, String>> students, // List of {id, name} maps
  }) async {
    try {
      // Get fee structure
      final structure = await getFeeStructureById(structureId);
      if (structure == null) {
        throw Exception('Fee structure not found');
      }
      
      final createdFees = <FeeModel>[];
      
      // Create fees for each student
      for (final student in students) {
        final fee = await createFee(
          studentId: student['id']!,
          studentName: student['name']!,
          academicYear: structure.academicYear,
          term: structure.term ?? 'Default Term',
          feeTitle: structure.title,
          feeType: structure.feeType,
          amount: structure.amount,
          dueDate: structure.dueDate,
          description: structure.description,
          isRecurring: structure.isRecurring,
          recurringFrequency: structure.recurringFrequency,
        );
        
        createdFees.add(fee);
      }
      
      return createdFees;
    } catch (e) {
      debugPrint('Error applying fee structure to students: $e');
      rethrow;
    }
  }
  
  // Generate sample fees for demo purposes
  Future<void> generateSampleFees() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Check if sample fees already exist
      final hasSampleFees = prefs.getBool('has_sample_fees') ?? false;
      if (hasSampleFees) {
        return;
      }
      
      // Sample fee types
      final feeTypes = [
        FeeType.tuition,
        FeeType.registration,
        FeeType.examination,
        FeeType.library,
        FeeType.laboratory,
      ];
      
      // Sample terms
      final terms = ['Term 1', 'Term 2', 'Term 3'];
      
      // Current academic year
      final currentYear = DateTime.now().year;
      final academicYear = '$currentYear-${currentYear + 1}';
      
      // Generate sample fees
      for (final term in terms) {
        for (final feeType in feeTypes) {
          final amount = _getRandomAmount(feeType);
          final dueDate = _getRandomDueDate();
          
          await createFee(
            studentId: currentUser.id,
            studentName: 'John Doe',
            academicYear: academicYear,
            term: term,
            feeTitle: _getFeeTitle(feeType),
            feeType: feeType,
            amount: amount,
            amountPaid: _getRandomAmountPaid(amount),
            discount: _getRandomDiscount(amount),
            dueDate: dueDate,
            status: _getRandomStatus(),
            description: 'Sample fee for demonstration purposes',
            isRecurring: feeType == FeeType.tuition,
            recurringFrequency: feeType == FeeType.tuition ? 'termly' : null,
          );
        }
      }
      
      // Mark that sample fees have been generated
      await prefs.setBool('has_sample_fees', true);
    } catch (e) {
      debugPrint('Error generating sample fees: $e');
    }
  }
  
  // Helper methods for sample data generation
  double _getRandomAmount(FeeType feeType) {
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    
    switch (feeType) {
      case FeeType.tuition:
        return 5000.0 + random;
      case FeeType.registration:
        return 500.0 + (random / 10);
      case FeeType.examination:
        return 1000.0 + (random / 5);
      case FeeType.library:
        return 300.0 + (random / 20);
      case FeeType.laboratory:
        return 800.0 + (random / 8);
      default:
        return 200.0 + (random / 10);
    }
  }
  
  double _getRandomAmountPaid(double amount) {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final paymentFactor = random / 100;
    
    if (paymentFactor < 0.3) {
      return 0.0; // 30% chance of no payment
    } else if (paymentFactor < 0.7) {
      return amount * (0.3 + (random / 200)); // 40% chance of partial payment
    } else {
      return amount; // 30% chance of full payment
    }
  }
  
  double _getRandomDiscount(double amount) {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    
    if (random < 80) {
      return 0.0; // 80% chance of no discount
    } else {
      return amount * (0.05 + (random / 1000)); // 20% chance of discount
    }
  }
  
  DateTime _getRandomDueDate() {
    final now = DateTime.now();
    final random = now.millisecondsSinceEpoch % 90;
    
    if (random < 30) {
      return now.subtract(Duration(days: random)); // Past due date
    } else {
      return now.add(Duration(days: random - 30)); // Future due date
    }
  }
  
  PaymentStatus _getRandomStatus() {
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    
    if (random < 50) {
      return PaymentStatus.pending;
    } else if (random < 70) {
      return PaymentStatus.partiallyPaid;
    } else if (random < 90) {
      return PaymentStatus.paid;
    } else if (random < 95) {
      return PaymentStatus.overdue;
    } else if (random < 98) {
      return PaymentStatus.waived;
    } else {
      return PaymentStatus.refunded;
    }
  }
  
  String _getFeeTitle(FeeType feeType) {
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
}
