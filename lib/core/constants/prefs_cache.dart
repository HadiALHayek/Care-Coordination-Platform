import 'package:shared_preferences/shared_preferences.dart';

/// Cached SharedPreferences instance to avoid repeated getInstance() calls
/// This significantly improves performance by reusing the same instance
class PrefsCache {
  static SharedPreferences? _instance;
  static bool _initialized = false;

  /// Get the cached SharedPreferences instance
  /// If not initialized, it will initialize and cache it
  static Future<SharedPreferences> getInstance() async {
    if (!_initialized || _instance == null) {
      _instance = await SharedPreferences.getInstance();
      _initialized = true;
    }
    return _instance!;
  }

  /// Clear the cache (useful for testing or logout)
  static void clearCache() {
    _instance = null;
    _initialized = false;
  }

  /// Check if cache is initialized
  static bool get isInitialized => _initialized && _instance != null;
}

