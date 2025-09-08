import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

// Custom clipper for wave effect
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height);
    
    var firstControlPoint = Offset(size.width / 4, size.height - 30);
    var firstEndPoint = Offset(size.width / 2, size.height - 20);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);
    
    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 10);
    var secondEndPoint = Offset(size.width, size.height - 30);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

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
        } else if (user.role == AppConstants.teacherRole) {
          debugPrint('SplashScreen: Navigating to teacher dashboard');
          Navigator.pushReplacementNamed(context, AppConstants.teacherDashboardRoute);
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withOpacity(0.8),
              AppTheme.backgroundColor,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            // App Logo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor,
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_outlined,
                size: 80,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            
            // App Name
            Text(
              AppConstants.appName,
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // App Tagline
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'School Management System',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // Animated Wave
            SizedBox(
              height: 40,
              child: ClipPath(
                clipper: WaveClipper(),
                child: Container(
                  color: Colors.white.withOpacity(0.2),
                  height: 40,
                  width: MediaQuery.of(context).size.width,
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            
            // Loading Indicator
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.3),
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 40),
            
            // Direct Login Buttons for Testing
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Quick Login for Testing',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Student Login Button
                  _buildLoginButton(
                    'Login as Student',
                    Icons.person,
                    AppTheme.primaryColor,
                    () => Navigator.pushReplacementNamed(context, AppConstants.studentDashboardRoute),
                  ),
                  const SizedBox(height: 12),
                  
                  // Teacher Login Button
                  _buildLoginButton(
                    'Login as Teacher',
                    Icons.school,
                    AppTheme.secondaryColor,
                    () => Navigator.pushReplacementNamed(context, AppConstants.teacherDashboardRoute),
                  ),
                  const SizedBox(height: 12),
                  
                  // Admin Login Button
                  _buildLoginButton(
                    'Login as Admin',
                    Icons.admin_panel_settings,
                    AppTheme.accentColor,
                    () => Navigator.pushReplacementNamed(context, AppConstants.adminDashboardRoute),
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
      ),
    );
  }
  
  Widget _buildLoginButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
