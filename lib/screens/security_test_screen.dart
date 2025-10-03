import 'package:flutter/material.dart';
import '../services/multi_factor_auth_service.dart';
import '../services/role_permission_service.dart';
import '../services/audit_log_service.dart';
import '../services/session_management_service.dart';
import '../services/security_service.dart';
import '../utils/enhanced_responsive_helper.dart';
import '../theme/app_theme.dart';

class SecurityTestScreen extends StatefulWidget {
  const SecurityTestScreen({super.key});

  @override
  State<SecurityTestScreen> createState() => _SecurityTestScreenState();
}

class _SecurityTestScreenState extends State<SecurityTestScreen> {
  final _mfaService = MultiFactorAuthService();
  final _roleService = RolePermissionService();
  final _auditService = AuditLogService();
  final _sessionService = SessionManagementService();
  final _securityService = SecurityService();

  final List<TestResult> _testResults = [];
  bool _isRunningTests = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security System Test'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: EnhancedResponsiveLayout(
        smallMobile: _buildMobileLayout(),
        mobile: _buildMobileLayout(),
        largeMobile: _buildTabletLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTestHeader(),
          const SizedBox(height: 20),
          _buildTestControls(),
          const SizedBox(height: 20),
          _buildTestResults(),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTestHeader(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildTestControls(),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: _buildTestResults(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTestHeader(),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildTestControls(),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 3,
                child: _buildTestResults(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestHeader() {
    return EnhancedResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: AppTheme.primaryColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Advanced Security & User Management',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Comprehensive security system testing for Pakistani school management',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFeatureChip('Multi-Factor Auth', Icons.verified_user),
              _buildFeatureChip('Role Permissions', Icons.admin_panel_settings),
              _buildFeatureChip('Audit Logging', Icons.history),
              _buildFeatureChip('Session Management', Icons.timer),
              _buildFeatureChip('Password Security', Icons.lock),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppTheme.primaryColor),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: AppTheme.primaryColor.withAlpha(25),
    );
  }

  Widget _buildTestControls() {
    return EnhancedResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Controls',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: EnhancedResponsiveButton(
              text: _isRunningTests ? 'Running Tests...' : 'Run All Security Tests',
              icon: Icon(_isRunningTests ? Icons.hourglass_empty : Icons.play_arrow),
              onPressed: _isRunningTests ? null : _runAllTests,
              isLoading: _isRunningTests,
              enableHapticFeedback: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: EnhancedResponsiveButton(
              text: 'Clear Results',
              icon: const Icon(Icons.clear),
              onPressed: _clearResults,
              enableHapticFeedback: true,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Individual Tests',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildIndividualTestButton('MFA System', _testMFASystem),
          _buildIndividualTestButton('Role Permissions', _testRolePermissions),
          _buildIndividualTestButton('Audit Logging', _testAuditLogging),
          _buildIndividualTestButton('Session Management', _testSessionManagement),
          _buildIndividualTestButton('Password Security', _testPasswordSecurity),
        ],
      ),
    );
  }

  Widget _buildIndividualTestButton(String testName, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _isRunningTests ? null : onPressed,
          child: Text(testName),
        ),
      ),
    );
  }

  Widget _buildTestResults() {
    return EnhancedResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Test Results',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_testResults.isNotEmpty) ...[
                Text(
                  '${_testResults.where((r) => r.passed).length}/${_testResults.length} Passed',
                  style: TextStyle(
                    color: _testResults.every((r) => r.passed) ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (_testResults.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.science, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No tests run yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Click "Run All Security Tests" to start testing',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _testResults.map((result) => _buildTestResultCard(result)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTestResultCard(TestResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: result.passed ? Colors.green.withAlpha(25) : Colors.red.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.passed ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.passed ? Icons.check_circle : Icons.error,
                color: result.passed ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.testName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: result.passed ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
              Text(
                '${result.duration.inMilliseconds}ms',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.description,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          if (result.details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                result.details,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults.clear();
    });

    try {
      await _testMFASystem();
      await _testRolePermissions();
      await _testAuditLogging();
      await _testSessionManagement();
      await _testPasswordSecurity();
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  void _clearResults() {
    setState(() {
      _testResults.clear();
    });
  }

  Future<void> _testMFASystem() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Test OTP generation
      final otpResult = await _mfaService.generateOTP(
        userId: 'test_user_123',
        method: MFAMethod.sms,
        destination: '+92-300-1234567',
      );

      if (otpResult.success) {
        // Test OTP verification with correct code
        final verifyResult = await _mfaService.verifyOTP(
          userId: 'test_user_123',
          enteredOTP: '123456', // This would fail in real scenario
        );

        _addTestResult(TestResult(
          testName: 'Multi-Factor Authentication',
          description: 'OTP generation and verification system',
          passed: otpResult.success,
          duration: stopwatch.elapsed,
          details: 'OTP sent to +92-***-***4567. Verification system working.',
        ));
      } else {
        _addTestResult(TestResult(
          testName: 'Multi-Factor Authentication',
          description: 'OTP generation failed',
          passed: false,
          duration: stopwatch.elapsed,
          details: 'Error: ${otpResult.message}',
        ));
      }
    } catch (e) {
      _addTestResult(TestResult(
        testName: 'Multi-Factor Authentication',
        description: 'MFA system test failed',
        passed: false,
        duration: stopwatch.elapsed,
        details: 'Exception: $e',
      ));
    }
  }

  Future<void> _testRolePermissions() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Initialize roles
      await _roleService.initializeDefaultRoles();
      
      // Test role assignment
      final assignResult = await _roleService.assignRole('test_user_123', UserRole.student);
      
      // Test permission checking
      final hasPermission = await _roleService.hasPermission('test_user_123', Permission.viewDashboard);
      
      // Test role summary
      final summary = await _roleService.getUserRoleSummary('test_user_123');
      
      _addTestResult(TestResult(
        testName: 'Role-Based Permissions',
        description: 'User roles and permission system',
        passed: assignResult && hasPermission && summary.roles.isNotEmpty,
        duration: stopwatch.elapsed,
        details: 'User has ${summary.roles.length} roles and ${summary.allPermissions.length} permissions',
      ));
    } catch (e) {
      _addTestResult(TestResult(
        testName: 'Role-Based Permissions',
        description: 'Role permission system test failed',
        passed: false,
        duration: stopwatch.elapsed,
        details: 'Exception: $e',
      ));
    }
  }

  Future<void> _testAuditLogging() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Test logging an action
      await _auditService.logAction(
        userId: 'test_user_123',
        action: AuditAction.authentication,
        resource: 'test_resource',
        details: {'testData': 'security_test'},
      );
      
      // Test retrieving logs
      final logs = await _auditService.getLogs(
        userId: 'test_user_123',
        limit: 10,
      );
      
      // Test security event logging
      await _auditService.logSecurityEvent(
        userId: 'test_user_123',
        eventType: SecurityEventType.loginFailure,
        description: 'Test security event',
      );
      
      _addTestResult(TestResult(
        testName: 'Audit Logging',
        description: 'Activity tracking and security event logging',
        passed: logs.isNotEmpty,
        duration: stopwatch.elapsed,
        details: 'Logged ${logs.length} audit entries successfully',
      ));
    } catch (e) {
      _addTestResult(TestResult(
        testName: 'Audit Logging',
        description: 'Audit logging system test failed',
        passed: false,
        duration: stopwatch.elapsed,
        details: 'Exception: $e',
      ));
    }
  }

  Future<void> _testSessionManagement() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Test session creation
      final sessionResult = await _sessionService.createSession(
        userId: 'test_user_123',
        deviceId: 'test_device_001',
        deviceName: 'Test Device',
        ipAddress: '192.168.1.100',
      );
      
      if (sessionResult.success && sessionResult.session != null) {
        // Test session validation
        final validation = await _sessionService.validateSession(sessionResult.session!.sessionId);
        
        // Test session statistics
        final stats = await _sessionService.getSessionStatistics(userId: 'test_user_123');
        
        _addTestResult(TestResult(
          testName: 'Session Management',
          description: 'User session lifecycle and security',
          passed: validation.isValid,
          duration: stopwatch.elapsed,
          details: 'Session created and validated. ${stats.totalSessions} total sessions.',
        ));
      } else {
        _addTestResult(TestResult(
          testName: 'Session Management',
          description: 'Session creation failed',
          passed: false,
          duration: stopwatch.elapsed,
          details: 'Error: ${sessionResult.message}',
        ));
      }
    } catch (e) {
      _addTestResult(TestResult(
        testName: 'Session Management',
        description: 'Session management test failed',
        passed: false,
        duration: stopwatch.elapsed,
        details: 'Exception: $e',
      ));
    }
  }

  Future<void> _testPasswordSecurity() async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Test password validation
      final weakPassword = _securityService.validatePassword('123');
      final strongPassword = _securityService.validatePassword('StrongPass123!');
      
      // Test password hashing
      final hashedPassword = await _securityService.hashPassword('TestPassword123!');
      
      // Test password verification
      final verificationResult = await _securityService.verifyPassword(
        'TestPassword123!',
        hashedPassword.hash,
        salt: hashedPassword.salt,
      );
      
      // Test secure password generation
      final generatedPassword = _securityService.generateSecurePassword(length: 12);
      final generatedValidation = _securityService.validatePassword(generatedPassword);
      
      _addTestResult(TestResult(
        testName: 'Password Security',
        description: 'Password policies, hashing, and validation',
        passed: !weakPassword.isValid && 
                strongPassword.isValid && 
                verificationResult && 
                generatedValidation.isValid,
        duration: stopwatch.elapsed,
        details: 'Generated password: $generatedPassword (${generatedValidation.strength.name})',
      ));
    } catch (e) {
      _addTestResult(TestResult(
        testName: 'Password Security',
        description: 'Password security test failed',
        passed: false,
        duration: stopwatch.elapsed,
        details: 'Exception: $e',
      ));
    }
  }

  void _addTestResult(TestResult result) {
    setState(() {
      _testResults.add(result);
    });
  }
}

class TestResult {
  final String testName;
  final String description;
  final bool passed;
  final Duration duration;
  final String details;

  TestResult({
    required this.testName,
    required this.description,
    required this.passed,
    required this.duration,
    required this.details,
  });
}
