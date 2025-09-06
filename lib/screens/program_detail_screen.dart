import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/program_model.dart';
import '../services/program_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

class ProgramDetailScreen extends StatefulWidget {
  final String programId;
  
  const ProgramDetailScreen({
    super.key,
    required this.programId,
  });

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  final ProgramService _programService = ProgramService();
  ProgramModel? _program;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgram();
  }

  Future<void> _loadProgram() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final program = await _programService.getProgramById(widget.programId);
      
      setState(() {
        _program = program;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading program: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      Fluttertoast.showToast(
        msg: 'Error loading program: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppTheme.errorColor,
        textColor: AppTheme.whiteColor,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? 'Program Details' : _program?.title ?? 'Program Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _program == null
              ? const Center(
                  child: Text(
                    'Program not found',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : _buildProgramDetails(),
    );
  }

  Widget _buildProgramDetails() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Program Image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              _program!.imageUrl,
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
                  _program!.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // University
                Row(
                  children: [
                    const Icon(
                      Icons.school,
                      size: 20,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _program!.university,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Program Info Cards
                Row(
                  children: [
                    _buildInfoCard('Degree', _program!.degreeType, Icons.badge),
                    const SizedBox(width: 16),
                    _buildInfoCard('Duration', _program!.duration, Icons.access_time),
                    const SizedBox(width: 16),
                    _buildInfoCard('Tuition', _program!.tuitionFee, Icons.euro),
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
                  _program!.description,
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
                ..._program!.requirements.map((requirement) {
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
                
                // Apply Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to application form
                      Navigator.pushNamed(context, AppConstants.applicationFormRoute);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Apply Now',
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
