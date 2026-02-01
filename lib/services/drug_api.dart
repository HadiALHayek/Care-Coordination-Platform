import 'dart:convert';

import 'package:http/http.dart' as http;

import '../base.dart';

class DdiApi {
  static Uri _catalogUri() =>
      Uri.parse('${ApiConfig.baseUrl}/api/ddi/catalog/');

  static Uri _interactionsUri() =>
      Uri.parse('${ApiConfig.baseUrl}/api/ddi/interactions/');

  static Map<String, String> _headers(String token) => {
    'Authorization': 'Token $token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static dynamic _tryJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  static Future<Map<String, dynamic>> fetchCatalog({
    required String token,
  }) async {
    try {
      final res = await http.get(_catalogUri(), headers: _headers(token));
      if (res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false, 'error': _tryJson(res.body)};
    } catch (e) {
      return {'success': false, 'error': 'Exception: $e'};
    }
  }

  static Future<Map<String, dynamic>> checkInteractions({
    required String token,
    required List<String> oncoDrugs,
    required List<String> otherChronic,
    required List<String> otherNonChronic,

    /// If null, the backend will not apply a minimum severity filter.
    String? minSeverity,
    bool translateAr = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'onco_drugs': oncoDrugs,
        'other_drugs_chronic_selected': otherChronic,
        'other_drugs_nonchronic_selected': otherNonChronic,
        'translate_ar': translateAr,
      };

      // Only include min_severity if caller explicitly sets it.
      if (minSeverity != null && minSeverity.isNotEmpty) {
        body['min_severity'] = minSeverity;
      }

      final res = await http.post(
        _interactionsUri(),
        headers: _headers(token),
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(res.body)};
      }
      return {'success': false, 'error': _tryJson(res.body)};
    } catch (e) {
      return {'success': false, 'error': 'Exception: $e'};
    }
  }
}
