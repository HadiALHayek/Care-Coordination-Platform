import 'package:flutter/material.dart';

/// Cached theme instances to prevent recreation on every rebuild
/// This significantly improves performance by reusing theme objects
class ThemeCache {
  static ThemeData? _lightTheme;
  static ThemeData? _darkTheme;

  /// Get cached light theme or create if not exists
  static ThemeData get lightTheme {
    _lightTheme ??= ThemeData.light();
    return _lightTheme!;
  }

  /// Get cached dark theme or create if not exists
  static ThemeData get darkTheme {
    _darkTheme ??= ThemeData.dark();
    return _darkTheme!;
  }

  /// Clear theme cache (useful for testing or theme updates)
  static void clearCache() {
    _lightTheme = null;
    _darkTheme = null;
  }
}
