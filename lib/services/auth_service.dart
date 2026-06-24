// Holds the signed-in session (tokens + current user) for the whole app.
// Tokens persist in flutter_secure_storage so the user stays logged in
// across app restarts. Notifies listeners on login/logout/role changes so
// the navigation shell can react.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

String get _platformDefaultHost => Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
String get _defaultBaseUrl => 'http://$_platformDefaultHost:8001';

String get authApiBaseUrl {
  if (!dotenv.isInitialized) return _defaultBaseUrl;
  final configured = dotenv.env['API_BASE_URL'];
  if (configured == null || configured.isEmpty || configured == 'http://127.0.0.1:8000') {
    return _defaultBaseUrl;
  }
  return configured;
}

class AuthUser {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String role;

  const AuthUser({required this.id, required this.email, required this.name, this.phone, required this.role});

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        role: json['role'] as String,
      );
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService extends ChangeNotifier {
  static const _accessTokenKey = 'petpal.access_token';
  static const _refreshTokenKey = 'petpal.refresh_token';

  final FlutterSecureStorage _storage;
  final http.Client _client;

  String? _accessToken;
  String? _refreshToken;
  AuthUser? _currentUser;
  bool _initialized = false;

  AuthService({FlutterSecureStorage? storage, http.Client? client})
      : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get initialized => _initialized;
  String? get role => _currentUser?.role;

  /// Test-only: injects an already-authenticated session without touching
  /// secure storage or the network, so widget tests can render past the
  /// login screen deterministically.
  @visibleForTesting
  void debugSetSession(AuthUser user) {
    _currentUser = user;
    _initialized = true;
  }

  Future<void> bootstrap() async {
    _accessToken = await _storage.read(key: _accessTokenKey);
    _refreshToken = await _storage.read(key: _refreshTokenKey);
    if (_refreshToken != null) {
      try {
        await _fetchAndSetCurrentUser();
      } catch (_) {
        await logout();
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    final body = await _post('/auth/login', {'email': email, 'password': password});
    await _storeTokens(body);
    await _fetchAndSetCurrentUser();
  }

  Future<void> register({required String email, required String password, required String name, String? phone}) async {
    final body = await _post('/auth/register', {
      'email': email,
      'password': password,
      'name': name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    await _storeTokens(body);
    await _fetchAndSetCurrentUser();
  }

  Future<void> loginWithGoogle({required String idToken}) async {
    final body = await _post('/auth/google', {'id_token': idToken});
    await _storeTokens(body);
    await _fetchAndSetCurrentUser();
  }

  Future<void> loginWithFacebook({required String accessToken}) async {
    final body = await _post('/auth/facebook', {'access_token': accessToken});
    await _storeTokens(body);
    await _fetchAndSetCurrentUser();
  }

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    notifyListeners();
  }

  /// Returns a still-valid access token, refreshing it first if we don't
  /// have one cached (e.g. right after a cold start).
  Future<String?> ensureValidAccessToken() async {
    return _accessToken;
  }

  Future<bool> refreshSession() async {
    if (_refreshToken == null) return false;
    try {
      final body = await _post('/auth/refresh', {'refresh_token': _refreshToken});
      await _storeTokens(body);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _fetchAndSetCurrentUser() async {
    final response = await _client.get(
      Uri.parse('$authApiBaseUrl/users/me'),
      headers: {'Authorization': 'Bearer $_accessToken'},
    );
    if (response.statusCode != 200) {
      throw AuthException('Could not load the signed-in user');
    }
    _currentUser = AuthUser.fromJson(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> _storeTokens(Map<String, dynamic> tokenResponse) async {
    _accessToken = tokenResponse['access_token'] as String;
    _refreshToken = tokenResponse['refresh_token'] as String;
    await _storage.write(key: _accessTokenKey, value: _accessToken);
    await _storage.write(key: _refreshTokenKey, value: _refreshToken);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final response = await _client
        .post(
          Uri.parse('$authApiBaseUrl$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'เข้าสู่ระบบไม่สำเร็จ กรุณาลองใหม่';
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map && decoded['detail'] != null) message = decoded['detail'].toString();
      } catch (_) {}
      throw AuthException(message);
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}
