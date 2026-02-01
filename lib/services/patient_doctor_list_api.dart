import 'dart:convert';

import 'package:http/http.dart' as http;

import '../base.dart';

class DoctorApi {
  static const baseUrl = "${ApiConfig.baseUrl}/api";

  static Future<Map<String, dynamic>> linkDoctor(
    int doctorId,
    String token,
  ) async {
    final url = Uri.parse("$baseUrl/doctor/link/");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Token $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"doctor_id": doctorId}),
    );

    if (response.statusCode == 201 || response.statusCode == 400) {
      return {"success": true};
    } else {
      return {"success": false, "error": response.body};
    }
  }

  static Future<Map<String, dynamic>> getDoctorList(String token) async {
    final url = Uri.parse("$baseUrl/doctor/list/");
    final response = await http.get(
      url,
      headers: {"Authorization": "Token $token"},
    );

    if (response.statusCode == 200) {
      return {"success": true, "data": jsonDecode(response.body)};
    } else {
      return {"success": false, "error": response.body};
    }
  }

  static Future<Map<String, dynamic>> sendReportToDoctor(
    int doctorId,
    int scanId,
    String token,
  ) async {
    final url = Uri.parse("$baseUrl/send-report/");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Token $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"doctor_id": doctorId, "scan_id": scanId}),
    );

    if (response.statusCode == 200) {
      return {"success": true};
    } else {
      return {"success": false, "error": response.body};
    }
  }
}
