import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import '../utils/toast_util.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final String userId;

  const NotificationSettingsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  
  // Notification preferences
  bool _enableAllNotifications = true;
  bool _enableApplicationNotifications = true;
  bool _enableProgramNotifications = true;
  bool _enableMessageNotifications = true;
  bool _enableGeneralNotifications = true;
  
  // Notification time preferences
  String _notificationTime = 'immediately';
  final List<String> _notificationTimeOptions = [
    'immediately',
    'hourly',
    'daily',
    'weekly',
  ];
  
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
      
      setState(() {
        _enableAllNotifications = prefs.getBool('${widget.userId}_enable_all_notifications') ?? true;
        _enableApplicationNotifications = prefs.getBool('${widget.userId}_enable_application_notifications') ?? true;
        _enableProgramNotifications = prefs.getBool('${widget.userId}_enable_program_notifications') ?? true;
        _enableMessageNotifications = prefs.getBool('${widget.userId}_enable_message_notifications') ?? true;
        _enableGeneralNotifications = prefs.getBool('${widget.userId}_enable_general_notifications') ?? true;
        _notificationTime = prefs.getString('${widget.userId}_notification_time') ?? 'immediately';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ToastUtil.showToast(
        context: context,
        message: 'Error loading notification settings',
      );
    }
  }
  
  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('${widget.userId}_enable_all_notifications', _enableAllNotifications);
      await prefs.setBool('${widget.userId}_enable_application_notifications', _enableApplicationNotifications);
      await prefs.setBool('${widget.userId}_enable_program_notifications', _enableProgramNotifications);
      await prefs.setBool('${widget.userId}_enable_message_notifications', _enableMessageNotifications);
      await prefs.setBool('${widget.userId}_enable_general_notifications', _enableGeneralNotifications);
      await prefs.setString('${widget.userId}_notification_time', _notificationTime);
      
      setState(() {
        _isLoading = false;
      });
      
      // Show success message
      ToastUtil.showToast(
        context: context,
        message: 'Notification settings saved',
      );
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      ToastUtil.showToast(
        context: context,
        message: 'Error saving notification settings',
      );
    }
  }
  
  void _toggleAllNotifications(bool value) {
    setState(() {
      _enableAllNotifications = value;
      if (!value) {
        // If all notifications are disabled, disable all specific types
        _enableApplicationNotifications = false;
        _enableProgramNotifications = false;
        _enableMessageNotifications = false;
        _enableGeneralNotifications = false;
      } else {
        // If all notifications are enabled, enable all specific types
        _enableApplicationNotifications = true;
        _enableProgramNotifications = true;
        _enableMessageNotifications = true;
        _enableGeneralNotifications = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // General notification settings
                  const Text(
                    'General Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchTile(
                    title: 'Enable All Notifications',
                    subtitle: 'Receive all types of notifications',
                    value: _enableAllNotifications,
                    onChanged: _toggleAllNotifications,
                    icon: Icons.notifications,
                  ),
                  const Divider(),
                  
                  // Notification types
                  const Text(
                    'Notification Types',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchTile(
                    title: 'Application Updates',
                    subtitle: 'Notifications about your applications',
                    value: _enableApplicationNotifications,
                    onChanged: _enableAllNotifications
                        ? (value) {
                            setState(() {
                              _enableApplicationNotifications = value;
                            });
                          }
                        : null,
                    icon: Icons.assignment,
                  ),
                  _buildSwitchTile(
                    title: 'Program Updates',
                    subtitle: 'Notifications about educational programs',
                    value: _enableProgramNotifications,
                    onChanged: _enableAllNotifications
                        ? (value) {
                            setState(() {
                              _enableProgramNotifications = value;
                            });
                          }
                        : null,
                    icon: Icons.school,
                  ),
                  _buildSwitchTile(
                    title: 'Messages',
                    subtitle: 'Notifications about new messages',
                    value: _enableMessageNotifications,
                    onChanged: _enableAllNotifications
                        ? (value) {
                            setState(() {
                              _enableMessageNotifications = value;
                            });
                          }
                        : null,
                    icon: Icons.message,
                  ),
                  _buildSwitchTile(
                    title: 'General Announcements',
                    subtitle: 'General notifications and announcements',
                    value: _enableGeneralNotifications,
                    onChanged: _enableAllNotifications
                        ? (value) {
                            setState(() {
                              _enableGeneralNotifications = value;
                            });
                          }
                        : null,
                    icon: Icons.campaign,
                  ),
                  const Divider(),
                  
                  // Notification frequency
                  const Text(
                    'Notification Frequency',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRadioListTile(
                    title: 'Immediately',
                    subtitle: 'Receive notifications as they happen',
                    value: 'immediately',
                    groupValue: _notificationTime,
                    onChanged: _enableAllNotifications
                        ? (value) {
                            setState(() {
                              _notificationTime = value!;
                            });
                          }
                        : null,
                    icon: Icons.bolt,
                  ),
                  _buildRadioListTile(
                    title: 'Hourly Digest',
                    subtitle: 'Receive notifications once per hour',
                    value: 'hourly',
                    groupValue: _notificationTime,
                    onChanged: _enableAllNotifications
                        ? (value) {
                            setState(() {
                              _notificationTime = value!;
                            });
                          }
                        : null,
                    icon: Icons.hourglass_bottom,
                  ),
                  _buildRadioListTile(
                    title: 'Daily Digest',
                    subtitle: 'Receive notifications once per day',
                    value: 'daily',
                    groupValue: _notificationTime,
                    onChanged: _enableAllNotifications
                        ? (value) {
                            setState(() {
                              _notificationTime = value!;
                            });
                          }
                        : null,
                    icon: Icons.calendar_today,
                  ),
                  _buildRadioListTile(
                    title: 'Weekly Digest',
                    subtitle: 'Receive notifications once per week',
                    value: 'weekly',
                    groupValue: _notificationTime,
                    onChanged: _enableAllNotifications
                        ? (value) {
                            setState(() {
                              _notificationTime = value!;
                            });
                          }
                        : null,
                    icon: Icons.date_range,
                  ),
                  const SizedBox(height: 24),
                  
                  // Save button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Settings'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool)? onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: onChanged != null ? AppTheme.primaryColor : Colors.grey,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }
  
  Widget _buildRadioListTile({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required Function(String?)? onChanged,
    required IconData icon,
  }) {
    return RadioListTile<String>(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      secondary: Icon(
        icon,
        color: onChanged != null ? AppTheme.primaryColor : Colors.grey,
      ),
      activeColor: AppTheme.primaryColor,
    );
  }
}
