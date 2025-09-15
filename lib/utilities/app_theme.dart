// app_theme.dart (updated)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeData>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeData> {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeNotifier() : super(_lightTheme) {
    _initTheme();
  }

  // Light green color definitions
  static const Color _lightGreen = Color(0xFF4CAF50); // Medium light green
  static const Color _lightGreenLight = Color(0xFF81C784); // Lighter variant
  static const Color _lightGreenDark = Color(0xFF388E3C); // Darker variant

  static final _lightTheme = ThemeData(
    primaryColor: _lightGreen,
    colorScheme: const ColorScheme.light(
      primary: _lightGreen,
      secondary: _lightGreenLight,
      primaryContainer: Color(0xFFE8F5E9), // Very light green background
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightGreen,
      foregroundColor: Colors.white,
    ),
    cardColor: Colors.white,
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _lightGreen,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightGreen,
        foregroundColor: Colors.white,
      ),
    ),
  );

  static final _darkTheme = ThemeData(
    primaryColor: _lightGreenDark,
    colorScheme: const ColorScheme.dark(
      primary: _lightGreen,
      secondary: _lightGreenLight,
      primaryContainer: Color(0xFF1B5E20), // Dark green background
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightGreenDark,
      foregroundColor: Colors.white,
    ),
    cardColor: const Color(0xFF1E1E1E),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _lightGreen,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightGreen,
        foregroundColor: Colors.white,
      ),
    ),
  );

  void _initTheme() {
    // You can add logic to load saved theme preference here
    state = _lightTheme;
  }

  ThemeMode getThemeMode() => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    state = mode == ThemeMode.dark ? _darkTheme : _lightTheme;
    // You can add logic to save theme preference here
  }

  void toggleTheme() {
    setThemeMode(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  // Getter for the light green color if needed elsewhere
  static Color get lightGreen => _lightGreen;
  static Color get lightGreenLight => _lightGreenLight;
  static Color get lightGreenDark => _lightGreenDark;
}