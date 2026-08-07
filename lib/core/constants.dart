import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  static const String appName = 'QuantTrade';
  static const String appTagline = 'Smart Stock Predictions';
  static const String appSlogan = 'AI Model based precision.';
  
  static String userApiBaseUrl = '';

  static String get apiBaseUrl {
    if (userApiBaseUrl.isNotEmpty) return userApiBaseUrl;
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }
  // Animation Durations
  static const Duration splashDelay = Duration(seconds: 3);
  static const Duration fastAnim = Duration(milliseconds: 200);
  static const Duration mediumAnim = Duration(milliseconds: 500);
  static const Duration slowAnim = Duration(seconds: 1);
}
