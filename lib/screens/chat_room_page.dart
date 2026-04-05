import 'package:flutter/material.dart';
import 'hotel_list_page.dart';

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({super.key});
  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFFFF9F1);
  static const Color _mutedBrown = Color(0xFF9E7A60);

  bool _hasActiveBooking = false; // สถานะเบื้องต้น: ยังไม่จอง
  final TextEditingController _ctrl = TextEditingController();
  final List<Map<String, dynamic>> _msgs = [
    {'text': 'สวัสดีค่ะ พี่เลี้ยงแอนจาก Paw Paradise นะคะ 🐶', 'isMe': false, 'time': '10:00'},
    {'text': 'ตอนนี้น้องมะม่วงทานข้าวเช้าหมดเกลี้ยงเลยค่ะ เก่งมากๆ มีวิดีโอดูในหน้ากล้องได้เลยนะคะ', 'isMe': false, 'time': '10:01'},
    {'text': 'ขอบคุณครับน้องดื้อรึเปล่าครับ?', 'isMe': true, 'time': '10:15'},
    {'text': 'ไม่เลยค่ะ เล่นฟุตบอลสนุกมากเพิ่งอาบน้ำเสร็จค่ะ 💦', 'isMe': false, 'time': '10:20'},
  ];

  void _send() {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() {
      _msgs.add({'text': _ctrl.text.trim(), 'isMe': true, 'time': '15:45'});
      _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasActiveBooking) return _buildEmptyState();

    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, right: 12, top: 10, bottom: 10),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFD4956A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.holiday_village_rounded, color: Colors.white, size: 24),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Paw Paradise Resort', style: TextStyle(color: _brown, fontSize: 17, fontWeight: FontWeight.w700)),
            SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.circle, color: Color(0xFF4CAF50), size: 10),
                SizedBox(width: 6),
                Text('กำลังออนไลน์ (พี่เลี้ยงแอน)', style: TextStyle(color: _mutedBrown, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_rounded, color: _brown, size: 26),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กำลังสลับไปหน้าจอโทรศัพท์...'))),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: _brown, size: 28),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กำลังเปิดกล้องวิดีโอคอล...'))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              itemCount: _msgs.length,
              itemBuilder: (context, i) {
                final m = _msgs[i];
                final isMe = m['isMe'] as bool;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: isMe ? _brown : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMe ? 20 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 20),
                          ),
                          boxShadow: [BoxShadow(color: _brown.withValues(alpha:0.08), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: Text(
                          m['text'] as String,
                          style: TextStyle(color: isMe ? Colors.white : _darkBrown, fontSize: 15, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(m['time'] as String, style: const TextStyle(fontSize: 11, color: _mutedBrown, fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: _brown.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, -4))],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate_rounded, color: _mutedBrown, size: 28),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ข้อความหาพี่เลี้ยง...',
                        hintStyle: const TextStyle(color: _mutedBrown, fontSize: 14),
                        filled: true,
                        fillColor: _bgCream,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: _brown,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: _bgCream,
      body: SafeArea(
        child: Center(
          child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(color: const Color(0xFFE2D0BC).withValues(alpha:0.3), shape: BoxShape.circle),
                child: const Icon(Icons.chat_bubble_outline_rounded, size: 50, color: _brown),
              ),
              const SizedBox(height: 24),
              const Text('ยังไม่มีการสนทนา', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _darkBrown)),
              const SizedBox(height: 12),
              const Text('คุณสามารถแชทพูดคุยกับพี่เลี้ยงเพื่ออัปเดตสถานะของน้องๆ ได้ตลอดเวลา เมื่อทำการจองและเข้าพัก', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: _mutedBrown, height: 1.5)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HotelListPage()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('จองห้องพักเลย', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => setState(() => _hasActiveBooking = true),
                child: const Text('ดูตัวอย่างหน้าแชท (Demo)', style: TextStyle(color: _mutedBrown)),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
