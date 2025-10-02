import 'package:flutter/foundation.dart';

enum FeeType {
  tuition,
  registration,
  examination,
  library,
  laboratory,
  transportation,
  hostel,
  uniform,
  books,
  activities,
  other
}

enum PaymentStatus {
  pending,
  partiallyPaid,
  paid,
  overdue,
  waived,
  refunded
}

enum PaymentMethod {
  cash,
  creditCard,
  debitCard,
  bankTransfer,
  check,
  onlineBanking,
  mobilePayment,
  other
}

class FeeModel {
  final String id;
  final String studentId;
  final String studentName;
  final String academicYear;
  final String term;
  final String feeTitle;
  final FeeType feeType;
  final double amount;
  final double amountPaid;
  final double discount;
  final DateTime dueDate;
  final PaymentStatus status;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isRecurring;
  final String? recurringFrequency; // monthly, quarterly, etc.

  FeeModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.academicYear,
    required this.term,
    required this.feeTitle,
    required this.feeType,
    required this.amount,
    required this.amountPaid,
    required this.discount,
    required this.dueDate,
    required this.status,
    this.description,
    required this.createdAt,
    this.updatedAt,
    required this.isRecurring,
    this.recurringFrequency,
  });

  // Calculate remaining amount
  double get remainingAmount => amount - amountPaid - discount;

  // Check if fee is overdue
  bool get isOverdue => status != PaymentStatus.paid && 
                        status != PaymentStatus.waived && 
                        DateTime.now().isAfter(dueDate);

  // Calculate days remaining until due date
  int get daysRemaining {
    if (status == PaymentStatus.paid || status == PaymentStatus.waived) {
      return 0;
    }
    
    final now = DateTime.now();
    if (now.isAfter(dueDate)) {
      return 0;
    }
    
    return dueDate.difference(now).inDays;
  }

  // Calculate days overdue
  int get daysOverdue {
    if (status == PaymentStatus.paid || status == PaymentStatus.waived || !isOverdue) {
      return 0;
    }
    
    return DateTime.now().difference(dueDate).inDays;
  }

  // Create a FeeModel from a map (e.g., from Firestore)
  factory FeeModel.fromMap(Map<String, dynamic> map, String id) {
    return FeeModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      academicYear: map['academicYear'] ?? '',
      term: map['term'] ?? '',
      feeTitle: map['feeTitle'] ?? '',
      feeType: _parseFeeType(map['feeType']),
      amount: map['amount']?.toDouble() ?? 0.0,
      amountPaid: map['amountPaid']?.toDouble() ?? 0.0,
      discount: map['discount']?.toDouble() ?? 0.0,
      dueDate: map['dueDate'] != null 
          ? DateTime.parse(map['dueDate']) 
          : DateTime.now().add(const Duration(days: 30)),
      status: _parsePaymentStatus(map['status']),
      description: map['description'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
      isRecurring: map['isRecurring'] ?? false,
      recurringFrequency: map['recurringFrequency'],
    );
  }

  // Convert FeeModel to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'academicYear': academicYear,
      'term': term,
      'feeTitle': feeTitle,
      'feeType': describeEnum(feeType),
      'amount': amount,
      'amountPaid': amountPaid,
      'discount': discount,
      'dueDate': dueDate.toIso8601String(),
      'status': describeEnum(status),
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isRecurring': isRecurring,
      'recurringFrequency': recurringFrequency,
    };
  }

  // Create a copy of FeeModel with some fields changed
  FeeModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? academicYear,
    String? term,
    String? feeTitle,
    FeeType? feeType,
    double? amount,
    double? amountPaid,
    double? discount,
    DateTime? dueDate,
    PaymentStatus? status,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRecurring,
    String? recurringFrequency,
  }) {
    return FeeModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      academicYear: academicYear ?? this.academicYear,
      term: term ?? this.term,
      feeTitle: feeTitle ?? this.feeTitle,
      feeType: feeType ?? this.feeType,
      amount: amount ?? this.amount,
      amountPaid: amountPaid ?? this.amountPaid,
      discount: discount ?? this.discount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
    );
  }

  // Helper method to parse FeeType from string
  static FeeType _parseFeeType(String? value) {
    if (value == null) return FeeType.other;
    
    try {
      return FeeType.values.firstWhere(
        (type) => describeEnum(type) == value,
        orElse: () => FeeType.other,
      );
    } catch (_) {
      return FeeType.other;
    }
  }

  // Helper method to parse PaymentStatus from string
  static PaymentStatus _parsePaymentStatus(String? value) {
    if (value == null) return PaymentStatus.pending;
    
    try {
      return PaymentStatus.values.firstWhere(
        (status) => describeEnum(status) == value,
        orElse: () => PaymentStatus.pending,
      );
    } catch (_) {
      return PaymentStatus.pending;
    }
  }
}

class FeeStructureModel {
  final String id;
  final String academicYear;
  final String? term;
  final String title;
  final FeeType feeType;
  final double amount;
  final DateTime createdAt;
  final String? gradeLevel;
  final String? program;
  final bool isRecurring;
  final String? recurringFrequency;
  final String? description;
  final DateTime dueDate;
  final DateTime? updatedAt;
  final bool isActive;

  FeeStructureModel({
    required this.id,
    required this.academicYear,
    this.term,
    required this.title,
    required this.feeType,
    required this.amount,
    this.gradeLevel,
    this.program,
    required this.isRecurring,
    this.recurringFrequency,
    this.description,
    required this.dueDate,
    required this.createdAt,
    this.updatedAt,
    required this.isActive,
  });

  // Create a FeeStructureModel from a map (e.g., from Firestore)
  factory FeeStructureModel.fromMap(Map<String, dynamic> map, String id) {
    return FeeStructureModel(
      id: id,
      academicYear: map['academicYear'] ?? '',
      term: map['term'],
      title: map['title'] ?? '',
      feeType: FeeModel._parseFeeType(map['feeType']),
      amount: map['amount']?.toDouble() ?? 0.0,
      gradeLevel: map['gradeLevel'],
      program: map['program'],
      isRecurring: map['isRecurring'] ?? false,
      recurringFrequency: map['recurringFrequency'],
      description: map['description'],
      dueDate: map['dueDate'] != null 
          ? DateTime.parse(map['dueDate']) 
          : DateTime.now().add(const Duration(days: 30)),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : null,
      isActive: map['isActive'] ?? true,
    );
  }

  // Convert FeeStructureModel to a map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'academicYear': academicYear,
      'term': term,
      'title': title,
      'feeType': describeEnum(feeType),
      'amount': amount,
      'gradeLevel': gradeLevel,
      'program': program,
      'isRecurring': isRecurring,
      'recurringFrequency': recurringFrequency,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Create a copy of FeeStructureModel with some fields changed
  FeeStructureModel copyWith({
    String? id,
    String? academicYear,
    String? term,
    String? title,
    FeeType? feeType,
    double? amount,
    String? gradeLevel,
    String? program,
    bool? isRecurring,
    String? recurringFrequency,
    String? description,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return FeeStructureModel(
      id: id ?? this.id,
      academicYear: academicYear ?? this.academicYear,
      term: term ?? this.term,
      title: title ?? this.title,
      feeType: feeType ?? this.feeType,
      amount: amount ?? this.amount,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      program: program ?? this.program,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

// Helper function to convert enum to string
String describeEnum(Object enumValue) {
  final String description = enumValue.toString();
  final int indexOfDot = description.indexOf('.');
  assert(indexOfDot != -1 && indexOfDot < description.length - 1);
  return description.substring(indexOfDot + 1);
}
