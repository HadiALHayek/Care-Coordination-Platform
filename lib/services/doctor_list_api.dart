import 'dart:convert';

import '../base.dart';
import '../core/constants/http_client.dart';
import '../core/constants/prefs_cache.dart';

class DoctorListApi {
  static final Uri _baseListUrl = Uri.parse(
    "${ApiConfig.baseUrl}/api/doctor/list/",
  );

  static Future<List> getDoctors({String? governorate}) async {
    final prefs = await PrefsCache.getInstance();
    final token = prefs.getString("token");

    final Uri url =
        (governorate == null || governorate.isEmpty)
            ? _baseListUrl
            : _baseListUrl.replace(
              queryParameters: {"governorate": governorate},
            );

    final res = await AppHttpClient.instance.get(
      url,
      headers: {"Authorization": "Token $token"},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }
}
