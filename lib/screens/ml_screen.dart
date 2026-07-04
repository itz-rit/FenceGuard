import 'package:flutter/material.dart';
import '../services/ml_service.dart';

class MLScreen extends StatefulWidget {
  const MLScreen({super.key});

  @override
  State<MLScreen> createState() => _MLScreenState();
}

class _MLScreenState extends State<MLScreen> {
  final MLService _mlService = MLService();
  List<ZoneDetectionResult> _results = [];
  List<SensorReading> _readings = [];
  bool _isScanning = false;
  DateTime? _lastScan;

  @override
  void initState() {
    super.initState();
    _runScan();
  }

  Future<void> _runScan() async {
    setState(() => _isScanning = true);

    // Generate + analyze — instant, no network needed
    final readings = _mlService.generateSampleReadings();
    final results = _mlService.analyzeAllSensors(readings);

    // ✅ Show results immediately before Firestore saves
    setState(() {
      _readings = readings;
      _results = results;
      _isScanning = false;
      _lastScan = DateTime.now();
    });

    // ✅ Save all results to Firestore in parallel (non-blocking)
    Future.wait(
      results.map((result) => _mlService.saveDetectionResult(result)),
    ).catchError((e) {
      debugPrint('Firestore save error: $e');
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'critical':
        return Icons.crisis_alert;
      case 'warning':
        return Icons.warning_amber;
      default:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final criticalCount =
        _results.where((r) => r.status == 'critical').length;
    final warningCount =
        _results.where((r) => r.status == 'warning').length;
    final safeCount = _results.where((r) => r.status == 'safe').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ML Zone Detection"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: Color(0xFF4CAF50)),
            onPressed: _isScanning ? null : _runScan,
            tooltip: 'Run ML Scan',
          ),
        ],
      ),
      body: _isScanning && _results.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  SizedBox(height: 16),
                  Text("Running ML scan on all sensors..."),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Last scan time
                  if (_lastScan != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            "Last scan: ${_lastScan!.hour.toString().padLeft(2, '0')}:${_lastScan!.minute.toString().padLeft(2, '0')} — ${_results.length} sensors analyzed",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                  // Summary row
                  Row(
                    children: [
                      _summaryChip(
                          criticalCount.toString(), "Breach", Colors.red),
                      const SizedBox(width: 8),
                      _summaryChip(
                          warningCount.toString(), "Warning", Colors.orange),
                      const SizedBox(width: 8),
                      _summaryChip(
                          safeCount.toString(), "Safe", Colors.green),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Zone Detection Results",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Zone result cards
                  ..._results.map((result) => _buildResultCard(result)),

                  const SizedBox(height: 20),

                  // Raw sensor readings
                  const Text(
                    "Raw Sensor Readings",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._readings.map((r) => _buildReadingCard(r)),

                  const SizedBox(height: 20),

                  // How it works section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.psychology,
                                color: Colors.blue, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "How ML Detection Works",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _howItWorksRow("⚡",
                            "Voltage drop below 7V → wire cut or animal contact"),
                        _howItWorksRow("📡",
                            "Tension spike above 85% → physical fence breach"),
                        _howItWorksRow("💧",
                            "Humidity above 98% → flooding or submersion"),
                        _howItWorksRow("🐘",
                            "Tension + voltage drop at dusk/dawn → elephant pattern"),
                        _howItWorksRow("🌧️",
                            "High humidity + low voltage in Jun–Oct → monsoon damage"),
                        _howItWorksRow("⚡",
                            "Near-zero current → fence wire broken"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isScanning ? null : _runScan,
        backgroundColor: const Color(0xFF4CAF50),
        icon: const Icon(Icons.radar, color: Colors.white),
        label: const Text("Scan All Zones",
            style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildResultCard(ZoneDetectionResult result) {
    final color = _statusColor(result.status);
    final confidencePct = (result.confidence * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon(result.status), color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.zoneName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "📍 ${result.sectorName} • ${result.sensorId}",
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        result.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$confidencePct% confidence",
                      style: TextStyle(
                          fontSize: 10, color: color),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Confidence bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("ML Confidence",
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text("$confidencePct%",
                        style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: result.confidence,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          // Reason
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.reason,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Anomalies list
          if (result.anomalies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Detected Anomalies:",
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  ...result.anomalies.map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.arrow_right,
                              size: 14, color: color),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(a,
                                style: const TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                "✅ No anomalies detected",
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReadingCard(SensorReading reading) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reading.sensorId,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _readingChip("⚡ ${reading.voltage.toStringAsFixed(1)}V"),
              _readingChip(
                  "📡 Tension ${(reading.tension * 100).toStringAsFixed(0)}%"),
              _readingChip("🌡️ ${reading.temperature.toStringAsFixed(1)}°C"),
              _readingChip(
                  "💧 ${reading.humidity.toStringAsFixed(0)}% RH"),
              _readingChip(
                  "⚡ ${reading.current.toStringAsFixed(0)}mA"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(count,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _readingChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _howItWorksRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
