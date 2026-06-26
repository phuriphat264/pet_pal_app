import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

String get _platformDefaultHost =>
    Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';

String get _defaultBaseUrl => 'http://$_platformDefaultHost:8001';

String get matchApiBaseUrl {
  if (!dotenv.isInitialized) return _defaultBaseUrl;
  final configured = dotenv.env['API_BASE_URL'];
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
  final String? jobId;

  const MatchApiResult({
    required this.summary,
    required this.matches,
    required this.isFallback,
    this.fallbackNotice,
    this.jobId,
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
      jobId: json['job_id']?.toString(),
    );
  }
}

Future<MatchApiResult> fetchMatch(String text, {http.Client? client}) async {
  final httpClient = client ?? http.Client();
  try {
    final response = await httpClient
        .post(
          Uri.parse('$matchApiBaseUrl/api/match'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw http.ClientException('Unexpected status: ${response.statusCode}');
    }
    return MatchApiResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } finally {
    if (client == null) httpClient.close();
  }
}

/// Polls the job status endpoint every 2s until ready/fallback or timeout.
/// Returns enriched result if ready, null if fallback/error.
Future<MatchApiResult?> pollMatchResult(
  String jobId, {
  Duration pollInterval = const Duration(seconds: 2),
  Duration timeout = const Duration(seconds: 20),
  void Function(String status)? onStatus,
}) async {
  final deadline = DateTime.now().add(timeout);
  final client = http.Client();
  try {
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(pollInterval);
      try {
        final response = await client
            .get(Uri.parse('$matchApiBaseUrl/api/match/status/$jobId'))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 404) return null;
        if (response.statusCode != 200) continue;

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final status = body['status']?.toString();
        onStatus?.call(status ?? '');

        if (status == 'ready' && body['result'] != null) {
          return MatchApiResult.fromJson(body['result'] as Map<String, dynamic>);
        }
        if (status == 'fallback') return null;
      } catch (_) {
        continue;
      }
    }
    return null;
  } finally {
    client.close();
  }
}
