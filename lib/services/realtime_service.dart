import 'package:firebase_database/firebase_database.dart';

class RealtimeService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  // Stream to listen to ESP32 device data
  Stream<Map<String, dynamic>> listenToDeviceData(String deviceId) {
    return _database.child('devices/$deviceId').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return {
        'voltage': (data['voltage'] ?? 220.0).toDouble(),
        'current': (data['current'] ?? 0.0).toDouble(),
        'status': data['status']?.toString() ?? 'offline',
      };
    });
  }
  
  // Get single device data (one-time read)
  Future<Map<String, dynamic>> getDeviceData(String deviceId) async {
    final snapshot = await _database.child('devices/$deviceId').get();
    final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
    return {
      'voltage': (data['voltage'] ?? 220.0).toDouble(),
      'current': (data['current'] ?? 0.0).toDouble(),
      'status': data['status']?.toString() ?? 'offline',
    };
  }
  
  // Stream to listen to all alerts
  Stream<List<Map<String, dynamic>>> listenToAlerts() {
    return _database.child('alerts').onValue.map((event) {
      final alerts = <Map<String, dynamic>>[];
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      
      data.forEach((key, value) {
        alerts.add({
          'id': key,
          'deviceId': value['deviceId']?.toString() ?? 'unknown',
          'message': value['message']?.toString() ?? 'No message',
          'severity': value['severity']?.toString() ?? 'info',
          'voltage': (value['voltage'] ?? 0).toDouble(),
          'current': (value['current'] ?? 0).toDouble(),
          'timestamp': DateTime.now(),
        });
      });
      
      // Sort by most recent first
      alerts.sort((a, b) => b['id'].toString().compareTo(a['id'].toString()));
      return alerts;
    });
  }
  
  // Acknowledge an alert (delete it)
  Future<void> acknowledgeAlert(String alertId) async {
    await _database.child('alerts/$alertId').remove();
  }
  
  // Delete all alerts
  Future<void> clearAllAlerts() async {
    await _database.child('alerts').remove();
  }
  
  // Get device status
  Future<String> getDeviceStatus(String deviceId) async {
    final snapshot = await _database.child('devices/$deviceId/status').get();
    return snapshot.value?.toString() ?? 'offline';
  }
  
  // Check if device is online (last update within 15 seconds)
  Future<bool> isDeviceOnline(String deviceId) async {
    final data = await getDeviceData(deviceId);
    // If data exists and status is not 'offline', consider online
    return data['status'] != 'offline';
  }
}