import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import 'audit_log_service.dart';

class SessionManagementService {
  static final SessionManagementService _instance = SessionManagementService._internal();
  factory SessionManagementService() => _instance;
  SessionManagementService._internal();

  final _auditService = AuditLogService();
  
  // Session configuration
  static const int sessionTimeoutMinutes = 30;
  static const int maxConcurrentSessions = 3;
  static const int sessionExtensionMinutes = 15;
  static const String _sessionsKey = 'user_sessions';
  static const String _currentSessionKey = 'current_session';

  Timer? _sessionTimer;
  StreamController<SessionEvent>? _sessionEventController;

  /// Get session event stream
  Stream<SessionEvent> get sessionEvents {
    _sessionEventController ??= StreamController<SessionEvent>.broadcast();
    return _sessionEventController!.stream;
  }

  /// Create new session
  Future<SessionResult> createSession({
    required String userId,
    required String deviceId,
    required String deviceName,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check existing sessions
      final existingSessions = await getUserSessions(userId);
      
      // Remove expired sessions
      await _cleanExpiredSessions(userId);
      
      // Check concurrent session limit
      final activeSessions = existingSessions.where((s) => s.isActive).toList();
      if (activeSessions.length >= maxConcurrentSessions) {
        // Terminate oldest session
        activeSessions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        await terminateSession(activeSessions.first.sessionId, 'Session limit exceeded');
      }

      // Generate session
      final session = UserSession(
        sessionId: _generateSessionId(),
        userId: userId,
        deviceId: deviceId,
        deviceName: deviceName,
        ipAddress: ipAddress,
        userAgent: userAgent,
        createdAt: DateTime.now(),
        lastAccessedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: sessionTimeoutMinutes)),
        isActive: true,
        metadata: metadata ?? {},
      );

      // Store session
      await _storeSession(session);
      await _setCurrentSession(session);

      // Start session monitoring
      _startSessionMonitoring();

      // Log session creation
      await _auditService.logAuth(
        userId: userId,
        authAction: AuthAction.login,
        ipAddress: ipAddress,
        userAgent: userAgent,
        result: AuditResult.success,
        details: {
          'sessionId': session.sessionId,
          'deviceId': deviceId,
          'deviceName': deviceName,
        },
      );

      // Emit session event
      _emitSessionEvent(SessionEvent(
        type: SessionEventType.sessionCreated,
        sessionId: session.sessionId,
        userId: userId,
        timestamp: DateTime.now(),
      ));

      return SessionResult.success(
        'Session created successfully',
        session: session,
      );
    } catch (e) {
      debugPrint('Error creating session: $e');
      return SessionResult.failure('Failed to create session');
    }
  }

  /// Validate session
  Future<SessionValidationResult> validateSession(String sessionId) async {
    try {
      final session = await getSession(sessionId);
      
      if (session == null) {
        return SessionValidationResult(
          isValid: false,
          reason: 'Session not found',
        );
      }

      if (!session.isActive) {
        return SessionValidationResult(
          isValid: false,
          reason: 'Session is inactive',
        );
      }

      if (DateTime.now().isAfter(session.expiresAt)) {
        await terminateSession(sessionId, 'Session expired');
        return SessionValidationResult(
          isValid: false,
          reason: 'Session expired',
        );
      }

      // Update last accessed time
      await _updateSessionAccess(sessionId);

      return SessionValidationResult(
        isValid: true,
        session: session,
      );
    } catch (e) {
      debugPrint('Error validating session: $e');
      return SessionValidationResult(
        isValid: false,
        reason: 'Validation error',
      );
    }
  }

  /// Extend session
  Future<SessionResult> extendSession(String sessionId) async {
    try {
      final session = await getSession(sessionId);
      
      if (session == null) {
        return SessionResult.failure('Session not found');
      }

      if (!session.isActive) {
        return SessionResult.failure('Session is inactive');
      }

      // Extend expiration time
      final newExpiryTime = DateTime.now().add(const Duration(minutes: sessionExtensionMinutes));
      final updatedSession = session.copyWith(
        expiresAt: newExpiryTime,
        lastAccessedAt: DateTime.now(),
      );

      await _storeSession(updatedSession);

      // Log session extension
      await _auditService.logAction(
        userId: session.userId,
        action: AuditAction.authentication,
        resource: 'session',
        resourceId: sessionId,
        details: {
          'action': 'extend',
          'newExpiryTime': newExpiryTime.toIso8601String(),
        },
      );

      return SessionResult.success(
        'Session extended successfully',
        session: updatedSession,
      );
    } catch (e) {
      debugPrint('Error extending session: $e');
      return SessionResult.failure('Failed to extend session');
    }
  }

  /// Terminate session
  Future<SessionResult> terminateSession(String sessionId, [String? reason]) async {
    try {
      final session = await getSession(sessionId);
      
      if (session == null) {
        return SessionResult.failure('Session not found');
      }

      // Mark session as inactive
      final terminatedSession = session.copyWith(
        isActive: false,
        terminatedAt: DateTime.now(),
        terminationReason: reason ?? 'Manual termination',
      );

      await _storeSession(terminatedSession);

      // Clear current session if it's the one being terminated
      final currentSession = await getCurrentSession();
      if (currentSession?.sessionId == sessionId) {
        await _clearCurrentSession();
        _stopSessionMonitoring();
      }

      // Log session termination
      await _auditService.logAuth(
        userId: session.userId,
        authAction: AuthAction.logout,
        details: {
          'sessionId': sessionId,
          'reason': reason ?? 'Manual termination',
          'duration': DateTime.now().difference(session.createdAt).inMinutes,
        },
      );

      // Emit session event
      _emitSessionEvent(SessionEvent(
        type: SessionEventType.sessionTerminated,
        sessionId: sessionId,
        userId: session.userId,
        timestamp: DateTime.now(),
        metadata: {'reason': reason},
      ));

      return SessionResult.success(
        'Session terminated successfully',
        session: terminatedSession,
      );
    } catch (e) {
      debugPrint('Error terminating session: $e');
      return SessionResult.failure('Failed to terminate session');
    }
  }

  /// Terminate all user sessions
  Future<SessionResult> terminateAllUserSessions(String userId, [String? reason]) async {
    try {
      final sessions = await getUserSessions(userId);
      final activeSessions = sessions.where((s) => s.isActive).toList();
      
      for (final session in activeSessions) {
        await terminateSession(session.sessionId, reason ?? 'All sessions terminated');
      }

      return SessionResult.success(
        'All sessions terminated successfully (${activeSessions.length} sessions)',
      );
    } catch (e) {
      debugPrint('Error terminating all sessions: $e');
      return SessionResult.failure('Failed to terminate all sessions');
    }
  }

  /// Get current session
  Future<UserSession?> getCurrentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = prefs.getString(_currentSessionKey);
      
      if (sessionData == null) return null;
      
      final sessionJson = jsonDecode(sessionData);
      return UserSession.fromJson(sessionJson);
    } catch (e) {
      debugPrint('Error getting current session: $e');
      return null;
    }
  }

  /// Get session by ID
  Future<UserSession?> getSession(String sessionId) async {
    try {
      final allSessions = await _getAllSessions();
      return allSessions.firstWhere(
        (session) => session.sessionId == sessionId,
        orElse: () => throw StateError('Session not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get user sessions
  Future<List<UserSession>> getUserSessions(String userId) async {
    try {
      final allSessions = await _getAllSessions();
      return allSessions.where((session) => session.userId == userId).toList();
    } catch (e) {
      debugPrint('Error getting user sessions: $e');
      return [];
    }
  }

  /// Get active sessions count
  Future<int> getActiveSessionsCount(String userId) async {
    final sessions = await getUserSessions(userId);
    return sessions.where((s) => s.isActive && DateTime.now().isBefore(s.expiresAt)).length;
  }

  /// Check for suspicious sessions
  Future<List<SuspiciousSession>> getSuspiciousSessions(String userId) async {
    try {
      final sessions = await getUserSessions(userId);
      final suspiciousSessions = <SuspiciousSession>[];
      
      for (final session in sessions.where((s) => s.isActive)) {
        final suspicionReasons = <String>[];
        
        // Check for unusual IP address
        final userSessions = sessions.where((s) => s.userId == userId).toList();
        final commonIPs = userSessions
            .where((s) => s.ipAddress != null)
            .map((s) => s.ipAddress!)
            .toSet();
        
        if (session.ipAddress != null && commonIPs.length > 1) {
          final ipCount = userSessions.where((s) => s.ipAddress == session.ipAddress).length;
          if (ipCount == 1) {
            suspicionReasons.add('Unusual IP address');
          }
        }
        
        // Check for unusual device
        final deviceCount = userSessions.where((s) => s.deviceId == session.deviceId).length;
        if (deviceCount == 1) {
          suspicionReasons.add('New device');
        }
        
        // Check for concurrent sessions from different locations
        final concurrentSessions = sessions.where((s) => 
          s.isActive && 
          s.sessionId != session.sessionId &&
          s.ipAddress != session.ipAddress
        ).toList();
        
        if (concurrentSessions.isNotEmpty) {
          suspicionReasons.add('Concurrent sessions from different locations');
        }
        
        if (suspicionReasons.isNotEmpty) {
          suspiciousSessions.add(SuspiciousSession(
            session: session,
            suspicionReasons: suspicionReasons,
            riskLevel: _calculateRiskLevel(suspicionReasons),
          ));
        }
      }
      
      return suspiciousSessions;
    } catch (e) {
      debugPrint('Error getting suspicious sessions: $e');
      return [];
    }
  }

  /// Clean expired sessions
  Future<void> cleanExpiredSessions() async {
    try {
      final allSessions = await _getAllSessions();
      final now = DateTime.now();
      
      final activeSessions = allSessions.where((session) {
        if (!session.isActive) return true; // Keep inactive sessions for audit
        return now.isBefore(session.expiresAt);
      }).toList();
      
      // Terminate expired sessions
      final expiredSessions = allSessions.where((session) => 
        session.isActive && now.isAfter(session.expiresAt)
      ).toList();
      
      for (final session in expiredSessions) {
        await terminateSession(session.sessionId, 'Session expired');
      }
      
      debugPrint('Cleaned ${expiredSessions.length} expired sessions');
    } catch (e) {
      debugPrint('Error cleaning expired sessions: $e');
    }
  }

  /// Get session statistics
  Future<SessionStatistics> getSessionStatistics({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final allSessions = await _getAllSessions();
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();
      
      var filteredSessions = allSessions.where((session) {
        if (userId != null && session.userId != userId) return false;
        return session.createdAt.isAfter(start) && session.createdAt.isBefore(end);
      }).toList();
      
      final totalSessions = filteredSessions.length;
      final activeSessions = filteredSessions.where((s) => s.isActive).length;
      final expiredSessions = filteredSessions.where((s) => 
        !s.isActive && s.terminationReason == 'Session expired'
      ).length;
      
      // Calculate average session duration
      final completedSessions = filteredSessions.where((s) => 
        !s.isActive && s.terminatedAt != null
      ).toList();
      
      double averageDuration = 0;
      if (completedSessions.isNotEmpty) {
        final totalDuration = completedSessions.fold<int>(0, (sum, session) => 
          sum + session.terminatedAt!.difference(session.createdAt).inMinutes
        );
        averageDuration = totalDuration / completedSessions.length;
      }
      
      // Device breakdown
      final deviceBreakdown = <String, int>{};
      for (final session in filteredSessions) {
        deviceBreakdown[session.deviceName] = (deviceBreakdown[session.deviceName] ?? 0) + 1;
      }
      
      return SessionStatistics(
        totalSessions: totalSessions,
        activeSessions: activeSessions,
        expiredSessions: expiredSessions,
        averageSessionDuration: averageDuration,
        deviceBreakdown: deviceBreakdown,
        period: DateRange(start, end),
      );
    } catch (e) {
      debugPrint('Error getting session statistics: $e');
      return SessionStatistics(
        totalSessions: 0,
        activeSessions: 0,
        expiredSessions: 0,
        averageSessionDuration: 0,
        deviceBreakdown: {},
        period: DateRange(DateTime.now(), DateTime.now()),
      );
    }
  }

  // Private helper methods

  String _generateSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  Future<void> _storeSession(UserSession session) async {
    try {
      final allSessions = await _getAllSessions();
      
      // Remove existing session with same ID
      allSessions.removeWhere((s) => s.sessionId == session.sessionId);
      
      // Add updated session
      allSessions.add(session);
      
      // Store all sessions
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = allSessions.map((s) => s.toJson()).toList();
      await prefs.setString(_sessionsKey, jsonEncode(sessionsJson));
    } catch (e) {
      debugPrint('Error storing session: $e');
    }
  }

  Future<List<UserSession>> _getAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsData = prefs.getString(_sessionsKey);
      
      if (sessionsData == null) return [];
      
      final sessionsJson = jsonDecode(sessionsData) as List;
      return sessionsJson.map((json) => UserSession.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting all sessions: $e');
      return [];
    }
  }

  Future<void> _setCurrentSession(UserSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentSessionKey, jsonEncode(session.toJson()));
    } catch (e) {
      debugPrint('Error setting current session: $e');
    }
  }

  Future<void> _clearCurrentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentSessionKey);
    } catch (e) {
      debugPrint('Error clearing current session: $e');
    }
  }

  Future<void> _updateSessionAccess(String sessionId) async {
    try {
      final session = await getSession(sessionId);
      if (session != null) {
        final updatedSession = session.copyWith(lastAccessedAt: DateTime.now());
        await _storeSession(updatedSession);
        
        // Update current session if it's the one being accessed
        final currentSession = await getCurrentSession();
        if (currentSession?.sessionId == sessionId) {
          await _setCurrentSession(updatedSession);
        }
      }
    } catch (e) {
      debugPrint('Error updating session access: $e');
    }
  }

  Future<void> _cleanExpiredSessions(String userId) async {
    final sessions = await getUserSessions(userId);
    final now = DateTime.now();
    
    for (final session in sessions) {
      if (session.isActive && now.isAfter(session.expiresAt)) {
        await terminateSession(session.sessionId, 'Session expired');
      }
    }
  }

  void _startSessionMonitoring() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await cleanExpiredSessions();
      
      // Check current session
      final currentSession = await getCurrentSession();
      if (currentSession != null) {
        final validation = await validateSession(currentSession.sessionId);
        if (!validation.isValid) {
          _emitSessionEvent(SessionEvent(
            type: SessionEventType.sessionExpired,
            sessionId: currentSession.sessionId,
            userId: currentSession.userId,
            timestamp: DateTime.now(),
          ));
        }
      }
    });
  }

  void _stopSessionMonitoring() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  void _emitSessionEvent(SessionEvent event) {
    _sessionEventController?.add(event);
  }

  RiskLevel _calculateRiskLevel(List<String> suspicionReasons) {
    if (suspicionReasons.length >= 3) return RiskLevel.high;
    if (suspicionReasons.length >= 2) return RiskLevel.medium;
    return RiskLevel.low;
  }

  void dispose() {
    _sessionTimer?.cancel();
    _sessionEventController?.close();
  }
}

// Data Models and Enums

enum SessionEventType {
  sessionCreated,
  sessionTerminated,
  sessionExpired,
  sessionExtended,
}

enum RiskLevel {
  low,
  medium,
  high,
}

class UserSession {
  final String sessionId;
  final String userId;
  final String deviceId;
  final String deviceName;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;
  final DateTime lastAccessedAt;
  final DateTime expiresAt;
  final bool isActive;
  final DateTime? terminatedAt;
  final String? terminationReason;
  final Map<String, dynamic> metadata;

  UserSession({
    required this.sessionId,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
    required this.lastAccessedAt,
    required this.expiresAt,
    required this.isActive,
    this.terminatedAt,
    this.terminationReason,
    required this.metadata,
  });

  UserSession copyWith({
    String? sessionId,
    String? userId,
    String? deviceId,
    String? deviceName,
    String? ipAddress,
    String? userAgent,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
    DateTime? expiresAt,
    bool? isActive,
    DateTime? terminatedAt,
    String? terminationReason,
    Map<String, dynamic>? metadata,
  }) {
    return UserSession(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      terminatedAt: terminatedAt ?? this.terminatedAt,
      terminationReason: terminationReason ?? this.terminationReason,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'createdAt': createdAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isActive': isActive,
      'terminatedAt': terminatedAt?.toIso8601String(),
      'terminationReason': terminationReason,
      'metadata': metadata,
    };
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      sessionId: json['sessionId'],
      userId: json['userId'],
      deviceId: json['deviceId'],
      deviceName: json['deviceName'],
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      createdAt: DateTime.parse(json['createdAt']),
      lastAccessedAt: DateTime.parse(json['lastAccessedAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      isActive: json['isActive'],
      terminatedAt: json['terminatedAt'] != null ? DateTime.parse(json['terminatedAt']) : null,
      terminationReason: json['terminationReason'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

class SessionResult {
  final bool success;
  final String message;
  final UserSession? session;

  SessionResult._({
    required this.success,
    required this.message,
    this.session,
  });

  factory SessionResult.success(String message, {UserSession? session}) {
    return SessionResult._(success: true, message: message, session: session);
  }

  factory SessionResult.failure(String message) {
    return SessionResult._(success: false, message: message);
  }
}

class SessionValidationResult {
  final bool isValid;
  final String? reason;
  final UserSession? session;

  SessionValidationResult({
    required this.isValid,
    this.reason,
    this.session,
  });
}

class SessionEvent {
  final SessionEventType type;
  final String sessionId;
  final String userId;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  SessionEvent({
    required this.type,
    required this.sessionId,
    required this.userId,
    required this.timestamp,
    this.metadata,
  });
}

class SuspiciousSession {
  final UserSession session;
  final List<String> suspicionReasons;
  final RiskLevel riskLevel;

  SuspiciousSession({
    required this.session,
    required this.suspicionReasons,
    required this.riskLevel,
  });
}

class SessionStatistics {
  final int totalSessions;
  final int activeSessions;
  final int expiredSessions;
  final double averageSessionDuration;
  final Map<String, int> deviceBreakdown;
  final DateRange period;

  SessionStatistics({
    required this.totalSessions,
    required this.activeSessions,
    required this.expiredSessions,
    required this.averageSessionDuration,
    required this.deviceBreakdown,
    required this.period,
  });
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);
}
