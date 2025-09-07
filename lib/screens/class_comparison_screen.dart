import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../services/class_service.dart';
import '../theme/app_theme.dart';
import 'class_detail_screen.dart';

class ClassComparisonScreen extends StatefulWidget {
  const ClassComparisonScreen({super.key});

  @override
  State<ClassComparisonScreen> createState() => _ClassComparisonScreenState();
}

class _ClassComparisonScreenState extends State<ClassComparisonScreen> {
  final ClassService _classService = ClassService();
  bool _isLoading = true;
  List<ClassModel> _comparisonList = [];
  List<ClassModel> _allClasses = [];
  String _searchQuery = '';
  
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
      final comparisonList = await _classService.getComparisonList();
      final allClasses = await _classService.getAllClasses();
      
      setState(() {
        _comparisonList = comparisonList;
        _allClasses = allClasses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading classes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _addToComparison(String classId) async {
    try {
      final success = await _classService.addToComparison(classId);
      
      if (success) {
        await _loadData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can compare up to 3 classes at a time'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding class to comparison: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _removeFromComparison(String classId) async {
    try {
      await _classService.removeFromComparison(classId);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing class from comparison: $e'),
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
        title: const Text('Class Comparison'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search classes...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                
                // Comparison section
                if (_comparisonList.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    color: Colors.grey[100],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Comparing Classes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildComparisonTable(),
                      ],
                    ),
                  ),
                ],
                
                // Available classes
                Expanded(
                  child: _filteredClasses.isEmpty
                      ? const Center(
                          child: Text('No classes found'),
                        )
                      : ListView.builder(
                          itemCount: _filteredClasses.length,
                          itemBuilder: (context, index) {
                            final classItem = _filteredClasses[index];
                            final isInComparison = _comparisonList.any((c) => c.id == classItem.id);
                            
                            return _buildClassCard(classItem, isInComparison);
                          },
                        ),
                ),
              ],
            ),
    );
  }
  
  List<ClassModel> get _filteredClasses {
    if (_searchQuery.isEmpty) {
      return _allClasses;
    }
    
    final query = _searchQuery.toLowerCase();
    return _allClasses.where((classItem) {
      return classItem.name.toLowerCase().contains(query) ||
          classItem.grade.toLowerCase().contains(query) ||
          classItem.teacherName.toLowerCase().contains(query) ||
          classItem.subject.toLowerCase().contains(query);
    }).toList();
  }
  
  Widget _buildClassCard(ClassModel classItem, bool isInComparison) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          classItem.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${classItem.grade} • ${classItem.subject} • ${classItem.teacherName}',
        ),
        trailing: IconButton(
          icon: Icon(
            isInComparison ? Icons.remove_circle : Icons.add_circle,
            color: isInComparison ? Colors.red : Colors.green,
          ),
          onPressed: () {
            if (isInComparison) {
              _removeFromComparison(classItem.id);
            } else {
              _addToComparison(classItem.id);
            }
          },
          tooltip: isInComparison ? 'Remove from comparison' : 'Add to comparison',
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassDetailScreen(classId: classItem.id),
            ),
          ).then((_) => _loadData());
        },
      ),
    );
  }
  
  Widget _buildComparisonTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        columns: [
          const DataColumn(label: Text('Feature')),
          ..._comparisonList.map((classItem) => DataColumn(
            label: Text(
              classItem.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          )).toList(),
        ],
        rows: [
          _buildDataRow('Grade', (c) => c.grade),
          _buildDataRow('Subject', (c) => c.subject),
          _buildDataRow('Teacher', (c) => c.teacherName),
          _buildDataRow('Schedule', (c) => c.schedule),
          _buildDataRow('Room', (c) => c.room),
          _buildDataRow('Capacity', (c) => c.capacity.toString()),
          _buildDataRow('Current Students', (c) => c.currentStudents.toString()),
          _buildDataRow('Average Grade', (c) => '${c.averageGrade.toStringAsFixed(1)}/100'),
        ],
      ),
    );
  }
  
  DataRow _buildDataRow(String feature, String Function(ClassModel) getValue) {
    return DataRow(
      cells: [
        DataCell(Text(
          feature,
          style: const TextStyle(fontWeight: FontWeight.bold),
        )),
        ..._comparisonList.map((classItem) => DataCell(
          Text(getValue(classItem)),
        )).toList(),
      ],
    );
  }
}
