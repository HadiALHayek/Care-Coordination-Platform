import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../base.dart';
import '../core/constants/http_client.dart';

class ChatApi {
  static const String baseUrl = "${ApiConfig.baseUrl}/api";

  static Future<bool> sendMessage({
    required int recipientId,
    String message = "",
    File? pdfFile,
    required String token,
  }) async {
    final url = Uri.parse("$baseUrl/chat/send/");

    final req = http.MultipartRequest("POST", url);
    req.headers["Authorization"] = "Token $token";

    req.fields["recipient_id"] = recipientId.toString();
    req.fields["message"] = message;

    if (pdfFile != null) {
      req.files.add(
        await http.MultipartFile.fromPath("pdf_file", pdfFile.path),
      );
    }

    final streamedResponse = await AppHttpClient.instance.send(req);
    return streamedResponse.statusCode == 201;
  }

  static Future<List<Map<String, dynamic>>> getMessages({
    required int otherUserId,
    required String token,
  }) async {
    final url = Uri.parse("$baseUrl/chat/$otherUserId/");

    final res = await AppHttpClient.instance.get(
      url,
      headers: {"Authorization": "Token $token"},
    );

    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
    return [];
  }

  static Future<Map<String, dynamic>> sendReportToDoctor({
    required int doctorId,
    required int scanId,
    required String token,
  }) async {
    final url = Uri.parse("$baseUrl/send-report/");

    final res = await AppHttpClient.instance.post(
      url,
      headers: {
        "Authorization": "Token $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"doctor_id": doctorId, "scan_id": scanId}),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final decoded = _safeJson(res.body);
      if (decoded is Map<String, dynamic>) return {"success": true, ...decoded};
      return {"success": true};
    }

    final decoded = _safeJson(res.body);
    if (decoded is Map<String, dynamic>) return {"success": false, ...decoded};
    return {"success": false, "error": decoded.toString()};
  }

  static dynamic _safeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }
}
