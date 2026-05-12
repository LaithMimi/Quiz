import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:quiz/config/api_config.dart';
import 'package:quiz/services/unsafe_http_client.dart'
    if (dart.library.io) 'package:quiz/services/unsafe_http_client_native.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? createUnsafeClient();

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
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    _ensureSuccess(response, 'POST ${ApiConfig.signUpUrl}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse(ApiConfig.loginUrl),
      headers: _jsonHeaders,
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    _ensureSuccess(response, 'POST ${ApiConfig.loginUrl}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTasks() async {
    final response = await _client.get(
      Uri.parse(ApiConfig.tasksUrl),
      headers: _jsonHeaders,
    );
    _ensureSuccess(response, 'GET ${ApiConfig.tasksUrl}');
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> createTask(String title) async {
    final response = await _client.post(
      Uri.parse(ApiConfig.tasksUrl),
      headers: _jsonHeaders,
      body: jsonEncode({'title': title, 'status': 'todo'}),
    );
    _ensureSuccess(response, 'POST ${ApiConfig.tasksUrl}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTask(String id, String status) async {
    final response = await _client.put(
      Uri.parse(ApiConfig.taskUrl(id)),
      headers: _jsonHeaders,
      body: jsonEncode({'status': status}),
    );
    _ensureSuccess(response, 'PUT ${ApiConfig.taskUrl(id)}');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> deleteTask(String id) async {
    final response = await _client.delete(
      Uri.parse(ApiConfig.taskUrl(id)),
      headers: _jsonHeaders,
    );
    _ensureSuccess(response, 'DELETE ${ApiConfig.taskUrl(id)}');
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