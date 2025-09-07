import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cost_calculator_model.dart';

/// Service to manage cost calculations in the system
class CostCalculatorService {
  // Shared Preferences keys
  static const String _scenariosKey = 'cost_scenarios';
  static const String _currenciesKey = 'currencies';
  
  // In-memory cache
  final Map<String, CostScenario> _scenarios = {};
  final Map<String, Currency> _currencies = {};
  
  /// Get all available currencies
  Future<List<Currency>> getAllCurrencies() async {
    // Load currencies if not already loaded
    if (_currencies.isEmpty) {
      await _loadCurrencies();
    }
    
    return _currencies.values.toList();
  }
  
  /// Get a specific currency by code
  Future<Currency?> getCurrency(String code) async {
    // Load currencies if not already loaded
    if (_currencies.isEmpty) {
      await _loadCurrencies();
    }
    
    return _currencies[code.toUpperCase()];
  }
  
  /// Get all saved cost scenarios
  Future<List<CostScenario>> getAllScenarios() async {
    // Load scenarios if not already loaded
    if (_scenarios.isEmpty) {
      await _loadScenarios();
    }
    
    // Sort by updated date (newest first)
    final scenarios = _scenarios.values.toList();
    scenarios.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    
    return scenarios;
  }
  
  /// Get a specific scenario by ID
  Future<CostScenario?> getScenario(String id) async {
    // Load scenarios if not already loaded
    if (_scenarios.isEmpty) {
      await _loadScenarios();
    }
    
    return _scenarios[id];
  }
  
  /// Create a new cost scenario
  Future<CostScenario> createScenario({
    required String name,
    required String description,
    required int durationMonths,
    required String currencyCode,
    List<CostItem>? initialCostItems,
  }) async {
    // Generate a unique ID
    final id = 'scenario_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create the scenario
    final scenario = CostScenario(
      id: id,
      name: name,
      description: description,
      costItems: initialCostItems ?? [],
      durationMonths: durationMonths,
      currencyCode: currencyCode,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // Add to in-memory cache
    _scenarios[id] = scenario;
    
    // Save to SharedPreferences
    await _saveScenarios();
    
    return scenario;
  }
  
  /// Update an existing cost scenario
  Future<CostScenario> updateScenario(CostScenario scenario) async {
    // Update the timestamp
    final updatedScenario = scenario.copyWith(
      updatedAt: DateTime.now(),
    );
    
    // Update in-memory cache
    _scenarios[updatedScenario.id] = updatedScenario;
    
    // Save to SharedPreferences
    await _saveScenarios();
    
    return updatedScenario;
  }
  
  /// Delete a cost scenario
  Future<bool> deleteScenario(String id) async {
    // Remove from in-memory cache
    final removed = _scenarios.remove(id);
    
    // Save to SharedPreferences
    await _saveScenarios();
    
    return removed != null;
  }
  
  /// Add a cost item to a scenario
  Future<CostScenario> addCostItem(String scenarioId, CostItem item) async {
    // Get the scenario
    final scenario = _scenarios[scenarioId];
    if (scenario == null) {
      throw Exception('Scenario not found');
    }
    
    // Add the item
    final updatedItems = List<CostItem>.from(scenario.costItems)..add(item);
    
    // Update the scenario
    final updatedScenario = scenario.copyWith(
      costItems: updatedItems,
      updatedAt: DateTime.now(),
    );
    
    // Update in-memory cache
    _scenarios[scenarioId] = updatedScenario;
    
    // Save to SharedPreferences
    await _saveScenarios();
    
    return updatedScenario;
  }
  
  /// Update a cost item in a scenario
  Future<CostScenario> updateCostItem(String scenarioId, CostItem item) async {
    // Get the scenario
    final scenario = _scenarios[scenarioId];
    if (scenario == null) {
      throw Exception('Scenario not found');
    }
    
    // Find the item index
    final itemIndex = scenario.costItems.indexWhere((i) => i.id == item.id);
    if (itemIndex == -1) {
      throw Exception('Cost item not found');
    }
    
    // Update the item
    final updatedItems = List<CostItem>.from(scenario.costItems);
    updatedItems[itemIndex] = item;
    
    // Update the scenario
    final updatedScenario = scenario.copyWith(
      costItems: updatedItems,
      updatedAt: DateTime.now(),
    );
    
    // Update in-memory cache
    _scenarios[scenarioId] = updatedScenario;
    
    // Save to SharedPreferences
    await _saveScenarios();
    
    return updatedScenario;
  }
  
  /// Remove a cost item from a scenario
  Future<CostScenario> removeCostItem(String scenarioId, String itemId) async {
    // Get the scenario
    final scenario = _scenarios[scenarioId];
    if (scenario == null) {
      throw Exception('Scenario not found');
    }
    
    // Remove the item
    final updatedItems = scenario.costItems.where((item) => item.id != itemId).toList();
    
    // Update the scenario
    final updatedScenario = scenario.copyWith(
      costItems: updatedItems,
      updatedAt: DateTime.now(),
    );
    
    // Update in-memory cache
    _scenarios[scenarioId] = updatedScenario;
    
    // Save to SharedPreferences
    await _saveScenarios();
    
    return updatedScenario;
  }
  
  /// Convert a cost from one currency to another
  Future<double> convertCurrency(double amount, String fromCurrencyCode, String toCurrencyCode) async {
    // Load currencies if not already loaded
    if (_currencies.isEmpty) {
      await _loadCurrencies();
    }
    
    // Get the currencies
    final fromCurrency = _currencies[fromCurrencyCode.toUpperCase()];
    final toCurrency = _currencies[toCurrencyCode.toUpperCase()];
    
    if (fromCurrency == null || toCurrency == null) {
      throw Exception('Currency not found');
    }
    
    // Convert the amount
    return fromCurrency.convert(amount, toCurrency);
  }
  
  /// Get default cost items for a new scenario
  List<CostItem> getDefaultCostItems() {
    return [
      CostItem(
        id: 'item_tuition',
        name: 'Tuition Fees',
        category: CostCategory.tuition,
        amount: 3500,
        period: TimePeriod.semester,
        isRequired: true,
        isCustom: false,
      ),
      CostItem(
        id: 'item_accommodation',
        name: 'Student Housing',
        category: CostCategory.accommodation,
        amount: 400,
        period: TimePeriod.monthly,
        isRequired: true,
        isCustom: false,
      ),
      CostItem(
        id: 'item_food',
        name: 'Food & Groceries',
        category: CostCategory.food,
        amount: 300,
        period: TimePeriod.monthly,
        isRequired: true,
        isCustom: false,
      ),
      CostItem(
        id: 'item_transportation',
        name: 'Public Transportation',
        category: CostCategory.transportation,
        amount: 50,
        period: TimePeriod.monthly,
        isRequired: true,
        isCustom: false,
      ),
      CostItem(
        id: 'item_health',
        name: 'Health Insurance',
        category: CostCategory.healthInsurance,
        amount: 200,
        period: TimePeriod.annual,
        isRequired: true,
        isCustom: false,
      ),
      CostItem(
        id: 'item_books',
        name: 'Books & Supplies',
        category: CostCategory.books,
        amount: 150,
        period: TimePeriod.semester,
        isRequired: true,
        isCustom: false,
      ),
      CostItem(
        id: 'item_utilities',
        name: 'Utilities (Electricity, Water, Internet)',
        category: CostCategory.utilities,
        amount: 80,
        period: TimePeriod.monthly,
        isRequired: true,
        isCustom: false,
      ),
      CostItem(
        id: 'item_entertainment',
        name: 'Entertainment & Leisure',
        category: CostCategory.entertainment,
        amount: 100,
        period: TimePeriod.monthly,
        isRequired: false,
        isCustom: false,
      ),
      CostItem(
        id: 'item_visa',
        name: 'Visa Application Fee',
        category: CostCategory.other,
        amount: 60,
        period: TimePeriod.oneTime,
        isRequired: true,
        isCustom: false,
      ),
      CostItem(
        id: 'item_flight',
        name: 'Flight Ticket',
        category: CostCategory.other,
        amount: 300,
        period: TimePeriod.oneTime,
        isRequired: true,
        isCustom: false,
      ),
    ];
  }
  
  /// Load scenarios from SharedPreferences
  Future<void> _loadScenarios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scenariosJson = prefs.getStringList(_scenariosKey);
      
      if (scenariosJson == null || scenariosJson.isEmpty) {
        // No saved scenarios, create a default one
        await _createDefaultScenario();
        return;
      }
      
      // Parse scenarios
      for (final json in scenariosJson) {
        try {
          final map = jsonDecode(json) as Map<String, dynamic>;
          final scenario = CostScenario.fromMap(map);
          _scenarios[scenario.id] = scenario;
        } catch (e) {
          debugPrint('Error parsing scenario: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading scenarios: $e');
    }
  }
  
  /// Save scenarios to SharedPreferences
  Future<void> _saveScenarios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scenariosJson = _scenarios.values.map((scenario) => 
        jsonEncode(scenario.toMap())
      ).toList();
      
      await prefs.setStringList(_scenariosKey, scenariosJson);
    } catch (e) {
      debugPrint('Error saving scenarios: $e');
    }
  }
  
  /// Create a default scenario
  Future<void> _createDefaultScenario() async {
    final defaultScenario = await createScenario(
      name: 'Standard Student Budget',
      description: 'A typical budget for studying in Cyprus',
      durationMonths: 12,
      currencyCode: 'EUR',
      initialCostItems: getDefaultCostItems(),
    );
    
    _scenarios[defaultScenario.id] = defaultScenario;
  }
  
  /// Load currencies from SharedPreferences or create defaults
  Future<void> _loadCurrencies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currenciesJson = prefs.getStringList(_currenciesKey);
      
      if (currenciesJson == null || currenciesJson.isEmpty) {
        // No saved currencies, create defaults
        _createDefaultCurrencies();
        return;
      }
      
      // Parse currencies
      for (final json in currenciesJson) {
        try {
          final map = jsonDecode(json) as Map<String, dynamic>;
          final currency = Currency(
            code: map['code'],
            name: map['name'],
            symbol: map['symbol'],
            conversionRateToEUR: map['conversionRateToEUR']?.toDouble() ?? 1.0,
          );
          _currencies[currency.code] = currency;
        } catch (e) {
          debugPrint('Error parsing currency: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading currencies: $e');
      // Create defaults if there was an error
      _createDefaultCurrencies();
    }
  }
  
  /// Create default currencies
  void _createDefaultCurrencies() {
    final defaultCurrencies = [
      Currency(
        code: 'EUR',
        name: 'Euro',
        symbol: '€',
        conversionRateToEUR: 1.0,
      ),
      Currency(
        code: 'USD',
        name: 'US Dollar',
        symbol: '\$',
        conversionRateToEUR: 0.85,
      ),
      Currency(
        code: 'GBP',
        name: 'British Pound',
        symbol: '£',
        conversionRateToEUR: 1.15,
      ),
      Currency(
        code: 'RUB',
        name: 'Russian Ruble',
        symbol: '₽',
        conversionRateToEUR: 0.01,
      ),
      Currency(
        code: 'CNY',
        name: 'Chinese Yuan',
        symbol: '¥',
        conversionRateToEUR: 0.13,
      ),
      Currency(
        code: 'INR',
        name: 'Indian Rupee',
        symbol: '₹',
        conversionRateToEUR: 0.011,
      ),
      Currency(
        code: 'NGN',
        name: 'Nigerian Naira',
        symbol: '₦',
        conversionRateToEUR: 0.0022,
      ),
    ];
    
    for (final currency in defaultCurrencies) {
      _currencies[currency.code] = currency;
    }
    
    // Save to SharedPreferences
    _saveCurrencies();
  }
  
  /// Save currencies to SharedPreferences
  Future<void> _saveCurrencies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currenciesJson = _currencies.values.map((currency) => 
        jsonEncode({
          'code': currency.code,
          'name': currency.name,
          'symbol': currency.symbol,
          'conversionRateToEUR': currency.conversionRateToEUR,
        })
      ).toList();
      
      await prefs.setStringList(_currenciesKey, currenciesJson);
    } catch (e) {
      debugPrint('Error saving currencies: $e');
    }
  }
  
  /// Update currency conversion rates
  Future<void> updateCurrencyRates(Map<String, double> rates) async {
    // Load currencies if not already loaded
    if (_currencies.isEmpty) {
      await _loadCurrencies();
    }
    
    // Update rates
    for (final entry in rates.entries) {
      final currency = _currencies[entry.key.toUpperCase()];
      if (currency != null) {
        _currencies[entry.key.toUpperCase()] = Currency(
          code: currency.code,
          name: currency.name,
          symbol: currency.symbol,
          conversionRateToEUR: entry.value,
        );
      }
    }
    
    // Save to SharedPreferences
    await _saveCurrencies();
  }
}
