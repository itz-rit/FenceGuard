import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// Background message handler — must be a top-level function
// ─────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Background FCM message: ${message.messageId}');
  // Firebase is already initialised by the time this fires
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ── Android notification channel ────────────────────────────
  static const AndroidNotificationChannel _criticalChannel =
      AndroidNotificationChannel(
    'fenceguard_critical',
    'Critical Alerts',
    description: 'Immediate breach and intrusion alerts',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _warningChannel =
      AndroidNotificationChannel(
    'fenceguard_warning',
    'Warning Alerts',
    description: 'Voltage drops, animal contact, and sensor anomalies',
    importance: Importance.high,
    playSound: true,
  );

  static const AndroidNotificationChannel _infoChannel =
      AndroidNotificationChannel(
    'fenceguard_info',
    'Info & Updates',
    description: 'Routine sensor updates and maintenance reminders',
    importance: Importance.defaultImportance,
  );

  // ─────────────────────────────────────────────────────────────
  // Initialise — call once from main.dart after Firebase.initializeApp()
  // ─────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    // 1. Request permission (iOS + Android 13+)
    final NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('⚠️  User denied notification permissions');
      return;
    }

    // 2. Set up local notifications plugin
    await _setupLocalNotifications();

    // 3. Create Android channels
    await _createAndroidChannels();

    // 4. Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 5. Foreground message listener
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. Notification tap handler (app in background, then opened)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 7. Check if app was launched from a notification
    final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // 8. Save FCM token to Firestore
    await _saveFCMToken();

    // 9. Listen for token refreshes
    _fcm.onTokenRefresh.listen((newToken) {
      _storeToken(newToken);
      debugPrint('🔄 FCM token refreshed: $newToken');
    });

    debugPrint('✅ NotificationService initialised');
  }

  // ─────────────────────────────────────────────────────────────
  // Local notifications setup
  // ─────────────────────────────────────────────────────────────
  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false, // already requested via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Local notification tapped: ${response.payload}');
        _handleLocalNotificationTap(response.payload);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Create Android notification channels
  // ─────────────────────────────────────────────────────────────
  Future<void> _createAndroidChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_criticalChannel);
      await androidPlugin.createNotificationChannel(_warningChannel);
      await androidPlugin.createNotificationChannel(_infoChannel);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FCM token management
  // ─────────────────────────────────────────────────────────────
  Future<void> _saveFCMToken() async {
    try {
      final String? token = await _fcm.getToken();
      if (token != null) {
        await _storeToken(token);
        debugPrint('📱 FCM token saved: $token');
      }
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  Future<void> _storeToken(String token) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      'platform': _getPlatform(),
    });
  }

  String _getPlatform() {
    // Simple runtime check — avoids dart:io import issues on web
    try {
      return 'android'; // adjust if building for iOS too
    } catch (_) {
      return 'unknown';
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Handle incoming FCM message while app is in foreground
  // ─────────────────────────────────────────────────────────────
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📬 Foreground FCM: ${message.notification?.title}');

    final String severity =
        message.data['severity'] ?? 'info';
    final String channelId = _channelIdForSeverity(severity);
    final int notifId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Show as local notification (FCM foreground messages don't auto-show on Android)
    await _localNotifications.show(
      notifId,
      message.notification?.title ?? 'FenceGuard Alert',
      message.notification?.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _channelNameForSeverity(severity),
          icon: '@mipmap/ic_launcher',
          importance: _importanceForSeverity(severity),
          priority: severity == 'critical' ? Priority.max : Priority.high,
          color: _colorForSeverity(severity),
          styleInformation: BigTextStyleInformation(
            message.notification?.body ?? '',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Handle notification tap (FCM — app was in background)
  // ─────────────────────────────────────────────────────────────
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 FCM notification tapped: ${message.data}');
    // Navigate to alerts screen — use a GlobalKey<NavigatorState>
    // or a NavigationService if you have one set up.
    // Example:
    //   NavigationService.navigateTo('/alerts');
  }

  // ─────────────────────────────────────────────────────────────
  // Handle local notification tap
  // ─────────────────────────────────────────────────────────────
  void _handleLocalNotificationTap(String? payload) {
    if (payload == null) return;
    try {
      final Map<String, dynamic> data =
          jsonDecode(payload) as Map<String, dynamic>;
      debugPrint('👆 Local notification tapped, data: $data');
      // Same navigation hook as above
    } catch (e) {
      debugPrint('❌ Error parsing notification payload: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Send a local notification directly (called from alert_service
  // or ml_service when a critical/warning event is detected)
  // ─────────────────────────────────────────────────────────────
  Future<void> showAlertNotification({
    required String title,
    required String body,
    required String severity, // 'critical' | 'warning' | 'info'
    String? deviceId,
    String? zone,
  }) async {
    final int notifId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final String channelId = _channelIdForSeverity(severity);

    final String fullBody = zone != null ? '📍 $zone\n$body' : body;

    await _localNotifications.show(
      notifId,
      title,
      fullBody,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          _channelNameForSeverity(severity),
          icon: '@mipmap/ic_launcher',
          importance: _importanceForSeverity(severity),
          priority: severity == 'critical' ? Priority.max : Priority.high,
          color: _colorForSeverity(severity),
          styleInformation: BigTextStyleInformation(fullBody),
          ticker: title,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: severity != 'info',
          subtitle: zone,
        ),
      ),
      payload: jsonEncode({
        'severity': severity,
        'deviceId': deviceId ?? '',
        'zone': zone ?? '',
      }),
    );

    // Also log to Firestore notification history
    await _logNotification(
      title: title,
      body: body,
      severity: severity,
      deviceId: deviceId,
      zone: zone,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Convenience: show breach alert (called by MLService or ESP32 listener)
  // ─────────────────────────────────────────────────────────────
  Future<void> showBreachAlert({
    required String sensorId,
    required String zoneName,
    required String reason,
  }) async {
    await showAlertNotification(
      title: '🚨 Fence Breach Detected!',
      body: reason,
      severity: 'critical',
      deviceId: sensorId,
      zone: zoneName,
    );
  }

  Future<void> showWarningAlert({
    required String sensorId,
    required String zoneName,
    required String reason,
  }) async {
    await showAlertNotification(
      title: '⚠️ Fence Warning',
      body: reason,
      severity: 'warning',
      deviceId: sensorId,
      zone: zoneName,
    );
  }

  Future<void> showInfoAlert({
    required String message,
    String? zone,
  }) async {
    await showAlertNotification(
      title: 'FenceGuard',
      body: message,
      severity: 'info',
      zone: zone,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Log notification to Firestore (for history / analytics)
  // ─────────────────────────────────────────────────────────────
  Future<void> _logNotification({
    required String title,
    required String body,
    required String severity,
    String? deviceId,
    String? zone,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'severity': severity,
        'deviceId': deviceId ?? '',
        'zone': zone ?? '',
        'sentAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      debugPrint('❌ Error logging notification: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Mark all notifications as read
  // ─────────────────────────────────────────────────────────────
  Future<void> markAllRead() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    final unread = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  // ─────────────────────────────────────────────────────────────
  // Stream unread notification count (use in AppBar badge)
  // ─────────────────────────────────────────────────────────────
  Stream<int> unreadCountStream() {
    final User? user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ─────────────────────────────────────────────────────────────
  // Cancel all pending local notifications
  // ─────────────────────────────────────────────────────────────
  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────
  String _channelIdForSeverity(String severity) {
    switch (severity) {
      case 'critical':
        return 'fenceguard_critical';
      case 'warning':
        return 'fenceguard_warning';
      default:
        return 'fenceguard_info';
    }
  }

  String _channelNameForSeverity(String severity) {
    switch (severity) {
      case 'critical':
        return 'Critical Alerts';
      case 'warning':
        return 'Warning Alerts';
      default:
        return 'Info & Updates';
    }
  }

  Importance _importanceForSeverity(String severity) {
    switch (severity) {
      case 'critical':
        return Importance.max;
      case 'warning':
        return Importance.high;
      default:
        return Importance.defaultImportance;
    }
  }

  Color _colorForSeverity(String severity) {
    switch (severity) {
      case 'critical':
        return const Color(0xFFF44336); // red
      case 'warning':
        return const Color(0xFFFF9800); // orange
      default:
        return const Color(0xFF4CAF50); // green
    }
  }
}