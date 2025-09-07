import 'package:flutter/material.dart';
import '../utils/toast_util.dart';
import '../models/program_model.dart';
import '../services/program_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

class CourseDetailScreen extends StatefulWidget {
  final String programId;
  
  const CourseDetailScreen({
    super.key,
    required this.programId,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final ProgramService _programService = ProgramService();
  ProgramModel? _course;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourse();
  }

  Future<void> _loadCourse() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final program = await _programService.getProgramById(widget.programId);
      
      setState(() {
        _course = program;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading course: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ToastUtil.showToast(
      context: context,
      message: 'Error loading course: $e',
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Course Details' : _course?.title ?? 'Course Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _course == null
              ? const Center(
                  child: Text(
                    'Course not found',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : _buildCourseDetails(),
    );
  }

  Widget _buildCourseDetails() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              _course!.imageUrl,
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
                  _course!.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // School/Department
                Row(
                  children: [
                    const Icon(
                      Icons.school,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _course!.university,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Course Info Cards
                Row(
                  children: [
                    _buildInfoCard('Grade', _course!.degreeType, Icons.grade),
                    const SizedBox(width: 16),
                    _buildInfoCard('Duration', _course!.duration, Icons.access_time),
                    const SizedBox(width: 16),
                    _buildInfoCard('Fee', _course!.tuitionFee, Icons.attach_money),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Description
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _course!.description,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Requirements
                const Text(
                  'Requirements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ..._course!.requirements.map((requirement) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            requirement,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 32),
                
                // Enroll Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to enrollment form
                      Navigator.pushNamed(context, AppConstants.enrollmentFormRoute);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Enroll Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(
                icon,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.lightTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
