import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  // Enhanced authentication service with encryption and security features
  // Password hashing, session management, and security validations
  
  static const String _saltKey = 'auth_salt';
  static const String _sessionTokenKey = 'session_token';
  static const int _sessionDurationHours = 24;
  static const int _maxLoginAttempts = 5;
  static const int _lockoutDurationMinutes = 30;
  
  // Get current user
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppConstants.userIdKey);
    
    if (userId == null) return null;
    
    return UserModel(
      id: userId,
      name: prefs.getString(AppConstants.userNameKey) ?? '',
      email: prefs.getString(AppConstants.userEmailKey) ?? '',
      role: prefs.getString(AppConstants.userRoleKey) ?? AppConstants.studentRole,
      phone: prefs.getString(AppConstants.userPhoneKey),
      createdAt: DateTime.now(),
    );
  }

  // Enhanced sign up with email and password
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String role = AppConstants.studentRole,
  }) async {
    try {
      // Validate input
      _validateEmail(email);
      _validatePassword(password);
      _validateName(name);
      
      // Check if user already exists
      final existingUser = await _getUserByEmail(email);
      if (existingUser != null) {
        throw Exception('User with this email already exists');
      }
      
      // Generate salt and hash password
      final salt = _generateSalt();
      final hashedPassword = _hashPassword(password, salt);
      
      // Generate a random user ID
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create user model
      final user = UserModel(
        id: userId,
        name: name,
        email: email,
        role: role,
        createdAt: DateTime.now(),
      );

      // Save user data with encrypted password
      await _saveUserData(
        userId: userId,
        name: name,
        email: email,
        role: role,
        hashedPassword: hashedPassword,
        salt: salt,
      );

      // Generate session token
      await _generateSessionToken(userId);

      return user;
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    }
  }

  // Enhanced sign in with email and password
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Validate input
      _validateEmail(email);
      if (password.isEmpty) {
        throw Exception('Password cannot be empty');
      }
      
      // Check for account lockout
      await _checkAccountLockout(email);
      
      // Get user by email
      final userData = await _getUserByEmail(email);
      if (userData == null) {
        await _recordFailedLogin(email);
        throw Exception('Invalid email or password');
      }
      
      // Verify password
      final storedSalt = userData['salt'] as String?;
      final storedHash = userData['hashedPassword'] as String?;
      
      if (storedSalt == null || storedHash == null) {
        throw Exception('Invalid user data');
      }
      
      final hashedPassword = _hashPassword(password, storedSalt);
      if (hashedPassword != storedHash) {
        await _recordFailedLogin(email);
        throw Exception('Invalid email or password');
      }
      
      // Clear failed login attempts
      await _clearFailedLogins(email);
      
      // Create user model
      final user = UserModel(
        id: userData['userId'] as String,
        name: userData['name'] as String,
        email: email,
        role: userData['role'] as String,
        phone: userData['phone'] as String?,
        createdAt: DateTime.parse(userData['createdAt'] as String),
      );

      // Generate new session token
      await _generateSessionToken(user.id);
      
      // Update last login time
      await _updateLastLogin(user.id);

      return user;
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _clearUserData();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Save user data to shared preferences with encryption
  Future<void> _saveUserData({
    required String userId,
    required String name,
    required String email,
    required String role,
    String? phone,
    String? hashedPassword,
    String? salt,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save current session data
      await prefs.setString(AppConstants.userIdKey, userId);
      await prefs.setString(AppConstants.userNameKey, name);
      await prefs.setString(AppConstants.userEmailKey, email);
      await prefs.setString(AppConstants.userRoleKey, role);
      if (phone != null) {
        await prefs.setString(AppConstants.userPhoneKey, phone);
      }
      await prefs.setBool(AppConstants.isLoggedInKey, true);
      
      // Save user account data (for authentication)
      final userAccountData = {
        'userId': userId,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'hashedPassword': hashedPassword,
        'salt': salt,
        'createdAt': DateTime.now().toIso8601String(),
        'lastLogin': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString('user_account_$email', jsonEncode(userAccountData));
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  // Clear user data from shared preferences
  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userIdKey);
      await prefs.remove(AppConstants.userNameKey);
      await prefs.remove(AppConstants.userEmailKey);
      await prefs.remove(AppConstants.userRoleKey);
      await prefs.remove(AppConstants.userPhoneKey);
      await prefs.setBool(AppConstants.isLoggedInKey, false);
    } catch (e) {
      debugPrint('Error clearing user data: $e');
    }
  }

  // Get user role
  Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.userRoleKey);
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(AppConstants.isLoggedInKey) ?? false;
    } catch (e) {
      debugPrint('Error checking if user is logged in: $e');
      return false;
    }
  }
  
  // Update user profile
  Future<void> updateUserProfile({
    required String name,
    String? phone,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(AppConstants.userIdKey);
      
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      // Update name
      await prefs.setString(AppConstants.userNameKey, name);
      
      // Update phone if provided
      if (phone != null) {
        await prefs.setString(AppConstants.userPhoneKey, phone);
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }
  
  // Security Helper Methods
  
  // Generate a random salt for password hashing
  String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(saltBytes);
  }
  
  // Hash password with salt using SHA-256
  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Validate email format
  void _validateEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      throw Exception('Invalid email format');
    }
  }
  
  // Validate password strength
  void _validatePassword(String password) {
    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters long');
    }
    
    if (!password.contains(RegExp(r'[A-Z]'))) {
      throw Exception('Password must contain at least one uppercase letter');
    }
    
    if (!password.contains(RegExp(r'[a-z]'))) {
      throw Exception('Password must contain at least one lowercase letter');
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      throw Exception('Password must contain at least one number');
    }
    
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      throw Exception('Password must contain at least one special character');
    }
  }
  
  // Validate name
  void _validateName(String name) {
    if (name.trim().isEmpty) {
      throw Exception('Name cannot be empty');
    }
    
    if (name.trim().length < 2) {
      throw Exception('Name must be at least 2 characters long');
    }
  }
  
  // Get user by email
  Future<Map<String, dynamic>?> _getUserByEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_account_$email');
      
      if (userDataJson == null) {
        return null;
      }
      
      return jsonDecode(userDataJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting user by email: $e');
      return null;
    }
  }
  
  // Generate session token
  Future<void> _generateSessionToken(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final random = Random.secure();
      final tokenBytes = List<int>.generate(32, (i) => random.nextInt(256));
      final token = base64Encode(tokenBytes);
      final expiryTime = DateTime.now().add(Duration(hours: _sessionDurationHours));
      
      await prefs.setString(_sessionTokenKey, token);
      await prefs.setString('session_expiry', expiryTime.toIso8601String());
      await prefs.setString('session_user_id', userId);
    } catch (e) {
      debugPrint('Error generating session token: $e');
    }
  }
  
  // Check if session is valid
  Future<bool> isSessionValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_sessionTokenKey);
      final expiryString = prefs.getString('session_expiry');
      
      if (token == null || expiryString == null) {
        return false;
      }
      
      final expiryTime = DateTime.parse(expiryString);
      return DateTime.now().isBefore(expiryTime);
    } catch (e) {
      debugPrint('Error checking session validity: $e');
      return false;
    }
  }
  
  // Record failed login attempt
  Future<void> _recordFailedLogin(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'failed_logins_$email';
      final attempts = prefs.getInt(key) ?? 0;
      await prefs.setInt(key, attempts + 1);
      await prefs.setString('last_failed_login_$email', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error recording failed login: $e');
    }
  }
  
  // Clear failed login attempts
  Future<void> _clearFailedLogins(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('failed_logins_$email');
      await prefs.remove('last_failed_login_$email');
      await prefs.remove('account_locked_$email');
    } catch (e) {
      debugPrint('Error clearing failed logins: $e');
    }
  }
  
  // Check for account lockout
  Future<void> _checkAccountLockout(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final failedAttempts = prefs.getInt('failed_logins_$email') ?? 0;
      
      if (failedAttempts >= _maxLoginAttempts) {
        final lastFailedString = prefs.getString('last_failed_login_$email');
        if (lastFailedString != null) {
          final lastFailed = DateTime.parse(lastFailedString);
          final lockoutEnd = lastFailed.add(Duration(minutes: _lockoutDurationMinutes));
          
          if (DateTime.now().isBefore(lockoutEnd)) {
            final remainingMinutes = lockoutEnd.difference(DateTime.now()).inMinutes;
            throw Exception('Account locked. Try again in $remainingMinutes minutes.');
          } else {
            // Lockout period expired, clear failed attempts
            await _clearFailedLogins(email);
          }
        }
      }
    } catch (e) {
      if (e.toString().contains('Account locked')) {
        rethrow;
      }
      debugPrint('Error checking account lockout: $e');
    }
  }
  
  // Update last login time
  Future<void> _updateLastLogin(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUser = await getCurrentUser();
      if (currentUser != null) {
        final userDataJson = prefs.getString('user_account_${currentUser.email}');
        if (userDataJson != null) {
          final userData = jsonDecode(userDataJson) as Map<String, dynamic>;
          userData['lastLogin'] = DateTime.now().toIso8601String();
          await prefs.setString('user_account_${currentUser.email}', jsonEncode(userData));
        }
      }
    } catch (e) {
      debugPrint('Error updating last login: $e');
    }
  }
  
  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Validate new password
      _validatePassword(newPassword);
      
      // Get user data
      final userData = await _getUserByEmail(currentUser.email);
      if (userData == null) {
        throw Exception('User data not found');
      }
      
      // Verify current password
      final storedSalt = userData['salt'] as String;
      final storedHash = userData['hashedPassword'] as String;
      final currentPasswordHash = _hashPassword(currentPassword, storedSalt);
      
      if (currentPasswordHash != storedHash) {
        throw Exception('Current password is incorrect');
      }
      
      // Generate new salt and hash new password
      final newSalt = _generateSalt();
      final newPasswordHash = _hashPassword(newPassword, newSalt);
      
      // Update user data
      userData['hashedPassword'] = newPasswordHash;
      userData['salt'] = newSalt;
      userData['lastPasswordChange'] = DateTime.now().toIso8601String();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_account_${currentUser.email}', jsonEncode(userData));
      
    } catch (e) {
      debugPrint('Error changing password: $e');
      rethrow;
    }
  }
  
  // Reset password (for admin use)
  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      // Validate new password
      _validatePassword(newPassword);
      
      // Get user data
      final userData = await _getUserByEmail(email);
      if (userData == null) {
        throw Exception('User not found');
      }
      
      // Generate new salt and hash new password
      final newSalt = _generateSalt();
      final newPasswordHash = _hashPassword(newPassword, newSalt);
      
      // Update user data
      userData['hashedPassword'] = newPasswordHash;
      userData['salt'] = newSalt;
      userData['lastPasswordChange'] = DateTime.now().toIso8601String();
      userData['passwordResetBy'] = 'admin';
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_account_$email', jsonEncode(userData));
      
      // Clear any failed login attempts
      await _clearFailedLogins(email);
      
    } catch (e) {
      debugPrint('Error resetting password: $e');
      rethrow;
    }
  }
}
