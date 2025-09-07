import 'package:flutter/material.dart';
import '../utils/toast_util.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = AppConstants.studentRole; // Default role

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm password is required';
    }
    
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  Widget _buildRoleSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.lightTextColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Student Role
          _buildRoleOption(
            title: 'Student',
            subtitle: 'Looking to study in Cyprus',
            value: AppConstants.studentRole,
            icon: Icons.school,
          ),
          const Divider(height: 1),
          
          // Teacher Role
          _buildRoleOption(
            title: 'Teacher',
            subtitle: 'School teacher or instructor',
            value: AppConstants.teacherRole,
            icon: Icons.business,
          ),
          const Divider(height: 1),
          
          // Admin Role
          _buildRoleOption(
            title: 'Admin',
            subtitle: 'System administrator',
            value: AppConstants.adminRole,
            icon: Icons.admin_panel_settings,
          ),
        ],
      ),
    );
  }
  
  Widget _buildRoleOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    return RadioListTile<String>(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      groupValue: _selectedRole,
      secondary: Icon(icon, color: _selectedRole == value ? AppTheme.primaryColor : AppTheme.lightTextColor),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedRole = newValue;
          });
        }
      },
      activeColor: AppTheme.primaryColor,
      selected: _selectedRole == value,
    );
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Call auth service to sign up user with selected role
        await AuthService().signUpWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
          role: _selectedRole,
        );
        
        if (!mounted) return;
        
        // Show success message
        ToastUtil.showToast(
      context: context,
      message: 'Account created successfully!',
    );
        
        // Navigate to appropriate dashboard based on role
        if (_selectedRole == AppConstants.adminRole) {
          Navigator.pushReplacementNamed(context, AppConstants.adminDashboardRoute);
        } else if (_selectedRole == AppConstants.teacherRole) {
          Navigator.pushReplacementNamed(context, AppConstants.teacherDashboardRoute);
        } else {
          Navigator.pushReplacementNamed(context, AppConstants.studentDashboardRoute);
        }
      } catch (e) {
        // Show error message
        ToastUtil.showToast(
      context: context,
      message: 'Error creating account: $e',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and App Name
                  const Icon(
                    Icons.school,
                    size: 60,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Join ${AppConstants.appName}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
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
                  
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 16),
                  
                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Confirm your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: _validateConfirmPassword,
                  ),
                  const SizedBox(height: 24),
                  
                  // Role Selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select your role:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildRoleSelector(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Sign Up Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.whiteColor,
                            ),
                          )
                        : const Text('Sign Up'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
