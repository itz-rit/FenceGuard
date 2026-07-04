import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/home_screen.dart';
import '../screens/devices_screen.dart';
import '../screens/alerts_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/farmer_management_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/add_device_screen.dart';
import '../screens/ml_screen.dart'; // ✅ Added ML import
import '../services/auth_service.dart';
import '../services/role_service.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final RoleService _roleService = RoleService();
  UserRole? _currentRole;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await _roleService.getCurrentUserRole();
    if (mounted) {
      setState(() {
        _currentRole = role;
      });
    }
  }

  Future<void> handleLogout() async {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF4CAF50)),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: _currentUser?.photoURL != null
                      ? NetworkImage(_currentUser!.photoURL!)
                      : null,
                  child: _currentUser?.photoURL == null
                      ? const Icon(
                          Icons.person,
                          color: Color(0xFF4CAF50),
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUser?.displayName ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentUser?.email ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (_currentRole != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            RoleService.getRoleDisplayName(_currentRole!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Main Menu Items ──────────────────────────────
          _drawerItem(
            context,
            icon: Icons.dashboard,
            title: "Dashboard",
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),

          _drawerItem(
            context,
            icon: Icons.devices,
            title: "Devices",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DevicesScreen()),
              );
            },
          ),

          if (_currentRole == UserRole.admin ||
              _currentRole == UserRole.technician)
            _drawerItem(
              context,
              icon: Icons.add_circle_outline,
              title: "Add Device",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddDeviceScreen()),
                );
              },
            ),

          _drawerItem(
            context,
            icon: Icons.notifications,
            title: "Alerts",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlertsScreen()),
              );
            },
          ),

          _drawerItem(
            context,
            icon: Icons.bar_chart,
            title: "Analytics",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),

          // ✅ ML Detection — visible to all
          _drawerItem(
            context,
            icon: Icons.psychology,
            title: "ML Detection",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MLScreen()),
              );
            },
          ),

          if (_currentRole == UserRole.admin)
            _drawerItem(
              context,
              icon: Icons.people,
              title: "Farmer Management",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FarmerManagementScreen(),
                  ),
                );
              },
            ),

          // ── Bottom Items ─────────────────────────────────
          const Spacer(),
          const Divider(),

          _drawerItem(
            context,
            icon: Icons.settings,
            title: "Settings",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),

          _drawerItem(
            context,
            icon: Icons.logout,
            title: "Logout",
            color: Colors.red,
            onTap: handleLogout,
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = const Color(0xFF4CAF50),
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color == Colors.red ? Colors.red : null),
      ),
      onTap: onTap,
    );
  }
}
