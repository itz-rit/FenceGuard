import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeviceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addDevice({
    required String deviceId,
    required String deviceName,
    required String location,
  }) async {
    final String uid = _auth.currentUser!.uid;

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .set({
      'deviceName': deviceName,
      'location': location,
      'status': 'safe',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
