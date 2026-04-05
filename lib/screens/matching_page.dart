// lib/screens/matching_page.dart
import 'package:flutter/material.dart';

class MatchingPage extends StatefulWidget {
  const MatchingPage({super.key});

  @override
  State<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage> {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _mutedBrown = Color(0xFF9E7A60);

  // ── นิสัยทั้งหมด ────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _traits = [
    {'label': 'ขี้เล่น',        'icon': Icons.sports_tennis_rounded, 'key': 'playful'},
    {'label': 'ชอบน้ำ',         'icon': Icons.pool_rounded, 'key': 'water'},
    {'label': 'เงียบๆ',         'icon': Icons.bedtime_rounded, 'key': 'calm'},
    {'label': 'ชอบนอน',         'icon': Icons.weekend_rounded, 'key': 'lazy'},
    {'label': 'กระฉับกระเฉง',   'icon': Icons.bolt_rounded, 'key': 'active'},
    {'label': 'เป็นมิตร',       'icon': Icons.handshake_rounded, 'key': 'social'},
    {'label': 'ชอบธรรมชาติ',    'icon': Icons.forest_rounded, 'key': 'nature'},
    {'label': 'ต้องการดูแลพิเศษ','icon': Icons.medical_services_rounded, 'key': 'care'},
    {'label': 'ชอบเพื่อนใหม่',  'icon': Icons.pets_rounded, 'key': 'friendly'},
    {'label': 'ขี้อาย',         'icon': Icons.visibility_off_rounded, 'key': 'shy'},
  ];

  final Set<String> _selected = {};
  bool _searched = false;

  // ── โรงแรมทั้งหมด + traits ที่รองรับ ────────────────────────────────────
  final List<Map<String, dynamic>> _hotels = [
    {
      'name': 'Paw Paradise Hotel',
      'type': 'โรงแรมสุนัข & แมว',
      'rating': '4.9',
      'price': '650 ฿/คืน',
      'icon': Icons.domain_rounded,
      'color': const Color(0xFFD4956A),
      'distance': '1.2 กม.',
      'highlight': 'สระว่ายน้ำสัตว์เลี้ยง + สนามวิ่ง',
      'tags': ['playful', 'water', 'active', 'friendly'],
      'petTypes': ['🐶'],
    },
    {
      'name': 'Whisker Inn',
      'type': 'โรงแรมแมวโดยเฉพาะ',
      'rating': '4.8',
      'price': '450 ฿/คืน',
      'icon': Icons.apartment_rounded,
      'color': const Color(0xFF9B7EC8),
      'distance': '0.8 กม.',
      'highlight': 'ห้องส่วนตัว Cat Tree + หน้าต่างดูนก',
      'tags': ['calm', 'lazy', 'shy'],
      'petTypes': ['🐱'],
    },
    {
      'name': 'Happy Paws Resort',
      'type': 'รีสอร์ทสัตว์เลี้ยง',
      'rating': '4.7',
      'price': '800 ฿/คืน',
      'icon': Icons.beach_access_rounded,
      'color': const Color(0xFFE8936A),
      'distance': '2.0 กม.',
      'highlight': 'Dog Park + กิจกรรมกลุ่มรายวัน',
      'tags': ['active', 'playful', 'friendly', 'social'],
      'petTypes': ['🐶', '🐱'],
    },
    {
      'name': 'Serene Pet Lodge',
      'type': 'โรงแรมสัตว์เลี้ยงพรีเมียม',
      'rating': '5.0',
      'price': '1,200 ฿/คืน',
      'icon': Icons.stars_rounded,
      'color': const Color(0xFF6A9EB5),
      'distance': '3.1 กม.',
      'highlight': 'Grooming ครบครัน + ดูแลพิเศษ',
      'tags': ['calm', 'care', 'social'],
      'petTypes': ['🐶', '🐱'],
    },
    {
      'name': 'Green Meadow Pet Stay',
      'type': 'ที่พักสัตว์เลี้ยงกลางธรรมชาติ',
      'rating': '4.6',
      'price': '550 ฿/คืน',
      'icon': Icons.park_rounded,
      'color': const Color(0xFF7DB87D),
      'distance': '4.5 กม.',
      'highlight': 'สวนหย่อม + ทางเดินธรรมชาติ',
      'tags': ['nature', 'active', 'calm', 'friendly'],
      'petTypes': ['🐶'],
    },
    {
      'name': 'Cozy Paws Hostel',
      'type': 'โฮสเทลสัตว์เลี้ยงราคาดี',
      'rating': '4.5',
      'price': '350 ฿/คืน',
      'icon': Icons.cottage_rounded,
      'color': const Color(0xFFB8956A),
      'distance': '0.5 กม.',
      'highlight': 'บรรยากาศบ้านๆ อบอุ่น',
      'tags': ['calm', 'lazy', 'shy', 'care'],
      'petTypes': ['🐶', '🐱'],
    },
  ];

  List<Map<String, dynamic>> get _filteredHotels {
    if (_selected.isEmpty) return _hotels;
    return _hotels.where((h) {
      final tags = h['tags'] as List<String>;
      // คืนโรงแรมที่มี trait ตรงกันอย่างน้อย 1 อัน
      return _selected.any((s) => tags.contains(s));
    }).toList()
      ..sort((a, b) {
        // เรียงตาม match score (trait ตรงกันมากขึ้นอยู่บน)
        final aScore = (a['tags'] as List<String>)
            .where((t) => _selected.contains(t))
            .length;
        final bScore = (b['tags'] as List<String>)
            .where((t) => _selected.contains(t))
            .length;
        return bScore.compareTo(aScore);
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildTraitSection()),
            if (_searched) ...[
              SliverToBoxAdapter(child: _buildResultHeader()),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildHotelCard(_filteredHotels[i], i),
                  childCount: _filteredHotels.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('หาที่พักให้น้อง',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _darkBrown)),
          SizedBox(height: 4),
          Text('เลือกนิสัยของน้อง แล้วเราจะหาโรงแรมที่ใช่ใกล้คุณ',
              style: TextStyle(fontSize: 15, color: _mutedBrown)),
        ],
      ),
    );
  }

  // ── เลือกนิสัย (Netflix-style chips) ────────────────────────────────────
  Widget _buildTraitSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── AI Smart Match Section ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _brown.withValues(alpha:0.3), width: 1.5),
              boxShadow: [BoxShadow(color: _brown.withValues(alpha:0.1), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: _brown, size: 22),
                    SizedBox(width: 8),
                    Text('AI Smart Match', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  maxLines: 2,
                  style: const TextStyle(fontSize: 15, color: _darkBrown),
                  decoration: InputDecoration(
                    hintText: 'เช่น "น้องแก่แล้วชอบนอนเงียบๆ แต่อยากให้มีสนามฝนเล็บและพี่เลี้ยงดูแลใกล้ชิด..."',
                    hintStyle: const TextStyle(color: _mutedBrown, fontSize: 14),
                    filled: true,
                    fillColor: _bgCream,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('✨ AI กำลังวิเคราะห์หาโรงแรมที่ใช่ที่สุด... (โหมดทดสอบ)'),
                        backgroundColor: _brown,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkBrown,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('✨ ปล่อยให้ AI จัดการให้', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFFD9C9BC))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('หรือ ค้นหาด่วนด้วยแท็ก', style: TextStyle(color: _brown, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              Expanded(child: Divider(color: Color(0xFFD9C9BC))),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _traits.map((t) {
              final key = t['key'] as String;
              final selected = _selected.contains(key);
              return GestureDetector(
                onTap: () => setState(() {
                  selected ? _selected.remove(key) : _selected.add(key);
                  _searched = false; // reset ผลเมื่อเปลี่ยน trait
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? _brown : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: selected ? _brown : const Color(0xFFD9C9BC),
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                                color: _brown.withValues(alpha:0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t['icon'] as IconData, size: 20, color: selected ? Colors.white : _mutedBrown),
                      const SizedBox(width: 8),
                      Text(t['label'],
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: selected
                                  ? Colors.white
                                  : _mutedBrown)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // ── ปุ่มค้นหา ──────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _selected.isEmpty
                  ? null
                  : () => setState(() => _searched = true),
              icon: const Icon(Icons.search, size: 22),
              label: Text(
                _selected.isEmpty
                    ? 'เลือกนิสัยก่อนนะ'
                    : 'ค้นหาโรงแรมใกล้ฉัน (${_selected.length} นิสัย)',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brown,
                disabledBackgroundColor: const Color(0xFFD9C9BC),
                foregroundColor: Colors.white,
                disabledForegroundColor: _mutedBrown,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── หัวข้อผลลัพธ์ ────────────────────────────────────────────────────────
  Widget _buildResultHeader() {
    final count = _filteredHotels.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Text('พบ $count โรงแรมที่เหมาะกับน้อง',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _darkBrown)),
          const Spacer(),
          const Icon(Icons.location_on, size: 16, color: _mutedBrown),
          const SizedBox(width: 4),
          const Text('ใกล้คุณ',
              style: TextStyle(fontSize: 14, color: _mutedBrown)),
        ],
      ),
    );
  }

  // ── การ์ดโรงแรม ──────────────────────────────────────────────────────────
  Widget _buildHotelCard(Map<String, dynamic> h, int index) {
    final hotelTags = h['tags'] as List<String>;
    final matchCount =
        hotelTags.where((t) => _selected.contains(t)).length;
    final matchRatio = matchCount / _selected.length;
    final isTopMatch = index == 0 && matchCount > 1;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha:0.06),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ส่วนรูป ───────────────────────────────────────────────────
          Stack(
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: (h['color'] as Color).withValues(alpha:0.18),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Center(
                  child: Icon(h['icon'] as IconData, size: 80, color: _brown),
                ),
              ),
              // badge Top Match
              if (isTopMatch)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _brown,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text('ตรงที่สุด',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              // badge ระยะทาง
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          size: 11, color: _brown),
                      const SizedBox(width: 2),
                      Text(h['distance'],
                          style: const TextStyle(
                              fontSize: 11, color: _brown)),
                    ],
                  ),
                ),
              ),
              // match bar ด้านล่างรูป
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(0)),
                  child: LinearProgressIndicator(
                    value: matchRatio.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha:0.4),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_brown),
                  ),
                ),
              ),
            ],
          ),
          // ── ข้อมูล ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(h['name'],
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _darkBrown)),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 15, color: Color(0xFFFFB300)),
                        const SizedBox(width: 4),
                        Text(h['rating'],
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _darkBrown)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(h['type'],
                    style: const TextStyle(
                        fontSize: 14, color: _mutedBrown)),
                const SizedBox(height: 6),
                // match traits
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 15, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(h['highlight'],
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // petTypes + price + ปุ่มจอง
                Row(
                  children: [
                    ...(h['petTypes'] as List<String>).map(
                        (e) => Text(e,
                            style: const TextStyle(fontSize: 20))),
                    const SizedBox(width: 8),
                    Text('รับได้',
                        style: const TextStyle(
                            fontSize: 13, color: _mutedBrown)),
                    const Spacer(),
                    Text(h['price'],
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _brown)),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: _brown,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('จอง',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}