import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('SplashScreen: Initializing app...');
      // Show splash screen for a moment
      await Future.delayed(const Duration(seconds: 2));
      debugPrint('SplashScreen: Delay completed');
      
      if (!mounted) return;
      
      // Check if user is logged in
      debugPrint('SplashScreen: Checking if user is logged in...');
      final authService = AuthService();
      final user = await authService.getCurrentUser();
      debugPrint('SplashScreen: User check completed. User: ${user?.name ?? 'null'}');
      
      if (user != null) {
        // User is logged in, navigate to appropriate dashboard based on role
        debugPrint('SplashScreen: User is logged in with role: ${user.role}');
        if (user.role == AppConstants.adminRole) {
          debugPrint('SplashScreen: Navigating to admin dashboard');
          Navigator.pushReplacementNamed(context, AppConstants.adminDashboardRoute);
        } else if (user.role == AppConstants.partnerRole) {
          debugPrint('SplashScreen: Navigating to partner dashboard');
          Navigator.pushReplacementNamed(context, AppConstants.partnerDashboardRoute);
        } else {
          debugPrint('SplashScreen: Navigating to student dashboard');
          Navigator.pushReplacementNamed(context, AppConstants.studentDashboardRoute);
        }
      } else {
        // User is not logged in, navigate to login screen
        debugPrint('SplashScreen: User is not logged in, navigating to login screen');
        Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
      }
    } catch (e) {
      debugPrint('Error in splash screen: $e');
      
      if (!mounted) return;
      
      // Navigate to login screen if there's an error
      debugPrint('SplashScreen: Error occurred, navigating to login screen');
      Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            const Icon(
              Icons.school,
              size: 100,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            
            // App Name
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            
            // App Tagline
            Text(
              'Education in Cyprus',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightTextColor,
                  ),
            ),
            const SizedBox(height: 24),
            
            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 32),
            
            // Direct Login Buttons for Testing
            const Text('Quick Login for Testing:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Student Login Button
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppConstants.studentDashboardRoute);
              },
              child: const Text('Login as Student'),
            ),
            const SizedBox(height: 8),
            
            // Partner Login Button
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppConstants.partnerDashboardRoute);
              },
              child: const Text('Login as Partner'),
            ),
            const SizedBox(height: 8),
            
            // Admin Login Button
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppConstants.adminDashboardRoute);
              },
              child: const Text('Login as Admin'),
            ),
          ],
        ),
      )),
    );
  }
}
