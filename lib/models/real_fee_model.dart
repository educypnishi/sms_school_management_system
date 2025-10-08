class FeeStructure {
  final String id;
  final String name;
  final String description;
  final double amount;
  final String feeType; // tuition, library, lab, transport, hostel, exam, etc.
  final String frequency; // monthly, quarterly, semester, annual, one-time
  final String applicableGrade;
  final bool isMandatory;
  final DateTime? dueDate;
  final double? lateFee;
  final int? gracePeriodDays;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FeeStructure({
    required this.id,
    required this.name,
    required this.description,
    required this.amount,
    required this.feeType,
    required this.frequency,
    required this.applicableGrade,
    required this.isMandatory,
    this.dueDate,
    this.lateFee,
    this.gracePeriodDays,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory FeeStructure.fromMap(Map<String, dynamic> map, String id) {
    return FeeStructure(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      feeType: map['feeType'] ?? '',
      frequency: map['frequency'] ?? '',
      applicableGrade: map['applicableGrade'] ?? '',
      isMandatory: map['isMandatory'] ?? true,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      lateFee: map['lateFee'] != null ? (map['lateFee']).toDouble() : null,
      gracePeriodDays: map['gracePeriodDays'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'amount': amount,
      'feeType': feeType,
      'frequency': frequency,
      'applicableGrade': applicableGrade,
      'isMandatory': isMandatory,
      'dueDate': dueDate?.toIso8601String(),
      'lateFee': lateFee,
      'gracePeriodDays': gracePeriodDays,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class StudentFeeRecord {
  final String id;
  final String studentId;
  final String feeStructureId;
  final String feeName;
  final double originalAmount;
  final double discountAmount;
  final double finalAmount;
  final double paidAmount;
  final double pendingAmount;
  final DateTime dueDate;
  final FeeStatus status;
  final String? discountReason;
  final List<FeePayment> payments;
  final DateTime createdAt;
  final DateTime? updatedAt;

  StudentFeeRecord({
    required this.id,
    required this.studentId,
    required this.feeStructureId,
    required this.feeName,
    required this.originalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.dueDate,
    required this.status,
    this.discountReason,
    required this.payments,
    required this.createdAt,
    this.updatedAt,
  });

  factory StudentFeeRecord.fromMap(Map<String, dynamic> map, String id) {
    return StudentFeeRecord(
      id: id,
      studentId: map['studentId'] ?? '',
      feeStructureId: map['feeStructureId'] ?? '',
      feeName: map['feeName'] ?? '',
      originalAmount: (map['originalAmount'] ?? 0).toDouble(),
      discountAmount: (map['discountAmount'] ?? 0).toDouble(),
      finalAmount: (map['finalAmount'] ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      pendingAmount: (map['pendingAmount'] ?? 0).toDouble(),
      dueDate: DateTime.parse(map['dueDate']),
      status: FeeStatus.values.firstWhere(
        (e) => e.toString() == 'FeeStatus.${map['status']}',
        orElse: () => FeeStatus.pending,
      ),
      discountReason: map['discountReason'],
      payments: (map['payments'] as List<dynamic>?)
          ?.map((p) => FeePayment.fromMap(p, p['id'] ?? ''))
          .toList() ?? [],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'feeStructureId': feeStructureId,
      'feeName': feeName,
      'originalAmount': originalAmount,
      'discountAmount': discountAmount,
      'finalAmount': finalAmount,
      'paidAmount': paidAmount,
      'pendingAmount': pendingAmount,
      'dueDate': dueDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'discountReason': discountReason,
      'payments': payments.map((p) => p.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class FeePayment {
  final String id;
  final String studentFeeRecordId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod; // cash, bank_transfer, online, cheque, card
  final String? transactionId;
  final String? receiptNumber;
  final PaymentStatus status;
  final String? remarks;
  final String? processedBy;
  final DateTime createdAt;

  FeePayment({
    required this.id,
    required this.studentFeeRecordId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.transactionId,
    this.receiptNumber,
    required this.status,
    this.remarks,
    this.processedBy,
    required this.createdAt,
  });

  factory FeePayment.fromMap(Map<String, dynamic> map, String id) {
    return FeePayment(
      id: id,
      studentFeeRecordId: map['studentFeeRecordId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentDate: DateTime.parse(map['paymentDate']),
      paymentMethod: map['paymentMethod'] ?? '',
      transactionId: map['transactionId'],
      receiptNumber: map['receiptNumber'],
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == 'PaymentStatus.${map['status']}',
        orElse: () => PaymentStatus.pending,
      ),
      remarks: map['remarks'],
      processedBy: map['processedBy'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentFeeRecordId': studentFeeRecordId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'receiptNumber': receiptNumber,
      'status': status.toString().split('.').last,
      'remarks': remarks,
      'processedBy': processedBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

enum FeeStatus {
  pending,
  partial,
  paid,
  overdue,
  waived,
  cancelled
}

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
  cancelled
}

class StudentFeeSummary {
  final String studentId;
  final double totalFees;
  final double totalPaid;
  final double totalPending;
  final double totalOverdue;
  final int pendingFeeCount;
  final int overdueFeeCount;
  final List<StudentFeeRecord> recentPayments;
  final List<StudentFeeRecord> upcomingDues;

  StudentFeeSummary({
    required this.studentId,
    required this.totalFees,
    required this.totalPaid,
    required this.totalPending,
    required this.totalOverdue,
    required this.pendingFeeCount,
    required this.overdueFeeCount,
    required this.recentPayments,
    required this.upcomingDues,
  });

  factory StudentFeeSummary.fromFeeRecords(String studentId, List<StudentFeeRecord> feeRecords) {
    final totalFees = feeRecords.map((f) => f.finalAmount).fold(0.0, (a, b) => a + b);
    final totalPaid = feeRecords.map((f) => f.paidAmount).fold(0.0, (a, b) => a + b);
    final totalPending = feeRecords.where((f) => f.status == FeeStatus.pending || f.status == FeeStatus.partial)
        .map((f) => f.pendingAmount).fold(0.0, (a, b) => a + b);
    final totalOverdue = feeRecords.where((f) => f.status == FeeStatus.overdue)
        .map((f) => f.pendingAmount).fold(0.0, (a, b) => a + b);
    
    final pendingFeeCount = feeRecords.where((f) => f.status == FeeStatus.pending || f.status == FeeStatus.partial).length;
    final overdueFeeCount = feeRecords.where((f) => f.status == FeeStatus.overdue).length;
    
    final recentPayments = feeRecords.where((f) => f.paidAmount > 0)
        .toList()..sort((a, b) => b.updatedAt?.compareTo(a.updatedAt ?? DateTime.now()) ?? 0);
    
    final upcomingDues = feeRecords.where((f) => f.pendingAmount > 0 && f.dueDate.isAfter(DateTime.now()))
        .toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return StudentFeeSummary(
      studentId: studentId,
      totalFees: totalFees,
      totalPaid: totalPaid,
      totalPending: totalPending,
      totalOverdue: totalOverdue,
      pendingFeeCount: pendingFeeCount,
      overdueFeeCount: overdueFeeCount,
      recentPayments: recentPayments.take(5).toList(),
      upcomingDues: upcomingDues.take(5).toList(),
    );
  }
}
