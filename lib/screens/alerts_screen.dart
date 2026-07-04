import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/alert_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final AlertService alertService = AlertService();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final DatabaseReference _rtdb = FirebaseDatabase.instance.ref();
  
  // ESP32 alerts from Realtime Database
  List<Map<String, dynamic>> _esp32Alerts = [];

  @override
  void initState() {
    super.initState();
    _seedSampleAlerts();
    _listenToESP32Alerts();
  }

  // ✅ Listen to ESP32 alerts from Realtime Database
  void _listenToESP32Alerts() {
    _rtdb.child('alerts').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      final List<Map<String, dynamic>> alertList = [];
      
      data.forEach((key, value) {
        alertList.add({
          'id': key,
          'deviceId': value['deviceId']?.toString() ?? 'esp32_001',
          'message': value['message']?.toString() ?? 'Unknown alert',
          'severity': value['severity']?.toString() ?? 'info',
          'voltage': (value['voltage'] ?? 0).toDouble(),
          'current': (value['current'] ?? 0).toDouble(),
          'timestamp': DateTime.now(),
          'acknowledged': false,
          'source': 'ESP32', // Mark as ESP32 source
        });
      });
      
      // Sort by most recent (newest first based on ID which contains timestamp)
      alertList.sort((a, b) => b['id'].toString().compareTo(a['id'].toString()));
      
      setState(() {
        _esp32Alerts = alertList;
      });
      
      debugPrint("📡 ESP32 Alerts received: ${alertList.length}");
    });
  }

  // ✅ Seeds sample alerts into Firestore if none exist
  Future<void> _seedSampleAlerts() async {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('alerts');

    final existing = await ref.limit(1).get();
    if (existing.docs.isNotEmpty) return; // already seeded

    final List<Map<String, dynamic>> sampleAlerts = [
      // 🐘 Elephant intrusion — very common in Kerala forest-border farms
      {
        'deviceId': 'FG-SENSOR-001',
        'message': 'Wild elephant intrusion detected near Wayanad border fence — immediate action required',
        'severity': 'critical',
        'acknowledged': false,
        'location': 'Wayanad North Boundary',
        'timestamp': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 1))),
      },
      // 🌧️ Monsoon rain damage — Kerala gets heavy Southwest monsoon
      {
        'deviceId': 'FG-SENSOR-002',
        'message': 'Heavy monsoon rain caused voltage drop on Idukki east fence — sensor partially submerged',
        'severity': 'critical',
        'acknowledged': false,
        'location': 'Idukki East Boundary',
        'timestamp': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 2))),
      },
      // 🐗 Wild boar — common crop threat in Kerala farmlands
      {
        'deviceId': 'FG-SENSOR-003',
        'message': 'Wild boar activity detected near paddy field — fence pressure spike at Palakkad sector',
        'severity': 'critical',
        'acknowledged': false,
        'location': 'Palakkad Paddy Field',
        'timestamp': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 3))),
      },
      // ⚡ Lightning strike — common during Kerala monsoon
      {
        'deviceId': 'FG-SENSOR-004',
        'message': 'Lightning strike damaged fence controller at Thrissur plantation — system offline',
        'severity': 'critical',
        'acknowledged': false,
        'location': 'Thrissur Plantation',
        'timestamp': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 5))),
      },
      // 🌿 Vegetation overgrowth — common in Kerala's humid climate
      {
        'deviceId': 'FG-SENSOR-005',
        'message': 'Rubber tree branch fallen on south fence — causing short circuit near Kottayam zone',
        'severity': 'warning',
        'acknowledged': false,
        'location': 'Kottayam Rubber Estate',
        'timestamp': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 6))),
      },
      // 🐒 Monkey — a real issue in Kerala hill farms
      {
        'deviceId': 'FG-SENSOR-001',
        'message': 'Repeated monkey intrusions detected at Munnar tea estate fence — tension abnormal',
        'severity': 'warning',
        'acknowledged': false,
        'location': 'Munnar Tea Estate',
        'timestamp': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 8))),
      },
      // 🌊 Flood warning — Kerala floods are seasonal
      {
        'deviceId': 'FG-SENSOR-006',
        'message': 'Flood water level rising near Alappuzha fence perimeter — risk of submersion',
        'severity': 'warning',
        'acknowledged': false,
        'location': 'Alappuzha Paddy Fields',
        'timestamp': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 10))),
      },
      // 🔋 Battery low — universal
      {
        'deviceId': 'FG-SENSOR-007',
        'message': 'Solar battery low on Kozhikode fence node — charge below 15% due to cloudy monsoon weather',
        'severity': 'warning',
        'acknowledged': true,
        'location': 'Kozhikode North Fence',
        'timestamp': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1))),
      },
      // 🐄 Cattle escape — common in Kerala villages
      {
        'deviceId': 'FG-SENSOR-002',
        'message': 'Cattle breach detected at Malappuram farm — fence wire snapped, cattle may have escaped',
        'severity': 'warning',
        'acknowledged': true,
        'location': 'Malappuram Farm',
        'timestamp': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1, hours: 3))),
      },
      // ✅ Info — system back online
      {
        'deviceId': 'FG-SENSOR-003',
        'message': 'Fence system restored at Palakkad sector after post-monsoon maintenance — all sensors normal',
        'severity': 'info',
        'acknowledged': true,
        'location': 'Palakkad Paddy Field',
        'timestamp': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 2))),
      },
      // ✅ Info — routine check
      {
        'deviceId': 'FG-SENSOR-005',
        'message': 'Scheduled fence inspection completed at Thrissur coconut grove — no issues found',
        'severity': 'info',
        'acknowledged': true,
        'location': 'Thrissur Coconut Grove',
        'timestamp': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 3))),
      },
    ];

    final batch = FirebaseFirestore.instance.batch();
    for (final alert in sampleAlerts) {
      batch.set(ref.doc(), alert);
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alerts"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {}, // future: filter by severity
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('alerts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Combine Firestore alerts with ESP32 alerts
          final List<Map<String, dynamic>> allAlerts = [];
          
          // Add Firestore alerts
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              allAlerts.add({
                'id': doc.id,
                'deviceId': data['deviceId'] ?? 'unknown',
                'message': data['message'] ?? 'No message',
                'severity': data['severity'] ?? 'info',
                'timestamp': data['timestamp'],
                'acknowledged': data['acknowledged'] ?? false,
                'source': 'Firestore',
                'voltage': data['voltage'],
                'current': data['current'],
              });
            }
          }
          
          // Add ESP32 alerts from Realtime Database
          for (var alert in _esp32Alerts) {
            allAlerts.add(alert);
          }
          
          // Sort all alerts by timestamp (newest first)
          allAlerts.sort((a, b) {
            final aTime = a['timestamp'] is Timestamp 
                ? a['timestamp'].toDate() 
                : (a['timestamp'] ?? DateTime.now());
            final bTime = b['timestamp'] is Timestamp 
                ? b['timestamp'].toDate() 
                : (b['timestamp'] ?? DateTime.now());
            return bTime.compareTo(aTime);
          });

          if (allAlerts.isEmpty) {
            return const Center(child: Text("No alerts yet"));
          }

          // Count unacknowledged
          final unacked = allAlerts.where((a) => a['acknowledged'] == false).length;

          return Column(
            children: [
              // Summary banner
              if (unacked > 0)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        "$unacked unacknowledged alert${unacked > 1 ? 's' : ''}",
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: allAlerts.length,
                  itemBuilder: (context, index) {
                    final data = allAlerts[index];
                    final String severity = data['severity'] ?? 'info';
                    final Color color = severity == 'critical'
                        ? Colors.red
                        : severity == 'warning'
                            ? Colors.orange
                            : Colors.blue;
                    final String source = data['source'] ?? 'Firestore';
                    final String timeAgo = _timeAgo(data['timestamp']);
                    final bool acknowledged = data['acknowledged'] ?? false;

                    return AlertTile(
                      alertId: data['id'],
                      deviceId: data['deviceId'] ?? '',
                      message: data['message'] ?? '',
                      severity: severity,
                      color: color,
                      time: timeAgo,
                      acknowledged: acknowledged,
                      source: source,
                      voltage: data['voltage'],
                      current: data['current'],
                      alertService: alertService,
                      uid: uid,
                      isESP32Alert: source == 'ESP32',
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

  String _timeAgo(dynamic time) {
    if (time == null) return 'Just now';
    
    DateTime dateTime;
    if (time is Timestamp) {
      dateTime = time.toDate();
    } else if (time is DateTime) {
      dateTime = time;
    } else {
      return 'Just now';
    }
    
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class AlertTile extends StatelessWidget {
  final String alertId;
  final String deviceId;
  final String message;
  final String severity;
  final Color color;
  final String time;
  final bool acknowledged;
  final String source;
  final double? voltage;
  final double? current;
  final AlertService alertService;
  final String uid;
  final bool isESP32Alert;

  const AlertTile({
    super.key,
    required this.alertId,
    required this.deviceId,
    required this.message,
    required this.severity,
    required this.color,
    required this.time,
    required this.acknowledged,
    required this.alertService,
    required this.uid,
    this.source = 'Firestore',
    this.voltage,
    this.current,
    this.isESP32Alert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      color: acknowledged ? Colors.grey.shade100 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (acknowledged ? Colors.grey : color).withOpacity(0.15),
          child: Icon(
            severity == 'critical'
                ? Icons.crisis_alert
                : severity == 'warning'
                    ? Icons.warning_amber
                    : Icons.info_outline,
            color: acknowledged ? Colors.grey : color,
            size: 20,
          ),
        ),
        title: Text(
          message,
          style: TextStyle(
            fontSize: 13,
            color: acknowledged ? Colors.grey : null,
            decoration: acknowledged ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📡 $deviceId • $time",
              style: const TextStyle(fontSize: 11),
            ),
            if (isESP32Alert && voltage != null && current != null)
              Text(
                "⚡ ${voltage!.toStringAsFixed(1)}V • 🔌 ${current!.toStringAsFixed(2)}A",
                style: TextStyle(fontSize: 10, color: color),
              ),
            if (source == 'ESP32')
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Live from ESP32",
                  style: TextStyle(fontSize: 9, color: Colors.blue.shade800),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (acknowledged ? Colors.grey : color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                severity.toUpperCase(),
                style: TextStyle(
                  color: acknowledged ? Colors.grey : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            if (!acknowledged)
              IconButton(
                icon: const Icon(Icons.check_circle_outline, size: 20),
                color: Colors.green,
                tooltip: 'Acknowledge',
                onPressed: () async {
                  if (isESP32Alert) {
                    // Delete ESP32 alert from Realtime Database
                    final dbRef = FirebaseDatabase.instance.ref();
                    await dbRef.child('alerts/$alertId').remove();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ESP32 alert acknowledged')),
                    );
                  } else {
                    // Acknowledge Firestore alert
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('alerts')
                        .doc(alertId)
                        .update({'acknowledged': true});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Alert acknowledged')),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}