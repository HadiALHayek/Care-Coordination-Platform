import 'dart:convert';

import '../base.dart';
import '../core/constants/http_client.dart';

class DoctorRequestsApi {
  static final Uri _createUrl = Uri.parse(
    "${ApiConfig.baseUrl}/api/doctor/requests/",
  );

  static final Uri _pendingUrl = Uri.parse(
    "${ApiConfig.baseUrl}/api/doctor/requests/pending/",
  );

  static Uri _handleUrl(int requestId) =>
      Uri.parse("${ApiConfig.baseUrl}/api/doctor/requests/$requestId/handle/");

  // ----------------------------
  // PATIENT: SEND REQUEST (WITH STATUS)
  // ----------------------------
  static Future<Map<String, dynamic>> requestDoctorWithStatus(
    String token, {
    required int doctorId,
  }) async {
    // debugPrint("🚨 requestDoctorWithStatus CALLED doctorId=$doctorId");
    // debugPrint(StackTrace.current.toString()); // ✅ shows the caller

    final res = await AppHttpClient.instance.post(
      _createUrl,
      headers: {
        "Authorization": "Token $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"doctor_id": doctorId}),
    );

    // ✅ backend returns JSON for 200 or 201
    if (res.statusCode == 200 || res.statusCode == 201) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {"success": true};
    }

    // ✅ extract backend error message if possible
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return {"success": false, ...decoded};
      }
    } catch (_) {}

    return {"success": false, "error": res.body};
  }

  // ----------------------------
  // DOCTOR: GET PENDING REQUESTS
  // ----------------------------
  static Future<List<Map<String, dynamic>>> getPending(String token) async {
    final res = await AppHttpClient.instance.get(
      _pendingUrl,
      headers: {"Authorization": "Token $token"},
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return [];
  }

  // ----------------------------
  // DOCTOR: ACCEPT / REJECT REQUEST
  // ----------------------------
  static Future<Map<String, dynamic>> handleRequest(
    String token, {
    required int requestId,
    required String action, // "accept" | "reject"
  }) async {
    final res = await AppHttpClient.instance.post(
      _handleUrl(requestId),
      headers: {
        "Authorization": "Token $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"action": action}),
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
    }

    return {"success": false, "error": res.body};
  }
}
