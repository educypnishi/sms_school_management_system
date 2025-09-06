import 'package:flutter/material.dart';
import '../utils/toast_util.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.getCurrentUser();
      
      setState(() {
        _user = user;
        _isLoading = false;
        
        // Initialize controllers
        if (user != null) {
          _nameController.text = user.name;
          _emailController.text = user.email;
          _phoneController.text = user.phone ?? '';
        }
      });
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ToastUtil.showToast(
      context: context,
      message: 'Error loading user profile: $e',
    );
    }
  }
  
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (_user != null) {
        // Update user profile
        await _authService.updateUserProfile(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );
        
        // Reload user profile
        await _loadUserProfile();
        
        // Exit editing mode
        setState(() {
          _isEditing = false;
        });
        
        // Show success message
        ToastUtil.showToast(
      context: context,
      message: 'Profile updated successfully',
    );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ToastUtil.showToast(
      context: context,
      message: 'Error updating profile: $e',
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_isEditing && !_isLoading && _user != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(
                  child: Text(
                    'User not found',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _isEditing
                      ? _buildEditProfileForm()
                      : _buildProfileView(),
                ),
    );
  }

  Widget _buildProfileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Header
        Center(
          child: Column(
            children: [
              // Profile Avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // User Name
              Text(
                _user!.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              
              // User Role
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _user!.role.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Profile Details
        const Text(
          'Profile Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Email
        _buildProfileItem(
          icon: Icons.email,
          title: 'Email',
          value: _user!.email,
        ),
        
        // Phone
        _buildProfileItem(
          icon: Icons.phone,
          title: 'Phone',
          value: _user!.phone ?? 'Not provided',
        ),
        
        // Member Since
        _buildProfileItem(
          icon: Icons.calendar_today,
          title: 'Member Since',
          value: _formatDate(_user!.createdAt),
        ),
        
        const SizedBox(height: 32),
        
        // Edit Profile Button
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEditProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Title
          const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Name Field
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Email Field (Disabled)
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
              helperText: 'Email cannot be changed',
            ),
            enabled: false,
          ),
          const SizedBox(height: 16),
          
          // Phone Field
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 32),
          
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cancel Button
              OutlinedButton(
                onPressed: () {
                  // Reset controllers
                  _nameController.text = _user!.name;
                  _phoneController.text = _user!.phone ?? '';
                  
                  setState(() {
                    _isEditing = false;
                  });
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              
              // Save Button
              ElevatedButton(
                onPressed: _updateProfile,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.lightTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                
                // Value
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
