import 'package:flutter/material.dart';

/// Represents a currency
class Currency {
  final String code;
  final String name;
  final String symbol;
  final double conversionRateToEUR;

  Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.conversionRateToEUR,
  });

  /// Convert an amount from this currency to EUR
  double toEUR(double amount) {
    return amount / conversionRateToEUR;
  }

  /// Convert an amount from EUR to this currency
  double fromEUR(double amount) {
    return amount * conversionRateToEUR;
  }

  /// Convert an amount from this currency to another currency
  double convert(double amount, Currency toCurrency) {
    // First convert to EUR, then to the target currency
    final amountInEUR = toEUR(amount);
    return toCurrency.fromEUR(amountInEUR);
  }
}

/// Represents a cost category
enum CostCategory {
  tuition,
  accommodation,
  food,
  transportation,
  healthInsurance,
  books,
  utilities,
  entertainment,
  other,
}

/// Represents a time period for costs
enum TimePeriod {
  monthly,
  semester,
  annual,
  oneTime,
}

/// Extension on TimePeriod to provide helper methods
extension TimePeriodExtension on TimePeriod {
  /// Get the number of months in this time period
  int get months {
    switch (this) {
      case TimePeriod.monthly:
        return 1;
      case TimePeriod.semester:
        return 6;
      case TimePeriod.annual:
        return 12;
      case TimePeriod.oneTime:
        return 0; // One-time costs are not recurring
    }
  }

  /// Get a display name for this time period
  String get displayName {
    switch (this) {
      case TimePeriod.monthly:
        return 'Monthly';
      case TimePeriod.semester:
        return 'Per Semester';
      case TimePeriod.annual:
        return 'Annual';
      case TimePeriod.oneTime:
        return 'One-time';
    }
  }

  /// Convert a cost from this time period to another
  double convertTo(double amount, TimePeriod targetPeriod) {
    if (this == TimePeriod.oneTime || targetPeriod == TimePeriod.oneTime) {
      // One-time costs cannot be converted
      return amount;
    }

    // Convert to monthly first
    final monthlyAmount = this == TimePeriod.monthly
        ? amount
        : amount / months;

    // Then convert to target period
    return monthlyAmount * targetPeriod.months;
  }
}

/// Represents a cost item in the calculator
class CostItem {
  final String id;
  final String name;
  final CostCategory category;
  final double amount;
  final TimePeriod period;
  final String? notes;
  final bool isRequired;
  final bool isCustom;

  CostItem({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.period,
    this.notes,
    this.isRequired = true,
    this.isCustom = false,
  });

  /// Create a copy of this cost item with updated fields
  CostItem copyWith({
    String? id,
    String? name,
    CostCategory? category,
    double? amount,
    TimePeriod? period,
    String? notes,
    bool? isRequired,
    bool? isCustom,
  }) {
    return CostItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      notes: notes ?? this.notes,
      isRequired: isRequired ?? this.isRequired,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  /// Get the monthly cost of this item
  double get monthlyCost {
    return period.convertTo(amount, TimePeriod.monthly);
  }

  /// Get the annual cost of this item
  double get annualCost {
    return period.convertTo(amount, TimePeriod.annual);
  }

  /// Get the total cost for a specified number of months
  double getTotalCost(int months) {
    if (period == TimePeriod.oneTime) {
      return amount;
    }
    return monthlyCost * months;
  }

  /// Create a CostItem from a map
  factory CostItem.fromMap(Map<String, dynamic> map) {
    return CostItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: _parseCostCategory(map['category']),
      amount: map['amount']?.toDouble() ?? 0.0,
      period: _parseTimePeriod(map['period']),
      notes: map['notes'],
      isRequired: map['isRequired'] ?? true,
      isCustom: map['isCustom'] ?? false,
    );
  }

  /// Convert CostItem to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.toString().split('.').last,
      'amount': amount,
      'period': period.toString().split('.').last,
      'notes': notes,
      'isRequired': isRequired,
      'isCustom': isCustom,
    };
  }

  /// Parse CostCategory from string
  static CostCategory _parseCostCategory(String? value) {
    if (value == null) return CostCategory.other;
    
    switch (value.toLowerCase()) {
      case 'tuition':
        return CostCategory.tuition;
      case 'accommodation':
        return CostCategory.accommodation;
      case 'food':
        return CostCategory.food;
      case 'transportation':
        return CostCategory.transportation;
      case 'healthinsurance':
        return CostCategory.healthInsurance;
      case 'books':
        return CostCategory.books;
      case 'utilities':
        return CostCategory.utilities;
      case 'entertainment':
        return CostCategory.entertainment;
      case 'other':
      default:
        return CostCategory.other;
    }
  }

  /// Parse TimePeriod from string
  static TimePeriod _parseTimePeriod(String? value) {
    if (value == null) return TimePeriod.monthly;
    
    switch (value.toLowerCase()) {
      case 'semester':
        return TimePeriod.semester;
      case 'annual':
        return TimePeriod.annual;
      case 'onetime':
        return TimePeriod.oneTime;
      case 'monthly':
      default:
        return TimePeriod.monthly;
    }
  }
}

/// Extension on CostCategory to provide helper methods
extension CostCategoryExtension on CostCategory {
  /// Get a display name for this cost category
  String get displayName {
    switch (this) {
      case CostCategory.tuition:
        return 'Tuition Fees';
      case CostCategory.accommodation:
        return 'Accommodation';
      case CostCategory.food:
        return 'Food & Groceries';
      case CostCategory.transportation:
        return 'Transportation';
      case CostCategory.healthInsurance:
        return 'Health Insurance';
      case CostCategory.books:
        return 'Books & Supplies';
      case CostCategory.utilities:
        return 'Utilities';
      case CostCategory.entertainment:
        return 'Entertainment';
      case CostCategory.other:
        return 'Other Expenses';
    }
  }

  /// Get an icon for this cost category
  IconData get icon {
    switch (this) {
      case CostCategory.tuition:
        return Icons.school;
      case CostCategory.accommodation:
        return Icons.home;
      case CostCategory.food:
        return Icons.restaurant;
      case CostCategory.transportation:
        return Icons.directions_bus;
      case CostCategory.healthInsurance:
        return Icons.health_and_safety;
      case CostCategory.books:
        return Icons.book;
      case CostCategory.utilities:
        return Icons.power;
      case CostCategory.entertainment:
        return Icons.movie;
      case CostCategory.other:
        return Icons.more_horiz;
    }
  }

  /// Get a color for this cost category
  Color get color {
    switch (this) {
      case CostCategory.tuition:
        return Colors.blue;
      case CostCategory.accommodation:
        return Colors.green;
      case CostCategory.food:
        return Colors.orange;
      case CostCategory.transportation:
        return Colors.purple;
      case CostCategory.healthInsurance:
        return Colors.red;
      case CostCategory.books:
        return Colors.teal;
      case CostCategory.utilities:
        return Colors.amber;
      case CostCategory.entertainment:
        return Colors.pink;
      case CostCategory.other:
        return Colors.grey;
    }
  }
}

/// Represents a cost scenario in the calculator
class CostScenario {
  final String id;
  final String name;
  final String description;
  final List<CostItem> costItems;
  final int durationMonths;
  final String currencyCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  CostScenario({
    required this.id,
    required this.name,
    required this.description,
    required this.costItems,
    required this.durationMonths,
    required this.currencyCode,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this scenario with updated fields
  CostScenario copyWith({
    String? id,
    String? name,
    String? description,
    List<CostItem>? costItems,
    int? durationMonths,
    String? currencyCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CostScenario(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      costItems: costItems ?? this.costItems,
      durationMonths: durationMonths ?? this.durationMonths,
      currencyCode: currencyCode ?? this.currencyCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get the total cost of all items in this scenario
  double get totalCost {
    return costItems.fold(0, (sum, item) => sum + item.getTotalCost(durationMonths));
  }

  /// Get the total cost by category
  Map<CostCategory, double> get costByCategory {
    final result = <CostCategory, double>{};
    
    for (final category in CostCategory.values) {
      final items = costItems.where((item) => item.category == category);
      final total = items.fold(0.0, (sum, item) => sum + item.getTotalCost(durationMonths));
      result[category] = total;
    }
    
    return result;
  }

  /// Get the monthly cost
  double get monthlyCost {
    if (durationMonths == 0) return 0;
    return totalCost / durationMonths;
  }

  /// Get the one-time costs
  double get oneTimeCosts {
    return costItems
        .where((item) => item.period == TimePeriod.oneTime)
        .fold(0, (sum, item) => sum + item.amount);
  }

  /// Get the recurring costs
  double get recurringCosts {
    return totalCost - oneTimeCosts;
  }

  /// Create a CostScenario from a map
  factory CostScenario.fromMap(Map<String, dynamic> map) {
    final costItemsList = <CostItem>[];
    if (map['costItems'] != null) {
      for (final item in map['costItems']) {
        costItemsList.add(CostItem.fromMap(item));
      }
    }
    
    return CostScenario(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      costItems: costItemsList,
      durationMonths: map['durationMonths'] ?? 12,
      currencyCode: map['currencyCode'] ?? 'EUR',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt']) 
          : DateTime.now(),
    );
  }

  /// Convert CostScenario to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'costItems': costItems.map((item) => item.toMap()).toList(),
      'durationMonths': durationMonths,
      'currencyCode': currencyCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
