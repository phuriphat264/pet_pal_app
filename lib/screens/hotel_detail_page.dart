// lib/screens/hotel_detail_page.dart
import 'package:flutter/material.dart';

class HotelDetailPage extends StatefulWidget {
  final Map<String, dynamic> hotel;
  const HotelDetailPage({super.key, required this.hotel});

  @override
  State<HotelDetailPage> createState() => _HotelDetailPageState();
}

class _HotelDetailPageState extends State<HotelDetailPage> {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _bgCard = Color(0xFFEDE2D5);
  static const Color _mutedBrown = Color(0xFF9E7A60);

  DateTime? _checkIn;
  DateTime? _checkOut;
  String _selectedRoom = 'Standard';

  final _rooms = [
    {'type': 'Standard', 'price': 0, 'desc': 'ห้องมาตรฐาน AC พร้อมที่นอนนุ่ม'},
    {'type': 'Deluxe', 'price': 150, 'desc': 'ห้องกว้างพร้อม play area ส่วนตัว'},
    {'type': 'Suite', 'price': 350, 'desc': 'ห้อง Suite พร้อม Live Cam 24 ชม.'},
  ];

  int get _nights {
    if (_checkIn == null || _checkOut == null) return 1;
    return _checkOut!.difference(_checkIn!).inDays.clamp(1, 30);
  }

  int get _basePrice => widget.hotel['price'] as int;
  int get _roomExtra => (_rooms.firstWhere((r) => r['type'] == _selectedRoom)['price'] as int);
  int get _total => (_basePrice + _roomExtra) * _nights;

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
    return Scaffold(
      backgroundColor: _bgCream,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                _buildHero(hotel, context),
                _buildInfo(hotel),
                _buildRoomSelector(),
                _buildDatePicker(),
                _buildReviews(),
              ],
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBookingBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(Map<String, dynamic> hotel, BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 260,
          color: (hotel['color'] as Color).withOpacity(0.25),
          child: Center(child: Text(hotel['emoji'], style: const TextStyle(fontSize: 120))),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          child: GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
              child: const Icon(Icons.chevron_left, color: _brown, size: 20),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
            child: const Icon(Icons.favorite_border, color: _brown, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo(Map<String, dynamic> hotel) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hotel['name'],
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _darkBrown)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 13, color: _mutedBrown),
                        const SizedBox(width: 2),
                        Text(hotel['location'],
                            style: const TextStyle(fontSize: 13, color: _mutedBrown)),
                        Text(' · ${hotel['distance']}',
                            style: const TextStyle(fontSize: 13, color: _mutedBrown)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Color(0xFFFFC107)),
                      const SizedBox(width: 2),
                      Text('${hotel['rating']}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _darkBrown)),
                    ],
                  ),
                  Text('${hotel['reviews']} รีวิว',
                      style: const TextStyle(fontSize: 11, color: _mutedBrown)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8, runSpacing: 6,
            children: [
              ...(hotel['tags'] as List<String>).map((t) => _tag(t)),
              if (hotel['available'] as bool)
                _tag('✅ ว่างอยู่', green: true)
              else
                _tag('❌ เต็มแล้ว', red: true),
            ],
          ),
          const SizedBox(height: 16),
          const Text('เกี่ยวกับสถานที่',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _darkBrown)),
          const SizedBox(height: 8),
          const Text(
            'เราดูแลน้องของคุณเหมือนลูกตัวเอง มีทีมผู้เชี่ยวชาญดูแลตลอด 24 ชั่วโมง '
            'พร้อมระบบกล้องวงจรปิดให้คุณติดตามน้องได้ตลอดเวลา สิ่งอำนวยความสะดวกครบครัน '
            'อาหารสด น้ำสะอาด และพื้นที่พักผ่อนที่สะอาดสบาย',
            style: TextStyle(fontSize: 13, color: _mutedBrown, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, {bool green = false, bool red = false}) {
    Color bg = _bgCard;
    Color fg = _brown;
    if (green) { bg = const Color(0xFFE8F5E9); fg = const Color(0xFF2E7D32); }
    if (red) { bg = const Color(0xFFFFEBEE); fg = const Color(0xFFC62828); }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildRoomSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('เลือกประเภทห้อง',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _darkBrown)),
          const SizedBox(height: 10),
          ..._rooms.map((r) {
            final selected = r['type'] == _selectedRoom;
            return GestureDetector(
              onTap: () => setState(() => _selectedRoom = r['type'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? _brown.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? _brown : const Color(0xFFD9C5B2),
                    width: selected ? 1.5 : 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: selected ? _brown : _mutedBrown, width: 1.5),
                        color: selected ? _brown : Colors.transparent,
                      ),
                      child: selected
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r['type'] as String,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _darkBrown)),
                          Text(r['desc'] as String,
                              style: const TextStyle(fontSize: 11, color: _mutedBrown)),
                        ],
                      ),
                    ),
                    Text(
                      (r['price'] as int) == 0 ? 'รวมอยู่แล้ว' : '+฿${r['price']}/คืน',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: (r['price'] as int) == 0 ? _mutedBrown : _brown,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('เลือกวันที่',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _darkBrown)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _dateBox('เช็คอิน', _checkIn, () => _pickDate(true))),
              const SizedBox(width: 10),
              Expanded(child: _dateBox('เช็คเอาท์', _checkOut, () => _pickDate(false))),
            ],
          ),
          if (_checkIn != null && _checkOut != null) ...[
            const SizedBox(height: 8),
            Text('รวม $_nights คืน',
                style: const TextStyle(fontSize: 12, color: _mutedBrown)),
          ],
        ],
      ),
    );
  }

  Widget _dateBox(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD9C5B2), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: _mutedBrown)),
            const SizedBox(height: 4),
            Text(
              date == null ? 'เลือกวัน' : '${date.day}/${date.month}/${date.year}',
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: date == null ? _mutedBrown : _darkBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isCheckIn) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? now : ((_checkIn ?? now).add(const Duration(days: 1))),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _brown, onSurface: _darkBrown),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (_checkOut != null && _checkOut!.isBefore(picked)) _checkOut = null;
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  Widget _buildReviews() {
    final reviews = [
      {'name': 'คุณนภา', 'rating': 5, 'comment': 'น้องหมามีความสุขมาก ทีมงานใจดีมาก จะกลับมาอีกแน่นอน!'},
      {'name': 'คุณวิน', 'rating': 5, 'comment': 'ห้องสะอาด อาหารดี กล้องดูได้ตลอด สบายใจมาก'},
      {'name': 'คุณมิ้ง', 'rating': 4, 'comment': 'ดีมากค่ะ น้องแมวชอบ ราคาเหมาะสม'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('รีวิวจากผู้ใช้',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _darkBrown)),
          const SizedBox(height: 10),
          ...reviews.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD9C5B2), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFEDE2D5),
                      child: Text(
                        (r['name'] as String).characters.last,
                        style: const TextStyle(fontSize: 12, color: _brown, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(r['name'] as String,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _darkBrown)),
                    const Spacer(),
                    Row(
                      children: List.generate(r['rating'] as int, (_) =>
                          const Icon(Icons.star, size: 12, color: Color(0xFFFFC107))),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(r['comment'] as String,
                    style: const TextStyle(fontSize: 12, color: _mutedBrown, height: 1.5)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBookingBar() {
    final available = widget.hotel['available'] as bool;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('฿$_total',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _darkBrown)),
              Text('$_nights คืน · ${_selectedRoom}',
                  style: const TextStyle(fontSize: 11, color: _mutedBrown)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: available ? _onBook : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: available ? _brown : Colors.grey,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                available ? 'จองเลย' : 'เต็มแล้ว',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onBook() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF5EFE8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ยืนยันการจอง', style: TextStyle(color: _darkBrown, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.hotel['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.w600, color: _darkBrown)),
            const SizedBox(height: 4),
            Text('ห้อง $_selectedRoom · $_nights คืน',
                style: const TextStyle(color: _mutedBrown, fontSize: 13)),
            const SizedBox(height: 4),
            Text('ยอดรวม ฿$_total',
                style: const TextStyle(color: _brown, fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: _mutedBrown)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _brown,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 จองสำเร็จ! น้องจะถูกดูแลอย่างดี'),
                  backgroundColor: _brown,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}