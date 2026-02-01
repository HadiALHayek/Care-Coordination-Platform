import 'dart:convert';

import '../base.dart';
import '../core/constants/http_client.dart';

class BlogApi {
  static final Uri _blogsUrl = Uri.parse("${ApiConfig.baseUrl}/api/blogs/");

  static Future<Map<String, dynamic>> getBlogs() async {
    final response = await AppHttpClient.instance.get(
      _blogsUrl,
      headers: {"Accept": "application/json"},
    );

    try {
      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
        final ok = decoded["success"] == true;
        final raw = decoded["data"];

        final list =
            (raw is List)
                ? raw.map((e) => Map<String, dynamic>.from(e)).toList()
                : <Map<String, dynamic>>[];

        return {
          "success": ok,
          "data": ok ? list : null,
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
