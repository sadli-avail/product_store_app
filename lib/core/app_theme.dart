import 'package:flutter/material.dart';

/// AppTheme defines Material 3 Light and Dark themes for the application.
class AppTheme {
  // Brand seed color
  static const Color primarySeed = Colors.indigo;

  // Light Theme configuration
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: primarySeed,
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 2,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primarySeed, width: 2),
      ),
    ),
  );

  // Dark Theme configuration
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: primarySeed,
    brightness: Brightness.dark,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 2,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.indigoAccent, width: 2),
      ),
    ),
  );
}
