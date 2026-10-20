import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/app_drawer.dart';

// ✅ Zone model — each sensor mapped to zone + sector
class FenceZone {
  final String sensorId;
  final String zoneName;
  final String sectorName;
  final LatLng center;
  final List<LatLng> polygon;
  final IconData icon;

  const FenceZone({
    required this.sensorId,
    required this.zoneName,
    required this.sectorName,
    required this.center,
    required this.polygon,
    required this.icon,
  });
}

// ✅ Kerala farm zones — coordinates around Wayanad area
// Replace with your actual farm GPS coordinates
final List<FenceZone> kFenceZones = [
  FenceZone(
    sensorId: 'FG-SENSOR-001',
    zoneName: 'North Zone',
    sectorName: 'Wayanad Paddy Field',
    center: const LatLng(11.6854, 76.1320),
    icon: Icons.grass,
    polygon: [
      const LatLng(11.6870, 76.1300),
      const LatLng(11.6870, 76.1340),
      const LatLng(11.6854, 76.1340),
      const LatLng(11.6854, 76.1300),
    ],
  ),
  FenceZone(
    sensorId: 'FG-SENSOR-002',
    zoneName: 'East Zone',
    sectorName: 'Rubber Estate',
    center: const LatLng(11.6840, 76.1355),
    icon: Icons.park,
    polygon: [
      const LatLng(11.6854, 76.1340),
      const LatLng(11.6854, 76.1370),
      const LatLng(11.6825, 76.1370),
      const LatLng(11.6825, 76.1340),
    ],
  ),
  FenceZone(
    sensorId: 'FG-SENSOR-003',
    zoneName: 'South Zone',
    sectorName: 'Coconut Grove',
    center: const LatLng(11.6816, 76.1320),
    icon: Icons.nature,
    polygon: [
      const LatLng(11.6825, 76.1300),
      const LatLng(11.6825, 76.1340),
      const LatLng(11.6808, 76.1340),
      const LatLng(11.6808, 76.1300),
    ],
  ),
  FenceZone(
    sensorId: 'FG-SENSOR-004',
    zoneName: 'West Zone',
    sectorName: 'Tea Garden',
    center: const LatLng(11.6840, 76.1288),
    icon: Icons.spa,
    polygon: [
      const LatLng(11.6854, 76.1278),
      const LatLng(11.6854, 76.1300),
      const LatLng(11.6825, 76.1300),
      const LatLng(11.6825, 76.1278),
    ],
  ),
  FenceZone(
    sensorId: 'FG-GATE-001',
    zoneName: 'Main Gate',
    sectorName: 'Entry Point',
    center: const LatLng(11.6837, 76.1320),
    icon: Icons.door_front_door,
    polygon: [
      const LatLng(11.6840, 76.1315),
      const LatLng(11.6840, 76.1325),
      const LatLng(11.6834, 76.1325),
      const LatLng(11.6834, 76.1315),
    ],
  ),
  // ✅ ESP32 Device Zone
  FenceZone(
    sensorId: 'esp32_001',
    zoneName: 'ESP32 Sensor',
    sectorName: 'Main Fence Line',
    center: const LatLng(11.6837, 76.1320),
    icon: Icons.memory,
    polygon: [
      const LatLng(11.6840, 76.1310),
      const LatLng(11.6840, 76.1330),
      const LatLng(11.6830, 76.1330),
      const LatLng(11.6830, 76.1310),
    ],
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final DatabaseReference _rtdb = FirebaseDatabase.instance.ref();
  
  // ESP32 live data from Realtime Database
  double _esp32Voltage = 0;
  double _esp32Current = 0;
  String _esp32Status = 'offline';
  
  // Firestore sensor status map
  Map<String, String> _sensorStatus = {};

  // ✅ Freshness tracking for the demo — shows judges the data is really live
  DateTime? _lastUpdated;
  bool _esp32HasReceivedData = false;

  @override
  void initState() {
    super.initState();
    
    // ✅ Listen to ESP32 data from Realtime Database
    _rtdb.child('devices/esp32_001').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      setState(() {
        _esp32Voltage = (data['voltage'] ?? 0).toDouble();
        _esp32Current = (data['current'] ?? 0).toDouble();
        _esp32Status = data['status']?.toString() ?? 'offline';
        _lastUpdated = DateTime.now();
        _esp32HasReceivedData = true;
        
        // Also update the sensor status map for the map display
        _sensorStatus['esp32_001'] = _esp32Status;
      });
      debugPrint("📡 ESP32: ${_esp32Voltage}V, ${_esp32Current}A, $_esp32Status");
    });
  }

  // ✅ Human-readable "X seconds ago" for the live badge
  String _lastUpdatedLabel() {
    if (_lastUpdated == null) return 'Connecting...';
    final seconds = DateTime.now().difference(_lastUpdated!).inSeconds;
    if (seconds < 5) return 'Just now';
    if (seconds < 60) return '${seconds}s ago';
    return '${(seconds / 60).floor()}m ago';
  }

  // ✅ Tap-to-view detail popup for the real ESP32 sensor
  void _showEsp32Detail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final color = _zoneColor('esp32_001');
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.memory, color: color, size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    'ESP32 Sensor — Live',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Main Fence Line',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const Divider(height: 28),
              _detailRow('Status', _zoneStatusLabel('esp32_001'), color),
              _detailRow('Voltage', '${_esp32Voltage.toStringAsFixed(1)} V', Colors.black87),
              _detailRow('Current', '${_esp32Current.toStringAsFixed(2)} A', Colors.black87),
              _detailRow('Last updated', _lastUpdatedLabel(), Colors.black87),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: valueColor, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ✅ Get status for any sensor (combines Firestore + Realtime)
  String _getSensorStatus(String sensorId) {
    if (sensorId == 'esp32_001') {
      return _esp32Status;
    }
    return _sensorStatus[sensorId] ?? 'safe';
  }

  Color _zoneColor(String sensorId) {
    final status = _getSensorStatus(sensorId);
    switch (status) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'safe':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _zoneStatusLabel(String sensorId) {
    final status = _getSensorStatus(sensorId);
    switch (status) {
      case 'critical':
        return 'BREACH';
      case 'warning':
        return 'WARNING';
      case 'safe':
        return 'SAFE';
      default:
        return 'OFFLINE';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4CAF50)),
        title: const Row(
          children: [
            Icon(Icons.shield, color: Color(0xFF4CAF50)),
            SizedBox(width: 8),
            Text(
              "FenceGuard",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // ✅ Live ESP32 Status Indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _esp32Status == 'offline' ? Colors.grey : 
                     (_esp32Status == 'critical' ? Colors.red :
                      (_esp32Status == 'warning' ? Colors.orange : Colors.green)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _esp32Status == 'offline' ? 'OFFLINE' : 
                  (_esp32Status == 'critical' ? 'BREACH' :
                   (_esp32Status == 'warning' ? 'WARNING' : 'LIVE')),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('devices')
            .snapshots(),
        builder: (context, deviceSnapshot) {
          if (deviceSnapshot.hasData) {
            final Map<String, String> statusMap = {};
            for (var doc in deviceSnapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final deviceId = data['deviceId'] ?? doc.id;
              statusMap[deviceId] = data['status'] ?? 'safe';
            }
            _sensorStatus = statusMap;
            // Keep ESP32 status from Realtime DB
            _sensorStatus['esp32_001'] = _esp32Status;
          }

          final breachedZones = kFenceZones
              .where((z) => _getSensorStatus(z.sensorId) == 'critical')
              .toList();
          final warningZones = kFenceZones
              .where((z) => _getSensorStatus(z.sensorId) == 'warning')
              .toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                // 📡 ESP32 Live Sensor Card (NEW)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _esp32Status == 'critical' 
                          ? [Colors.red.shade700, Colors.red.shade400]
                          : _esp32Status == 'warning'
                              ? [Colors.orange.shade700, Colors.orange.shade400]
                              : [Colors.green.shade700, Colors.green.shade400],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.sensors, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "ESP32 Live Data",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildLiveMetric(
                            title: "Voltage",
                            value: _esp32Voltage.toStringAsFixed(1),
                            unit: "V",
                            icon: Icons.bolt,
                          ),
                          _buildLiveMetric(
                            title: "Current",
                            value: _esp32Current.toStringAsFixed(2),
                            unit: "A",
                            icon: Icons.electrical_services,
                          ),
                          _buildLiveMetric(
                            title: "Status",
                            value: _esp32Status.toUpperCase(),
                            unit: "",
                            icon: _esp32Status == 'critical' 
                                ? Icons.warning 
                                : _esp32Status == 'warning'
                                    ? Icons.info
                                    : Icons.check_circle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wifi,
                              size: 14,
                              color: _esp32Status != 'offline' ? Colors.white : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _esp32Status != 'offline' ? "Device Online" : "Device Offline",
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.timer,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "Updates every 5s",
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 🚨 Breach Alert Banner
                if (breachedZones.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.crisis_alert, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "⚠️ BREACH in: ${breachedZones.map((z) => z.sectorName).join(', ')}",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Farm Zone Map
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Farm Zone Monitor",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Map with colored zone polygons
                      Container(
                        height: 260,
                        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: FlutterMap(
                          options: const MapOptions(
                            initialCenter: LatLng(11.6837, 76.1320),
                            initialZoom: 15.5,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.example.fenceguard',
                            ),

                            // Zone polygons colored by status
                            PolygonLayer(
                              polygons: kFenceZones.map((zone) {
                                final color = _zoneColor(zone.sensorId);
                                return Polygon(
                                  points: zone.polygon,
                                  color: color.withOpacity(0.35),
                                  borderColor: color,
                                  borderStrokeWidth: 2.5,
                                );
                              }).toList(),
                            ),

                            // Status label markers
                            MarkerLayer(
                              markers: kFenceZones.map((zone) {
                                final color = _zoneColor(zone.sensorId);
                                final status =
                                    _zoneStatusLabel(zone.sensorId);
                                final isLive = zone.sensorId == 'esp32_001';
                                final markerContent = Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // "LIVE" tag only on the real ESP32 sensor
                                    if (isLive)
                                      Container(
                                        margin: const EdgeInsets.only(bottom: 2),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          '● LIVE',
                                          style: TextStyle(
                                            color: Colors.greenAccent,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: isLive
                                            ? Border.all(
                                                color: Colors.white, width: 1.5)
                                            : null,
                                      ),
                                      child: Text(
                                        status,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.location_pin,
                                        color: color,
                                        size: isLive ? 32 : 28),
                                  ],
                                );
                                return Marker(
                                  point: zone.center,
                                  width: 80,
                                  height: isLive ? 70 : 55,
                                  child: isLive
                                      ? GestureDetector(
                                          onTap: () => _showEsp32Detail(context),
                                          child: markerContent,
                                        )
                                      : markerContent,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      // Legend
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _legendDot(Colors.green, "Safe"),
                            _legendDot(Colors.orange, "Warning"),
                            _legendDot(Colors.red, "Breach"),
                            _legendDot(Colors.grey, "Offline"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Zone Status List
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.fence, color: Color(0xFF4CAF50)),
                          SizedBox(width: 8),
                          Text(
                            "Zone Status",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...kFenceZones.map((zone) {
                        final color = _zoneColor(zone.sensorId);
                        final status = _zoneStatusLabel(zone.sensorId);
                        final isLive = zone.sensorId == 'esp32_001';
                        final card = Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: isLive
                                    ? color
                                    : color.withOpacity(0.3),
                                width: isLive ? 1.5 : 1),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    color.withOpacity(0.15),
                                child: Icon(zone.icon,
                                    color: color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      zone.zoneName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      "📍 ${zone.sectorName} • ${zone.sensorId}",
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey),
                                    ),
                                    // Show live data for ESP32 zone
                                    if (zone.sensorId == 'esp32_001')
                                      Text(
                                        "⚡ ${_esp32Voltage.toStringAsFixed(1)}V • 🔌 ${_esp32Current.toStringAsFixed(2)}A • ${_lastUpdatedLabel()}",
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        return isLive
                            ? GestureDetector(
                                onTap: () => _showEsp32Detail(context),
                                child: card,
                              )
                            : card;
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Recent Alerts (Combined from Firestore + Realtime)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('alerts')
                      .orderBy('timestamp', descending: true)
                      .limit(3)
                      .snapshots(),
                  builder: (context, alertSnapshot) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.notifications, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                "Recent Alerts",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (!alertSnapshot.hasData || alertSnapshot.data!.docs.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  "No recent alerts",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          ...?alertSnapshot.data?.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final severity = data['severity'] ?? 'info';
                            final color = severity == 'critical'
                                ? Colors.red
                                : severity == 'warning'
                                    ? Colors.orange
                                    : Colors.blue;

                            final deviceId = data['deviceId'] ?? '';
                            final matchedZones = kFenceZones
                                .where((z) => z.sensorId == deviceId);
                            final zoneName = matchedZones.isNotEmpty
                                ? "${matchedZones.first.zoneName} — ${matchedZones.first.sectorName}"
                                : "Unknown Zone";

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.circle, color: color, size: 12),
                              title: Text(
                                data['message'] ?? '',
                                style: const TextStyle(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                "📍 $zoneName",
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  severity.toUpperCase(),
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Stats Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _statCard(kFenceZones.length.toString(),
                          "Total Zones", Icons.fence, Colors.green),
                      const SizedBox(width: 12),
                      _statCard(breachedZones.length.toString(),
                          "Breaches", Icons.warning, Colors.red),
                      const SizedBox(width: 12),
                      _statCard(warningZones.length.toString(),
                          "Warnings", Icons.report_problem, Colors.orange),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveMetric({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          "$title${unit.isNotEmpty ? " ($unit)" : ""}",
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 10),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }

  static Widget _statCard(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}