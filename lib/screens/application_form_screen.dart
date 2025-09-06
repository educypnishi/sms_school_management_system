import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/application_model.dart';
import '../services/application_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';

class ApplicationFormScreen extends StatefulWidget {
  const ApplicationFormScreen({super.key});

  @override
  State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final _applicationService = ApplicationService();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _applicationId;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get current user
      final user = await _authService.getCurrentUser();
      if (user != null) {
        // Pre-fill form with user data
        _nameController.text = user.name;
        _emailController.text = user.email;
        
        // Check if user has an existing application
        final applications = await _applicationService.getUserApplications();
        if (applications.isNotEmpty) {
          // Use the most recent application
          final application = applications.last;
          _applicationId = application.id;
          _nameController.text = application.name;
          _emailController.text = application.email;
          _phoneController.text = application.phone;
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _saveDraft() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Save application draft
        final application = await _applicationService.saveDraft(
          id: _applicationId,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
        );
        
        // Update application ID
        _applicationId = application.id;
        
        // Show success message
        Fluttertoast.showToast(
          msg: 'Application draft saved',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: AppTheme.whiteColor,
        );
      } catch (e) {
        // Show error message
        Fluttertoast.showToast(
          msg: 'Error saving draft: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.errorColor,
          textColor: AppTheme.whiteColor,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  Future<void> _submitApplication() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });
      
      try {
        // First save the draft to ensure all data is up to date
        final application = await _applicationService.saveDraft(
          id: _applicationId,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
        );
        
        // Update application ID
        _applicationId = application.id;
        
        // Submit application
        await _applicationService.submitApplication(_applicationId!);
        
        // Show success message
        Fluttertoast.showToast(
          msg: 'Application submitted successfully',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: AppTheme.whiteColor,
        );
        
        // Navigate back to student dashboard
        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        // Show error message
        Fluttertoast.showToast(
          msg: 'Error submitting application: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppTheme.errorColor,
          textColor: AppTheme.whiteColor,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Form'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form Title
                    const Text(
                      'Step 1: Basic Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please provide your basic contact information',
                      style: TextStyle(
                        color: AppTheme.lightTextColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: Validators.validateName,
                    ),
                    const SizedBox(height: 16),
                    
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Enter your phone number',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: Validators.validatePhone,
                    ),
                    const SizedBox(height: 32),
                    
                    // Action Buttons
                    Row(
                      children: [
                        // Save Draft Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _saveDraft,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Draft'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Submit Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _submitApplication,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.whiteColor,
                                    ),
                                  )
                                : const Icon(Icons.send),
                            label: const Text('Submit'),
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
}
