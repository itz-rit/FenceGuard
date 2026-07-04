import 'package:flutter/material.dart';
import '../services/role_service.dart';

class FarmerManagementScreen extends StatelessWidget {
  const FarmerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RoleService roleService = RoleService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Farmer Management"),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: roleService.getAllUsersWithRoles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          final users = snapshot.data!;

          return Column(
            children: [
              // Summary card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, size: 40, color: Colors.green),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Total Users",
                            style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          users.length.toString(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Users list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final String role = user['role'] ?? 'farmer';
                    // role color and icon handled below directly

                    final Color roleColor = _roleColor(role);
                    final IconData roleIcon = _roleIcon(role);

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: roleColor.withOpacity(0.15),
                          backgroundImage: user['photoUrl'] != null &&
                                  user['photoUrl'].toString().isNotEmpty
                              ? NetworkImage(user['photoUrl'])
                              : null,
                          child: user['photoUrl'] == null ||
                                  user['photoUrl'].toString().isEmpty
                              ? Icon(roleIcon, color: roleColor)
                              : null,
                        ),
                        title: Text(
                          user['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(user['email'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: TextStyle(
                                  color: roleColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Role change button
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 18),
                              onSelected: (newRole) async {
                                final UserRole selectedRole =
                                    _stringToUserRole(newRole);
                                await roleService.setUserRole(
                                    user['id'], selectedRole);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "Role updated to $newRole for ${user['name']}"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                    value: 'admin',
                                    child: Text('Set as Admin')),
                                const PopupMenuItem(
                                    value: 'farmer',
                                    child: Text('Set as Farmer')),
                                const PopupMenuItem(
                                    value: 'technician',
                                    child: Text('Set as Technician')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'technician':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  IconData _roleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'technician':
        return Icons.build;
      default:
        return Icons.person;
    }
  }

  UserRole _stringToUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'technician':
        return UserRole.technician;
      default:
        return UserRole.farmer;
    }
  }
}