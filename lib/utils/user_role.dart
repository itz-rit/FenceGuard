import 'package:flutter/material.dart';

enum UserRole {
  admin,
  farmer,
  technician
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.farmer:
        return 'Farmer';
      case UserRole.technician:
        return 'Technician';
    }
  }

  String get code {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.farmer:
        return 'farmer';
      case UserRole.technician:
        return 'technician';
    }
  }

  Color get color {
    switch (this) {
      case UserRole.admin:
        return const Color(0xFF9C27B0); // Purple
      case UserRole.farmer:
        return const Color(0xFF4CAF50); // Green
      case UserRole.technician:
        return const Color(0xFF2196F3); // Blue
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.farmer:
        return Icons.person;
      case UserRole.technician:
        return Icons.build;
    }
  }

  List<String> get permissions {
    switch (this) {
      case UserRole.admin:
        return [
          'manage_users',
          'manage_devices',
          'view_all_alerts',
          'manage_farms',
          'view_analytics',
          'add_technicians',
        ];
      case UserRole.farmer:
        return [
          'view_own_devices',
          'view_own_alerts',
          'view_basic_analytics',
          'manage_own_farm',
        ];
      case UserRole.technician:
        return [
          'manage_devices',
          'view_assigned_alerts',
          'update_device_status',
          'view_technical_analytics',
        ];
    }
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }
}

class UserRoleHelper {
  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'technician':
        return UserRole.technician;
      case 'farmer':
      default:
        return UserRole.farmer;
    }
  }

  static List<UserRole> getAllRoles() {
    return UserRole.values;
  }

  static Map<UserRole, String> getRoleMap() {
    return {
      UserRole.admin: 'Administrator',
      UserRole.farmer: 'Farmer',
      UserRole.technician: 'Technician',
    };
  }
}