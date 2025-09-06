import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  
  // Settings
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  bool _isLoading = true;
  String _userName = '';
  String _userEmail = '';
  String _userRole = '';
  
  // Language options
  final List<String> _languages = ['English', 'Greek', 'Turkish', 'Russian', 'Arabic'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final user = await _authService.getCurrentUser();
      
      setState(() {
        // Load user info
        if (user != null) {
          _userName = user.name;
          _userEmail = user.email;
          _userRole = user.role;
        }
        
        // Load settings
        _isDarkMode = prefs.getBool('darkMode') ?? false;
        _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
        _selectedLanguage = prefs.getString('language') ?? 'English';
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      Fluttertoast.showToast(
        msg: 'Error loading settings: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppTheme.errorColor,
        textColor: AppTheme.whiteColor,
      );
    }
  }
  
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save settings
      await prefs.setBool('darkMode', _isDarkMode);
      await prefs.setBool('notificationsEnabled', _notificationsEnabled);
      await prefs.setString('language', _selectedLanguage);
      
      // Show success message
      Fluttertoast.showToast(
        msg: 'Settings saved',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: AppTheme.whiteColor,
      );
    } catch (e) {
      debugPrint('Error saving settings: $e');
      
      // Show error message
      Fluttertoast.showToast(
        msg: 'Error saving settings: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppTheme.errorColor,
        textColor: AppTheme.whiteColor,
      );
    }
  }
  
  Future<void> _logout() async {
    try {
      await _authService.signOut();
      
      if (!mounted) return;
      
      // Navigate to login screen
      Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
    } catch (e) {
      debugPrint('Error logging out: $e');
      
      // Show error message
      Fluttertoast.showToast(
        msg: 'Error logging out: $e',
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
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // User Profile Card
                Card(
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      ).then((_) => _loadSettings());
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person,
                                size: 30,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // User Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _userEmail,
                                  style: const TextStyle(
                                    color: AppTheme.lightTextColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _userRole.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Edit Icon
                          const Icon(
                            Icons.chevron_right,
                            color: AppTheme.lightTextColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Settings Sections
                const Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Dark Mode
                Card(
                  child: SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Enable dark theme'),
                    secondary: const Icon(Icons.dark_mode),
                    value: _isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        _isDarkMode = value;
                      });
                      _saveSettings();
                      
                      // Show message that theme will apply on restart
                      Fluttertoast.showToast(
                        msg: 'Theme will apply on app restart',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: AppTheme.primaryColor,
                        textColor: AppTheme.whiteColor,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                
                // Language
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Language',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.language),
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedLanguage,
                          items: _languages.map((language) {
                            return DropdownMenuItem<String>(
                              value: language,
                              child: Text(language),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedLanguage = value;
                              });
                              _saveSettings();
                              
                              // Show message that language will apply on restart
                              Fluttertoast.showToast(
                                msg: 'Language will apply on app restart',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: AppTheme.primaryColor,
                                textColor: AppTheme.whiteColor,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Notifications
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Enable Notifications
                Card(
                  child: SwitchListTile(
                    title: const Text('Enable Notifications'),
                    subtitle: const Text('Receive notifications about your applications'),
                    secondary: const Icon(Icons.notifications),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                      _saveSettings();
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                // Account
                const Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Logout
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout'),
                    subtitle: const Text('Sign out of your account'),
                    onTap: () {
                      // Show confirmation dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _logout();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                
                // About
                const Text(
                  'About',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                
                // App Version
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('App Version'),
                    subtitle: const Text('1.0.0'),
                  ),
                ),
                
                // Privacy Policy
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('Privacy Policy'),
                    onTap: () {
                      // Show privacy policy
                      Fluttertoast.showToast(
                        msg: 'Privacy policy will be available in future phases',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: AppTheme.primaryColor,
                        textColor: AppTheme.whiteColor,
                      );
                    },
                  ),
                ),
                
                // Terms of Service
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Terms of Service'),
                    onTap: () {
                      // Show terms of service
                      Fluttertoast.showToast(
                        msg: 'Terms of service will be available in future phases',
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: AppTheme.primaryColor,
                        textColor: AppTheme.whiteColor,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
