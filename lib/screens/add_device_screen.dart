import 'package:flutter/material.dart';
import '../services/device_service.dart';

class AddDeviceScreen extends StatelessWidget {
  AddDeviceScreen({super.key});

  final _deviceIdController = TextEditingController();
  final _deviceNameController = TextEditingController();
  final _locationController = TextEditingController();

  final DeviceService _deviceService = DeviceService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add ESP32 Device")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _deviceIdController,
              decoration: const InputDecoration(
                labelText: "Device ID (ESP32)",
              ),
            ),
            TextField(
              controller: _deviceNameController,
              decoration: const InputDecoration(
                labelText: "Device Name",
              ),
            ),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: "Farm Location",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _deviceService.addDevice(
                  deviceId: _deviceIdController.text.trim(),
                  deviceName: _deviceNameController.text.trim(),
                  location: _locationController.text.trim(),
                );

                Navigator.pop(context);
              },
              child: const Text("Add Device"),
            )
          ],
        ),
      ),
    );
  }
}
