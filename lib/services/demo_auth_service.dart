import 'package:shared_preferences/shared_preferences.dart';

class DemoAuthService {
  static const String _userNameKey = 'demo_user_name';
  static const String _userEmailKey = 'demo_user_email';
  static const String _userRoleKey = 'demo_user_role';
  static const String _userIdKey = 'demo_user_id';
  static const String _isLoggedInKey = 'demo_is_logged_in';

  // Demo user data
  static const Map<String, Map<String, String>> _demoUsers = {
    'student': {
      'id': 'student_001',
      'name': 'Ahmed Ali Khan',
      'email': 'ahmed.ali@school.edu.pk',
      'role': 'student',
    },
    'teacher': {
      'id': 'teacher_001', 
      'name': 'Dr. Sarah Ahmed',
      'email': 'sarah.ahmed@school.edu.pk',
      'role': 'teacher',
    },
    'admin': {
      'id': 'admin_001',
      'name': 'Muhammad Hassan',
      'email': 'hassan@school.edu.pk', 
      'role': 'admin',
    },
  };

  static Future<void> loginDemoUser(String role) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = _demoUsers[role];
    
    if (userData != null) {
      await prefs.setString(_userNameKey, userData['name']!);
      await prefs.setString(_userEmailKey, userData['email']!);
      await prefs.setString(_userRoleKey, userData['role']!);
      await prefs.setString(_userIdKey, userData['id']!);
      await prefs.setBool(_isLoggedInKey, true);
    }
  }

  static Future<Map<String, String>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    
    if (!isLoggedIn) return null;
    
    return {
      'id': prefs.getString(_userIdKey) ?? '',
      'name': prefs.getString(_userNameKey) ?? '',
      'email': prefs.getString(_userEmailKey) ?? '',
      'role': prefs.getString(_userRoleKey) ?? '',
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey) ?? 'User';
  }

  static Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey) ?? '';
  }

  static Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey) ?? '';
  }

  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey) ?? '';
  }
}
