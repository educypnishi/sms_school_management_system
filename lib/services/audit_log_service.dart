import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_model.dart';

class AuditLogService {
  static final AuditLogService _instance = AuditLogService._internal();
  factory AuditLogService() => _instance;
  AuditLogService._internal();

  // Storage configuration
  static const String _logsKey = 'audit_logs';
  static const int _maxLogsInMemory = 1000;
  static const int _maxLogFileSize = 10 * 1024 * 1024; // 10MB
  static const int _logRetentionDays = 90;

  /// Log user action
  Future<void> logAction({
    required String userId,
    required AuditAction action,
    required String resource,
    String? resourceId,
    Map<String, dynamic>? details,
    String? ipAddress,
    String? userAgent,
    AuditResult result = AuditResult.success,
    String? errorMessage,
  }) async {
    try {
      final logEntry = AuditLogEntry(
        id: _generateLogId(),
        userId: userId,
        action: action,
        resource: resource,
        resourceId: resourceId,
        timestamp: DateTime.now(),
        ipAddress: ipAddress,
        userAgent: userAgent,
        details: details ?? {},
        result: result,
        errorMessage: errorMessage,
      );

      await _storeLogEntry(logEntry);
      
      // Log to console in debug mode
      if (kDebugMode) {
        debugPrint('AUDIT: ${logEntry.toString()}');
      }
      
      // Check for suspicious activity
      await _checkSuspiciousActivity(userId, action);
      
    } catch (e) {
      debugPrint('Error logging audit action: $e');
    }
  }

  /// Log authentication events
  Future<void> logAuth({
    required String userId,
    required AuthAction authAction,
    String? ipAddress,
    String? userAgent,
    AuditResult result = AuditResult.success,
    String? errorMessage,
    Map<String, dynamic>? details,
  }) async {
    await logAction(
      userId: userId,
      action: AuditAction.authentication,
      resource: 'auth',
      details: {
        'authAction': authAction.toString(),
        ...?details,
      },
      ipAddress: ipAddress,
      userAgent: userAgent,
      result: result,
      errorMessage: errorMessage,
    );
  }

  /// Log data access events
  Future<void> logDataAccess({
    required String userId,
    required String resource,
    required String resourceId,
    required DataAccessType accessType,
    String? ipAddress,
    Map<String, dynamic>? details,
  }) async {
    await logAction(
      userId: userId,
      action: AuditAction.dataAccess,
      resource: resource,
      resourceId: resourceId,
      details: {
        'accessType': accessType.toString(),
        ...?details,
      },
      ipAddress: ipAddress,
    );
  }

  /// Log system configuration changes
  Future<void> logSystemChange({
    required String userId,
    required String setting,
    required dynamic oldValue,
    required dynamic newValue,
    String? ipAddress,
  }) async {
    await logAction(
      userId: userId,
      action: AuditAction.systemConfiguration,
      resource: 'system_settings',
      resourceId: setting,
      details: {
        'oldValue': oldValue,
        'newValue': newValue,
        'setting': setting,
      },
      ipAddress: ipAddress,
    );
  }

  /// Log security events
  Future<void> logSecurityEvent({
    required String userId,
    required SecurityEventType eventType,
    required String description,
    String? ipAddress,
    String? userAgent,
    AuditResult result = AuditResult.failure,
    Map<String, dynamic>? details,
  }) async {
    await logAction(
      userId: userId,
      action: AuditAction.securityEvent,
      resource: 'security',
      details: {
        'eventType': eventType.toString(),
        'description': description,
        ...?details,
      },
      ipAddress: ipAddress,
      userAgent: userAgent,
      result: result,
    );
  }

  /// Get audit logs with filtering
  Future<List<AuditLogEntry>> getLogs({
    String? userId,
    AuditAction? action,
    String? resource,
    DateTime? startDate,
    DateTime? endDate,
    AuditResult? result,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final allLogs = await _getAllLogs();
      
      // Apply filters
      var filteredLogs = allLogs.where((log) {
        if (userId != null && log.userId != userId) return false;
        if (action != null && log.action != action) return false;
        if (resource != null && log.resource != resource) return false;
        if (result != null && log.result != result) return false;
        if (startDate != null && log.timestamp.isBefore(startDate)) return false;
        if (endDate != null && log.timestamp.isAfter(endDate)) return false;
        return true;
      }).toList();
      
      // Sort by timestamp (newest first)
      filteredLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Apply pagination
      final startIndex = offset;
      final endIndex = (offset + limit).clamp(0, filteredLogs.length);
      
      return filteredLogs.sublist(startIndex, endIndex);
    } catch (e) {
      debugPrint('Error getting audit logs: $e');
      return [];
    }
  }

  /// Get security alerts
  Future<List<SecurityAlert>> getSecurityAlerts({
    DateTime? since,
    int limit = 50,
  }) async {
    try {
      final cutoffTime = since ?? DateTime.now().subtract(const Duration(days: 7));
      
      final logs = await getLogs(
        action: AuditAction.securityEvent,
        startDate: cutoffTime,
        result: AuditResult.failure,
        limit: limit,
      );
      
      final alerts = <SecurityAlert>[];
      
      for (final log in logs) {
        final eventType = SecurityEventType.values.firstWhere(
          (type) => type.toString() == log.details['eventType'],
          orElse: () => SecurityEventType.other,
        );
        
        alerts.add(SecurityAlert(
          id: log.id,
          userId: log.userId,
          eventType: eventType,
          description: log.details['description'] ?? 'Security event',
          timestamp: log.timestamp,
          ipAddress: log.ipAddress,
          severity: _getEventSeverity(eventType),
          resolved: false,
        ));
      }
      
      return alerts;
    } catch (e) {
      debugPrint('Error getting security alerts: $e');
      return [];
    }
  }

  /// Get user activity summary
  Future<UserActivitySummary> getUserActivitySummary(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();
      
      final logs = await getLogs(
        userId: userId,
        startDate: start,
        endDate: end,
        limit: 10000, // Get all logs for analysis
      );
      
      final actionCounts = <AuditAction, int>{};
      final dailyActivity = <String, int>{};
      var lastLoginTime = DateTime.fromMillisecondsSinceEpoch(0);
      var totalSessions = 0;
      var failedLogins = 0;
      
      for (final log in logs) {
        // Count actions
        actionCounts[log.action] = (actionCounts[log.action] ?? 0) + 1;
        
        // Daily activity
        final dateKey = '${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')}';
        dailyActivity[dateKey] = (dailyActivity[dateKey] ?? 0) + 1;
        
        // Authentication stats
        if (log.action == AuditAction.authentication) {
          final authAction = log.details['authAction'];
          if (authAction == AuthAction.login.toString()) {
            if (log.result == AuditResult.success) {
              totalSessions++;
              if (log.timestamp.isAfter(lastLoginTime)) {
                lastLoginTime = log.timestamp;
              }
            } else {
              failedLogins++;
            }
          }
        }
      }
      
      return UserActivitySummary(
        userId: userId,
        period: DateRange(start, end),
        totalActions: logs.length,
        actionBreakdown: actionCounts,
        dailyActivity: dailyActivity,
        lastLoginTime: lastLoginTime.millisecondsSinceEpoch > 0 ? lastLoginTime : null,
        totalSessions: totalSessions,
        failedLoginAttempts: failedLogins,
      );
    } catch (e) {
      debugPrint('Error getting user activity summary: $e');
      return UserActivitySummary(
        userId: userId,
        period: DateRange(DateTime.now(), DateTime.now()),
        totalActions: 0,
        actionBreakdown: {},
        dailyActivity: {},
        lastLoginTime: null,
        totalSessions: 0,
        failedLoginAttempts: 0,
      );
    }
  }

  /// Export audit logs
  Future<String?> exportLogs({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    ExportFormat format = ExportFormat.csv,
  }) async {
    try {
      final logs = await getLogs(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        limit: 10000,
      );
      
      if (logs.isEmpty) return null;
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'audit_logs_$timestamp.${format.name}';
      final file = File('${directory.path}/$fileName');
      
      String content;
      switch (format) {
        case ExportFormat.csv:
          content = _generateCSV(logs);
          break;
        case ExportFormat.json:
          content = _generateJSON(logs);
          break;
      }
      
      await file.writeAsString(content);
      return file.path;
    } catch (e) {
      debugPrint('Error exporting logs: $e');
      return null;
    }
  }

  /// Clean old logs
  Future<void> cleanOldLogs() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: _logRetentionDays));
      final allLogs = await _getAllLogs();
      
      final filteredLogs = allLogs.where((log) => log.timestamp.isAfter(cutoffDate)).toList();
      
      await _storeLogs(filteredLogs);
      
      debugPrint('Cleaned ${allLogs.length - filteredLogs.length} old audit logs');
    } catch (e) {
      debugPrint('Error cleaning old logs: $e');
    }
  }

  // Private helper methods

  String _generateLogId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  Future<void> _storeLogEntry(AuditLogEntry entry) async {
    try {
      final logs = await _getAllLogs();
      logs.add(entry);
      
      // Keep only recent logs in memory
      if (logs.length > _maxLogsInMemory) {
        logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        logs.removeRange(_maxLogsInMemory, logs.length);
      }
      
      await _storeLogs(logs);
    } catch (e) {
      debugPrint('Error storing log entry: $e');
    }
  }

  Future<void> _storeLogs(List<AuditLogEntry> logs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = logs.map((log) => log.toJson()).toList();
      await prefs.setString(_logsKey, jsonEncode(logsJson));
    } catch (e) {
      debugPrint('Error storing logs: $e');
    }
  }

  Future<List<AuditLogEntry>> _getAllLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsString = prefs.getString(_logsKey);
      
      if (logsString == null) return [];
      
      final logsJson = jsonDecode(logsString) as List;
      return logsJson.map((json) => AuditLogEntry.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting all logs: $e');
      return [];
    }
  }

  Future<void> _checkSuspiciousActivity(String userId, AuditAction action) async {
    try {
      // Check for rapid successive actions (potential automation/attack)
      final recentLogs = await getLogs(
        userId: userId,
        startDate: DateTime.now().subtract(const Duration(minutes: 5)),
        limit: 50,
      );
      
      if (recentLogs.length > 30) {
        await logSecurityEvent(
          userId: userId,
          eventType: SecurityEventType.suspiciousActivity,
          description: 'Rapid successive actions detected (${recentLogs.length} actions in 5 minutes)',
          details: {
            'actionCount': recentLogs.length,
            'timeWindow': '5 minutes',
            'lastAction': action.toString(),
          },
        );
      }
      
      // Check for failed login attempts
      if (action == AuditAction.authentication) {
        final failedLogins = recentLogs.where((log) => 
          log.action == AuditAction.authentication && 
          log.result == AuditResult.failure
        ).length;
        
        if (failedLogins > 5) {
          await logSecurityEvent(
            userId: userId,
            eventType: SecurityEventType.bruteForceAttempt,
            description: 'Multiple failed login attempts detected ($failedLogins attempts)',
            details: {
              'failedAttempts': failedLogins,
              'timeWindow': '5 minutes',
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking suspicious activity: $e');
    }
  }

  SecuritySeverity _getEventSeverity(SecurityEventType eventType) {
    switch (eventType) {
      case SecurityEventType.bruteForceAttempt:
      case SecurityEventType.unauthorizedAccess:
      case SecurityEventType.privilegeEscalation:
        return SecuritySeverity.high;
      case SecurityEventType.suspiciousActivity:
      case SecurityEventType.dataExfiltration:
        return SecuritySeverity.medium;
      case SecurityEventType.loginFailure:
      case SecurityEventType.other:
        return SecuritySeverity.low;
    }
  }

  String _generateCSV(List<AuditLogEntry> logs) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('ID,User ID,Action,Resource,Resource ID,Timestamp,IP Address,Result,Error Message,Details');
    
    // Data rows
    for (final log in logs) {
      buffer.writeln([
        log.id,
        log.userId,
        log.action.toString(),
        log.resource,
        log.resourceId ?? '',
        log.timestamp.toIso8601String(),
        log.ipAddress ?? '',
        log.result.toString(),
        log.errorMessage ?? '',
        jsonEncode(log.details),
      ].map((field) => '"${field.toString().replaceAll('"', '""')}"').join(','));
    }
    
    return buffer.toString();
  }

  String _generateJSON(List<AuditLogEntry> logs) {
    return jsonEncode(logs.map((log) => log.toJson()).toList());
  }
}

// Enums and Data Models

enum AuditAction {
  authentication,
  dataAccess,
  dataModification,
  systemConfiguration,
  userManagement,
  securityEvent,
  fileUpload,
  fileDownload,
  reportGeneration,
  paymentProcessing,
}

enum AuthAction {
  login,
  logout,
  passwordChange,
  passwordReset,
  mfaSetup,
  mfaDisable,
  accountLock,
  accountUnlock,
}

enum DataAccessType {
  view,
  create,
  update,
  delete,
  export,
  import,
}

enum SecurityEventType {
  loginFailure,
  bruteForceAttempt,
  unauthorizedAccess,
  suspiciousActivity,
  privilegeEscalation,
  dataExfiltration,
  other,
}

enum AuditResult {
  success,
  failure,
  warning,
}

enum SecuritySeverity {
  low,
  medium,
  high,
  critical,
}

enum ExportFormat {
  csv,
  json,
}

class AuditLogEntry {
  final String id;
  final String userId;
  final AuditAction action;
  final String resource;
  final String? resourceId;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;
  final Map<String, dynamic> details;
  final AuditResult result;
  final String? errorMessage;

  AuditLogEntry({
    required this.id,
    required this.userId,
    required this.action,
    required this.resource,
    this.resourceId,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
    required this.details,
    required this.result,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'action': action.toString(),
      'resource': resource,
      'resourceId': resourceId,
      'timestamp': timestamp.toIso8601String(),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'details': details,
      'result': result.toString(),
      'errorMessage': errorMessage,
    };
  }

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'],
      userId: json['userId'],
      action: AuditAction.values.firstWhere(
        (a) => a.toString() == json['action'],
        orElse: () => AuditAction.dataAccess,
      ),
      resource: json['resource'],
      resourceId: json['resourceId'],
      timestamp: DateTime.parse(json['timestamp']),
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      details: Map<String, dynamic>.from(json['details'] ?? {}),
      result: AuditResult.values.firstWhere(
        (r) => r.toString() == json['result'],
        orElse: () => AuditResult.success,
      ),
      errorMessage: json['errorMessage'],
    );
  }

  @override
  String toString() {
    return 'AuditLog(${action.name}) User:$userId Resource:$resource Result:${result.name} Time:${timestamp.toIso8601String()}';
  }
}

class SecurityAlert {
  final String id;
  final String userId;
  final SecurityEventType eventType;
  final String description;
  final DateTime timestamp;
  final String? ipAddress;
  final SecuritySeverity severity;
  final bool resolved;

  SecurityAlert({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.description,
    required this.timestamp,
    this.ipAddress,
    required this.severity,
    required this.resolved,
  });
}

class UserActivitySummary {
  final String userId;
  final DateRange period;
  final int totalActions;
  final Map<AuditAction, int> actionBreakdown;
  final Map<String, int> dailyActivity;
  final DateTime? lastLoginTime;
  final int totalSessions;
  final int failedLoginAttempts;

  UserActivitySummary({
    required this.userId,
    required this.period,
    required this.totalActions,
    required this.actionBreakdown,
    required this.dailyActivity,
    this.lastLoginTime,
    required this.totalSessions,
    required this.failedLoginAttempts,
  });
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);
}
