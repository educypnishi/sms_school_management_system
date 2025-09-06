import 'package:flutter/material.dart';
import '../models/program_comparison_model.dart';
import '../services/program_comparison_service.dart';
import '../theme/app_theme.dart';
import 'program_comparison_screen.dart';

class SavedComparisonsScreen extends StatefulWidget {
  final String userId;

  const SavedComparisonsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<SavedComparisonsScreen> createState() => _SavedComparisonsScreenState();
}

class _SavedComparisonsScreenState extends State<SavedComparisonsScreen> {
  final ProgramComparisonService _comparisonService = ProgramComparisonService();
  
  bool _isLoading = true;
  List<ProgramComparisonModel> _comparisons = [];
  
  @override
  void initState() {
    super.initState();
    _loadComparisons();
  }
  
  Future<void> _loadComparisons() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // For demo purposes, generate sample data if it doesn't exist
      await _comparisonService.generateSampleComparisons(widget.userId);
      
      // Get user comparisons
      final comparisons = await _comparisonService.getUserComparisons(widget.userId);
      
      setState(() {
        _comparisons = comparisons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading comparisons: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _deleteComparison(String comparisonId) async {
    try {
      await _comparisonService.deleteComparison(comparisonId, widget.userId);
      
      // Refresh comparisons
      await _loadComparisons();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comparison deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting comparison: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showDeleteConfirmationDialog(String comparisonId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comparison'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComparison(comparisonId);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _viewComparison(String comparisonId) {
    // In a real app, we would navigate to the comparison screen with the comparison ID
    // For now, we'll just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Viewing comparison details will be available in the next update'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  void _createNewComparison() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProgramComparisonScreen(
          userId: widget.userId,
        ),
      ),
    ).then((_) => _loadComparisons());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Comparisons'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadComparisons,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewComparison,
        tooltip: 'Create New Comparison',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_comparisons.isEmpty) {
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
              'No Saved Comparisons',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a new comparison to get started',
              style: TextStyle(color: AppTheme.lightTextColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewComparison,
              icon: const Icon(Icons.add),
              label: const Text('Create New Comparison'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _comparisons.length,
      itemBuilder: (context, index) {
        final comparison = _comparisons[index];
        return _buildComparisonCard(comparison);
      },
    );
  }
  
  Widget _buildComparisonCard(ProgramComparisonModel comparison) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _viewComparison(comparison.id!),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and date
              Row(
                children: [
                  Expanded(
                    child: Text(
                      comparison.title ?? 'Untitled Comparison',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(comparison.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.lightTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Programs being compared
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: comparison.programs.map((program) {
                  return Chip(
                    label: Text(program.title),
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _viewComparison(comparison.id!),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showDeleteConfirmationDialog(
                      comparison.id!,
                      comparison.title ?? 'Untitled Comparison',
                    ),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
