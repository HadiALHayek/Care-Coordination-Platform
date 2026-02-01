import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../base.dart';
import '../core/constants/http_client.dart';

class BreastMammoScanApi {
  static final Uri uploadUrl = Uri.parse(
    "${ApiConfig.baseUrl}/api/mammo/upload/",
  );

  static Future<Map<String, dynamic>> uploadBreastScan({
    required File imageFile,
    required String token,
  }) async {
    try {
      if (!await imageFile.exists() || await imageFile.length() == 0) {
        return {
          "success": false,
          "error_type": "file_error",
          "message": "Selected file does not exist or is empty.",
        };
      }

      final request = http.MultipartRequest("POST", uploadUrl);

      request.headers["Authorization"] = "Token $token";

      request.files.add(
        await http.MultipartFile.fromPath("image", imageFile.path),
      );

      final streamedResponse = await AppHttpClient.instance.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      final body = response.body;

      if (response.statusCode == 401) {
        return {
          "success": false,
          "error_type": "unauthorized",
          "message": "Session expired or invalid token.",
        };
      }

      if (response.statusCode == 400) {
        return {"success": false, "error": _safeJson(body)};
      }

      if (response.statusCode == 502 ||
          response.statusCode == 503 ||
          response.statusCode == 504) {
        return {
          "success": false,
          "error_type": "ai_service",
          "status_code": response.statusCode,
          "error": _safeJson(body),
        };
      }

      if (response.statusCode == 201) {
        return {"success": true, "data": _safeJson(body)};
      }

      return {
        "success": false,
        "status_code": response.statusCode,
        "error": _safeJson(body),
      };
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  static dynamic _safeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }
}
