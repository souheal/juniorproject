import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode options
enum AppThemeMode {
  light,
  dark,
  system,
}

/// Provider for managing app theme with persistence.
///
/// Features:
/// - Toggle between light, dark, and system themes
/// - Persists theme preference using SharedPreferences
/// - Loads saved preference on app startup
///
/// Usage:
/// ```dart
/// // In main.dart, wrap with ChangeNotifierProvider
/// ChangeNotifierProvider(
///   create: (_) => ThemeProvider()..loadTheme(),
///   child: MyApp(),
/// )
///
/// // In widgets
/// final themeProvider = context.watch<ThemeProvider>();
/// bool isDark = themeProvider.isDarkMode;
///
/// // Toggle theme
/// context.read<ThemeProvider>().toggleTheme();
/// ```
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';

  AppThemeMode _themeMode = AppThemeMode.light;
  bool _isInitialized = false;

  /// Current theme mode
  AppThemeMode get themeMode => _themeMode;

  /// Whether the provider has loaded saved preferences
  bool get isInitialized => _isInitialized;

  /// Check if current theme is dark
  bool get isDarkMode => _themeMode == AppThemeMode.dark;

  /// Check if using system theme
  bool get isSystemMode => _themeMode == AppThemeMode.system;

  /// Get the appropriate ThemeMode for MaterialApp
  ThemeMode get materialThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Load saved theme preference from SharedPreferences.
  /// Call this in main() before runApp or in provider creation.
  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);

      if (savedTheme != null) {
        _themeMode = AppThemeMode.values.firstWhere(
          (mode) => mode.name == savedTheme,
          orElse: () => AppThemeMode.light,
        );
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Set theme mode and persist to SharedPreferences.
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  /// Toggle between light and dark mode.
  /// If currently system mode, switches to light.
  Future<void> toggleTheme() async {
    if (_themeMode == AppThemeMode.dark) {
      await setThemeMode(AppThemeMode.light);
    } else {
      await setThemeMode(AppThemeMode.dark);
    }
  }

  /// Set to light mode
  Future<void> setLightMode() async {
    await setThemeMode(AppThemeMode.light);
  }

  /// Set to dark mode
  Future<void> setDarkMode() async {
    await setThemeMode(AppThemeMode.dark);
  }

  /// Set to system mode (follows device settings)
  Future<void> setSystemMode() async {
    await setThemeMode(AppThemeMode.system);
  }
}
