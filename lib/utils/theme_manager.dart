import 'package:flutter/material.dart';

class ThemeManager {
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color primaryLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFF9800);
  static const Color danger = Color(0xFFF44336);
  static const Color wet = Color(0xFF2196F3);
  static const Color optimal = Color(0xFF4CAF50);
  static const Color dry = Color(0xFFFF9800);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF11181C),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: primaryColor, width: 1),
      ),
      shadowColor: primaryColor.withOpacity(0.3),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFF0a0a0a),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1f2937),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: primaryColor, width: 1),
      ),
      shadowColor: primaryColor.withOpacity(0.3),
    ),
  );
}