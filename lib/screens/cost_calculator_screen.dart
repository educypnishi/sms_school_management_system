import 'package:flutter/material.dart';
import '../models/cost_calculator_model.dart';
import '../services/cost_calculator_service.dart';
import '../theme/app_theme.dart';
import 'cost_breakdown_screen.dart';

class CostCalculatorScreen extends StatefulWidget {
  const CostCalculatorScreen({super.key});

  @override
  State<CostCalculatorScreen> createState() => _CostCalculatorScreenState();
}

class _CostCalculatorScreenState extends State<CostCalculatorScreen> {
  final CostCalculatorService _costCalculatorService = CostCalculatorService();
  bool _isLoading = true;
  List<CostScenario> _scenarios = [];
  CostScenario? _selectedScenario;
  List<Currency> _currencies = [];
  Currency? _selectedCurrency;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load scenarios
      final scenarios = await _costCalculatorService.getAllScenarios();
      
      // Load currencies
      final currencies = await _costCalculatorService.getAllCurrencies();
      
      setState(() {
        _scenarios = scenarios;
        _currencies = currencies;
        _selectedScenario = scenarios.isNotEmpty ? scenarios.first : null;
        _selectedCurrency = currencies.firstWhere(
          (c) => c.code == (_selectedScenario?.currencyCode ?? 'EUR'),
          orElse: () => currencies.first,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _createNewScenario() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    int durationMonths = 12;
    String currencyCode = 'EUR';
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Scenario'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Scenario Name',
                  hintText: 'e.g., My Study Budget',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g., Budget for studying at University of Cyprus',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Text('Duration:'),
              DropdownButtonFormField<int>(
                value: durationMonths,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 6, child: const Text('6 months')),
                  DropdownMenuItem(value: 12, child: const Text('1 year')),
                  DropdownMenuItem(value: 24, child: const Text('2 years')),
                  DropdownMenuItem(value: 36, child: const Text('3 years')),
                  DropdownMenuItem(value: 48, child: const Text('4 years')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    durationMonths = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Currency:'),
              DropdownButtonFormField<String>(
                value: currencyCode,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: _currencies.map((currency) => DropdownMenuItem(
                  value: currency.code,
                  child: Text('${currency.code} (${currency.symbol})'),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    currencyCode = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    
    if (result == true && nameController.text.isNotEmpty) {
      try {
        final newScenario = await _costCalculatorService.createScenario(
          name: nameController.text,
          description: descriptionController.text,
          durationMonths: durationMonths,
          currencyCode: currencyCode,
          initialCostItems: _costCalculatorService.getDefaultCostItems(),
        );
        
        setState(() {
          _scenarios = [..._scenarios, newScenario];
          _selectedScenario = newScenario;
          _selectedCurrency = _currencies.firstWhere(
            (c) => c.code == currencyCode,
            orElse: () => _currencies.first,
          );
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scenario created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating scenario: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _deleteScenario(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scenario'),
        content: const Text('Are you sure you want to delete this scenario? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await _costCalculatorService.deleteScenario(id);
        
        // Reload scenarios
        final scenarios = await _costCalculatorService.getAllScenarios();
        
        setState(() {
          _scenarios = scenarios;
          _selectedScenario = scenarios.isNotEmpty ? scenarios.first : null;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scenario deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting scenario: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _changeCurrency(String currencyCode) async {
    final currency = _currencies.firstWhere(
      (c) => c.code == currencyCode,
      orElse: () => _currencies.first,
    );
    
    setState(() {
      _selectedCurrency = currency;
    });
  }
  
  Future<void> _viewBreakdown() async {
    if (_selectedScenario == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CostBreakdownScreen(
          scenarioId: _selectedScenario!.id,
          currencyCode: _selectedCurrency?.code ?? 'EUR',
        ),
      ),
    ).then((_) => _loadData());
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cost Calculator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scenarios.isEmpty
              ? _buildEmptyState()
              : _buildCalculator(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewScenario,
        tooltip: 'Create New Scenario',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calculate,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Cost Scenarios Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a new scenario to calculate your study costs',
            style: TextStyle(color: AppTheme.lightTextColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewScenario,
            icon: const Icon(Icons.add),
            label: const Text('Create New Scenario'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCalculator() {
    if (_selectedScenario == null) {
      return const Center(
        child: Text('No scenario selected'),
      );
    }
    
    // Calculate costs
    final totalCost = _selectedScenario!.totalCost;
    final monthlyCost = _selectedScenario!.monthlyCost;
    final oneTimeCosts = _selectedScenario!.oneTimeCosts;
    final recurringCosts = _selectedScenario!.recurringCosts;
    
    // Get currency symbol
    final currencySymbol = _selectedCurrency?.symbol ?? '€';
    
    // Convert costs if needed
    double convertedTotalCost = totalCost;
    double convertedMonthlyCost = monthlyCost;
    double convertedOneTimeCosts = oneTimeCosts;
    double convertedRecurringCosts = recurringCosts;
    
    if (_selectedCurrency != null && 
        _selectedCurrency!.code != _selectedScenario!.currencyCode) {
      // This is a simplified conversion for the UI
      // The actual conversion should be done through the service
      final conversionRate = _selectedCurrency!.conversionRateToEUR / 
          _currencies.firstWhere(
            (c) => c.code == _selectedScenario!.currencyCode,
            orElse: () => _currencies.first,
          ).conversionRateToEUR;
      
      convertedTotalCost = totalCost * conversionRate;
      convertedMonthlyCost = monthlyCost * conversionRate;
      convertedOneTimeCosts = oneTimeCosts * conversionRate;
      convertedRecurringCosts = recurringCosts * conversionRate;
    }
    
    return Column(
      children: [
        // Scenario selector
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedScenario!.id,
                      decoration: const InputDecoration(
                        labelText: 'Select Scenario',
                        border: OutlineInputBorder(),
                      ),
                      items: _scenarios.map((scenario) => DropdownMenuItem(
                        value: scenario.id,
                        child: Text(scenario.name),
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedScenario = _scenarios.firstWhere(
                              (s) => s.id == value,
                            );
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete Scenario',
                    onPressed: () => _deleteScenario(_selectedScenario!.id),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _selectedScenario!.description,
                style: const TextStyle(
                  color: AppTheme.lightTextColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Duration:'),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedScenario!.durationMonths} months',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const Text('Currency:'),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedCurrency?.code ?? 'EUR',
                    items: _currencies.map((currency) => DropdownMenuItem(
                      value: currency.code,
                      child: Text('${currency.code} (${currency.symbol})'),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _changeCurrency(value);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Cost summary
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cost Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Total cost card
                Card(
                  color: AppTheme.primaryColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Cost',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$currencySymbol ${convertedTotalCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'for ${_selectedScenario!.durationMonths} months',
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Cost breakdown cards
                Row(
                  children: [
                    Expanded(
                      child: _buildCostCard(
                        'Monthly Cost',
                        convertedMonthlyCost,
                        currencySymbol,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCostCard(
                        'One-time Costs',
                        convertedOneTimeCosts,
                        currencySymbol,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildCostCard(
                        'Recurring Costs',
                        convertedRecurringCosts,
                        currencySymbol,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCostCard(
                        'Cost per Day',
                        convertedMonthlyCost / 30,
                        currencySymbol,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Category breakdown
                const Text(
                  'Cost by Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Category list
                ..._buildCategoryList(),
                
                const SizedBox(height: 24),
                
                // View detailed breakdown button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _viewBreakdown,
                    icon: const Icon(Icons.pie_chart),
                    label: const Text('View Detailed Breakdown'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCostCard(String title, double amount, String currencySymbol, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$currencySymbol ${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildCategoryList() {
    if (_selectedScenario == null) return [];
    
    final costByCategory = _selectedScenario!.costByCategory;
    final totalCost = _selectedScenario!.totalCost;
    
    // Sort categories by cost (highest first)
    final sortedCategories = costByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Get currency symbol
    final currencySymbol = _selectedCurrency?.symbol ?? '€';
    
    return sortedCategories.map((entry) {
      final category = entry.key;
      final cost = entry.value;
      final percentage = totalCost > 0 ? (cost / totalCost * 100) : 0;
      
      // Convert cost if needed
      double convertedCost = cost;
      if (_selectedCurrency != null && 
          _selectedCurrency!.code != _selectedScenario!.currencyCode) {
        final conversionRate = _selectedCurrency!.conversionRateToEUR / 
            _currencies.firstWhere(
              (c) => c.code == _selectedScenario!.currencyCode,
              orElse: () => _currencies.first,
            ).conversionRateToEUR;
        
        convertedCost = cost * conversionRate;
      }
      
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                category.icon,
                color: category.color,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(category.color),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$currencySymbol ${convertedCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
