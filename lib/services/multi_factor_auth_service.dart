import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class MultiFactorAuthService {
  static final MultiFactorAuthService _instance = MultiFactorAuthService._internal();
  factory MultiFactorAuthService() => _instance;
  MultiFactorAuthService._internal();

  // MFA Configuration
  static const int otpLength = 6;
  static const int otpExpiryMinutes = 5;
  static const int maxAttempts = 3;
  static const int lockoutMinutes = 15;

  // Storage keys
  static const String _otpStorageKey = 'mfa_otp_data';
  static const String _attemptsStorageKey = 'mfa_attempts';
  static const String _lockoutStorageKey = 'mfa_lockout';
  static const String _mfaEnabledKey = 'mfa_enabled';
  static const String _backupCodesKey = 'mfa_backup_codes';

  /// Generate a secure OTP for the user
  Future<MFAResult> generateOTP({
    required String userId,
    required MFAMethod method,
    required String destination, // phone number or email
  }) async {
    try {
      // Check if user is locked out
      if (await _isUserLockedOut(userId)) {
        final lockoutEnd = await _getLockoutEndTime(userId);
        return MFAResult.failure(
          'Account temporarily locked. Try again after ${_formatLockoutTime(lockoutEnd)}',
          MFAErrorType.lockedOut,
        );
      }

      // Generate secure OTP
      final otp = _generateSecureOTP();
      final expiryTime = DateTime.now().add(const Duration(minutes: otpExpiryMinutes));

      // Store OTP data
      await _storeOTPData(userId, otp, method, destination, expiryTime);

      // Send OTP based on method
      bool sent = false;
      switch (method) {
        case MFAMethod.sms:
          sent = await _sendSMSOTP(destination, otp);
          break;
        case MFAMethod.email:
          sent = await _sendEmailOTP(destination, otp);
          break;
        case MFAMethod.whatsapp:
          sent = await _sendWhatsAppOTP(destination, otp);
          break;
      }

      if (sent) {
        return MFAResult.success(
          'OTP sent successfully to ${_maskDestination(destination, method)}',
          data: {
            'method': method.toString(),
            'destination': _maskDestination(destination, method),
            'expiryTime': expiryTime.toIso8601String(),
          },
        );
      } else {
        return MFAResult.failure(
          'Failed to send OTP. Please try again.',
          MFAErrorType.sendFailed,
        );
      }
    } catch (e) {
      debugPrint('Error generating OTP: $e');
      return MFAResult.failure(
        'An error occurred while generating OTP',
        MFAErrorType.systemError,
      );
    }
  }

  /// Verify the OTP entered by the user
  Future<MFAResult> verifyOTP({
    required String userId,
    required String enteredOTP,
  }) async {
    try {
      // Check if user is locked out
      if (await _isUserLockedOut(userId)) {
        final lockoutEnd = await _getLockoutEndTime(userId);
        return MFAResult.failure(
          'Account temporarily locked. Try again after ${_formatLockoutTime(lockoutEnd)}',
          MFAErrorType.lockedOut,
        );
      }

      // Get stored OTP data
      final otpData = await _getOTPData(userId);
      if (otpData == null) {
        return MFAResult.failure(
          'No OTP found. Please request a new one.',
          MFAErrorType.otpNotFound,
        );
      }

      // Check if OTP has expired
      if (DateTime.now().isAfter(otpData.expiryTime)) {
        await _clearOTPData(userId);
        return MFAResult.failure(
          'OTP has expired. Please request a new one.',
          MFAErrorType.otpExpired,
        );
      }

      // Verify OTP
      if (enteredOTP == otpData.otp) {
        // Success - clear OTP data and reset attempts
        await _clearOTPData(userId);
        await _resetFailedAttempts(userId);
        
        return MFAResult.success(
          'OTP verified successfully',
          data: {
            'method': otpData.method.toString(),
            'verifiedAt': DateTime.now().toIso8601String(),
          },
        );
      } else {
        // Failed attempt
        await _incrementFailedAttempts(userId);
        final attempts = await _getFailedAttempts(userId);
        
        if (attempts >= maxAttempts) {
          await _lockoutUser(userId);
          return MFAResult.failure(
            'Too many failed attempts. Account locked for $lockoutMinutes minutes.',
            MFAErrorType.tooManyAttempts,
          );
        } else {
          final remaining = maxAttempts - attempts;
          return MFAResult.failure(
            'Invalid OTP. $remaining attempts remaining.',
            MFAErrorType.invalidOTP,
          );
        }
      }
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return MFAResult.failure(
        'An error occurred while verifying OTP',
        MFAErrorType.systemError,
      );
    }
  }

  /// Verify backup code
  Future<MFAResult> verifyBackupCode({
    required String userId,
    required String backupCode,
  }) async {
    try {
      final backupCodes = await _getBackupCodes(userId);
      if (backupCodes.isEmpty) {
        return MFAResult.failure(
          'No backup codes available',
          MFAErrorType.noBackupCodes,
        );
      }

      // Hash the entered code to compare
      final hashedCode = _hashBackupCode(backupCode);
      
      if (backupCodes.contains(hashedCode)) {
        // Remove used backup code
        backupCodes.remove(hashedCode);
        await _storeBackupCodes(userId, backupCodes);
        
        return MFAResult.success(
          'Backup code verified successfully',
          data: {
            'remainingCodes': backupCodes.length,
            'verifiedAt': DateTime.now().toIso8601String(),
          },
        );
      } else {
        return MFAResult.failure(
          'Invalid backup code',
          MFAErrorType.invalidBackupCode,
        );
      }
    } catch (e) {
      debugPrint('Error verifying backup code: $e');
      return MFAResult.failure(
        'An error occurred while verifying backup code',
        MFAErrorType.systemError,
      );
    }
  }

  /// Enable MFA for a user
  Future<MFAResult> enableMFA({
    required String userId,
    required MFAMethod primaryMethod,
    required String destination,
  }) async {
    try {
      // Generate backup codes
      final backupCodes = _generateBackupCodes();
      
      // Store MFA configuration
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${_mfaEnabledKey}_$userId', true);
      await prefs.setString('mfa_primary_method_$userId', primaryMethod.toString());
      await prefs.setString('mfa_destination_$userId', destination);
      
      // Store backup codes
      await _storeBackupCodes(userId, backupCodes.map(_hashBackupCode).toList());
      
      return MFAResult.success(
        'MFA enabled successfully',
        data: {
          'backupCodes': backupCodes,
          'primaryMethod': primaryMethod.toString(),
          'destination': _maskDestination(destination, primaryMethod),
        },
      );
    } catch (e) {
      debugPrint('Error enabling MFA: $e');
      return MFAResult.failure(
        'Failed to enable MFA',
        MFAErrorType.systemError,
      );
    }
  }

  /// Disable MFA for a user
  Future<MFAResult> disableMFA({
    required String userId,
    required String currentPassword,
  }) async {
    try {
      // In a real app, verify the current password here
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_mfaEnabledKey}_$userId');
      await prefs.remove('mfa_primary_method_$userId');
      await prefs.remove('mfa_destination_$userId');
      await prefs.remove('${_backupCodesKey}_$userId');
      
      // Clear any pending OTP data
      await _clearOTPData(userId);
      await _resetFailedAttempts(userId);
      
      return MFAResult.success('MFA disabled successfully');
    } catch (e) {
      debugPrint('Error disabling MFA: $e');
      return MFAResult.failure(
        'Failed to disable MFA',
        MFAErrorType.systemError,
      );
    }
  }

  /// Check if MFA is enabled for a user
  Future<bool> isMFAEnabled(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('${_mfaEnabledKey}_$userId') ?? false;
    } catch (e) {
      debugPrint('Error checking MFA status: $e');
      return false;
    }
  }

  /// Get MFA configuration for a user
  Future<MFAConfig?> getMFAConfig(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('${_mfaEnabledKey}_$userId') ?? false;
      
      if (!isEnabled) return null;
      
      final methodString = prefs.getString('mfa_primary_method_$userId');
      final destination = prefs.getString('mfa_destination_$userId');
      final backupCodes = await _getBackupCodes(userId);
      
      if (methodString == null || destination == null) return null;
      
      final method = MFAMethod.values.firstWhere(
        (m) => m.toString() == methodString,
        orElse: () => MFAMethod.sms,
      );
      
      return MFAConfig(
        isEnabled: isEnabled,
        primaryMethod: method,
        destination: destination,
        backupCodesCount: backupCodes.length,
      );
    } catch (e) {
      debugPrint('Error getting MFA config: $e');
      return null;
    }
  }

  // Private helper methods

  String _generateSecureOTP() {
    final random = Random.secure();
    String otp = '';
    for (int i = 0; i < otpLength; i++) {
      otp += random.nextInt(10).toString();
    }
    return otp;
  }

  List<String> _generateBackupCodes() {
    final random = Random.secure();
    final codes = <String>[];
    
    for (int i = 0; i < 10; i++) {
      String code = '';
      for (int j = 0; j < 8; j++) {
        code += random.nextInt(10).toString();
      }
      codes.add(code);
    }
    
    return codes;
  }

  String _hashBackupCode(String code) {
    final bytes = utf8.encode(code + 'backup_salt_2024');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _storeOTPData(
    String userId,
    String otp,
    MFAMethod method,
    String destination,
    DateTime expiryTime,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final otpData = {
      'otp': otp,
      'method': method.toString(),
      'destination': destination,
      'expiryTime': expiryTime.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString('${_otpStorageKey}_$userId', jsonEncode(otpData));
  }

  Future<OTPData?> _getOTPData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('${_otpStorageKey}_$userId');
      
      if (dataString == null) return null;
      
      final data = jsonDecode(dataString);
      return OTPData(
        otp: data['otp'],
        method: MFAMethod.values.firstWhere(
          (m) => m.toString() == data['method'],
          orElse: () => MFAMethod.sms,
        ),
        destination: data['destination'],
        expiryTime: DateTime.parse(data['expiryTime']),
        createdAt: DateTime.parse(data['createdAt']),
      );
    } catch (e) {
      debugPrint('Error getting OTP data: $e');
      return null;
    }
  }

  Future<void> _clearOTPData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_otpStorageKey}_$userId');
  }

  Future<bool> _sendSMSOTP(String phoneNumber, String otp) async {
    // Pakistani SMS integration
    try {
      // Integrate with Pakistani SMS providers like:
      // - Jazz Business
      // - Telenor Business
      // - Zong Business
      // - Ufone Business
      
      debugPrint('Sending SMS OTP to $phoneNumber: $otp');
      
      // Simulate SMS sending for demo
      await Future.delayed(const Duration(seconds: 1));
      
      // In production, integrate with actual SMS API
      return true;
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      return false;
    }
  }

  Future<bool> _sendEmailOTP(String email, String otp) async {
    try {
      debugPrint('Sending Email OTP to $email: $otp');
      
      // Simulate email sending for demo
      await Future.delayed(const Duration(seconds: 1));
      
      // In production, integrate with email service
      return true;
    } catch (e) {
      debugPrint('Error sending email: $e');
      return false;
    }
  }

  Future<bool> _sendWhatsAppOTP(String phoneNumber, String otp) async {
    try {
      debugPrint('Sending WhatsApp OTP to $phoneNumber: $otp');
      
      // Simulate WhatsApp sending for demo
      await Future.delayed(const Duration(seconds: 1));
      
      // In production, integrate with WhatsApp Business API
      return true;
    } catch (e) {
      debugPrint('Error sending WhatsApp: $e');
      return false;
    }
  }

  String _maskDestination(String destination, MFAMethod method) {
    switch (method) {
      case MFAMethod.sms:
      case MFAMethod.whatsapp:
        // Mask phone number: +92-300-1234567 -> +92-***-***4567
        if (destination.length > 4) {
          return '${destination.substring(0, destination.length - 4).replaceAll(RegExp(r'\d'), '*')}${destination.substring(destination.length - 4)}';
        }
        return destination;
      case MFAMethod.email:
        // Mask email: user@example.com -> u***@example.com
        final parts = destination.split('@');
        if (parts.length == 2 && parts[0].isNotEmpty) {
          return '${parts[0][0]}***@${parts[1]}';
        }
        return destination;
    }
  }

  Future<void> _incrementFailedAttempts(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getInt('${_attemptsStorageKey}_$userId') ?? 0;
    await prefs.setInt('${_attemptsStorageKey}_$userId', attempts + 1);
  }

  Future<int> _getFailedAttempts(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${_attemptsStorageKey}_$userId') ?? 0;
  }

  Future<void> _resetFailedAttempts(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_attemptsStorageKey}_$userId');
  }

  Future<void> _lockoutUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutEnd = DateTime.now().add(const Duration(minutes: lockoutMinutes));
    await prefs.setString('${_lockoutStorageKey}_$userId', lockoutEnd.toIso8601String());
  }

  Future<bool> _isUserLockedOut(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutString = prefs.getString('${_lockoutStorageKey}_$userId');
    
    if (lockoutString == null) return false;
    
    final lockoutEnd = DateTime.parse(lockoutString);
    if (DateTime.now().isAfter(lockoutEnd)) {
      // Lockout expired, clear it
      await prefs.remove('${_lockoutStorageKey}_$userId');
      await _resetFailedAttempts(userId);
      return false;
    }
    
    return true;
  }

  Future<DateTime?> _getLockoutEndTime(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutString = prefs.getString('${_lockoutStorageKey}_$userId');
    
    if (lockoutString == null) return null;
    
    return DateTime.parse(lockoutString);
  }

  String _formatLockoutTime(DateTime? lockoutEnd) {
    if (lockoutEnd == null) return '';
    
    final remaining = lockoutEnd.difference(DateTime.now());
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    
    return '${minutes}m ${seconds}s';
  }

  Future<List<String>> _getBackupCodes(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final codesString = prefs.getString('${_backupCodesKey}_$userId');
      
      if (codesString == null) return [];
      
      final codesList = jsonDecode(codesString) as List;
      return codesList.cast<String>();
    } catch (e) {
      debugPrint('Error getting backup codes: $e');
      return [];
    }
  }

  Future<void> _storeBackupCodes(String userId, List<String> codes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_backupCodesKey}_$userId', jsonEncode(codes));
  }
}

// Data models

enum MFAMethod {
  sms,
  email,
  whatsapp,
}

enum MFAErrorType {
  invalidOTP,
  otpExpired,
  otpNotFound,
  sendFailed,
  tooManyAttempts,
  lockedOut,
  systemError,
  invalidBackupCode,
  noBackupCodes,
}

class MFAResult {
  final bool success;
  final String message;
  final MFAErrorType? errorType;
  final Map<String, dynamic>? data;

  MFAResult._({
    required this.success,
    required this.message,
    this.errorType,
    this.data,
  });

  factory MFAResult.success(String message, {Map<String, dynamic>? data}) {
    return MFAResult._(
      success: true,
      message: message,
      data: data,
    );
  }

  factory MFAResult.failure(String message, MFAErrorType errorType) {
    return MFAResult._(
      success: false,
      message: message,
      errorType: errorType,
    );
  }
}

class OTPData {
  final String otp;
  final MFAMethod method;
  final String destination;
  final DateTime expiryTime;
  final DateTime createdAt;

  OTPData({
    required this.otp,
    required this.method,
    required this.destination,
    required this.expiryTime,
    required this.createdAt,
  });
}

class MFAConfig {
  final bool isEnabled;
  final MFAMethod primaryMethod;
  final String destination;
  final int backupCodesCount;

  MFAConfig({
    required this.isEnabled,
    required this.primaryMethod,
    required this.destination,
    required this.backupCodesCount,
  });
}
