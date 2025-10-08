import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_model.dart';

class RealAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save user session locally
      await _saveUserSession(credential.user!);
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(
    String email, 
    String password, 
    Map<String, dynamic> userData
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      await _createUserProfile(credential.user!, userData);
      
      // Save user session locally
      await _saveUserSession(credential.user!);
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _clearUserSession();
    } catch (e) {
      throw Exception('Error signing out: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Get current user data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      userData['uid'] = user.uid;
      userData['email'] = user.email;
      
      return userData;
    } catch (e) {
      print('Error getting current user data: $e');
      return null;
    }
  }

  // Get student profile for current user
  Future<StudentModel?> getCurrentStudentProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final studentQuery = await _firestore
          .collection('students')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (studentQuery.docs.isEmpty) return null;

      final doc = studentQuery.docs.first;
      return StudentModel.fromMap(doc.data(), doc.id);
    } catch (e) {
      print('Error getting student profile: $e');
      return null;
    }
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _auth.currentUser != null;
  }

  // Get user role
  Future<String?> getUserRole() async {
    try {
      final userData = await getCurrentUserData();
      return userData?['role'];
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(user.uid).update(updates);
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  // Update email
  Future<void> updateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await user.updateEmail(newEmail);
      await _firestore.collection('users').doc(user.uid).update({
        'email': newEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error updating email: $e');
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error updating password: $e');
    }
  }

  // Verify email
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error sending verification email: $e');
    }
  }

  // Check if email is verified
  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Reload user to get updated verification status
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();
      
      // Delete student profile if exists
      final studentQuery = await _firestore
          .collection('students')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      for (final doc in studentQuery.docs) {
        await doc.reference.delete();
      }

      // Delete Firebase Auth account
      await user.delete();
      
      // Clear local session
      await _clearUserSession();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error deleting account: $e');
    }
  }

  // Private helper methods
  Future<void> _createUserProfile(User user, Map<String, dynamic> userData) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      ...userData,
    });
  }

  Future<void> _saveUserSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.uid);
    await prefs.setString('user_email', user.email ?? '');
    await prefs.setBool('is_logged_in', true);
  }

  Future<void> _clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.setBool('is_logged_in', false);
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'requires-recent-login':
        return 'Please log in again to perform this action.';
      default:
        return 'Authentication error: ${e.message}';
    }
  }

  // Demo data compatibility methods (for gradual migration)
  static Future<Map<String, String>?> getCurrentUser() async {
    final authService = RealAuthService();
    final userData = await authService.getCurrentUserData();
    
    if (userData == null) return null;
    
    return {
      'id': userData['uid'] ?? '',
      'name': userData['name'] ?? userData['displayName'] ?? 'User',
      'email': userData['email'] ?? '',
      'role': userData['role'] ?? 'student',
    };
  }

  static Future<void> loginDemoUser(String role) async {
    // This method is kept for compatibility but should be replaced
    // with proper authentication flow
    throw Exception('Demo login not supported in real auth service. Use proper authentication.');
  }

  static Future<void> logout() async {
    final authService = RealAuthService();
    await authService.signOut();
  }

  static Future<bool> isLoggedIn() async {
    final authService = RealAuthService();
    return authService.isLoggedIn();
  }

  static Future<String> getUserName() async {
    final userData = await getCurrentUser();
    return userData?['name'] ?? 'User';
  }

  static Future<String> getUserEmail() async {
    final userData = await getCurrentUser();
    return userData?['email'] ?? '';
  }

  static Future<String> getUserRole() async {
    final userData = await getCurrentUser();
    return userData?['role'] ?? '';
  }

  static Future<String> getUserId() async {
    final userData = await getCurrentUser();
    return userData?['id'] ?? '';
  }
}
