import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:quiz/config/api_config.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Map<String, dynamic>> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse(ApiConfig.signUpUrl),
      headers: _jsonHeaders,
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    _ensureSuccess(response, 'POST ${ApiConfig.signUpUrl}');
    return json.decode(response.body) as Map<String, dynamic>;
  }

  void close() => _client.close();

  static void _ensureSuccess(http.Response response, String label) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        '$label failed with status ${response.statusCode}: ${response.body}',
      );
    }
  }
}
