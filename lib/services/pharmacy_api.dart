import 'dart:convert';

import '../base.dart';
import '../core/constants/http_client.dart';

class PharmacyApi {
  // ApiConfig.baseUrl should be like: http://10.0.2.2:8000  (NO /api)
  static const String apiRoot = "${ApiConfig.baseUrl}/api";

  static Future<List<Map<String, dynamic>>> listPharmacies({
    required String token,
  }) async {
    final url = Uri.parse("$apiRoot/pharmacies/");

    final res = await AppHttpClient.instance.get(
      url,
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

  static Future<Map<String, dynamic>> setPreferredPharmacy({
    required String token,
    required int pharmacyId,
  }) async {
    // ✅ Use the backend route that exists
    final url = Uri.parse("$apiRoot/pharmacies/preferred/");

    final res = await AppHttpClient.instance.put(
      url,
      headers: {
        "Authorization": "Token $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"pharmacy_id": pharmacyId}),
    );

    dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (_) {
      decoded = res.body;
    }

    if (res.statusCode == 200) {
      return {"success": true, "data": decoded};
    }
    return {"success": false, "error": decoded};
  }
}
