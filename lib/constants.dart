import 'package:flutter/material.dart';
import 'config/app_keys.dart';

class AppColors {
  static const Color primary = Color(0xFF00A65A); // FWU Green
  static const Color primaryDark = Color(0xFF008d4c);
  static const Color primaryLight = Color(0xFFe6f6ef);
  static const Color secondary = Color(0xFFFF6B6B); // Coral Red
  static const Color background = Color(0xFFF4F7F6);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Color(0xFF777777);
}

class AppConfig {
  static String get baseUrl => AppKeys.baseUrl;
}
