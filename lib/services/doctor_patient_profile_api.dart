import 'dart:convert';

import 'package:http/http.dart' as http;

import '../base.dart';

class DoctorPatientProfileApi {
  static const String baseUrl = "${ApiConfig.baseUrl}/api";

  // GET all doctor patients
  static Future<Map<String, dynamic>> getDoctorPatients(String token) async {
    final url = Uri.parse("$baseUrl/doctor/patients/");

    final response = await http.get(
      url,
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

  // GET specific patient profile (extract from full list)
  static Future<Map<String, dynamic>> getPatientProfile(
    int patientId,
    String token,
  ) async {
    final all = await getDoctorPatients(token);

    if (!all["success"]) return all;

    final list = all["data"] as List;

    final patient = list.firstWhere(
      (p) => p["patient_id"] == patientId,
      orElse: () => null,
    );

    if (patient == null) {
      return {"success": false, "error": "Patient not found"};
    }

    return {"success": true, "data": patient};
  }
}
