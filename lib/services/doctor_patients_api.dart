import 'dart:convert';

import '../base.dart';
import '../core/constants/http_client.dart';

class DoctorPatientsApi {
  static final Uri _patientsUrl = Uri.parse(
    "${ApiConfig.baseUrl}/api/doctor/patients/",
  );

  static Future<Map<String, dynamic>> getDoctorPatients(String token) async {
    final response = await AppHttpClient.instance.get(
      _patientsUrl,
      headers: {
        "Authorization": "Token $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      return {"success": false, "error": response.body};
    }
  }
}
