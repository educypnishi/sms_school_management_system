import 'fee_model.dart';

class PaymentModel {
  final String id;
  final String feeId;
  final String studentId;
  final String? studentName;
  final double amount;
  final DateTime paymentDate;
  final PaymentMethod paymentMethod;
  final String status;
  final String? transactionId;
  final String? receiptNumber;
  final String? notes;
  final bool isVerified;
  
  // Getter for compatibility
  PaymentMethod get method => paymentMethod;

  PaymentModel({
    required this.id,
    required this.feeId,
    required this.studentId,
    this.studentName,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    required this.status,
    this.transactionId,
    this.receiptNumber,
    this.notes,
    this.isVerified = false,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      feeId: map['feeId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'],
      amount: (map['amount'] ?? 0).toDouble(),
      paymentDate: map['paymentDate'] != null 
          ? DateTime.parse(map['paymentDate']) 
          : DateTime.now(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == (map['paymentMethod'] ?? 'cash'),
        orElse: () => PaymentMethod.cash,
      ),
      status: map['status'] ?? '',
      transactionId: map['transactionId'],
      receiptNumber: map['receiptNumber'],
      notes: map['notes'],
      isVerified: map['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'feeId': feeId,
      'studentId': studentId,
      'studentName': studentName,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod.toString().split('.').last,
      'status': status,
      'transactionId': transactionId,
      'receiptNumber': receiptNumber,
      'notes': notes,
      'isVerified': isVerified,
    };
  }
}
