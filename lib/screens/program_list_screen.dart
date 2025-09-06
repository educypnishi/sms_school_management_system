import 'package:flutter/material.dart';
import '../utils/toast_util.dart';
import '../models/program_model.dart';
import '../services/program_service.dart';
import '../theme/app_theme.dart';
import 'program_detail_screen.dart';

class ProgramListScreen extends StatefulWidget {
  const ProgramListScreen({super.key});

  @override
  State<ProgramListScreen> createState() => _ProgramListScreenState();
}

class _ProgramListScreenState extends State<ProgramListScreen> {
  final ProgramService _programService = ProgramService();
  List<ProgramModel> _programs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPrograms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final programs = await _programService.getAllPrograms();
      
      setState(() {
        _programs = programs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading programs: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ToastUtil.showToast(
      context: context,
      message: 'Error loading programs: $e',
    );
    }
  }
  
  List<ProgramModel> get _filteredPrograms {
    if (_searchQuery.isEmpty) {
      return _programs;
    }
    
    final query = _searchQuery.toLowerCase();
    return _programs.where((program) {
      return program.title.toLowerCase().contains(query) ||
          program.university.toLowerCase().contains(query) ||
          program.degreeType.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Programs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrograms,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search programs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
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
          
          // Programs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPrograms.isEmpty
                    ? const Center(
                        child: Text(
                          'No programs found',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredPrograms.length,
                        itemBuilder: (context, index) {
                          final program = _filteredPrograms[index];
                          return _buildProgramCard(program);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard(ProgramModel program) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProgramDetailScreen(programId: program.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Program Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                program.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Program Title
                  Text(
                    program.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // University
                  Row(
                    children: [
                      const Icon(
                        Icons.school,
                        size: 16,
                        color: AppTheme.lightTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        program.university,
                        style: const TextStyle(
                          color: AppTheme.lightTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Degree Type & Duration
                  Row(
                    children: [
                      const Icon(
                        Icons.badge,
                        size: 16,
                        color: AppTheme.lightTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${program.degreeType} • ${program.duration}',
                        style: const TextStyle(
                          color: AppTheme.lightTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // View Details Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProgramDetailScreen(programId: program.id),
                            ),
                          );
                        },
                        child: const Text('View Details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
