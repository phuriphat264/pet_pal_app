import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../data/hotel_data.dart';
import 'match_result_page.dart';
import 'hotel_detail_page.dart';

class MatchingPage extends StatefulWidget {
  const MatchingPage({super.key});

  @override
  State<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage> {
  final TextEditingController _aiController = TextEditingController();
  bool _isAiLoading = false;
  final Set<String> _selected = {};

  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _mutedBrown = Color(0xFF9E7A60);
  static const Color _accent = Color(0xFFE8936A);

  final List<Map<String, dynamic>> _traits = [
    {'key': 'playful', 'label': 'ขี้เล่น', 'icon': Icons.toys_rounded},
    {'key': 'water', 'label': 'ชอบน้ำ', 'icon': Icons.waves_rounded},
    {'key': 'calm', 'label': 'รักสงบ', 'icon': Icons.self_improvement_rounded},
    {'key': 'lazy', 'label': 'สายขี้เกียจ', 'icon': Icons.bed_rounded},
    {'key': 'active', 'label': 'พลังเยอะ', 'icon': Icons.bolt_rounded},
    {'key': 'social', 'label': 'เข้าสังคมเก่ง', 'icon': Icons.groups_rounded},
    {'key': 'nature', 'label': 'รักธรรมชาติ', 'icon': Icons.forest_rounded},
    {'key': 'care', 'label': 'ต้องการคนดูแล', 'icon': Icons.favorite_rounded},
    {'key': 'friendly', 'label': 'เป็นมิตร', 'icon': Icons.sentiment_very_satisfied_rounded},
  ];

  final List<Map<String, dynamic>> _hotels = allHotels;

  List<Map<String, dynamic>> get _filteredHotels {
    final list = _hotels.toList();
    list.sort((a, b) {
      final dA = double.tryParse(a['distance'].toString().replaceAll(' กม.', '')) ?? 99.0;
      final dB = double.tryParse(b['distance'].toString().replaceAll(' กม.', '')) ?? 99.0;
      return dA.compareTo(dB);
    });
    return list;
  }

  Future<void> _analyzeWithAI() async {
    final text = _aiController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเล่านิสัยของน้องๆ ก่อนนะคะ 🐶🐱'), backgroundColor: _brown),
      );
      return;
    }

    setState(() => _isAiLoading = true);
    FocusScope.of(context).unfocus();

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ ไม่พบ API Key! กรุณาใส่ API Key ในไฟล์ .env'), backgroundColor: Colors.red),
        );
        setState(() => _isAiLoading = false);
        return;
      }

      final hotelContext = _hotels.asMap().entries.map((entry) {
        final i = entry.key + 1;
        final h = entry.value;
        final tags = (h['tags'] as List<dynamic>).join(', ');
        final desc = (h['description'] as String? ?? '');
        final shortDesc = desc.length > 150 ? desc.substring(0, 150) : desc;
        return 'โรงแรม $i: "${h['name']}"\n  ประเภท: ${h['type']}\n  จุดเด่น: $tags\n  รายละเอียด: $shortDesc';
      }).join('\n\n');

      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      final prompt = '''
คุณคือ AI ผู้เชี่ยวชาญจับคู่สัตว์เลี้ยงกับโรงแรมสัตว์เลี้ยง

--- ข้อมูลโรงแรมที่มีให้เลือก ---
$hotelContext

--- สิ่งที่เจ้าของเล่ามาเกี่ยวกับสัตว์เลี้ยง ---
"$text"

--- หน้าที่ของคุณ ---
1. วิเคราะห์ว่าสัตว์เลี้ยงตัวนี้ต้องการอะไรจากโรงแรม
2. เลือกเฉพาะโรงแรมที่ตอบโจทย์จริงๆ
3. อธิบายเหตุผลสั้นๆ เป็นภาษาไทยเข้าใจง่าย

ตอบเป็น JSON เท่านั้น:
{
  "summary": "สรุปนิสัยสัตว์เลี้ยงใน 1 ประโยค",
  "matches": [
    { "hotelName": "ชื่อโรงแรม", "reason": "เหตุผลว่าทำไมเหมาะ" }
  ]
}
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final rawResult = response.text?.trim() ?? '';
      
      final jsonStr = rawResult
          .replaceAll(RegExp(r'```json\s*'), '')
          .replaceAll(RegExp(r'```\s*'), '')
          .trim();

      final parsed = _parseJsonResult(jsonStr);
      final summary = parsed['summary'] as String? ?? '';
      final matchList = parsed['matches'] as List<dynamic>? ?? [];

      if (matchList.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบโรงแรมที่เหมาะสม')));
        return;
      }

      final matchedHotels = <Map<String, dynamic>>[];
      final matchReasons = <String, String>{};

      for (final m in matchList) {
        final name = (m as Map)['hotelName'] ?? '';
        try {
          final hotel = _hotels.firstWhere(
            (h) => (h['name'] as String).contains(name) || name.contains(h['name'] as String),
          );
          matchedHotels.add(hotel);
          matchReasons[hotel['name'] as String] = m['reason'] ?? '';
        } catch (_) {}
      }

      matchedHotels.sort((a, b) {
        final dA = double.tryParse(a['distance'].toString().replaceAll(' กม.', '')) ?? 99.0;
        final dB = double.tryParse(b['distance'].toString().replaceAll(' กม.', '')) ?? 99.0;
        return dA.compareTo(dB);
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MatchResultPage(
              inputText: text,
              aiSummary: summary,
              matchedHotels: matchedHotels,
              matchReasons: matchReasons,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  Map<String, dynamic> _parseJsonResult(String json) {
    try {
      final start = json.indexOf('{');
      final end = json.lastIndexOf('}');
      if (start == -1 || end == -1) return {};
      final cleaned = json.substring(start, end + 1);

      final result = <String, dynamic>{};
      final summaryRx = RegExp(r'"summary"\s* : \s*"((?:[^"\\]|\\.)*)"', caseSensitive: false);
      final sm = summaryRx.firstMatch(cleaned);
      if (sm != null) result['summary'] = sm.group(1)?.replaceAll(r'\"', '"') ?? '';

      final matches = <Map<String, String>>[];
      final matchBlocks = RegExp(r'\{[^{}]*\}').allMatches(cleaned.substring(cleaned.indexOf('[')));
      for (final m in matchBlocks) {
        final block = m.group(0)!;
        final nRx = RegExp(r'"hotelName"\s*:\s*"((?:[^"\\]|\\.)*)"');
        final rRx = RegExp(r'"reason"\s*:\s*"((?:[^"\\]|\\.)*)"');
        final nM = nRx.firstMatch(block);
        final rM = rRx.firstMatch(block);
        if (nM != null) {
          matches.add({
            'hotelName': nM.group(1)?.replaceAll(r'\"', '"') ?? '',
            'reason': rM?.group(1)?.replaceAll(r'\"', '"') ?? '',
          });
        }
      }
      result['matches'] = matches;
      return result;
    } catch (_) { return {}; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildTraitSection()),
          SliverPadding(
            padding: const EdgeInsets.only(top: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _buildHotelCard(_filteredHotels[i], i),
                childCount: _filteredHotels.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
      decoration: const BoxDecoration(
        color: _brown,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'AI Smart Match',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'เล่านิสัยสัตว์เลี้ยงของคุณให้ AI ช่วยหาโรงแรมที่ใช่ที่สุด',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _aiController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 15, color: _darkBrown),
                  decoration: const InputDecoration(
                    hintText: 'เช่น "น้องขี้อายแต่ชอบพื้นที่เงียบๆ" หรือ "น้องพลังเยอะ ชอบวิ่งเล่นสนามหญ้า"',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isAiLoading ? null : _analyzeWithAI,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brown,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isAiLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome, size: 18),
                              SizedBox(width: 8),
                              Text('วิเคราะห์และค้นหา', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraitSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ค้นหาตามจุดเด่น',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _darkBrown),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 45,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _traits.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) {
                final t = _traits[i];
                final isSelected = _selected.contains(t['key']);
                return FilterChip(
                  selected: isSelected,
                  onSelected: (val) => setState(() => val ? _selected.add(t['key']!.toString()) : _selected.remove(t['key']!)),
                  label: Text(t['label']!.toString()),
                  avatar: Icon(t['icon']! as IconData, size: 16, color: isSelected ? Colors.white : _brown),
                  selectedColor: _accent,
                  checkmarkColor: Colors.white,
                  showCheckmark: false,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : _brown, fontWeight: FontWeight.w600),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? _accent : _brown.withValues(alpha: 0.2))),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelCard(Map<String, dynamic> h, int index) {
    final aiTags = h['aiTags'] as List<dynamic>? ?? [];
    final petTypes = List<String>.from(h['petTypes'] as List? ?? []);
    
    final matchedKeys = aiTags.where((t) => _selected.contains(t.toString())).toList();
    final matchCount = matchedKeys.length;
    final matchRatio = _selected.isEmpty ? 0.0 : matchCount / _selected.length;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HotelDetailPage(hotel: h))),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: (h['color'] as Color?)?.withValues(alpha: 0.1) ?? _brown.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: h['images'] != null && (h['images'] as List).isNotEmpty
                        ? Image.asset((h['images'] as List).first as String, fit: BoxFit.cover)
                        : Center(child: Icon(h['icon'] as IconData? ?? Icons.hotel, size: 60, color: _brown)),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: _brown),
                        const SizedBox(width: 4),
                        Text(
                          h['distance']?.toString() ?? '',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _brown),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selected.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: matchRatio.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          h['name']?.toString() ?? '',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _darkBrown),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            '${h['rating'] ?? 0.0}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _darkBrown),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    h['type']?.toString() ?? '',
                    style: const TextStyle(fontSize: 13, color: _mutedBrown, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ...petTypes.map((e) {
                        Color color;
                        if (e == '🐶') {
                          color = Colors.orange.shade700;
                        } else if (e == '🐱') {
                          color = Colors.blue.shade700;
                        } else {
                          color = _mutedBrown;
                        }
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color.withValues(alpha: 0.2)),
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 16)),
                        );
                      }),
                      const Spacer(),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '฿${h['price'] ?? 0}',
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _brown),
                          ),
                          const Text('ต่อคืน', style: TextStyle(fontSize: 11, color: _mutedBrown, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HotelDetailPage(hotel: h))),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brown,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('จองเลย', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
