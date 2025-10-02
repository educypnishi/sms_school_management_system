class PaymentModel {
  final String id;
  final String feeId;
  final String studentId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String status;
  final String? transactionId;
  final String? receiptNumber;
  final String? notes;

  PaymentModel({
    required this.id,
    required this.feeId,
    required this.studentId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    required this.status,
    this.transactionId,
    this.receiptNumber,
    this.notes,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      feeId: map['feeId'] ?? '',
      studentId: map['studentId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentDate: map['paymentDate'] != null 
          ? DateTime.parse(map['paymentDate']) 
          : DateTime.now(),
      paymentMethod: map['paymentMethod'] ?? '',
      status: map['status'] ?? '',
      transactionId: map['transactionId'],
      receiptNumber: map['receiptNumber'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'feeId': feeId,
      'studentId': studentId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'status': status,
      'transactionId': transactionId,
      'receiptNumber': receiptNumber,
      'notes': notes,
    };
  }
}
