import 'package:flutter/material.dart';
import '../data/hotel_data.dart';
import '../services/match_api_service.dart';
import '../utils/semantic_match.dart';
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
      final result = await fetchMatch(text);

      final matchedHotels = <Map<String, dynamic>>[];
      final matchReasons = <String, String>{};

      for (final m in result.matches) {
        try {
          final hotel = _hotels.firstWhere(
            (h) {
              final hName = h['name']?.toString() ?? '';
              return hName.contains(m.hotelName) || m.hotelName.contains(hName);
            },
          );
          final name = hotel['name']?.toString() ?? '';
          matchedHotels.add(hotel);
          matchReasons[name] = m.reason;
        } catch (_) {}
      }

      // The backend's hotel names didn't resolve to anything locally ->
      // fall back to the local semantic matcher instead of an empty result.
      if (matchedHotels.isEmpty) {
        _showFallbackResult(
          text,
          notice: '🤖 ไม่สามารถจับคู่ผลลัพธ์จากเซิร์ฟเวอร์ได้ ระบบจึงจับคู่จากนิสัยที่คุณอธิบายด้วยฐานข้อมูลพื้นฐานให้ก่อน',
        );
        return;
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
              aiSummary: result.summary,
              matchedHotels: matchedHotels,
              matchReasons: matchReasons,
              isFallback: result.isFallback,
              fallbackNotice: result.fallbackNotice,
            ),
          ),
        );
      }
    } catch (_) {
      // Backend unreachable, timed out, or returned an unexpected response ->
      // fall back to the local semantic matcher so the demo never gets stuck.
      _showFallbackResult(
        text,
        notice: '⚠️ ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ AI ได้ ระบบจึงจับคู่จากนิสัยที่คุณอธิบายด้วยฐานข้อมูลพื้นฐานให้ก่อน',
      );
    } finally {
      if (mounted) setState(() => _isAiLoading = false);
    }
  }

  void _showFallbackResult(String text, {required String notice}) {
    final fallback = localSemanticMatch(text, _hotels);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MatchResultPage(
            inputText: text,
            aiSummary: fallback.summary,
            matchedHotels: fallback.matchedHotels,
            matchReasons: fallback.matchReasons,
            isFallback: true,
            fallbackNotice: notice,
          ),
        ),
      );
    }
    if (mounted) setState(() => _isAiLoading = false);
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
              itemCount: petTraits.length,
              separatorBuilder: (_, i) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) {
                final t = petTraits[i];
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
