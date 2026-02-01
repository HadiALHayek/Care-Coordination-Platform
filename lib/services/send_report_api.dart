import 'dart:convert';

import '../base.dart';
import '../core/constants/http_client.dart';

class SendReportApi {
  static final Uri _url = Uri.parse("${ApiConfig.baseUrl}/api/send-report/");

  static Future<Map<String, dynamic>> sendReport({
    required String token,
    required int doctorId,
    required int scanId,
  }) async {
    final res = await AppHttpClient.instance.post(
      _url,
      headers: {
        "Authorization": "Token $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"doctor_id": doctorId, "scan_id": scanId}),
    );

    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}

    return {"success": false, "detail": res.body};
  }
}
