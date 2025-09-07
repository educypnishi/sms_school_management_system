import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  // For Phase 2, we'll use SharedPreferences to store user data
  // In a real app, this would use Firebase Auth and Firestore
  
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

  // Sign up with email and password
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String role = AppConstants.studentRole,
  }) async {
    try {
      // For Phase 2, we'll simulate user creation
      await Future.delayed(const Duration(seconds: 1));
      
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

      // Save user data to shared preferences
      await _saveUserData(
        userId: userId,
        name: name,
        email: email,
        role: role,
      );

      return user;
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // For Phase 2, we'll simulate user login
      await Future.delayed(const Duration(seconds: 1));
      
      // Generate a random user ID
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Determine role based on email (for testing purposes)
      String role = AppConstants.studentRole;
      if (email.contains('admin')) {
        role = AppConstants.adminRole;
      } else if (email.contains('teacher')) {
        role = AppConstants.teacherRole;
      }
      
      // Create user model
      final user = UserModel(
        id: userId,
        name: email.split('@')[0], // Use part of email as name
        email: email,
        role: role,
        createdAt: DateTime.now(),
      );

      // Save user data to shared preferences
      await _saveUserData(
        userId: userId,
        name: user.name,
        email: email,
        role: role,
      );

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

  // Save user data to shared preferences
  Future<void> _saveUserData({
    required String userId,
    required String name,
    required String email,
    required String role,
    String? phone,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userIdKey, userId);
      await prefs.setString(AppConstants.userNameKey, name);
      await prefs.setString(AppConstants.userEmailKey, email);
      await prefs.setString(AppConstants.userRoleKey, role);
      if (phone != null) {
        await prefs.setString(AppConstants.userPhoneKey, phone);
      }
      await prefs.setBool(AppConstants.isLoggedInKey, true);
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
}
