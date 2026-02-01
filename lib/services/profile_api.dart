import 'dart:convert';

import '../base.dart';
import '../core/constants/http_client.dart';

class ProfileApi {
  static final Uri baseUrl = Uri.parse("${ApiConfig.baseUrl}/api/profile/");

  // ============================================================
  // UPDATE PROFILE (PATCH)
  // ============================================================
  static Future<Map<String, dynamic>> updateProfile(
    String token,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await AppHttpClient.instance.patch(
        baseUrl,
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      final decoded = _safeDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "data": decoded};
      }

      return {"success": false, "error": decoded};
    } catch (e) {
      return {"success": false, "error": "Exception: $e"};
    }
  }

  // ============================================================
  // GET PROFILE
  // ============================================================
  static Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      final response = await AppHttpClient.instance.get(
        baseUrl,
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
      );

      final decoded = _safeDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "data": decoded};
      }

      return {"success": false, "error": decoded};
    } catch (e) {
      return {"success": false, "error": "Exception: $e"};
    }
  }

  // ============================================================
  // SAFE JSON DECODER
  // ============================================================
  static dynamic _safeDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body; // plain text error → return as-is
    }
  }
}
