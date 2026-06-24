// HTTP client for the PetPal AI Smart Match backend (FastAPI, see /backend).
// Performs the semantic-matching request and throws on any failure
// (connection error, timeout, bad response) so callers can apply a
// client-side local fallback (see matching_page.dart).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// Android emulator routes 10.0.2.2 → host machine; other platforms use loopback.
String get _platformDefaultHost =>
    Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';

String get _defaultBaseUrl => 'http://$_platformDefaultHost:8001';

String get matchApiBaseUrl {
  if (!dotenv.isInitialized) return _defaultBaseUrl;
  final configured = dotenv.env['API_BASE_URL'];
  // Only override if explicitly set to something other than the placeholder.
  if (configured == null || configured.isEmpty || configured == 'http://127.0.0.1:8000') {
    return _defaultBaseUrl;
  }
  return configured;
}

class MatchApiItem {
  final String hotelName;
  final String reason;

  const MatchApiItem({required this.hotelName, required this.reason});

  factory MatchApiItem.fromJson(Map<String, dynamic> json) {
    return MatchApiItem(
      hotelName: json['hotelName']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
    );
  }
}

class MatchApiResult {
  final String summary;
  final List<MatchApiItem> matches;
  final bool isFallback;
  final String? fallbackNotice;

  const MatchApiResult({
    required this.summary,
    required this.matches,
    required this.isFallback,
    this.fallbackNotice,
  });

  factory MatchApiResult.fromJson(Map<String, dynamic> json) {
    final matchList = (json['matches'] as List<dynamic>? ?? [])
        .map((m) => MatchApiItem.fromJson(m as Map<String, dynamic>))
        .toList();
    return MatchApiResult(
      summary: json['summary']?.toString() ?? '',
      matches: matchList,
      isFallback: json['isFallback'] == true,
      fallbackNotice: json['fallbackNotice']?.toString(),
    );
  }
}

/// Calls `POST /api/match` on the AI Smart Match backend.
/// Throws on connection failure, timeout, or a non-200/unparseable response.
Future<MatchApiResult> fetchMatch(String text, {http.Client? client}) async {
  final httpClient = client ?? http.Client();
  try {
    final response = await httpClient
        .post(
          Uri.parse('$matchApiBaseUrl/api/match'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}),
        )
        .timeout(const Duration(seconds: 50));

    if (response.statusCode != 200) {
      throw http.ClientException('Unexpected status code: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return MatchApiResult.fromJson(decoded);
  } finally {
    if (client == null) httpClient.close();
  }
}
