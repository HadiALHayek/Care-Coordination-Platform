import 'dart:convert';

import 'package:http/http.dart' as http;

import '../base.dart';

const String baseUrl = "${ApiConfig.baseUrl}/api/register/";

Future<Map<String, dynamic>> registerPatient({
  required String fullName,
  required String email,
  required String password,
  required String gender,
  required String dateOfBirth,
  required String phoneNumber,
  required String emergencyContact,
  required String location, // <-- renamed from address
  required double weightKg,
}) async {
  try {
    final body = {
      "full_name": fullName,
      "email": email,
      "password": password,
      "gender": gender,
      "date_of_birth": dateOfBirth,
      "phone_number": phoneNumber,
      "emergency_contact_number": emergencyContact,
      "location": location, // send governorate
      "weight_kg": weightKg,
    };

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final decoded = _safeJson(response.body);

    if (response.statusCode == 201) {
      return {"success": true, "data": decoded};
    }

    return {"success": false, "error": decoded};
  } catch (e) {
    return {"success": false, "error": "Exception: $e"};
  }
}

dynamic _safeJson(String body) {
  try {
    return jsonDecode(body);
  } catch (_) {
    return body;
  }
}
