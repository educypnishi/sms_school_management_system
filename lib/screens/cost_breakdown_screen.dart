import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/cost_calculator_model.dart';
import '../services/cost_calculator_service.dart';
import '../theme/app_theme.dart';

class CostBreakdownScreen extends StatefulWidget {
  final String scenarioId;
  final String currencyCode;
  
  const CostBreakdownScreen({
    super.key,
    required this.scenarioId,
    required this.currencyCode,
  });

  @override
  State<CostBreakdownScreen> createState() => _CostBreakdownScreenState();
}

class _CostBreakdownScreenState extends State<CostBreakdownScreen> with SingleTickerProviderStateMixin {
  final CostCalculatorService _costCalculatorService = CostCalculatorService();
  bool _isLoading = true;
  CostScenario? _scenario;
  Currency? _currency;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load scenario
      final scenario = await _costCalculatorService.getScenario(widget.scenarioId);
      
      // Load currency
      final currency = await _costCalculatorService.getCurrency(widget.currencyCode);
      
      setState(() {
        _scenario = scenario;
        _currency = currency;
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_scenario?.name ?? 'Cost Breakdown'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chart'),
            Tab(text: 'Items'),
            Tab(text: 'Summary'),
          ],
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _scenario == null
              ? const Center(child: Text('Scenario not found'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChartTab(),
                    _buildItemsTab(),
                    _buildSummaryTab(),
                  ],
                ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _addCostItem,
              tooltip: 'Add Cost Item',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  Widget _buildChartTab() {
    if (_scenario == null) {
      return const Center(child: Text('No data available'));
    }
    
    final costByCategory = _scenario!.costByCategory;
    final totalCost = _scenario!.totalCost;
    
    // Filter out categories with zero cost
    final nonZeroCategories = costByCategory.entries
        .where((entry) => entry.value > 0)
        .toList();
    
    // Sort by cost (highest first)
    nonZeroCategories.sort((a, b) => b.value.compareTo(a.value));
    
    // Prepare pie chart sections
    final pieChartSections = <PieChartSectionData>[];
    
    for (var i = 0; i < nonZeroCategories.length; i++) {
      final entry = nonZeroCategories[i];
      final category = entry.key;
      final cost = entry.value;
      final percentage = totalCost > 0 ? (cost / totalCost * 100) : 0;
      
      pieChartSections.add(
        PieChartSectionData(
          color: category.color,
          value: cost,
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: nonZeroCategories.length <= 5 ? Icon(
            category.icon,
            size: 20,
            color: Colors.white,
          ) : null,
          badgePositionPercentageOffset: 0.8,
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cost Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Pie chart
          SizedBox(
            height: 300,
            child: nonZeroCategories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.pie_chart_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No cost data available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sections: pieChartSections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      startDegreeOffset: -90,
                      centerSpaceColor: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          
          // Legend
          const Text(
            'Legend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Category list
          ...nonZeroCategories.map((entry) {
            final category = entry.key;
            final cost = entry.value;
            final percentage = totalCost > 0 ? (cost / totalCost * 100) : 0;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: category.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    category.icon,
                    size: 16,
                    color: category.color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(category.displayName),
                  ),
                  Text(
                    '${(_currency?.symbol ?? '€')} ${cost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${percentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          const SizedBox(height: 24),
          
          // Total
          Card(
            color: AppTheme.primaryColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Total Cost:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_currency?.symbol ?? '€'} ${totalCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildItemsTab() {
    if (_scenario == null || _scenario!.costItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.list_alt,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Cost Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add cost items to your scenario',
              style: TextStyle(color: AppTheme.lightTextColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addCostItem,
              icon: const Icon(Icons.add),
              label: const Text('Add Cost Item'),
            ),
          ],
        ),
      );
    }
    
    // Group items by category
    final itemsByCategory = <CostCategory, List<CostItem>>{};
    for (final category in CostCategory.values) {
      final items = _scenario!.costItems
          .where((item) => item.category == category)
          .toList();
      
      if (items.isNotEmpty) {
        itemsByCategory[category] = items;
      }
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in itemsByCategory.entries)
          _buildCategorySection(entry.key, entry.value),
      ],
    );
  }
  
  Widget _buildCategorySection(CostCategory category, List<CostItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              category.icon,
              color: category.color,
            ),
            const SizedBox(width: 8),
            Text(
              category.displayName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => _buildCostItemCard(item)),
        const SizedBox(height: 16),
      ],
    );
  }
  
  Widget _buildCostItemCard(CostItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.name),
        subtitle: Text(item.period.displayName),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_currency?.symbol ?? '€'} ${item.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editCostItem(item),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteCostItem(item.id),
            ),
          ],
        ),
        leading: CircleAvatar(
          backgroundColor: item.category.color.withOpacity(0.2),
          child: Icon(
            item.category.icon,
            color: item.category.color,
            size: 20,
          ),
        ),
      ),
    );
  }
  
  Widget _buildSummaryTab() {
    if (_scenario == null) {
      return const Center(child: Text('No data available'));
    }
    
    final totalCost = _scenario!.totalCost;
    final monthlyCost = _scenario!.monthlyCost;
    final oneTimeCosts = _scenario!.oneTimeCosts;
    final recurringCosts = _scenario!.recurringCosts;
    
    return SingleChildScrollView(
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
                    '${_currency?.symbol ?? '€'} ${totalCost.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'for ${_scenario!.durationMonths} months',
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
                child: _buildSummaryCard(
                  'Monthly Cost',
                  monthlyCost,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'One-time Costs',
                  oneTimeCosts,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Recurring Costs',
                  recurringCosts,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Daily Cost',
                  monthlyCost / 30,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard(String title, double amount, Color color) {
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
              '${_currency?.symbol ?? '€'} ${amount.toStringAsFixed(2)}',
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
  
  Future<void> _addCostItem() async {
    if (_scenario == null) return;
    
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    CostCategory category = CostCategory.other;
    TimePeriod period = TimePeriod.monthly;
    bool isRequired = true;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Cost Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'e.g., Gym Membership',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  border: const OutlineInputBorder(),
                  prefixText: _currency?.symbol ?? '€',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text('Category:'),
              DropdownButtonFormField<CostCategory>(
                value: category,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: CostCategory.values.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat.displayName),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    category = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Period:'),
              DropdownButtonFormField<TimePeriod>(
                value: period,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: TimePeriod.values.map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(p.displayName),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    period = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Required Expense'),
                value: isRequired,
                onChanged: (value) {
                  if (value != null) {
                    isRequired = value;
                  }
                },
                controlAffinity: ListTileControlAffinity.leading,
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
            child: const Text('Add'),
          ),
        ],
      ),
    );
    
    if (result == true && 
        nameController.text.isNotEmpty && 
        amountController.text.isNotEmpty) {
      try {
        final amount = double.tryParse(amountController.text) ?? 0;
        
        if (amount <= 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Amount must be greater than zero'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        final costItem = CostItem(
          id: 'item_${DateTime.now().millisecondsSinceEpoch}',
          name: nameController.text,
          category: category,
          amount: amount,
          period: period,
          isRequired: isRequired,
          isCustom: true,
        );
        
        await _costCalculatorService.addCostItem(_scenario!.id, costItem);
        
        // Reload data
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cost item added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding cost item: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _editCostItem(CostItem item) async {
    if (_scenario == null) return;
    
    final nameController = TextEditingController(text: item.name);
    final amountController = TextEditingController(text: item.amount.toString());
    CostCategory category = item.category;
    TimePeriod period = item.period;
    bool isRequired = item.isRequired;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Cost Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: const OutlineInputBorder(),
                  prefixText: _currency?.symbol ?? '€',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text('Category:'),
              DropdownButtonFormField<CostCategory>(
                value: category,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: CostCategory.values.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat.displayName),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    category = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Period:'),
              DropdownButtonFormField<TimePeriod>(
                value: period,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: TimePeriod.values.map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(p.displayName),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    period = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Required Expense'),
                value: isRequired,
                onChanged: (value) {
                  if (value != null) {
                    isRequired = value;
                  }
                },
                controlAffinity: ListTileControlAffinity.leading,
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result == true && 
        nameController.text.isNotEmpty && 
        amountController.text.isNotEmpty) {
      try {
        final amount = double.tryParse(amountController.text) ?? 0;
        
        if (amount <= 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Amount must be greater than zero'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        
        final updatedItem = item.copyWith(
          name: nameController.text,
          category: category,
          amount: amount,
          period: period,
          isRequired: isRequired,
        );
        
        await _costCalculatorService.updateCostItem(_scenario!.id, updatedItem);
        
        // Reload data
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cost item updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating cost item: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  
  Future<void> _deleteCostItem(String itemId) async {
    if (_scenario == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cost Item'),
        content: const Text('Are you sure you want to delete this cost item?'),
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
        await _costCalculatorService.removeCostItem(_scenario!.id, itemId);
        
        // Reload data
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cost item deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting cost item: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
