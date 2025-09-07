import 'package:flutter/material.dart';
import '../models/university_model.dart';
import '../services/university_service.dart';
import '../theme/app_theme.dart';
import 'university_detail_screen.dart';

class UniversityComparisonScreen extends StatefulWidget {
  const UniversityComparisonScreen({super.key});

  @override
  State<UniversityComparisonScreen> createState() => _UniversityComparisonScreenState();
}

class _UniversityComparisonScreenState extends State<UniversityComparisonScreen> {
  final UniversityService _universityService = UniversityService();
  bool _isLoading = true;
  List<UniversityModel> _comparisonList = [];
  List<UniversityModel> _allUniversities = [];
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
      final comparisonList = await _universityService.getComparisonList();
      final allUniversities = await _universityService.getAllUniversities();
      
      setState(() {
        _comparisonList = comparisonList;
        _allUniversities = allUniversities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading universities: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _addToComparison(String universityId) async {
    try {
      final success = await _universityService.addToComparison(universityId);
      
      if (success) {
        await _loadData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can compare up to 3 universities at a time'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding university to comparison: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _removeFromComparison(String universityId) async {
    try {
      await _universityService.removeFromComparison(universityId);
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing university from comparison: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _clearComparison() async {
    try {
      await _universityService.clearComparisonList();
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing comparison list: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _saveComparison() async {
    final nameController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Comparison'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a name for this comparison:'),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Comparison Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
    
    if (result == true && nameController.text.isNotEmpty) {
      try {
        final universityIds = _comparisonList.map((u) => u.id).toList();
        await _universityService.saveComparisonResult(nameController.text, universityIds);
        
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
  }
  
  void _searchUniversities(String query) {
    setState(() {
      _searchQuery = query;
    });
  }
  
  List<UniversityModel> get _filteredUniversities {
    if (_searchQuery.isEmpty) {
      return _allUniversities;
    }
    
    final queryLower = _searchQuery.toLowerCase();
    return _allUniversities.where((university) {
      return university.name.toLowerCase().contains(queryLower) ||
          university.location.toLowerCase().contains(queryLower);
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('University Comparison'),
        actions: [
          if (_comparisonList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save Comparison',
              onPressed: _saveComparison,
            ),
          if (_comparisonList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear Comparison',
              onPressed: _clearComparison,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Comparison section
                if (_comparisonList.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Comparison',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 200,
                          child: _buildComparisonTable(),
                        ),
                      ],
                    ),
                  ),
                
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search Universities',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _searchUniversities,
                  ),
                ),
                
                // University list
                Expanded(
                  child: _filteredUniversities.isEmpty
                      ? const Center(
                          child: Text('No universities found'),
                        )
                      : ListView.builder(
                          itemCount: _filteredUniversities.length,
                          itemBuilder: (context, index) {
                            final university = _filteredUniversities[index];
                            final isInComparison = _comparisonList.any((u) => u.id == university.id);
                            
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primaryColor,
                                  child: Text(
                                    university.name.substring(0, 1),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(university.name),
                                subtitle: Text(university.location),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isInComparison ? Icons.remove_circle : Icons.add_circle,
                                        color: isInComparison ? Colors.red : Colors.green,
                                      ),
                                      tooltip: isInComparison ? 'Remove from Comparison' : 'Add to Comparison',
                                      onPressed: () {
                                        if (isInComparison) {
                                          _removeFromComparison(university.id);
                                        } else {
                                          _addToComparison(university.id);
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.info),
                                      tooltip: 'View Details',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => UniversityDetailScreen(
                                              universityId: university.id,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UniversityDetailScreen(
                                        universityId: university.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildComparisonTable() {
    if (_comparisonList.isEmpty) {
      return const Center(
        child: Text('Add universities to compare'),
      );
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowHeight: 40,
        dataRowHeight: 30,
        columns: [
          const DataColumn(label: Text('Criteria')),
          ..._comparisonList.map((university) => DataColumn(
            label: Text(university.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          )),
        ],
        rows: [
          // Type
          DataRow(cells: [
            const DataCell(Text('Type')),
            ..._comparisonList.map((university) => DataCell(
              Text(university.universityType),
            )),
          ]),
          
          // Founded
          DataRow(cells: [
            const DataCell(Text('Founded')),
            ..._comparisonList.map((university) => DataCell(
              Text(university.foundedYear.toString()),
            )),
          ]),
          
          // Students
          DataRow(cells: [
            const DataCell(Text('Students')),
            ..._comparisonList.map((university) => DataCell(
              Text(university.studentCount.toString()),
            )),
          ]),
          
          // Faculty
          DataRow(cells: [
            const DataCell(Text('Faculty')),
            ..._comparisonList.map((university) => DataCell(
              Text(university.facultyCount.toString()),
            )),
          ]),
          
          // Student-Faculty Ratio
          DataRow(cells: [
            const DataCell(Text('Student-Faculty Ratio')),
            ..._comparisonList.map((university) => DataCell(
              Text(university.formattedStudentFacultyRatio),
            )),
          ]),
          
          // Rating
          DataRow(cells: [
            const DataCell(Text('Rating')),
            ..._comparisonList.map((university) => DataCell(
              Row(
                children: [
                  Text(university.rating.toString()),
                  const SizedBox(width: 4),
                  Icon(Icons.star, size: 16, color: Colors.amber),
                ],
              ),
            )),
          ]),
          
          // Tuition Fee Range
          DataRow(cells: [
            const DataCell(Text('Tuition Fee Range')),
            ..._comparisonList.map((university) => DataCell(
              Text(university.tuitionFeeRange),
            )),
          ]),
          
          // Programs
          DataRow(cells: [
            const DataCell(Text('Programs')),
            ..._comparisonList.map((university) => DataCell(
              Text('${university.programs.length} programs'),
            )),
          ]),
          
          // Bachelor Programs
          DataRow(cells: [
            const DataCell(Text('Bachelor Programs')),
            ..._comparisonList.map((university) => DataCell(
              Text(university.bachelorProgramCount.toString()),
            )),
          ]),
          
          // Master Programs
          DataRow(cells: [
            const DataCell(Text('Master Programs')),
            ..._comparisonList.map((university) => DataCell(
              Text(university.masterProgramCount.toString()),
            )),
          ]),
          
          // PhD Programs
          DataRow(cells: [
            const DataCell(Text('PhD Programs')),
            ..._comparisonList.map((university) => DataCell(
              Text(university.phdProgramCount.toString()),
            )),
          ]),
        ],
      ),
    );
  }
}
