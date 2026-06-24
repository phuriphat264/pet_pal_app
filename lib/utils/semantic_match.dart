// lib/utils/semantic_match.dart
import 'package:flutter/material.dart';

const List<Map<String, dynamic>> petTraits = [
  {'key': 'playful', 'label': 'ขี้เล่น', 'icon': Icons.toys_rounded},
  {'key': 'water', 'label': 'ชอบน้ำ', 'icon': Icons.waves_rounded},
  {'key': 'calm', 'label': 'รักสงบ', 'icon': Icons.self_improvement_rounded},
  {'key': 'lazy', 'label': 'สายขี้เกียจ', 'icon': Icons.bed_rounded},
  {'key': 'active', 'label': 'พลังเยอะ', 'icon': Icons.bolt_rounded},
  {'key': 'social', 'label': 'เข้าสังคมเก่ง', 'icon': Icons.groups_rounded},
  {'key': 'nature', 'label': 'รักธรรมชาติ', 'icon': Icons.forest_rounded},
  {'key': 'care', 'label': 'ต้องการคนดูแล', 'icon': Icons.favorite_rounded},
  {'key': 'friendly', 'label': 'เป็นมิตร', 'icon': Icons.sentiment_very_satisfied_rounded},
  {'key': 'private', 'label': 'รักสันโดษ', 'icon': Icons.home_rounded},
];

const Map<String, List<String>> traitKeywords = {
  'calm': ['อินโทรเวิร์ท', 'introvert', 'ขี้อาย', 'ขี้กลัว', 'เงียบ', 'สงบ', 'ไม่ชอบเสียงดัง', 'ไม่ชอบที่พลุกพล่าน', 'ส่วนตัว', 'รักสงบ', 'สันโดษ', 'ชอบอยู่คนเดียว', 'ไม่ชอบถูกรบกวน'],
  'playful': ['ขี้เล่น', 'ซน', 'ชอบเล่น', 'ของเล่น'],
  'water': ['ชอบน้ำ', 'ว่ายน้ำ', 'เล่นน้ำ', 'อาบน้ำ'],
  'lazy': ['ขี้เกียจ', 'ชอบนอน', 'เฉื่อย', 'นิ่งๆ'],
  'active': ['พลังเยอะ', 'พลังล้นเหลือ', 'ชอบวิ่ง', 'ซุกซน', 'energetic'],
  'social': ['เข้าสังคม', 'ชอบเพื่อน', 'เล่นกับสัตว์อื่น', 'เจอคนใหม่'],
  'nature': ['ธรรมชาติ', 'สนามหญ้า', 'สวน', 'กลางแจ้ง', 'outdoor'],
  'care': ['ป่วย', 'แพ้ง่าย', 'สุขภาพไม่ดี', 'ดูแลใกล้ชิด', 'สูงอายุ', 'ทานยา'],
  'friendly': ['เป็นมิตร', 'น่ารัก', 'อารมณ์ดี', 'ไม่ดุ'],
  'private': ['สันโดษ', 'รักสันโดษ', 'ชอบอยู่คนเดียว', 'ความเป็นส่วนตัว', 'ต้องการความเป็นส่วนตัว', 'ห้องส่วนตัว', 'ไม่ชอบถูกรบกวน', 'ไม่ชอบคนแปลกหน้า', 'ไม่อยากให้รบกวน'],
};

const String _privateReasonSuffix =
    ' — มีห้องส่วนตัว เงียบสงบ ไม่ถูกรบกวน '
    'ไม่จำเป็นต้องขอให้พนักงานอัปเดตบ่อยๆ เพราะอาจรบกวนน้องได้';

class SemanticMatchResult {
  final String summary;
  final List<Map<String, dynamic>> matchedHotels;
  final Map<String, String> matchReasons;

  const SemanticMatchResult({
    required this.summary,
    required this.matchedHotels,
    required this.matchReasons,
  });
}

SemanticMatchResult localSemanticMatch(String text, List<Map<String, dynamic>> hotels) {
  final lower = text.toLowerCase();
  final matchedTraitKeys = <String>{};
  for (final entry in traitKeywords.entries) {
    for (final kw in entry.value) {
      if (lower.contains(kw.toLowerCase())) {
        matchedTraitKeys.add(entry.key);
        break;
      }
    }
  }

  double distanceOf(Map<String, dynamic> h) =>
      double.tryParse(h['distance'].toString().replaceAll(' กม.', '')) ?? 99.0;

  List<Map<String, dynamic>> candidates;
  String summary;

  if (matchedTraitKeys.isEmpty) {
    candidates = hotels.toList()
      ..sort((a, b) {
        final ratingCompare = (b['rating'] as num).compareTo(a['rating'] as num);
        if (ratingCompare != 0) return ratingCompare;
        return distanceOf(a).compareTo(distanceOf(b));
      });
    candidates = candidates.take(3).toList();
    summary = 'ระบบยังไม่สามารถวิเคราะห์นิสัยจากข้อความนี้ได้ จึงแนะนำโรงแรมที่รีวิวดีและอยู่ใกล้คุณที่สุดให้ก่อน';
  } else {
    final traitLabels = petTraits
        .where((t) => matchedTraitKeys.contains(t['key']))
        .map((t) => t['label'].toString())
        .toList();

    final scored = hotels.map((h) {
      final tags = (h['aiTags'] as List<dynamic>? ?? []).map((e) => e.toString()).toSet();
      final overlap = tags.intersection(matchedTraitKeys);
      return {'hotel': h, 'score': overlap.length};
    }).where((e) => (e['score'] as int) > 0).toList();

    scored.sort((a, b) {
      final scoreCompare = (b['score'] as int).compareTo(a['score'] as int);
      if (scoreCompare != 0) return scoreCompare;
      return distanceOf(a['hotel'] as Map<String, dynamic>)
          .compareTo(distanceOf(b['hotel'] as Map<String, dynamic>));
    });

    if (scored.isEmpty) {
      candidates = hotels.take(3).toList();
      summary = 'น้องของคุณดูจะเป็นสัตว์เลี้ยงที่ ${traitLabels.join(', ')} แต่ระบบยังไม่พบโรงแรมที่ตรงกับนิสัยนี้โดยตรง จึงแนะนำโรงแรมใกล้เคียงให้เลือกดูก่อน';
    } else {
      candidates = scored.take(3).map((e) => e['hotel'] as Map<String, dynamic>).toList();
      summary = 'น้องของคุณดูจะเป็นสัตว์เลี้ยงที่ ${traitLabels.join(', ')} ระบบจึงเลือกที่พักที่มีจุดเด่นตรงกับนิสัยเหล่านี้ให้ก่อน';
    }
  }

  final reasons = <String, String>{};
  for (final h in candidates) {
    final hName = h['name']?.toString() ?? '';
    final tags = (h['aiTags'] as List<dynamic>? ?? []).map((e) => e.toString()).toSet();
    final overlap = tags.intersection(matchedTraitKeys);
    final overlapLabels =
        petTraits.where((t) => overlap.contains(t['key'])).map((t) => t['label'].toString()).toList();

    if (overlapLabels.isNotEmpty) {
      var reason = 'ที่พักนี้มีจุดเด่นที่เหมาะกับน้องที่ ${overlapLabels.join(', ')}';
      if (overlap.contains('private')) reason += _privateReasonSuffix;
      reasons[hName] = reason;
    } else {
      reasons[hName] = 'โรงแรมแนะนำใกล้คุณที่มีรีวิวดี';
    }
  }

  return SemanticMatchResult(summary: summary, matchedHotels: candidates, matchReasons: reasons);
}
