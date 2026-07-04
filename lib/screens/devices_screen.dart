import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Devices"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('devices')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final devices = snapshot.data!.docs;

          if (devices.isEmpty) {
            return const Center(child: Text("No devices added yet"));
          }

          return Column(
            children: [
              /// Total Devices Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.memory, size: 40, color: Colors.green),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Total Devices",
                            style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          devices.length.toString(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              /// Devices List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final data =
                        devices[index].data() as Map<String, dynamic>;

                    final status = data['status'] ?? 'unknown';
                    final color =
                        status == 'safe' ? Colors.green : Colors.red;

                    return DeviceTile(
                      deviceId: devices[index].id,
                      status: status.toUpperCase(),
                      color: color,
                      lastUpdated: "Live",
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
}

class DeviceTile extends StatelessWidget {
  final String deviceId;
  final String status;
  final Color color;
  final String lastUpdated;

  const DeviceTile({
    super.key,
    required this.deviceId,
    required this.status,
    required this.color,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.router, color: color),
        title: Text(deviceId),
        subtitle: Text("Last updated: $lastUpdated"),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
