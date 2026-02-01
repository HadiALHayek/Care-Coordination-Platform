import 'package:http/http.dart' as http;

/// Singleton HTTP client for connection reuse and better performance
/// Reusing HTTP clients allows connection pooling and reduces overhead
class AppHttpClient {
  static http.Client? _instance;

  /// Get the singleton HTTP client instance
  static http.Client get instance {
    _instance ??= http.Client();
    return _instance!;
  }

  /// Dispose the HTTP client (call on app termination)
  static void dispose() {
    _instance?.close();
    _instance = null;
  }
}
