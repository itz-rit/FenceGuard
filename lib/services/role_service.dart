import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum UserRole { admin, farmer, technician }

class RoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's role
  Future<UserRole?> getCurrentUserRole() async {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      final DocumentSnapshot doc = 
          await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        final String role = doc.get('role') ?? 'farmer';
        return _stringToRole(role);
      }
    } catch (e) {
      print('Error getting user role: $e');
    }
    return UserRole.farmer; // Default role
  }

  // Set user role (admin only)
  Future<bool> setUserRole(String userId, UserRole role) async {
    try {
      // Check if current user is admin
      final isAdmin = await _isCurrentUserAdmin();
      if (!isAdmin) return false;

      await _firestore.collection('users').doc(userId).update({
        'role': _roleToString(role),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error setting user role: $e');
      return false;
    }
  }

  // Get all users with their roles (admin only)
  Stream<List<Map<String, dynamic>>> getAllUsersWithRoles() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc.get('name') ?? 'Unknown',
          'email': doc.get('email') ?? '',
          'photoUrl': doc.get('photoUrl') ?? '',
          'role': doc.get('role') ?? 'farmer',
          'createdAt': doc.get('createdAt'),
        };
      }).toList();
    });
  }

  // Check if current user is admin
  Future<bool> _isCurrentUserAdmin() async {
    final role = await getCurrentUserRole();
    return role == UserRole.admin;
  }

  // Check if user has access to specific feature
  Future<bool> hasAccess({required List<UserRole> allowedRoles}) async {
    final currentRole = await getCurrentUserRole();
    if (currentRole == null) return false;
    return allowedRoles.contains(currentRole);
  }

  // Role-based UI visibility helpers
  Future<bool> canManageFarmers() async {
    return hasAccess(allowedRoles: [UserRole.admin]);
  }

  Future<bool> canAddDevices() async {
    return hasAccess(allowedRoles: [UserRole.admin, UserRole.technician]);
  }

  Future<bool> canViewAnalytics() async {
    return hasAccess(allowedRoles: [UserRole.admin, UserRole.farmer, UserRole.technician]);
  }

  // Converters
  UserRole _stringToRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'technician':
        return UserRole.technician;
      default:
        return UserRole.farmer;
    }
  }

  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.technician:
        return 'technician';
      case UserRole.farmer:
        return 'farmer';
    }
  }

  // Get role display name
  static String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.technician:
        return 'Technician';
      case UserRole.farmer:
        return 'Farmer';
    }
  }

  // Get role color
  static Color getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.technician:
        return Colors.blue;
      case UserRole.farmer:
        return Colors.green;
    }
  }
}