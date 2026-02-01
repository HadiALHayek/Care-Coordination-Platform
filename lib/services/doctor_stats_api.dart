import 'dart:convert';

import '../base.dart';
import '../core/constants/http_client.dart';

class DoctorStatsApi {
  static final Uri _statsUrl = Uri.parse(
    "${ApiConfig.baseUrl}/api/doctor/stats/",
  );

  static Future<Map<String, dynamic>> getStats(String token) async {
    final res = await AppHttpClient.instance.get(
      _statsUrl,
      headers: {"Authorization": "Token $token"},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return {"success": false};
  }
}
