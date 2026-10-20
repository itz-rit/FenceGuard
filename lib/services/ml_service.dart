import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ Sensor reading model
class SensorReading {
  final String sensorId;
  final double voltage;
  final double tension; // 0.0 - 1.0 (normalized)
  final double temperature; // °C
  final double humidity; // %
  final double current; // mA
  final DateTime timestamp;

  SensorReading({
    required this.sensorId,
    required this.voltage,
    required this.tension,
    required this.temperature,
    required this.humidity,
    required this.current,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'sensorId': sensorId,
        'voltage': voltage,
        'tension': tension,
        'temperature': temperature,
        'humidity': humidity,
        'current': current,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}

// ✅ ML Detection result
class ZoneDetectionResult {
  final String sensorId;
  final String zoneName;
  final String sectorName;
  final String status; // safe / warning / critical
  final double confidence; // 0.0 - 1.0
  final String reason; // human-readable explanation
  final List<String> anomalies; // list of detected anomalies
  final DateTime detectedAt;

  ZoneDetectionResult({
    required this.sensorId,
    required this.zoneName,
    required this.sectorName,
    required this.status,
    required this.confidence,
    required this.reason,
    required this.anomalies,
    required this.detectedAt,
  });
}

// ✅ Zone definition for ML matching
class ZoneDefinition {
  final String sensorId;
  final String zoneName;
  final String sectorName;

  // Normal operating ranges for this zone
  final double normalVoltageMin;
  final double normalVoltageMax;
  final double normalTensionMax;
  final double normalTempMin;
  final double normalTempMax;
  final double normalHumidityMax;

  const ZoneDefinition({
    required this.sensorId,
    required this.zoneName,
    required this.sectorName,
    required this.normalVoltageMin,
    required this.normalVoltageMax,
    required this.normalTensionMax,
    required this.normalTempMin,
    required this.normalTempMax,
    required this.normalHumidityMax,
  });
}

class MLService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  // ✅ Zone normal operating ranges — Kerala climate calibrated
  // High humidity (80-95%) and temps (25-35°C) are normal in Kerala
  static const List<ZoneDefinition> _zoneDefinitions = [
    ZoneDefinition(
      sensorId: 'FG-SENSOR-001',
      zoneName: 'North Zone',
      sectorName: 'Wayanad Paddy Field',
      normalVoltageMin: 10.5,
      normalVoltageMax: 13.5,
      normalTensionMax: 0.4,
      normalTempMin: 22.0,
      normalTempMax: 36.0,
      normalHumidityMax: 95.0, // paddy fields are very humid
    ),
    ZoneDefinition(
      sensorId: 'FG-SENSOR-002',
      zoneName: 'East Zone',
      sectorName: 'Rubber Estate',
      normalVoltageMin: 10.5,
      normalVoltageMax: 13.5,
      normalTensionMax: 0.35,
      normalTempMin: 23.0,
      normalTempMax: 35.0,
      normalHumidityMax: 90.0,
    ),
    ZoneDefinition(
      sensorId: 'FG-SENSOR-003',
      zoneName: 'South Zone',
      sectorName: 'Coconut Grove',
      normalVoltageMin: 10.5,
      normalVoltageMax: 13.5,
      normalTensionMax: 0.4,
      normalTempMin: 24.0,
      normalTempMax: 37.0,
      normalHumidityMax: 88.0,
    ),
    ZoneDefinition(
      sensorId: 'FG-SENSOR-004',
      zoneName: 'West Zone',
      sectorName: 'Tea Garden',
      normalVoltageMin: 10.5,
      normalVoltageMax: 13.5,
      normalTensionMax: 0.3,
      normalTempMin: 18.0, // tea gardens are cooler (hill area)
      normalTempMax: 30.0,
      normalHumidityMax: 92.0,
    ),
    ZoneDefinition(
      sensorId: 'FG-GATE-001',
      zoneName: 'Main Gate',
      sectorName: 'Entry Point',
      normalVoltageMin: 11.0,
      normalVoltageMax: 13.5,
      normalTensionMax: 0.25,
      normalTempMin: 22.0,
      normalTempMax: 38.0,
      normalHumidityMax: 85.0,
    ),
  ];

  // ✅ CORE ML FUNCTION — Analyze sensor reading and detect zone status
  ZoneDetectionResult analyzeReading(SensorReading reading) {
    // Find zone definition for this sensor
    final zoneDef = _zoneDefinitions.firstWhere(
      (z) => z.sensorId == reading.sensorId,
      orElse: () => _zoneDefinitions.first,
    );

    final List<String> anomalies = [];
    double riskScore = 0.0; // 0.0 = safe, 1.0 = critical breach

    // ── 1. VOLTAGE ANALYSIS ──────────────────────────────────────
    if (reading.voltage < 7.0) {
      anomalies.add(
          'Critical voltage drop (${reading.voltage.toStringAsFixed(1)}V) — possible wire cut or short circuit');
      riskScore += 0.45;
    } else if (reading.voltage < zoneDef.normalVoltageMin) {
      anomalies.add(
          'Low voltage (${reading.voltage.toStringAsFixed(1)}V) — below normal ${zoneDef.normalVoltageMin}V threshold');
      riskScore += 0.20;
    } else if (reading.voltage > zoneDef.normalVoltageMax) {
      anomalies.add(
          'Voltage surge (${reading.voltage.toStringAsFixed(1)}V) — possible lightning strike nearby');
      riskScore += 0.15;
    }

    // ── 2. TENSION ANALYSIS ──────────────────────────────────────
    if (reading.tension > 0.85) {
      anomalies.add(
          'Extreme tension spike (${(reading.tension * 100).toStringAsFixed(0)}%) — animal pushing/breaching fence');
      riskScore += 0.40;
    } else if (reading.tension > zoneDef.normalTensionMax) {
      anomalies.add(
          'High tension (${(reading.tension * 100).toStringAsFixed(0)}%) — possible animal contact');
      riskScore += 0.20;
    }

    // ── 3. TEMPERATURE ANALYSIS ──────────────────────────────────
    if (reading.temperature > zoneDef.normalTempMax + 5) {
      anomalies.add(
          'Abnormal temperature (${reading.temperature.toStringAsFixed(1)}°C) — sensor may be near fire or direct sunburn');
      riskScore += 0.10;
    } else if (reading.temperature < zoneDef.normalTempMin - 5) {
      anomalies.add(
          'Unusually low temperature (${reading.temperature.toStringAsFixed(1)}°C) — check sensor placement');
      riskScore += 0.05;
    }

    // ── 4. HUMIDITY ANALYSIS ─────────────────────────────────────
    if (reading.humidity > 98.0) {
      anomalies.add(
          'Sensor submerged or waterlogged (humidity ${reading.humidity.toStringAsFixed(0)}%) — check for flooding');
      riskScore += 0.20;
    } else if (reading.humidity > zoneDef.normalHumidityMax) {
      anomalies.add(
          'High humidity (${reading.humidity.toStringAsFixed(0)}%) — monsoon rain may affect readings');
      riskScore += 0.05;
    }

    // ── 5. CURRENT ANALYSIS ──────────────────────────────────────
    if (reading.current < 5.0) {
      anomalies.add(
          'Near-zero current (${reading.current.toStringAsFixed(1)}mA) — fence wire may be broken');
      riskScore += 0.30;
    } else if (reading.current > 500.0) {
      anomalies.add(
          'Current spike (${reading.current.toStringAsFixed(1)}mA) — short circuit or metal contact detected');
      riskScore += 0.25;
    }

    // ── 6. KERALA-SPECIFIC COMBINED PATTERNS ────────────────────
    // Elephant pattern: high tension + voltage drop at dusk
    final hour = reading.timestamp.hour;
    final isDuskOrDawn = (hour >= 5 && hour <= 7) || (hour >= 17 && hour <= 20);
    if (isDuskOrDawn && reading.tension > 0.6 && reading.voltage < 9.0) {
      anomalies.add(
          '🐘 Elephant activity pattern detected — high tension + voltage drop during animal active hours ($hour:00)');
      riskScore += 0.35;
    }

    // Monsoon pattern: high humidity + voltage drop
    final isMonsoonSeason = [6, 7, 8, 9, 10].contains(reading.timestamp.month);
    if (isMonsoonSeason && reading.humidity > 95 && reading.voltage < 9.5) {
      anomalies.add(
          '🌧️ Monsoon damage pattern — high humidity combined with low voltage suggests water ingress');
      riskScore += 0.20;
    }

    // Clamp risk score to 1.0
    riskScore = min(riskScore, 1.0);

    // ── DETERMINE STATUS ─────────────────────────────────────────
    String status;
    String reason;
    double confidence;

    if (riskScore >= 0.60) {
      status = 'critical';
      confidence = 0.75 + (riskScore - 0.60) * 0.5;
      reason = anomalies.isNotEmpty
          ? anomalies.first
          : 'Multiple critical anomalies detected';
    } else if (riskScore >= 0.25) {
      status = 'warning';
      confidence = 0.65 + riskScore * 0.3;
      reason = anomalies.isNotEmpty
          ? anomalies.first
          : 'Sensor readings outside normal range';
    } else {
      status = 'safe';
      confidence = 1.0 - riskScore;
      reason = 'All readings within normal Kerala farm operating range';
    }

    confidence = min(confidence, 0.99);

    return ZoneDetectionResult(
      sensorId: reading.sensorId,
      zoneName: zoneDef.zoneName,
      sectorName: zoneDef.sectorName,
      status: status,
      confidence: confidence,
      reason: reason,
      anomalies: anomalies,
      detectedAt: reading.timestamp,
    );
  }

  // ✅ Analyze all sensors and return results
  List<ZoneDetectionResult> analyzeAllSensors(
      List<SensorReading> readings) {
    return readings.map((r) => analyzeReading(r)).toList();
  }

  // ✅ Save ML result back to Firestore device
  Future<void> saveDetectionResult(ZoneDetectionResult result) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(result.sensorId)
        .update({
      'status': result.status,
      'mlConfidence': result.confidence,
      'mlReason': result.reason,
      'mlAnomalies': result.anomalies,
      'lastMLScan': Timestamp.fromDate(result.detectedAt),
    });

    // Auto-create alert if critical or warning
    if (result.status == 'critical' || result.status == 'warning') {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('alerts')
          .add({
        'deviceId': result.sensorId,
        'message':
            '[ML] ${result.zoneName} (${result.sectorName}): ${result.reason}',
        'severity': result.status,
        'acknowledged': false,
        'mlGenerated': true,
        'confidence': result.confidence,
        'anomalies': result.anomalies,
        'timestamp': Timestamp.fromDate(result.detectedAt),
      });
    }
  }

  // ✅ Generate realistic Kerala farm sensor readings for demo
  List<SensorReading> generateSampleReadings() {
    final random = Random();
    final now = DateTime.now();

    return [
      // Normal sensor
      SensorReading(
        sensorId: 'FG-SENSOR-001',
        voltage: 12.0 + random.nextDouble() * 1.0,
        tension: 0.1 + random.nextDouble() * 0.15,
        temperature: 28.0 + random.nextDouble() * 4.0,
        humidity: 82.0 + random.nextDouble() * 8.0,
        current: 120.0 + random.nextDouble() * 30.0,
        timestamp: now,
      ),
      // Breach sensor — elephant pattern
      SensorReading(
        sensorId: 'FG-SENSOR-002',
        voltage: 6.5 + random.nextDouble() * 1.5,
        tension: 0.80 + random.nextDouble() * 0.15,
        temperature: 30.0 + random.nextDouble() * 3.0,
        humidity: 88.0 + random.nextDouble() * 5.0,
        current: 8.0 + random.nextDouble() * 5.0,
        timestamp: now.subtract(const Duration(minutes: 5)),
      ),
      // Warning sensor — voltage drop
      SensorReading(
        sensorId: 'FG-SENSOR-003',
        voltage: 8.5 + random.nextDouble() * 1.5,
        tension: 0.45 + random.nextDouble() * 0.1,
        temperature: 29.0 + random.nextDouble() * 3.0,
        humidity: 91.0 + random.nextDouble() * 4.0,
        current: 65.0 + random.nextDouble() * 20.0,
        timestamp: now.subtract(const Duration(minutes: 12)),
      ),
      // Warning — monsoon humidity
      SensorReading(
        sensorId: 'FG-SENSOR-004',
        voltage: 9.2 + random.nextDouble() * 1.0,
        tension: 0.20 + random.nextDouble() * 0.1,
        temperature: 24.0 + random.nextDouble() * 2.0,
        humidity: 96.0 + random.nextDouble() * 3.0,
        current: 95.0 + random.nextDouble() * 15.0,
        timestamp: now.subtract(const Duration(minutes: 8)),
      ),
      // Normal gate sensor
      SensorReading(
        sensorId: 'FG-GATE-001',
        voltage: 12.3 + random.nextDouble() * 0.8,
        tension: 0.08 + random.nextDouble() * 0.1,
        temperature: 31.0 + random.nextDouble() * 3.0,
        humidity: 79.0 + random.nextDouble() * 6.0,
        current: 130.0 + random.nextDouble() * 20.0,
        timestamp: now,
      ),
    ];
  }
}
