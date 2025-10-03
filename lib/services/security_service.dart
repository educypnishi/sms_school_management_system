import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  // Password policy configuration
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int passwordHistoryCount = 5;
  static const int passwordExpiryDays = 90;
  static const int maxLoginAttempts = 5;
  static const int accountLockoutMinutes = 30;

  // Encryption configuration
  static const String _saltKey = 'password_salts';
  static const String _passwordHistoryKey = 'password_history';
  static const String _passwordPolicyKey = 'password_policy';
  static const String _encryptionKeyKey = 'encryption_key';

  /// Validate password against policy
  PasswordValidationResult validatePassword(String password, {String? userId}) {
    final errors = <String>[];
    final warnings = <String>[];

    // Length check
    if (password.length < minPasswordLength) {
      errors.add('Password must be at least $minPasswordLength characters long');
    }
    if (password.length > maxPasswordLength) {
      errors.add('Password must not exceed $maxPasswordLength characters');
    }

    // Character requirements
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      errors.add('Password must contain at least one uppercase letter');
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      errors.add('Password must contain at least one lowercase letter');
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      errors.add('Password must contain at least one number');
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      errors.add('Password must contain at least one special character');
    }

    // Common password patterns
    if (_isCommonPassword(password)) {
      errors.add('Password is too common. Please choose a more unique password');
    }

    // Sequential characters
    if (_hasSequentialCharacters(password)) {
      warnings.add('Avoid sequential characters (e.g., 123, abc)');
    }

    // Repeated characters
    if (_hasRepeatedCharacters(password)) {
      warnings.add('Avoid repeated characters (e.g., aaa, 111)');
    }

    // Personal information (if userId provided)
    if (userId != null && _containsPersonalInfo(password, userId)) {
      errors.add('Password should not contain personal information');
    }

    // Calculate strength
    final strength = _calculatePasswordStrength(password);

    return PasswordValidationResult(
      isValid: errors.isEmpty,
      strength: strength,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Hash password with salt
  Future<PasswordHash> hashPassword(String password, {String? userId}) async {
    try {
      // Generate salt
      final salt = _generateSalt();
      
      // Create hash with PBKDF2
      final hash = _pbkdf2Hash(password, salt);
      
      // Store salt for user
      if (userId != null) {
        await _storeSalt(userId, salt);
      }

      return PasswordHash(
        hash: hash,
        salt: salt,
        algorithm: 'PBKDF2-SHA256',
        iterations: 100000,
      );
    } catch (e) {
      debugPrint('Error hashing password: $e');
      throw SecurityException('Failed to hash password');
    }
  }

  /// Verify password against hash
  Future<bool> verifyPassword(String password, String hash, {String? userId, String? salt}) async {
    try {
      String actualSalt = salt ?? '';
      
      // Get salt from storage if userId provided
      if (userId != null && salt == null) {
        actualSalt = await _getSalt(userId) ?? '';
      }

      if (actualSalt.isEmpty) {
        debugPrint('No salt found for password verification');
        return false;
      }

      // Hash the provided password with the same salt
      final computedHash = _pbkdf2Hash(password, actualSalt);
      
      // Compare hashes
      return computedHash == hash;
    } catch (e) {
      debugPrint('Error verifying password: $e');
      return false;
    }
  }

  /// Check password history
  Future<bool> isPasswordInHistory(String userId, String newPassword) async {
    try {
      final history = await _getPasswordHistory(userId);
      
      for (final historicalHash in history) {
        if (await verifyPassword(newPassword, historicalHash.hash, salt: historicalHash.salt)) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking password history: $e');
      return false;
    }
  }

  /// Update password with history tracking
  Future<PasswordUpdateResult> updatePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Validate current password
      final currentSalt = await _getSalt(userId);
      if (currentSalt == null) {
        return PasswordUpdateResult.failure('User not found');
      }

      final currentHash = await _getCurrentPasswordHash(userId);
      if (currentHash == null || !await verifyPassword(currentPassword, currentHash, salt: currentSalt)) {
        return PasswordUpdateResult.failure('Current password is incorrect');
      }

      // Validate new password
      final validation = validatePassword(newPassword, userId: userId);
      if (!validation.isValid) {
        return PasswordUpdateResult.failure('Password validation failed: ${validation.errors.join(', ')}');
      }

      // Check password history
      if (await isPasswordInHistory(userId, newPassword)) {
        return PasswordUpdateResult.failure('Password has been used recently. Please choose a different password');
      }

      // Hash new password
      final newPasswordHash = await hashPassword(newPassword, userId: userId);

      // Update password history
      await _addToPasswordHistory(userId, PasswordHistoryEntry(
        hash: newPasswordHash.hash,
        salt: newPasswordHash.salt,
        createdAt: DateTime.now(),
      ));

      // Store new password hash
      await _storePasswordHash(userId, newPasswordHash.hash);

      return PasswordUpdateResult.success('Password updated successfully');
    } catch (e) {
      debugPrint('Error updating password: $e');
      return PasswordUpdateResult.failure('Failed to update password');
    }
  }

  /// Generate secure random password
  String generateSecurePassword({
    int length = 12,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSpecialChars = true,
  }) {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const specialChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String chars = '';
    if (includeUppercase) chars += uppercase;
    if (includeLowercase) chars += lowercase;
    if (includeNumbers) chars += numbers;
    if (includeSpecialChars) chars += specialChars;

    if (chars.isEmpty) {
      throw ArgumentError('At least one character type must be included');
    }

    final random = Random.secure();
    final password = StringBuffer();

    // Ensure at least one character from each selected type
    if (includeUppercase) password.write(uppercase[random.nextInt(uppercase.length)]);
    if (includeLowercase) password.write(lowercase[random.nextInt(lowercase.length)]);
    if (includeNumbers) password.write(numbers[random.nextInt(numbers.length)]);
    if (includeSpecialChars) password.write(specialChars[random.nextInt(specialChars.length)]);

    // Fill remaining length with random characters
    for (int i = password.length; i < length; i++) {
      password.write(chars[random.nextInt(chars.length)]);
    }

    // Shuffle the password
    final passwordList = password.toString().split('');
    passwordList.shuffle(random);
    
    return passwordList.join('');
  }

  /// Encrypt sensitive data
  String encryptData(String data, {String? key}) {
    try {
      final encryptionKey = key ?? _getDefaultEncryptionKey();
      
      // Simple XOR encryption for demo (use AES in production)
      final dataBytes = utf8.encode(data);
      final keyBytes = utf8.encode(encryptionKey);
      final encryptedBytes = <int>[];

      for (int i = 0; i < dataBytes.length; i++) {
        encryptedBytes.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return base64.encode(encryptedBytes);
    } catch (e) {
      debugPrint('Error encrypting data: $e');
      throw SecurityException('Failed to encrypt data');
    }
  }

  /// Decrypt sensitive data
  String decryptData(String encryptedData, {String? key}) {
    try {
      final encryptionKey = key ?? _getDefaultEncryptionKey();
      
      // Simple XOR decryption for demo (use AES in production)
      final encryptedBytes = base64.decode(encryptedData);
      final keyBytes = utf8.encode(encryptionKey);
      final decryptedBytes = <int>[];

      for (int i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(decryptedBytes);
    } catch (e) {
      debugPrint('Error decrypting data: $e');
      throw SecurityException('Failed to decrypt data');
    }
  }

  /// Generate secure token
  String generateSecureToken({int length = 32}) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Validate token format
  bool isValidToken(String token) {
    // Check if token is valid base64url
    try {
      base64Url.decode(token + '=='); // Add padding
      return token.length >= 16; // Minimum length check
    } catch (e) {
      return false;
    }
  }

  /// Get password policy
  Future<PasswordPolicy> getPasswordPolicy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final policyData = prefs.getString(_passwordPolicyKey);
      
      if (policyData != null) {
        final policyJson = jsonDecode(policyData);
        return PasswordPolicy.fromJson(policyJson);
      }
      
      // Return default policy
      return PasswordPolicy.defaultPolicy();
    } catch (e) {
      debugPrint('Error getting password policy: $e');
      return PasswordPolicy.defaultPolicy();
    }
  }

  /// Update password policy
  Future<void> updatePasswordPolicy(PasswordPolicy policy) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_passwordPolicyKey, jsonEncode(policy.toJson()));
    } catch (e) {
      debugPrint('Error updating password policy: $e');
    }
  }

  // Private helper methods

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }

  String _pbkdf2Hash(String password, String salt) {
    final passwordBytes = utf8.encode(password);
    final saltBytes = base64.decode(salt);
    
    // PBKDF2 implementation (simplified for demo)
    var hmac = Hmac(sha256, passwordBytes);
    var digest = hmac.convert(saltBytes);
    
    // Multiple iterations for security
    for (int i = 0; i < 100000; i++) {
      hmac = Hmac(sha256, digest.bytes);
      digest = hmac.convert(saltBytes);
    }
    
    return base64.encode(digest.bytes);
  }

  bool _isCommonPassword(String password) {
    final commonPasswords = [
      'password', '123456', '123456789', 'qwerty', 'abc123',
      'password123', 'admin', 'letmein', 'welcome', 'monkey',
      'dragon', 'master', 'shadow', 'superman', 'michael',
      'pakistan', 'karachi', 'lahore', 'islamabad', 'school',
    ];
    
    return commonPasswords.contains(password.toLowerCase());
  }

  bool _hasSequentialCharacters(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      final char1 = password.codeUnitAt(i);
      final char2 = password.codeUnitAt(i + 1);
      final char3 = password.codeUnitAt(i + 2);
      
      if (char2 == char1 + 1 && char3 == char2 + 1) {
        return true;
      }
    }
    return false;
  }

  bool _hasRepeatedCharacters(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      if (password[i] == password[i + 1] && password[i + 1] == password[i + 2]) {
        return true;
      }
    }
    return false;
  }

  bool _containsPersonalInfo(String password, String userId) {
    final lowerPassword = password.toLowerCase();
    final lowerUserId = userId.toLowerCase();
    
    // Check if password contains user ID
    if (lowerPassword.contains(lowerUserId)) {
      return true;
    }
    
    // Add more personal info checks as needed
    return false;
  }

  PasswordStrength _calculatePasswordStrength(String password) {
    int score = 0;
    
    // Length scoring
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;
    if (password.length >= 16) score += 1;
    
    // Character variety scoring
    if (RegExp(r'[a-z]').hasMatch(password)) score += 1;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 1;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 1;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 1;
    
    // Complexity scoring
    if (!_hasSequentialCharacters(password)) score += 1;
    if (!_hasRepeatedCharacters(password)) score += 1;
    if (!_isCommonPassword(password)) score += 1;
    
    // Convert score to strength
    if (score <= 3) return PasswordStrength.weak;
    if (score <= 6) return PasswordStrength.medium;
    if (score <= 8) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  Future<void> _storeSalt(String userId, String salt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final salts = await _getAllSalts();
      salts[userId] = salt;
      await prefs.setString(_saltKey, jsonEncode(salts));
    } catch (e) {
      debugPrint('Error storing salt: $e');
    }
  }

  Future<String?> _getSalt(String userId) async {
    try {
      final salts = await _getAllSalts();
      return salts[userId];
    } catch (e) {
      debugPrint('Error getting salt: $e');
      return null;
    }
  }

  Future<Map<String, String>> _getAllSalts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saltsData = prefs.getString(_saltKey);
      
      if (saltsData != null) {
        final saltsJson = jsonDecode(saltsData) as Map<String, dynamic>;
        return saltsJson.cast<String, String>();
      }
      
      return <String, String>{};
    } catch (e) {
      debugPrint('Error getting all salts: $e');
      return <String, String>{};
    }
  }

  Future<void> _addToPasswordHistory(String userId, PasswordHistoryEntry entry) async {
    try {
      final history = await _getPasswordHistory(userId);
      history.add(entry);
      
      // Keep only recent passwords
      if (history.length > passwordHistoryCount) {
        history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        history.removeRange(passwordHistoryCount, history.length);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final allHistory = await _getAllPasswordHistory();
      allHistory[userId] = history.map((e) => e.toJson()).toList();
      await prefs.setString(_passwordHistoryKey, jsonEncode(allHistory));
    } catch (e) {
      debugPrint('Error adding to password history: $e');
    }
  }

  Future<List<PasswordHistoryEntry>> _getPasswordHistory(String userId) async {
    try {
      final allHistory = await _getAllPasswordHistory();
      final userHistory = allHistory[userId] as List<dynamic>? ?? [];
      
      return userHistory.map((json) => PasswordHistoryEntry.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting password history: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _getAllPasswordHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyData = prefs.getString(_passwordHistoryKey);
      
      if (historyData != null) {
        return jsonDecode(historyData) as Map<String, dynamic>;
      }
      
      return <String, dynamic>{};
    } catch (e) {
      debugPrint('Error getting all password history: $e');
      return <String, dynamic>{};
    }
  }

  Future<String?> _getCurrentPasswordHash(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('password_hash_$userId');
    } catch (e) {
      debugPrint('Error getting current password hash: $e');
      return null;
    }
  }

  Future<void> _storePasswordHash(String userId, String hash) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('password_hash_$userId', hash);
    } catch (e) {
      debugPrint('Error storing password hash: $e');
    }
  }

  String _getDefaultEncryptionKey() {
    // In production, this should be securely generated and stored
    return 'SchoolManagementSystem2024SecureKey!';
  }
}

// Data Models and Enums

enum PasswordStrength {
  weak,
  medium,
  strong,
  veryStrong,
}

class PasswordValidationResult {
  final bool isValid;
  final PasswordStrength strength;
  final List<String> errors;
  final List<String> warnings;

  PasswordValidationResult({
    required this.isValid,
    required this.strength,
    required this.errors,
    required this.warnings,
  });
}

class PasswordHash {
  final String hash;
  final String salt;
  final String algorithm;
  final int iterations;

  PasswordHash({
    required this.hash,
    required this.salt,
    required this.algorithm,
    required this.iterations,
  });
}

class PasswordUpdateResult {
  final bool success;
  final String message;

  PasswordUpdateResult._({required this.success, required this.message});

  factory PasswordUpdateResult.success(String message) {
    return PasswordUpdateResult._(success: true, message: message);
  }

  factory PasswordUpdateResult.failure(String message) {
    return PasswordUpdateResult._(success: false, message: message);
  }
}

class PasswordHistoryEntry {
  final String hash;
  final String salt;
  final DateTime createdAt;

  PasswordHistoryEntry({
    required this.hash,
    required this.salt,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'salt': salt,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PasswordHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PasswordHistoryEntry(
      hash: json['hash'],
      salt: json['salt'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class PasswordPolicy {
  final int minLength;
  final int maxLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireNumbers;
  final bool requireSpecialChars;
  final int historyCount;
  final int expiryDays;
  final int maxAttempts;
  final int lockoutMinutes;

  PasswordPolicy({
    required this.minLength,
    required this.maxLength,
    required this.requireUppercase,
    required this.requireLowercase,
    required this.requireNumbers,
    required this.requireSpecialChars,
    required this.historyCount,
    required this.expiryDays,
    required this.maxAttempts,
    required this.lockoutMinutes,
  });

  factory PasswordPolicy.defaultPolicy() {
    return PasswordPolicy(
      minLength: 8,
      maxLength: 128,
      requireUppercase: true,
      requireLowercase: true,
      requireNumbers: true,
      requireSpecialChars: true,
      historyCount: 5,
      expiryDays: 90,
      maxAttempts: 5,
      lockoutMinutes: 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minLength': minLength,
      'maxLength': maxLength,
      'requireUppercase': requireUppercase,
      'requireLowercase': requireLowercase,
      'requireNumbers': requireNumbers,
      'requireSpecialChars': requireSpecialChars,
      'historyCount': historyCount,
      'expiryDays': expiryDays,
      'maxAttempts': maxAttempts,
      'lockoutMinutes': lockoutMinutes,
    };
  }

  factory PasswordPolicy.fromJson(Map<String, dynamic> json) {
    return PasswordPolicy(
      minLength: json['minLength'],
      maxLength: json['maxLength'],
      requireUppercase: json['requireUppercase'],
      requireLowercase: json['requireLowercase'],
      requireNumbers: json['requireNumbers'],
      requireSpecialChars: json['requireSpecialChars'],
      historyCount: json['historyCount'],
      expiryDays: json['expiryDays'],
      maxAttempts: json['maxAttempts'],
      lockoutMinutes: json['lockoutMinutes'],
    );
  }
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}
