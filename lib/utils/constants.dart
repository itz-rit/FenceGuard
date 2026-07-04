import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'FenceGuard';
  static const String appTagline = 'Smart Fence Monitoring System';
  static const String appVersion = '1.0.0';

  // Colors
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color primaryDarkColor = Color(0xFF2E7D32);
  static const Color primaryLightColor = Color(0xFFC8E6C9);
  static const Color accentColor = Color(0xFFFFA000);
  
  // Status Colors
  static const Color statusSafe = Color(0xFF4CAF50);
  static const Color statusWarning = Color(0xFFFF9800);
  static const Color statusCritical = Color(0xFFF44336);
  static const Color statusOffline = Color(0xFF9E9E9E);

  // Firestore Collections
  static const String collectionUsers = 'users';
  static const String collectionDevices = 'devices';
  static const String collectionAlerts = 'alerts';
  static const String collectionFarms = 'farms';

  // Device Status
  static const String deviceStatusSafe = 'safe';
  static const String deviceStatusWarning = 'warning';
  static const String deviceStatusCritical = 'critical';
  static const String deviceStatusOffline = 'offline';

  // Alert Severity
  static const String alertSeverityInfo = 'info';
  static const String alertSeverityWarning = 'warning';
  static const String alertSeverityCritical = 'critical';

  // Shared Preferences Keys
  static const String prefUserRole = 'user_role';
  static const String prefFirstLaunch = 'first_launch';
  static const String prefLanguage = 'language';

  // Route Names
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeHome = '/home';
  static const String routeDevices = '/devices';
  static const String routeAlerts = '/alerts';
  static const String routeAnalytics = '/analytics';
  static const String routeFarmers = '/farmers';
  static const String routeSettings = '/settings';
  static const String routeAddDevice = '/add-device';

  // Animation Durations
  static const Duration animationQuick = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 400);
  static const Duration animationSlow = Duration(milliseconds: 600);

  // Padding & Margins
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingExtraLarge = 32.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusExtraLarge = 24.0;

  // Font Sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeRegular = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeExtraLarge = 20.0;
  static const double fontSizeHeading = 24.0;
  static const double fontSizeTitle = 28.0;

  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconRegular = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconExtraLarge = 48.0;
}