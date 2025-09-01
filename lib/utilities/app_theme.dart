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

  static final _lightTheme = ThemeData(
    primaryColor: Colors.blue,
    colorScheme: const ColorScheme.light(primary: Colors.blue),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    cardColor: Colors.white,
  );

  static final _darkTheme = ThemeData(
    primaryColor: Colors.blue[700],
    colorScheme: ColorScheme.dark(primary: Colors.blue[700]!),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
    ),
    cardColor: Colors.grey[900],
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
}