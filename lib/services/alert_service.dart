import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add an alert for a device
  Future<void> addAlert({
    required String deviceId,
    required String message,
    required String severity, // 'critical', 'warning', 'info'
  }) async {
    final String uid = _auth.currentUser!.uid;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('alerts')
        .add({
      'deviceId': deviceId,
      'message': message,
      'severity': severity,
      'timestamp': FieldValue.serverTimestamp(),
      'acknowledged': false,
    });
  }

  // Stream all alerts (newest first)
  Stream<QuerySnapshot> getAlertsStream() {
    final String uid = _auth.currentUser!.uid;

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Acknowledge an alert
  Future<void> acknowledgeAlert(String alertId) async {
    final String uid = _auth.currentUser!.uid;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('alerts')
        .doc(alertId)
        .update({'acknowledged': true});
  }

  // Delete an alert
  Future<void> deleteAlert(String alertId) async {
    final String uid = _auth.currentUser!.uid;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('alerts')
        .doc(alertId)
        .delete();
  }
}