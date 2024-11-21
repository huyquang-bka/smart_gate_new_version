import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors with reduced intensity for eye comfort
  static const Color primaryColor = Color(0xFF1976D2); // Softer blue
  static const Color primaryLight = Color(0xFF64B5F6); // Light blue
  static const Color primaryDark = Color(0xFF0D47A1); // Dark blue

  // Action colors
  static const Color actionColor = Color(0xFF4CAF50); // Soft green
  static const Color warningColor = Color(0xFFFFA726); // Soft orange
  static const Color errorColor = Color(0xFFEF5350); // Soft red

  // Background colors for better contrast
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light grey
  static const Color surfaceColor = Color(0xFFFFFFFF); // White
  static const Color cardColor = Color(0xFFFFFFFF); // White

  // Text colors for better readability
  static const Color textPrimary = Color(0xFF212121); // Dark grey
  static const Color textSecondary = Color(0xFF757575); // Medium grey
  static const Color textLight = Color(0xFFBDBDBD); // Light grey

  // Button styles
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
  );

  static final ButtonStyle actionButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: actionColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
  );

  // Text Styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
  );

  // Theme Data
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: primaryLight,
      error: errorColor,
      brightness: Brightness.light,
      background: backgroundColor,
      surface: surfaceColor,
    ),
    // AppBar Theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    // Card Theme
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: primaryButtonStyle,
    ),
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      background: const Color(0xFF303030), // Dark grey background
      surface: const Color(0xFF424242), // Slightly lighter surface
      primary: primaryColor,
      secondary: primaryLight,
    ),
  );
}
