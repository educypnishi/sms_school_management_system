import 'package:flutter/material.dart';
import '../models/program_comparison_model.dart';
import '../models/program_model.dart';
import '../services/program_comparison_service.dart';
import '../services/program_service.dart';
import '../theme/app_theme.dart';
import '../widgets/program_comparison_table.dart';

class ProgramComparisonScreen extends StatefulWidget {
  final String userId;
  final List<String>? initialProgramIds;

  const ProgramComparisonScreen({
    super.key,
    required this.userId,
    this.initialProgramIds,
  });

  @override
  State<ProgramComparisonScreen> createState() => _ProgramComparisonScreenState();
}

class _ProgramComparisonScreenState extends State<ProgramComparisonScreen> {
  final ProgramComparisonService _comparisonService = ProgramComparisonService();
  final ProgramService _programService = ProgramService();
  
  bool _isLoading = true;
  ProgramComparisonModel? _comparison;
  List<ProgramModel> _availablePrograms = [];
  final TextEditingController _titleController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load available programs
      final programs = await _programService.getAllPrograms();
      
      // Create or load comparison
      ProgramComparisonModel? comparison;
      
      if (widget.initialProgramIds != null && widget.initialProgramIds!.isNotEmpty) {
        // Create a new comparison with the specified programs
        comparison = await _comparisonService.createComparison(
          widget.initialProgramIds!,
          widget.userId,
        );
      } else {
        // Create an empty comparison
        comparison = ProgramComparisonModel.createEmpty(userId: widget.userId);
      }
      
      setState(() {
        _comparison = comparison;
        _availablePrograms = programs.where((p) => 
          !(comparison?.programs.any((cp) => cp.id == p.id) ?? false)
        ).toList();
        _isLoading = false;
        
        if (comparison?.title != null) {
          _titleController.text = comparison?.title ?? '';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading comparison: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _saveComparison() async {
    if (_comparison == null) return;
    
    try {
      // Update title if provided
      final title = _titleController.text.trim();
      final updatedComparison = _comparison!.copyWith(
        title: title.isNotEmpty ? title : null,
      );
      
      // Save comparison
      final savedComparison = await _comparisonService.saveComparison(updatedComparison);
      
      setState(() {
        _comparison = savedComparison;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comparison saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving comparison: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _addProgram(ProgramModel program) {
    if (_comparison == null) return;
    
    try {
      final updatedComparison = _comparison!.addProgram(program);
      
      setState(() {
        _comparison = updatedComparison;
        _availablePrograms.removeWhere((p) => p.id == program.id);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding program: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _removeProgram(String programId) {
    if (_comparison == null) return;
    
    // Find the program to remove
    final program = _comparison!.programs.firstWhere((p) => p.id == programId);
    
    // Update comparison
    final updatedComparison = _comparison!.removeProgram(programId);
    
    setState(() {
      _comparison = updatedComparison;
      _availablePrograms.add(program);
    });
  }
  
  void _addCriterion(String criterion) {
    if (_comparison == null) return;
    
    setState(() {
      _comparison = _comparison!.addCriterion(criterion);
    });
  }
  
  void _removeCriterion(String criterion) {
    if (_comparison == null) return;
    
    setState(() {
      _comparison = _comparison!.removeCriterion(criterion);
    });
  }
  
  void _showAddProgramDialog() {
    if (_availablePrograms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more programs available to add'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Program to Compare'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availablePrograms.length,
            itemBuilder: (context, index) {
              final program = _availablePrograms[index];
              return ListTile(
                title: Text(program.title),
                subtitle: Text(program.university),
                onTap: () {
                  Navigator.pop(context);
                  _addProgram(program);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _showAddCriterionDialog() {
    if (_comparison == null) return;
    
    // Get all available criteria
    final allCriteria = ProgramComparisonModel.getAllCriteria();
    
    // Filter out criteria that are already in the comparison
    final availableCriteria = allCriteria.where(
      (c) => !_comparison!.comparisonCriteria.contains(c)
    ).toList();
    
    if (availableCriteria.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All criteria are already added'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comparison Criterion'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableCriteria.length,
            itemBuilder: (context, index) {
              final criterion = availableCriteria[index];
              return ListTile(
                leading: Icon(ProgramComparisonModel.getCriterionIcon(criterion)),
                title: Text(ProgramComparisonModel.getCriterionDisplayName(criterion)),
                onTap: () {
                  Navigator.pop(context);
                  _addCriterion(criterion);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Program Comparison Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to use Program Comparison:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Add programs to compare using the + button'),
              Text('• Add or remove criteria to customize your comparison'),
              Text('• Save your comparison for future reference'),
              Text('• You can compare up to 3 programs at once'),
              SizedBox(height: 16),
              Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Give your comparison a meaningful title'),
              Text('• Focus on the criteria that matter most to you'),
              Text('• Remove programs or criteria by clicking the X icon'),
              Text('• Scroll horizontally to see all program details'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Comparison'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _comparison != null && _comparison!.programs.length >= 2 
                ? _saveComparison 
                : null,
            tooltip: 'Save Comparison',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: _comparison != null && _comparison!.programs.length < 3
          ? FloatingActionButton(
              onPressed: _showAddProgramDialog,
              tooltip: 'Add Program',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  Widget _buildBody() {
    if (_comparison == null) {
      return const Center(
        child: Text('Error loading comparison'),
      );
    }
    
    if (_comparison!.programs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.compare_arrows,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Programs to Compare',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add programs to start comparing',
              style: TextStyle(color: AppTheme.lightTextColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddProgramDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Program'),
            ),
          ],
        ),
      );
    }
    
    if (_comparison!.programs.length == 1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.compare_arrows,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Add Another Program',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You need at least 2 programs to compare',
              style: TextStyle(color: AppTheme.lightTextColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddProgramDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Program'),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title input
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Comparison Title',
              hintText: 'Enter a title for this comparison',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          
          // Comparison table
          ProgramComparisonTable(
            comparison: _comparison!,
            onRemoveCriterion: _removeCriterion,
            onRemoveProgram: _removeProgram,
          ),
          const SizedBox(height: 24),
          
          // Add criterion button
          Center(
            child: OutlinedButton.icon(
              onPressed: _showAddCriterionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Criterion'),
            ),
          ),
          const SizedBox(height: 24),
          
          // Save button
          Center(
            child: ElevatedButton.icon(
              onPressed: _saveComparison,
              icon: const Icon(Icons.save),
              label: const Text('Save Comparison'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
