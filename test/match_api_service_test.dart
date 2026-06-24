// Unit tests for the AI Smart Match backend HTTP client. Uses MockClient so
// no real network/backend is required.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_pal_app/services/match_api_service.dart';

void main() {
  group('fetchMatch', () {
    test('parses a successful AI response', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/match');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['text'], 'น้องแมวขี้อาย');

        return http.Response(
          jsonEncode({
            'summary': 'น้องเป็นแมวรักสงบ',
            'matches': [
              {'hotelName': 'Sky Cat Hotel', 'reason': 'ห้องเงียบสงบ'},
            ],
            'isFallback': false,
            'fallbackNotice': null,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await fetchMatch('น้องแมวขี้อาย', client: client);

      expect(result.summary, 'น้องเป็นแมวรักสงบ');
      expect(result.isFallback, isFalse);
      expect(result.fallbackNotice, isNull);
      expect(result.matches, hasLength(1));
      expect(result.matches.first.hotelName, 'Sky Cat Hotel');
      expect(result.matches.first.reason, 'ห้องเงียบสงบ');
    });

    test('parses a fallback AI response', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'summary': 'สรุปจากฐานข้อมูลพื้นฐาน',
            'matches': <Map<String, String>>[],
            'isFallback': true,
            'fallbackNotice': '⚠️ ยังไม่ได้ตั้งค่า AI (API Key)',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await fetchMatch('สวัสดีครับ', client: client);

      expect(result.isFallback, isTrue);
      expect(result.fallbackNotice, '⚠️ ยังไม่ได้ตั้งค่า AI (API Key)');
      expect(result.matches, isEmpty);
    });

    test('throws when the backend returns a non-200 status', () async {
      final client = MockClient((request) async => http.Response('error', 500));

      expect(() => fetchMatch('ข้อความ', client: client), throwsA(isA<Exception>()));
    });

    test('throws when the backend is unreachable', () async {
      final client = MockClient((request) async => throw const SocketExceptionStub());

      expect(() => fetchMatch('ข้อความ', client: client), throwsA(isA<Exception>()));
    });
  });
}

/// Minimal stand-in for SocketException to avoid importing dart:io in tests.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();

  @override
  String toString() => 'SocketExceptionStub: connection refused';
}
