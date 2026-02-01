import 'package:flutter/material.dart';
import 'prefs_cache.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await PrefsCache.getInstance();
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleDarkMode(bool value) async {
    if (_isDarkMode == value) return; // Avoid unnecessary updates
    _isDarkMode = value;
    try {
      final prefs = await PrefsCache.getInstance();
      await prefs.setBool('darkMode', value);
      notifyListeners();
    } catch (e) {
      // Revert on error
      _isDarkMode = !value;
      notifyListeners();
    }
  }
}
