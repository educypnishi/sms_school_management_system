import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class RolePermissionService {
  static final RolePermissionService _instance = RolePermissionService._internal();
  factory RolePermissionService() => _instance;
  RolePermissionService._internal();

  // Storage keys
  static const String _userRolesKey = 'user_roles';
  static const String _rolePermissionsKey = 'role_permissions';
  static const String _userPermissionsKey = 'user_permissions';

  // Initialize default roles and permissions
  Future<void> initializeDefaultRoles() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if roles are already initialized
    if (prefs.containsKey(_rolePermissionsKey)) {
      return;
    }

    // Define default roles and their permissions
    final defaultRoles = {
      UserRole.superAdmin: _getSuperAdminPermissions(),
      UserRole.admin: _getAdminPermissions(),
      UserRole.teacher: _getTeacherPermissions(),
      UserRole.student: _getStudentPermissions(),
      UserRole.parent: _getParentPermissions(),
      UserRole.accountant: _getAccountantPermissions(),
      UserRole.librarian: _getLibrarianPermissions(),
    };

    // Store default roles
    final roleData = <String, List<String>>{};
    for (final entry in defaultRoles.entries) {
      roleData[entry.key.toString()] = entry.value.map((p) => p.toString()).toList();
    }

    await prefs.setString(_rolePermissionsKey, jsonEncode(roleData));
    debugPrint('Default roles and permissions initialized');
  }

  /// Assign role to user
  Future<bool> assignRole(String userId, UserRole role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get current user roles
      final userRoles = await getUserRoles(userId);
      
      // Add new role if not already present
      if (!userRoles.contains(role)) {
        userRoles.add(role);
        
        // Store updated roles
        final rolesData = <String, List<String>>{};
        final existingData = prefs.getString(_userRolesKey);
        if (existingData != null) {
          final decoded = jsonDecode(existingData) as Map<String, dynamic>;
          rolesData.addAll(decoded.cast<String, List<String>>());
        }
        
        rolesData[userId] = userRoles.map((r) => r.toString()).toList();
        await prefs.setString(_userRolesKey, jsonEncode(rolesData));
        
        debugPrint('Role $role assigned to user $userId');
        return true;
      }
      
      return false; // Role already assigned
    } catch (e) {
      debugPrint('Error assigning role: $e');
      return false;
    }
  }

  /// Remove role from user
  Future<bool> removeRole(String userId, UserRole role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get current user roles
      final userRoles = await getUserRoles(userId);
      
      // Remove role if present
      if (userRoles.contains(role)) {
        userRoles.remove(role);
        
        // Store updated roles
        final rolesData = <String, List<String>>{};
        final existingData = prefs.getString(_userRolesKey);
        if (existingData != null) {
          final decoded = jsonDecode(existingData) as Map<String, dynamic>;
          rolesData.addAll(decoded.cast<String, List<String>>());
        }
        
        rolesData[userId] = userRoles.map((r) => r.toString()).toList();
        await prefs.setString(_userRolesKey, jsonEncode(rolesData));
        
        debugPrint('Role $role removed from user $userId');
        return true;
      }
      
      return false; // Role not found
    } catch (e) {
      debugPrint('Error removing role: $e');
      return false;
    }
  }

  /// Get user roles
  Future<List<UserRole>> getUserRoles(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rolesData = prefs.getString(_userRolesKey);
      
      if (rolesData == null) return [];
      
      final decoded = jsonDecode(rolesData) as Map<String, dynamic>;
      final userRoleStrings = (decoded[userId] as List<dynamic>?)?.cast<String>() ?? [];
      
      return userRoleStrings.map((roleString) {
        return UserRole.values.firstWhere(
          (role) => role.toString() == roleString,
          orElse: () => UserRole.student, // Default fallback
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting user roles: $e');
      return [];
    }
  }

  /// Get user permissions (combined from all roles)
  Future<List<Permission>> getUserPermissions(String userId) async {
    try {
      final userRoles = await getUserRoles(userId);
      final allPermissions = <Permission>{};
      
      // Get permissions from all user roles
      for (final role in userRoles) {
        final rolePermissions = await getRolePermissions(role);
        allPermissions.addAll(rolePermissions);
      }
      
      // Get additional user-specific permissions
      final userSpecificPermissions = await getUserSpecificPermissions(userId);
      allPermissions.addAll(userSpecificPermissions);
      
      return allPermissions.toList();
    } catch (e) {
      debugPrint('Error getting user permissions: $e');
      return [];
    }
  }

  /// Get permissions for a specific role
  Future<List<Permission>> getRolePermissions(UserRole role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roleData = prefs.getString(_rolePermissionsKey);
      
      if (roleData == null) return [];
      
      final decoded = jsonDecode(roleData) as Map<String, dynamic>;
      final permissionStrings = (decoded[role.toString()] as List<dynamic>?)?.cast<String>() ?? [];
      
      return permissionStrings.map((permString) {
        return Permission.values.firstWhere(
          (perm) => perm.toString() == permString,
          orElse: () => Permission.viewDashboard, // Default fallback
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting role permissions: $e');
      return [];
    }
  }

  /// Check if user has specific permission
  Future<bool> hasPermission(String userId, Permission permission) async {
    final userPermissions = await getUserPermissions(userId);
    return userPermissions.contains(permission);
  }

  /// Check if user has any of the specified permissions
  Future<bool> hasAnyPermission(String userId, List<Permission> permissions) async {
    final userPermissions = await getUserPermissions(userId);
    return permissions.any((perm) => userPermissions.contains(perm));
  }

  /// Check if user has all specified permissions
  Future<bool> hasAllPermissions(String userId, List<Permission> permissions) async {
    final userPermissions = await getUserPermissions(userId);
    return permissions.every((perm) => userPermissions.contains(perm));
  }

  /// Grant specific permission to user (beyond role permissions)
  Future<bool> grantUserPermission(String userId, Permission permission) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get current user-specific permissions
      final userPermissions = await getUserSpecificPermissions(userId);
      
      if (!userPermissions.contains(permission)) {
        userPermissions.add(permission);
        
        // Store updated permissions
        final permissionsData = <String, List<String>>{};
        final existingData = prefs.getString(_userPermissionsKey);
        if (existingData != null) {
          final decoded = jsonDecode(existingData) as Map<String, dynamic>;
          permissionsData.addAll(decoded.cast<String, List<String>>());
        }
        
        permissionsData[userId] = userPermissions.map((p) => p.toString()).toList();
        await prefs.setString(_userPermissionsKey, jsonEncode(permissionsData));
        
        debugPrint('Permission $permission granted to user $userId');
        return true;
      }
      
      return false; // Permission already granted
    } catch (e) {
      debugPrint('Error granting user permission: $e');
      return false;
    }
  }

  /// Revoke specific permission from user
  Future<bool> revokeUserPermission(String userId, Permission permission) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get current user-specific permissions
      final userPermissions = await getUserSpecificPermissions(userId);
      
      if (userPermissions.contains(permission)) {
        userPermissions.remove(permission);
        
        // Store updated permissions
        final permissionsData = <String, List<String>>{};
        final existingData = prefs.getString(_userPermissionsKey);
        if (existingData != null) {
          final decoded = jsonDecode(existingData) as Map<String, dynamic>;
          permissionsData.addAll(decoded.cast<String, List<String>>());
        }
        
        permissionsData[userId] = userPermissions.map((p) => p.toString()).toList();
        await prefs.setString(_userPermissionsKey, jsonEncode(permissionsData));
        
        debugPrint('Permission $permission revoked from user $userId');
        return true;
      }
      
      return false; // Permission not found
    } catch (e) {
      debugPrint('Error revoking user permission: $e');
      return false;
    }
  }

  /// Get user-specific permissions (not from roles)
  Future<List<Permission>> getUserSpecificPermissions(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final permissionsData = prefs.getString(_userPermissionsKey);
      
      if (permissionsData == null) return [];
      
      final decoded = jsonDecode(permissionsData) as Map<String, dynamic>;
      final permissionStrings = (decoded[userId] as List<dynamic>?)?.cast<String>() ?? [];
      
      return permissionStrings.map((permString) {
        return Permission.values.firstWhere(
          (perm) => perm.toString() == permString,
          orElse: () => Permission.viewDashboard, // Default fallback
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting user-specific permissions: $e');
      return [];
    }
  }

  /// Get all users with a specific role
  Future<List<String>> getUsersWithRole(UserRole role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rolesData = prefs.getString(_userRolesKey);
      
      if (rolesData == null) return [];
      
      final decoded = jsonDecode(rolesData) as Map<String, dynamic>;
      final usersWithRole = <String>[];
      
      for (final entry in decoded.entries) {
        final userId = entry.key;
        final userRoleStrings = (entry.value as List<dynamic>).cast<String>();
        
        if (userRoleStrings.contains(role.toString())) {
          usersWithRole.add(userId);
        }
      }
      
      return usersWithRole;
    } catch (e) {
      debugPrint('Error getting users with role: $e');
      return [];
    }
  }

  /// Get user role summary
  Future<UserRoleSummary> getUserRoleSummary(String userId) async {
    final roles = await getUserRoles(userId);
    final permissions = await getUserPermissions(userId);
    final specificPermissions = await getUserSpecificPermissions(userId);
    
    return UserRoleSummary(
      userId: userId,
      roles: roles,
      allPermissions: permissions,
      specificPermissions: specificPermissions,
      highestRole: _getHighestRole(roles),
    );
  }

  /// Get the highest priority role
  UserRole _getHighestRole(List<UserRole> roles) {
    if (roles.isEmpty) return UserRole.student;
    
    // Role hierarchy (highest to lowest)
    const hierarchy = [
      UserRole.superAdmin,
      UserRole.admin,
      UserRole.teacher,
      UserRole.accountant,
      UserRole.librarian,
      UserRole.parent,
      UserRole.student,
    ];
    
    for (final role in hierarchy) {
      if (roles.contains(role)) {
        return role;
      }
    }
    
    return UserRole.student;
  }

  // Default permission sets for each role

  List<Permission> _getSuperAdminPermissions() {
    return Permission.values; // All permissions
  }

  List<Permission> _getAdminPermissions() {
    return [
      // User Management
      Permission.viewUsers,
      Permission.createUser,
      Permission.editUser,
      Permission.deleteUser,
      Permission.manageRoles,
      
      // Academic Management
      Permission.viewStudents,
      Permission.editStudent,
      Permission.viewTeachers,
      Permission.editTeacher,
      Permission.manageClasses,
      Permission.manageCourses,
      Permission.viewGrades,
      Permission.editGrades,
      
      // Financial Management
      Permission.viewFees,
      Permission.manageFees,
      Permission.viewPayments,
      Permission.processPayments,
      Permission.viewFinancialReports,
      
      // System Management
      Permission.viewDashboard,
      Permission.viewReports,
      Permission.manageSettings,
      Permission.viewAuditLogs,
      Permission.manageNotifications,
      
      // Attendance & Scheduling
      Permission.viewAttendance,
      Permission.manageAttendance,
      Permission.manageTimetable,
      
      // Communication
      Permission.sendNotifications,
      Permission.viewMessages,
      Permission.sendMessages,
    ];
  }

  List<Permission> _getTeacherPermissions() {
    return [
      // Basic Access
      Permission.viewDashboard,
      
      // Student Management
      Permission.viewStudents,
      Permission.viewGrades,
      Permission.editGrades,
      
      // Class Management
      Permission.viewClasses,
      Permission.manageAttendance,
      Permission.viewAttendance,
      
      // Academic
      Permission.viewCourses,
      Permission.manageCourses,
      Permission.viewTimetable,
      
      // Communication
      Permission.viewMessages,
      Permission.sendMessages,
      Permission.sendNotifications,
      
      // Reports
      Permission.viewReports,
    ];
  }

  List<Permission> _getStudentPermissions() {
    return [
      // Basic Access
      Permission.viewDashboard,
      
      // Academic
      Permission.viewGrades,
      Permission.viewCourses,
      Permission.viewTimetable,
      Permission.viewAttendance,
      
      // Financial
      Permission.viewFees,
      Permission.viewPayments,
      
      // Communication
      Permission.viewMessages,
      Permission.viewNotifications,
      
      // Personal
      Permission.editProfile,
    ];
  }

  List<Permission> _getParentPermissions() {
    return [
      // Basic Access
      Permission.viewDashboard,
      
      // Child's Academic Info
      Permission.viewStudents, // Limited to their children
      Permission.viewGrades,   // Limited to their children
      Permission.viewAttendance, // Limited to their children
      Permission.viewCourses,
      Permission.viewTimetable,
      
      // Financial
      Permission.viewFees,
      Permission.viewPayments,
      Permission.processPayments,
      
      // Communication
      Permission.viewMessages,
      Permission.sendMessages,
      Permission.viewNotifications,
      
      // Personal
      Permission.editProfile,
    ];
  }

  List<Permission> _getAccountantPermissions() {
    return [
      // Basic Access
      Permission.viewDashboard,
      
      // Financial Management
      Permission.viewFees,
      Permission.manageFees,
      Permission.viewPayments,
      Permission.processPayments,
      Permission.viewFinancialReports,
      
      // Student Info (for fee management)
      Permission.viewStudents,
      
      // Communication
      Permission.viewMessages,
      Permission.sendMessages,
      Permission.sendNotifications,
      
      // Reports
      Permission.viewReports,
    ];
  }

  List<Permission> _getLibrarianPermissions() {
    return [
      // Basic Access
      Permission.viewDashboard,
      
      // Library Management
      Permission.viewStudents,
      Permission.viewTeachers,
      
      // Communication
      Permission.viewMessages,
      Permission.sendMessages,
      
      // Reports
      Permission.viewReports,
    ];
  }
}

// Enums and Data Models

enum UserRole {
  superAdmin,
  admin,
  teacher,
  student,
  parent,
  accountant,
  librarian,
}

enum Permission {
  // Dashboard & Basic
  viewDashboard,
  editProfile,
  
  // User Management
  viewUsers,
  createUser,
  editUser,
  deleteUser,
  manageRoles,
  
  // Student Management
  viewStudents,
  createStudent,
  editStudent,
  deleteStudent,
  
  // Teacher Management
  viewTeachers,
  createTeacher,
  editTeacher,
  deleteTeacher,
  
  // Academic Management
  viewClasses,
  manageClasses,
  viewCourses,
  manageCourses,
  viewGrades,
  editGrades,
  deleteGrades,
  
  // Attendance Management
  viewAttendance,
  manageAttendance,
  
  // Timetable Management
  viewTimetable,
  manageTimetable,
  
  // Financial Management
  viewFees,
  manageFees,
  viewPayments,
  processPayments,
  viewFinancialReports,
  
  // Communication
  viewMessages,
  sendMessages,
  viewNotifications,
  sendNotifications,
  manageNotifications,
  
  // Reports & Analytics
  viewReports,
  createReports,
  exportReports,
  
  // System Management
  manageSettings,
  viewAuditLogs,
  manageSystem,
  
  // Library Management
  viewLibrary,
  manageLibrary,
}

class UserRoleSummary {
  final String userId;
  final List<UserRole> roles;
  final List<Permission> allPermissions;
  final List<Permission> specificPermissions;
  final UserRole highestRole;

  UserRoleSummary({
    required this.userId,
    required this.roles,
    required this.allPermissions,
    required this.specificPermissions,
    required this.highestRole,
  });
  
  bool hasRole(UserRole role) => roles.contains(role);
  bool hasPermission(Permission permission) => allPermissions.contains(permission);
  bool isAdmin() => hasRole(UserRole.admin) || hasRole(UserRole.superAdmin);
  bool isTeacher() => hasRole(UserRole.teacher);
  bool isStudent() => hasRole(UserRole.student);
  bool isParent() => hasRole(UserRole.parent);
}
