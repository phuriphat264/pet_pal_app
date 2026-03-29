// lib/screens/notification_page.dart
import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _bgCard = Color(0xFFEDE2D5);
  static const Color _mutedBrown = Color(0xFF9E7A60);

  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'มะม่วงกำลังนอนหลับ',
      'body': 'น้องหมาเข้านอนเวลา 22:03 น.',
      'time': '2 นาทีที่แล้ว',
      'icon': '😴',
      'color': const Color(0xFF9B7EC8),
      'read': false,
      'type': 'activity',
    },
    {
      'title': 'ตรวจจับการเคลื่อนไหว',
      'body': 'มีการเคลื่อนไหวในห้องนอนเวลา 21:45 น.',
      'time': '18 นาทีที่แล้ว',
      'icon': '🚨',
      'color': const Color(0xFFE57373),
      'read': false,
      'type': 'alert',
    },
    {
      'title': 'การจองได้รับการยืนยัน',
      'body': 'Paw Paradise Resort · 15-17 เม.ย. 68',
      'time': '1 ชั่วโมงที่แล้ว',
      'icon': '🏡',
      'color': const Color(0xFF7CB9A8),
      'read': true,
      'type': 'booking',
    },
    {
      'title': 'จับคู่สำเร็จ!',
      'body': 'บัตเตอร์ กับ มะม่วงถูกใจกัน รีบติดต่อเลย!',
      'time': '3 ชั่วโมงที่แล้ว',
      'icon': '❤️',
      'color': const Color(0xFFE8936A),
      'read': true,
      'type': 'match',
    },
    {
      'title': 'ใกล้ถึงเวลาให้อาหาร',
      'body': 'มะม่วงควรกินข้าวมื้อเย็นแล้ว เวลา 18:00 น.',
      'time': '5 ชั่วโมงที่แล้ว',
      'icon': '🍖',
      'color': const Color(0xFFD4956A),
      'read': true,
      'type': 'reminder',
    },
    {
      'title': 'นัดหมอเตือนความจำ',
      'body': 'มะม่วงมีนัดตรวจสุขภาพ 15 เม.ย. 68 เวลา 10:00 น.',
      'time': 'เมื่อวาน',
      'icon': '🏥',
      'color': const Color(0xFFFFD54F),
      'read': true,
      'type': 'vet',
    },
    {
      'title': 'วัคซีนครบแล้ว',
      'body': 'มะม่วงได้รับวัคซีนครบตามกำหนดแล้ว',
      'time': '2 วันที่แล้ว',
      'icon': '💉',
      'color': const Color(0xFF81C784),
      'read': true,
      'type': 'health',
    },
  ];

  String _filter = 'ทั้งหมด';
  final _filters = ['ทั้งหมด', 'ยังไม่อ่าน', 'แจ้งเตือน', 'จอง'];

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'ยังไม่อ่าน') return _notifications.where((n) => n['read'] == false).toList();
    if (_filter == 'แจ้งเตือน') return _notifications.where((n) => n['type'] == 'alert' || n['type'] == 'activity').toList();
    if (_filter == 'จอง') return _notifications.where((n) => n['type'] == 'booking').toList();
    return _notifications;
  }

  int get _unread => _notifications.where((n) => n['read'] == false).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('การแจ้งเตือน',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _darkBrown)),
              if (_unread > 0)
                Text('ยังไม่อ่าน $_unread รายการ',
                    style: const TextStyle(fontSize: 12, color: _mutedBrown)),
            ],
          ),
          const Spacer(),
          if (_unread > 0)
            GestureDetector(
              onTap: () => setState(() {
                for (var n in _notifications) { n['read'] = true; }
              }),
              child: const Text('อ่านทั้งหมด',
                  style: TextStyle(fontSize: 12, color: _brown, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final selected = _filters[i] == _filter;
          return GestureDetector(
            onTap: () => setState(() => _filter = _filters[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _brown : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? _brown : const Color(0xFFD9C5B2), width: 0.5),
              ),
              child: Text(_filters[i],
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : _mutedBrown,
                  )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList() {
    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('🔔', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('ไม่มีการแจ้งเตือน', style: TextStyle(fontSize: 16, color: _mutedBrown)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildNotifCard(items[i]),
    );
  }

  Widget _buildNotifCard(Map<String, dynamic> n) {
    final unread = n['read'] == false;
    return GestureDetector(
      onTap: () => setState(() => n['read'] = true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unread ? Colors.white : _bgCard.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unread ? (n['color'] as Color).withOpacity(0.4) : const Color(0xFFD9C5B2),
            width: unread ? 1 : 0.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: (n['color'] as Color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(n['icon'] as String, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(n['title'] as String,
                            style: TextStyle(
                              fontSize: 13, fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                              color: _darkBrown,
                            )),
                      ),
                      if (unread)
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(color: n['color'] as Color, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(n['body'] as String,
                      style: const TextStyle(fontSize: 12, color: _mutedBrown, height: 1.4)),
                  const SizedBox(height: 4),
                  Text(n['time'] as String,
                      style: const TextStyle(fontSize: 11, color: _mutedBrown)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}