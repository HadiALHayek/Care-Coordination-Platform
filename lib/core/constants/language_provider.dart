import 'package:flutter/material.dart';
import 'prefs_cache.dart';

class LanguageProvider extends ChangeNotifier {
  final List<String> _languages = const ['English', 'Arabic'];
  String _language = 'English';
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<String> get languages => _languages;
  String get language => _language;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await PrefsCache.getInstance();
      _language = prefs.getString('language') ?? _languages.first;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String? lang) async {
    if (lang == null || !_languages.contains(lang) || _language == lang) {
      return; // Avoid unnecessary updates
    }
    _language = lang;
    try {
      final prefs = await PrefsCache.getInstance();
      await prefs.setString('language', lang);
      notifyListeners();
    } catch (e) {
      // Revert on error
      _language = _languages.first;
      notifyListeners();
    }
  }
}
