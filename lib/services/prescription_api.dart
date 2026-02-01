import 'dart:convert';

import '../base.dart';
import '../core/constants/http_client.dart';

class PrescriptionApi {
  static const String baseUrl = "${ApiConfig.baseUrl}";

  static Future<Map<String, dynamic>> createPrescription({
    required String token,
    required int patientId,
    String notes = "",
    required List<Map<String, dynamic>>
    items, // [{drug_name, dosage, frequency, duration}]
  }) async {
    final url = Uri.parse("$baseUrl /api/prescriptions/create/");

    final body = {"patient_id": patientId, "notes": notes, "items": items};

    final res = await AppHttpClient.instance.post(
      url,
      headers: {
        "Authorization": "Token $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (_) {
      decoded = res.body;
    }

    if (res.statusCode == 201) {
      return {"success": true, "data": decoded};
    }
    return {"success": false, "error": decoded};
  }
}
