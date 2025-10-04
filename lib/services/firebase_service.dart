import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseService {
  static bool _initialized = false;
  
  static Future<void> initializeFirebase() async {
    if (_initialized) return;
    
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      debugPrint('✅ Firebase initialized successfully');
      
      // Enable offline persistence for Firestore
      if (!kIsWeb) {
        await FirebaseFirestore.instance.enablePersistence();
        debugPrint('✅ Firestore offline persistence enabled');
      }
      
      // Set up authentication state listener
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user == null) {
          debugPrint('🔐 User is currently signed out!');
        } else {
          debugPrint('🔐 User is signed in: ${user.email}');
        }
      });
      
    } catch (e) {
      debugPrint('❌ Error initializing Firebase: $e');
      rethrow;
    }
  }

  // Auth instance
  static FirebaseAuth get auth => FirebaseAuth.instance;
  
  // Firestore instance
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  
  // Storage instance
  static FirebaseStorage get storage => FirebaseStorage.instance;
  
  // Check if user is authenticated
  static bool get isAuthenticated => auth.currentUser != null;
  
  // Get current user
  static User? get currentUser => auth.currentUser;
  
  // Get current user ID
  static String? get currentUserId => auth.currentUser?.uid;
  
  // Sign out
  static Future<void> signOut() async {
    try {
      await auth.signOut();
      debugPrint('✅ User signed out successfully');
    } catch (e) {
      debugPrint('❌ Error signing out: $e');
      rethrow;
    }
  }
}

