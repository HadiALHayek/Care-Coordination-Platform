import 'dart:convert';

import '../base.dart';
import '../core/constants/http_client.dart';

class DoctorProfileApi {
  static final Uri _profileUrl = Uri.parse(
    "${ApiConfig.baseUrl}/api/doctor/profile/",
  );

  /// Normalized return:
  /// { "success": bool, "data": Map<String,dynamic>?, "error": String? }
  static Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await AppHttpClient.instance.get(
      _profileUrl,
      headers: {"Authorization": "Token $token"},
    );

    try {
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
        // decoded looks like: {success:true, data: ...}
        dynamic data = decoded["data"];

        // If data is wrapped again: {success:true, data:{...}}
        if (data is Map<String, dynamic> && data.containsKey("data")) {
          final inner = data["data"];
          if (inner is Map<String, dynamic>) {
            data = inner;
          }
        }

        return {
          "success": decoded["success"] == true,
          "data": (data is Map<String, dynamic>) ? data : null,
          "error":
              (decoded["success"] == true)
                  ? null
                  : (decoded["message"]?.toString() ?? "Unknown error"),
        };
      }

      return {
        "success": false,
        "data": null,
        "error": "HTTP ${response.statusCode}: ${response.body}",
      };
    } catch (e) {
      return {
        "success": false,
        "data": null,
        "error": "Failed to parse response: $e",
      };
    }
  }

  static Future<Map<String, dynamic>> updateProfile(
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await AppHttpClient.instance.put(
      _profileUrl,
      headers: {
        "Authorization": "Token $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    try {
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
        final ok = decoded["success"] == true;
        final data = decoded["data"];

        return {
          "success": ok,
          "data": (data is Map<String, dynamic>) ? data : null,
          "error":
              ok ? null : (decoded["message"]?.toString() ?? "Unknown error"),
        };
      }

      return {
        "success": false,
        "data": null,
        "error": "HTTP ${response.statusCode}: ${response.body}",
      };
    } catch (e) {
      return {
        "success": false,
        "data": null,
        "error": "Failed to parse response: $e",
      };
    }
  }
}
