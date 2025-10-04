import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;
  
  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;
  
  // Check if user is authenticated
  static bool get isAuthenticated => _auth.currentUser != null;

  // Sign up with email and password
  static Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String role, // 'student', 'teacher', 'admin'
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Create user account
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(fullName);

      // Create user document in Firestore
      await _createUserDocument(
        uid: userCredential.user!.uid,
        email: email,
        fullName: fullName,
        role: role,
        additionalData: additionalData,
      );

      debugPrint('✅ User created successfully: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ Unexpected error during sign up: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ User signed in successfully: ${userCredential.user?.email}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ Unexpected error during sign in: $e');
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('✅ User signed out successfully');
    } catch (e) {
      debugPrint('❌ Error signing out: $e');
      rethrow;
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('✅ Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ Unexpected error during password reset: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting user data: $e');
      rethrow;
    }
  }

  // Update user data in Firestore
  static Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      debugPrint('✅ User data updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating user data: $e');
      rethrow;
    }
  }

  // Create user document in Firestore
  static Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String fullName,
    required String role,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      Map<String, dynamic> userData = {
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'profileImageUrl': '',
        'phoneNumber': '',
        'address': '',
        'dateOfBirth': '',
        'gender': '',
        ...?additionalData,
      };

      // Add role-specific data
      switch (role) {
        case 'student':
          userData.addAll({
            'studentId': _generateStudentId(),
            'enrollmentDate': FieldValue.serverTimestamp(),
            'class': '',
            'section': '',
            'rollNumber': '',
            'parentName': '',
            'parentPhone': '',
            'parentEmail': '',
            'emergencyContact': '',
            'bloodGroup': '',
            'medicalConditions': [],
            'subjects': [],
            'totalFees': 0.0,
            'paidFees': 0.0,
            'pendingFees': 0.0,
          });
          break;
        case 'teacher':
          userData.addAll({
            'teacherId': _generateTeacherId(),
            'joiningDate': FieldValue.serverTimestamp(),
            'department': '',
            'designation': '',
            'qualification': '',
            'experience': 0,
            'subjects': [],
            'classes': [],
            'salary': 0.0,
            'employeeType': 'full-time', // full-time, part-time, contract
          });
          break;
        case 'admin':
          userData.addAll({
            'adminId': _generateAdminId(),
            'joiningDate': FieldValue.serverTimestamp(),
            'department': 'Administration',
            'designation': 'Administrator',
            'permissions': [
              'manage_students',
              'manage_teachers',
              'manage_courses',
              'manage_fees',
              'view_reports',
              'system_settings',
            ],
          });
          break;
      }

      await _firestore.collection('users').doc(uid).set(userData);
      debugPrint('✅ User document created successfully');
    } catch (e) {
      debugPrint('❌ Error creating user document: $e');
      rethrow;
    }
  }

  // Generate unique IDs
  static String _generateStudentId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'STU${timestamp.toString().substring(8)}';
  }

  static String _generateTeacherId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'TCH${timestamp.toString().substring(8)}';
  }

  static String _generateAdminId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'ADM${timestamp.toString().substring(8)}';
  }

  // Handle Firebase Auth exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }

  // Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if email is verified
  static bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Send email verification
  static Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      debugPrint('✅ Email verification sent');
    } catch (e) {
      debugPrint('❌ Error sending email verification: $e');
      rethrow;
    }
  }

  // Reload user
  static Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
      debugPrint('✅ User reloaded');
    } catch (e) {
      debugPrint('❌ Error reloading user: $e');
      rethrow;
    }
  }
}
