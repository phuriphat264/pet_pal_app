// Pure-Dart unit tests for the local "semantic search" fallback matcher used
// by AI Smart Match (matching_page.dart) when the Gemini LLM is unavailable.
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_pal_app/data/hotel_data.dart';
import 'package:pet_pal_app/utils/semantic_match.dart';

void main() {
  group('localSemanticMatch', () {
    test('introvert/quiet-seeking pet matches calm/care hotels', () {
      final result = localSemanticMatch(
        'น้องค่อนข้างเป็นอินโทรเวิร์ท ขี้อาย ไม่ชอบที่พลุกพล่าน อยากได้ห้องส่วนตัวเงียบๆ',
        allHotels,
      );

      final matchedNames = result.matchedHotels.map((h) => h['name']).toList();

      // Every matched hotel should advertise a 'calm' or 'care' environment.
      for (final hotel in result.matchedHotels) {
        final tags = (hotel['aiTags'] as List<dynamic>).map((e) => e.toString()).toSet();
        expect(tags.contains('calm') || tags.contains('care'), isTrue,
            reason: '${hotel['name']} should have calm/care in aiTags');
      }

      expect(matchedNames, isNotEmpty);
      expect(result.summary, isNotEmpty);
      expect(result.matchReasons.keys, containsAll(matchedNames.cast<String>()));
    });

    test('active/outdoor-seeking pet matches active/nature hotels', () {
      final result = localSemanticMatch(
        'น้องหมาพลังเยอะมาก ชอบวิ่งเล่นกลางแจ้ง รักสนามหญ้าและธรรมชาติ ชอบเข้าสังคมกับเพื่อนๆ',
        allHotels,
      );

      final matchedNames = result.matchedHotels.map((h) => h['name']).toList();

      expect(matchedNames, contains('PigPao Pet Shop'));
      for (final hotel in result.matchedHotels) {
        final tags = (hotel['aiTags'] as List<dynamic>).map((e) => e.toString()).toSet();
        expect(
          tags.intersection({'active', 'nature', 'social', 'friendly', 'playful'}).isNotEmpty,
          isTrue,
          reason: '${hotel['name']} should overlap with the requested traits',
        );
      }
    });

    test('unrecognized input falls back to top-rated/nearest hotels', () {
      final result = localSemanticMatch('สวัสดีครับ', allHotels);

      expect(result.matchedHotels.length, 3);
      expect(result.summary, contains('แนะนำโรงแรมที่รีวิวดี'));

      // Should be sorted by rating (desc) then distance (asc).
      final ratings = result.matchedHotels.map((h) => h['rating'] as num).toList();
      for (var i = 0; i < ratings.length - 1; i++) {
        expect(ratings[i] >= ratings[i + 1], isTrue);
      }
    });
  });
}
