import 'package:flutter/material.dart';
import '../utils/toast_util.dart';
import '../models/program_model.dart';
import '../services/program_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'program_detail_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final ProgramService _programService = ProgramService();
  List<ProgramModel> _courses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // For course comparison
  bool _comparisonMode = false;
  final Set<String> _selectedCourseIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final programs = await _programService.getAllPrograms();
      
      setState(() {
        _courses = programs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading courses: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ToastUtil.showToast(
      context: context,
      message: 'Error loading courses: $e',
    );
    }
  }
  
  List<ProgramModel> get _filteredCourses {
    if (_searchQuery.isEmpty) {
      return _courses;
    }
    
    final query = _searchQuery.toLowerCase();
    return _courses.where((course) {
      return course.title.toLowerCase().contains(query) ||
          course.university.toLowerCase().contains(query) ||
          course.degreeType.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Courses'),
        actions: [
          // Compare button
          if (!_comparisonMode && _courses.length >= 2)
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              onPressed: () {
                setState(() {
                  _comparisonMode = true;
                });
              },
              tooltip: 'Compare Courses',
            ),
          // View saved comparisons
          if (!_comparisonMode)
            IconButton(
              icon: const Icon(Icons.saved_search),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppConstants.savedComparisonsRoute,
                  arguments: {
                    'userId': 'user123', // Using a sample user ID for demo
                  },
                );
              },
              tooltip: 'Saved Comparisons',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCourses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Comparison mode banner
          if (_comparisonMode)
            Container(
              color: AppTheme.primaryColor.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.compare_arrows, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Select courses to compare (max 3)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '${_selectedCourseIds.length}/3 selected',
                    style: TextStyle(
                      color: _selectedCourseIds.length == 3 ? Colors.red : AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _comparisonMode = false;
                        _selectedCourseIds.clear();
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _selectedCourseIds.length >= 2
                        ? () => _compareSelectedCourses()
                        : null,
                    child: const Text('Compare'),
                  ),
                ],
              ),
            ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search courses...',
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
          
          // Courses List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCourses.isEmpty
                    ? const Center(
                        child: Text(
                          'No courses found',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredCourses.length,
                        itemBuilder: (context, index) {
                          final course = _filteredCourses[index];
                          return _buildCourseCard(course);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _toggleCourseSelection(String courseId) {
    setState(() {
      if (_selectedCourseIds.contains(courseId)) {
        _selectedCourseIds.remove(courseId);
      } else {
        // Check if we've already selected the maximum number of courses
        if (_selectedCourseIds.length < 3) {
          _selectedCourseIds.add(courseId);
        } else {
          // Show a message that max courses are selected
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can compare up to 3 courses at once'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }
  
  void _compareSelectedCourses() {
    if (_selectedCourseIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least 2 courses to compare'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Navigate to comparison screen
    Navigator.pushNamed(
      context,
      AppConstants.courseComparisonRoute,
      arguments: {
        'userId': 'user123', // Using a sample user ID for demo
        'programIds': _selectedCourseIds.toList(),
      },
    ).then((_) {
      // Reset selection mode when returning from comparison
      setState(() {
        _comparisonMode = false;
        _selectedCourseIds.clear();
      });
    });
  }
  
  Widget _buildCourseCard(ProgramModel course) {
    final bool isSelected = _selectedCourseIds.contains(course.id);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: isSelected
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppTheme.primaryColor, width: 2),
            )
          : null,
      child: InkWell(
        onTap: () {
          if (_comparisonMode) {
            _toggleCourseSelection(course.id);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProgramDetailScreen(programId: course.id),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                course.imageUrl,
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
                  // Course Title
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // School/Department
                  Row(
                    children: [
                      const Icon(
                        Icons.school,
                        size: 16,
                        color: AppTheme.lightTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        course.university,
                        style: const TextStyle(
                          color: AppTheme.lightTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Grade Level & Duration
                  Row(
                    children: [
                      const Icon(
                        Icons.badge,
                        size: 16,
                        color: AppTheme.lightTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${course.degreeType} • ${course.duration}',
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
                              builder: (context) => ProgramDetailScreen(programId: course.id),
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
