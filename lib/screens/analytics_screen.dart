import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  int totalAlerts = 0;
  int criticalAlerts = 0;
  int warningAlerts = 0;
  int totalDevices = 0;
  Map<String, int> alertsPerDay = {};
  Map<String, int> alertsBySeverity = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    // Load alerts
    final alertsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('alerts')
        .get();

    // Load devices
    final devicesSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('devices')
        .get();

    int critical = 0;
    int warning = 0;
    Map<String, int> perDay = {};

    for (var doc in alertsSnap.docs) {
      final data = doc.data();
      final severity = data['severity'] ?? 'info';

      if (severity == 'critical') critical++;
      if (severity == 'warning') warning++;

      // Group by day
      final Timestamp? ts = data['timestamp'];
      if (ts != null) {
        final date = ts.toDate();
        final dayKey =
            '${date.day}/${date.month}';
        perDay[dayKey] = (perDay[dayKey] ?? 0) + 1;
      }
    }

    setState(() {
      totalAlerts = alertsSnap.docs.length;
      criticalAlerts = critical;
      warningAlerts = warning;
      totalDevices = devicesSnap.docs.length;
      alertsPerDay = perDay;
      alertsBySeverity = {
        'Critical': critical,
        'Warning': warning,
        'Info': totalAlerts - critical - warning,
      };
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              _loadAnalytics();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          title: "Total Alerts",
                          value: totalAlerts.toString(),
                          color: Colors.blue,
                          icon: Icons.notifications,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          title: "Critical",
                          value: criticalAlerts.toString(),
                          color: Colors.red,
                          icon: Icons.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          title: "Warnings",
                          value: warningAlerts.toString(),
                          color: Colors.orange,
                          icon: Icons.report_problem,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _summaryCard(
                          title: "Devices",
                          value: totalDevices.toString(),
                          color: Colors.green,
                          icon: Icons.devices,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Alerts per day bar chart
                  const Text(
                    "Alerts per Day",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 6)
                      ],
                    ),
                    child: alertsPerDay.isEmpty
                        ? const Center(
                            child: Text(
                              "No alert data yet",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (alertsPerDay.values.isEmpty
                                          ? 1
                                          : alertsPerDay.values
                                              .reduce((a, b) => a > b ? a : b))
                                      .toDouble() +
                                  1,
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    getTitlesWidget: (value, meta) => Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final keys =
                                          alertsPerDay.keys.toList();
                                      if (value.toInt() < keys.length) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            keys[value.toInt()],
                                            style:
                                                const TextStyle(fontSize: 10),
                                          ),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.shade200,
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: alertsPerDay.entries
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map(
                                    (e) => BarChartGroupData(
                                      x: e.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: e.value.value.toDouble(),
                                          color: const Color(0xFF4CAF50),
                                          width: 18,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                  ),

                  const SizedBox(height: 28),

                  // Severity pie chart
                  const Text(
                    "Alerts by Severity",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 240,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 6)
                      ],
                    ),
                    child: totalAlerts == 0
                        ? const Center(
                            child: Text(
                              "No alert data yet",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : Row(
                            children: [
                              // Pie chart
                              Expanded(
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 36,
                                    sections: [
                                      if (criticalAlerts > 0)
                                        PieChartSectionData(
                                          value:
                                              criticalAlerts.toDouble(),
                                          color: Colors.red,
                                          title:
                                              '$criticalAlerts',
                                          radius: 60,
                                          titleStyle: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      if (warningAlerts > 0)
                                        PieChartSectionData(
                                          value:
                                              warningAlerts.toDouble(),
                                          color: Colors.orange,
                                          title:
                                              '$warningAlerts',
                                          radius: 60,
                                          titleStyle: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      if (totalAlerts -
                                              criticalAlerts -
                                              warningAlerts >
                                          0)
                                        PieChartSectionData(
                                          value: (totalAlerts -
                                                  criticalAlerts -
                                                  warningAlerts)
                                              .toDouble(),
                                          color: Colors.blue,
                                          title:
                                              '${totalAlerts - criticalAlerts - warningAlerts}',
                                          radius: 60,
                                          titleStyle: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              // Legend
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _legendItem(
                                      color: Colors.red,
                                      label: "Critical",
                                      count: criticalAlerts),
                                  const SizedBox(height: 12),
                                  _legendItem(
                                      color: Colors.orange,
                                      label: "Warning",
                                      count: warningAlerts),
                                  const SizedBox(height: 12),
                                  _legendItem(
                                      color: Colors.blue,
                                      label: "Info",
                                      count: totalAlerts -
                                          criticalAlerts -
                                          warningAlerts),
                                ],
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 28),

                  // Device status
                  const Text(
                    "Device Overview",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _deviceStatusStream(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _deviceStatusStream() {
    return StreamBuilder<QuerySnapshot>(
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
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6)
              ],
            ),
            child: const Center(
              child: Text(
                "No devices added yet",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        int safe = 0, warning = 0, critical = 0, offline = 0;
        for (var d in devices) {
          final status =
              (d.data() as Map<String, dynamic>)['status'] ?? 'offline';
          if (status == 'safe') {
            safe++;
          } else if (status == 'warning') warning++;
          else if (status == 'critical') critical++;
          else offline++;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6)
            ],
          ),
          child: Column(
            children: [
              _deviceStatusRow("Safe", safe, Colors.green),
              const Divider(),
              _deviceStatusRow("Warning", warning, Colors.orange),
              const Divider(),
              _deviceStatusRow("Critical", critical, Colors.red),
              const Divider(),
              _deviceStatusRow("Offline", offline, Colors.grey),
            ],
          ),
        );
      },
    );
  }

  Widget _deviceStatusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
    required int count,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "$label ($count)",
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
        color: color.withOpacity(0.05),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title,
              style:
                  const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}