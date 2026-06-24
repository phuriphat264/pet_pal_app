// Shared HTTP client for the PetPal backend: resolves the base URL (same
// convention as the existing AI Smart Match service), attaches the bearer
// token, and transparently refreshes it once on a 401 before retrying.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

String get _platformDefaultHost => Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';

String get _defaultBaseUrl => 'http://$_platformDefaultHost:8001';

String get apiBaseUrl {
  if (!dotenv.isInitialized) return _defaultBaseUrl;
  final configured = dotenv.env['API_BASE_URL'];
  if (configured == null || configured.isEmpty || configured == 'http://127.0.0.1:8000') {
    return _defaultBaseUrl;
  }
  return configured;
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final AuthService authService;
  final http.Client _client;

  ApiClient({required this.authService, http.Client? client}) : _client = client ?? http.Client();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final clean = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$apiBaseUrl$clean').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await authService.ensureValidAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    bool auth = true,
    bool retried = false,
  }) async {
    final headers = await _headers(auth: auth);
    final uri = _uri(path, query);
    http.Response response;

    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _client.post(uri, headers: headers, body: body == null ? null : jsonEncode(body));
        break;
      case 'PATCH':
        response = await _client.patch(uri, headers: headers, body: body == null ? null : jsonEncode(body));
        break;
      case 'DELETE':
        response = await _client.delete(uri, headers: headers);
        break;
      default:
        throw ArgumentError('Unsupported method $method');
    }

    if (response.statusCode == 401 && auth && !retried) {
      final refreshed = await authService.refreshSession();
      if (refreshed) {
        return _send(method, path, body: body, query: query, auth: auth, retried: true);
      }
      await authService.logout();
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }

    String message = response.body;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['detail'] != null) message = decoded['detail'].toString();
    } catch (_) {
      // keep raw body as the message
    }
    throw ApiException(response.statusCode, message);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) =>
      _send('GET', path, query: query, auth: auth);

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);

  Future<dynamic> patch(String path, {Map<String, dynamic>? body, bool auth = true}) =>
      _send('PATCH', path, body: body, auth: auth);

  Future<dynamic> delete(String path, {bool auth = true}) => _send('DELETE', path, auth: auth);
}
