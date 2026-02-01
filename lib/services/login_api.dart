import 'dart:convert';

import '../base.dart';
import '../core/constants/http_client.dart';

class LoginApi {
  static final Uri loginUrl = Uri.parse("${ApiConfig.baseUrl}/api/login/");

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await AppHttpClient.instance.post(
        loginUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
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

  static dynamic _safeDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }
}
