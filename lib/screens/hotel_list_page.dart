// lib/screens/hotel_list_page.dart
import 'package:flutter/material.dart';
import 'hotel_detail_page.dart';

class HotelListPage extends StatefulWidget {
  const HotelListPage({super.key});

  @override
  State<HotelListPage> createState() => _HotelListPageState();
}

class _HotelListPageState extends State<HotelListPage> {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _bgCard = Color(0xFFEDE2D5);
  static const Color _mutedBrown = Color(0xFF9E7A60);

  String _selectedFilter = 'ทั้งหมด';
  final _filters = ['ทั้งหมด', 'ใกล้ที่สุด', 'ราคาถูก', 'คะแนนสูง'];

  final List<Map<String, dynamic>> _hotels = [
    {
      'name': 'โรงพยาบาลสัตว์แผ่นดินทอง',
      'location': 'จันทบุรี',
      'distance': '1.2 กม.',
      'rating': 4.8,
      'reviews': 120,
      'price': 320,
      'icon': Icons.local_hospital_rounded,
      'color': const Color(0xFF7CB9A8),
      'tags': ['หมอตรวจก่อนเข้าพัก', 'มีแอร์', 'รับฝากรายชั่วโมง'],
      'available': true,
      'description': 'นับเวลาฝาก 24 ช.ม. จากเวลา Check-in เท่ากับ 1 วัน หากเกินเวลาคิดค่าใช้จ่ายเพิ่มเติมชั่วโมงละ 50 บาท (เกิน 6 ช.ม. คิดเป็น 1 วัน) สามารถมาฝากและรับกลับภายในเวลาทำการ 08.30-20.30 น. เท่านั้น\n**แนะนำให้มาฝากเวลา 10.30-20.00 น. เพื่อให้คุณหมอตรวจสุขภาพก่อนเข้าพักค่ะ**\n\n-ฝากไม่เต็มวัน ไม่เกิน 6 ชม. คิดครึ่งราคา หากเกิน 6 ชม. คิดราคาเต็มค่ะ',
      'rooms': [
        {'type': 'Dog < 5 กก.', 'price': 0, 'desc': 'เริ่มต้นที่ 320 บาท/คืน'},
        {'type': 'Dog 5.1-10 กก.', 'price': 60, 'desc': '380 บาท/คืน'},
        {'type': 'Dog 10.1-15 กก.', 'price': 110, 'desc': '430 บาท/คืน'},
        {'type': 'Dog 15.1-20 กก.', 'price': 140, 'desc': '460 บาท/คืน'},
        {'type': 'Dog 20.1-25 กก.', 'price': 160, 'desc': '480 บาท/คืน'},
        {'type': 'Dog 25.1-30 กก.', 'price': 180, 'desc': '500 บาท/คืน'},
        {'type': 'Dog 30.1-35 กก.', 'price': 220, 'desc': '540 บาท/คืน'},
        {'type': 'Dog 35.1-40 กก.', 'price': 250, 'desc': '570 บาท/คืน'},
        {'type': 'Dog > 40 กก.', 'price': 270, 'desc': '590 บาท/คืน'},
        {'type': 'Cat ห้อง VIP', 'price': 80, 'desc': '400 บาท อยู่ได้สูงสุด 2 ตัว (ตัวที่ 2 +50)'},
        {'type': 'Cat ห้อง VVIP', 'price': 380, 'desc': '700 บาท อยู่ได้สูงสุด 5 ตัว (ราคาเหมา)'},
      ],
      'images': List.generate(12, (i) => 'assets/images/hotel1_${i + 1}.jpg'),
    },
    {
      'name': 'Sky Cat Hotel',
      'location': 'ตัวเมืองจันทบุรี',
      'distance': '2.5 กม.',
      'rating': 4.9,
      'reviews': 85,
      'price': 300,
      'icon': Icons.pets_rounded,
      'color': const Color(0xFFD4956A),
      'tags': ['แอร์ 24 ชม.', 'กล้องวงจรปิด', 'PlayZone'],
      'available': true,
      'description': 'โรงแรมแมวเมืองจันทบุรี Sky Cat hotel\nพร้อมสิ่งอำนวยความสะดวกน้องแมวดังนี้\n- ฟรี! กล้องวงจรปิดส่วนตัวทุกห้อง\n- ฟรี! น้ำดื่มสะอาดเกรดเดียวกับคนดื่ม\n- เปิดแอร์ 24 ชม. และเครื่องฟอกอากาศ ลดสารก่อภูมิแพ้ ห้องสะอาด ทำความสะอาดฆ่าเชื้อทุกวัน\n- พาน้องออกมาเล่นพื้นที่ส่วนกลาง PlayZone\n- อัปเดตรูปภาพและวิดีโอทุกวัน\n- ปลอดภัยไร้กังวล เจ้าของดูเองทุกขั้นตอน',
      'rooms': [
        {'type': 'ห้องไซส์ M', 'price': 0, 'desc': '300 บาท/คืน สำหรับ 1 ตัว'},
        {'type': 'ห้องคู่มีช่องแมวลอด', 'price': 200, 'desc': '500 บาท/คืน'},
      ],
      'images': List.generate(3, (i) => 'assets/images/hotel2_${i + 1}.jpg'),
    },
    {
      'name': 'PigPao Pet Shop',
      'location': 'จันทบุรี',
      'distance': '3.1 กม.',
      'rating': 4.7,
      'reviews': 210,
      'price': 350,
      'icon': Icons.store_rounded,
      'color': const Color(0xFF9B7EC8),
      'tags': ['ไม่ขังกรง', 'สนามหญ้า', 'บริการรถรับส่ง'],
      'available': true,
      'description': 'สถานที่บริการรับฝากเลี้ยงน้องหมาจังหวัดจันทบุรี แบบไม่ขังกรง ที่นอนนุ่มสบาย นอนห้องแอร์ มีกล้องวงจรปิดดู 24 ชม. มีบริการพาเดินเล่นรอบสวน มีบริการรถรับส่ง เปิดรับฝากตลอด 24 ชม.',
      'rooms': [
        {'type': 'น้องหมาเล็ก', 'price': 0, 'desc': '350/คืน (ไม่รวมอาหาร)'},
        {'type': 'น้องหมาใหญ่', 'price': 100, 'desc': '450/คืน (ไม่รวมอาหาร)'},
      ],
      'images': List.generate(7, (i) => 'assets/images/hotel3_${i + 1}.jpg'),
    },
    {
      'name': 'Dapperdou',
      'location': 'จันทบุรี',
      'distance': '1.8 กม.',
      'rating': 4.9,
      'reviews': 150,
      'price': 450,
      'icon': Icons.coffee_rounded,
      'color': const Color(0xFF6A9E7E),
      'tags': ['คาเฟ่โดนัท', 'ระบบกรอง Ro', 'ทรายพรีเมี่ยม'],
      'available': true,
      'description': 'คาเฟ่โดนัท & โรงแรมแมวพรีเมียมและกรูมมิ่งแมวจันทบุรี\nเปิดแอร์ 24 ชั่วโมง กล้องวงจรปิดเข้าดูเด็กๆได้ตลอดเวลา น้ำดื่มผ่านระบบกรอง Ro รวมทรายแมวพรีเมี่ยม อัพเดทเป็นภาพและวิดิโอ\nรับฝากรายชั่วโมง (ลูกค้าเตรียมอาหารน้องมาอย่างเดียวค่ะ)\n\nหมายเหตุ: จองก่อน ได้เลือกห้องก่อนค่ะ',
      'rooms': [
        {'type': 'Single Room', 'price': 0, 'desc': '450 บาท/วัน (แมว 1-2 ตัว)'},
        {'type': 'Family Room', 'price': 200, 'desc': '650 บาท/วัน (แมว 2-3 ตัว)'},
      ],
      'images': List.generate(13, (i) => 'assets/images/hotel4_${i + 1}.jpg'),
    },
  ];

  List<Map<String, dynamic>> get _filteredHotels {
    var list = [..._hotels];
    if (_selectedFilter == 'ใกล้ที่สุด') {
      list.sort((a, b) => double.parse(a['distance'].replaceAll(' กม.', ''))
          .compareTo(double.parse(b['distance'].replaceAll(' กม.', ''))));
    } else if (_selectedFilter == 'ราคาถูก') {
      list.sort((a, b) => (a['price'] as int).compareTo(b['price'] as int));
    } else if (_selectedFilter == 'คะแนนสูง') {
      list.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            _buildFilters(),
            Expanded(child: _buildHotelList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(color: Color(0xFFE8D8C8), shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left, color: _brown, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('โรงแรมสัตว์เลี้ยง',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _darkBrown)),
              Text('4 แห่งใกล้คุณ', style: TextStyle(fontSize: 14, color: _mutedBrown)),
            ],
          ),
          const Spacer(),
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(color: Color(0xFFE8D8C8), shape: BoxShape.circle),
            child: const Icon(Icons.tune, color: _brown, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD9C5B2), width: 0.5),
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'ค้นหาโรงแรม...',
            hintStyle: TextStyle(color: _mutedBrown, fontSize: 16),
            prefixIcon: Icon(Icons.search, color: _mutedBrown, size: 22),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final selected = _filters[i] == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = _filters[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? _brown : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? _brown : const Color(0xFFD9C5B2), width: 0.5),
              ),
              child: Text(_filters[i],
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : _mutedBrown,
                  )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHotelList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: _filteredHotels.length,
      itemBuilder: (_, i) => _buildHotelCard(_filteredHotels[i]),
    );
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => HotelDetailPage(hotel: hotel))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // รูปโรงแรม
            Builder(
              builder: (context) {
                final List<String> images = (hotel['images'] as List?)?.cast<String>() ?? 
                    (hotel['image'] != null ? [hotel['image'] as String] : []);
                final String? coverImage = images.isNotEmpty ? images.first : null;

                return Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: (hotel['color'] as Color).withValues(alpha:0.2),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (coverImage == null)
                        Center(child: Icon(hotel['icon'] as IconData, size: 80, color: _brown))
                      else
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.asset(
                            coverImage,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(hotel['icon'] as IconData, size: 80, color: _brown),
                            ),
                          ),
                        ),
                  if (!(hotel['available'] as bool))
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha:0.4),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: const Center(
                        child: Text('เต็มแล้ว',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
                          const SizedBox(width: 4),
                          Text('${hotel['rating']}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _darkBrown)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(hotel['name'],
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
                      ),
                      Text('฿${hotel['price']}/คืน',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _brown)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: _mutedBrown),
                      const SizedBox(width: 4),
                      Text(hotel['location'],
                          style: const TextStyle(fontSize: 14, color: _mutedBrown)),
                      const SizedBox(width: 6),
                      Text('· ${hotel['distance']}',
                          style: const TextStyle(fontSize: 14, color: _mutedBrown)),
                      const Spacer(),
                      Text('(${hotel['reviews']} รีวิว)',
                          style: const TextStyle(fontSize: 13, color: _mutedBrown)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: (hotel['tags'] as List<String>).map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(8)),
                      child: Text(t, style: const TextStyle(fontSize: 13, color: _brown)),
                    )).toList(),
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