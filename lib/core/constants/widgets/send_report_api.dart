import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../base.dart';

class SendReportApi {
  static const String url = "${ApiConfig.baseUrl}/api/send-report/";

  static Future<Map<String, dynamic>> sendReport({
    required int doctorId,
    required int scanId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final request = http.MultipartRequest("POST", Uri.parse(url));
    request.headers["Authorization"] = "Token $token";

    request.fields["doctor_id"] = doctorId.toString();
    request.fields["scan_id"] = scanId.toString();

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final json = jsonDecode(body);

    if (response.statusCode == 201) {
      return {"success": true, "data": json};
    }

    return {"success": false, "error": json};
  }
}
