import 'package:flutter/material.dart';
import '../data/hotel_data.dart';
import 'hotel_list_page.dart';

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({super.key});
  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _mutedBrown = Color(0xFF9E7A60);

  @override
  Widget build(BuildContext context) {
    if (activeBookings.isEmpty) return _buildEmptyState();

    return Scaffold(
      backgroundColor: _bgCream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final booking = activeBookings[index];
                  final hotel = booking['hotel'] as Map<String, dynamic>;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: _brown.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 54, height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: (hotel['color'] as Color).withValues(alpha: 0.1),
                          image: (hotel['images'] as List?) != null && (hotel['images'] as List).isNotEmpty
                              ? DecorationImage(
                                  image: AssetImage((hotel['images'] as List).first as String),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (hotel['images'] as List?) == null || (hotel['images'] as List).isEmpty
                            ? Icon(hotel['icon'] as IconData, color: hotel['color'] as Color, size: 24)
                            : null,
                      ),
                      title: Text(hotel['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkBrown)),
                      subtitle: const Text('พี่เลี้ยง: สวัสดีครับ น้องสบายดี น้องกําลังกินข้าวอยู่ครับ', style: TextStyle(fontSize: 13, color: _mutedBrown), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('10:20', style: TextStyle(fontSize: 11, color: _mutedBrown)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: _brown, shape: BoxShape.circle),
                            child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailViewPage(hotel: hotel)));
                      },
                    ),
                  );
                },
                childCount: activeBookings.length,
              ),
            ),
          ),
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Chat',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'พูดคุยกับพี่เลี้ยงและสอบถามความเป็นอยู่ของน้องๆ',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: _bgCream,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(color: _brown.withValues(alpha:0.05), shape: BoxShape.circle),
                    child: const Icon(Icons.chat_bubble_outline_rounded, size: 50, color: _brown),
                  ),
                  const SizedBox(height: 24),
                  const Text('ยังไม่มีการสนทนา', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _darkBrown)),
                  const SizedBox(height: 12),
                  const Text('คุณสามารถสอบถาม หรือดูเด็กๆ ผ่านกล้องได้ตลอดเวลา เมื่อทําการจองห้องพักและชำระเงิน', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: _mutedBrown, height: 1.5)),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HotelListPage()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('จองห้องพักเลย', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatDetailViewPage extends StatefulWidget {
  final Map<String, dynamic> hotel;
  const ChatDetailViewPage({super.key, required this.hotel});

  @override
  State<ChatDetailViewPage> createState() => _ChatDetailViewPageState();
}

class _ChatDetailViewPageState extends State<ChatDetailViewPage> {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _mutedBrown = Color(0xFF9E7A60);

  final TextEditingController _ctrl = TextEditingController();
  final List<Map<String, dynamic>> _msgs = [
    {'text': 'สวัสดีครับ พี่เลี้ยงครับ', 'isMe': false, 'time': '10:00'},
    {'text': 'ตอนนี้น้องสบายดีมากครับ น้องกําลังเล่นกับเพื่อนอยู่ครับ', 'isMe': false, 'time': '10:01'},
    {'text': 'ขอบคุณครับ ฝากน้องด้วยนะครับ?', 'isMe': true, 'time': '10:15'},
    {'text': 'ไม่ต้องห่วงเลยครับ เราดูแลอย่างดีที่สุดแน่นอน 😍', 'isMe': false, 'time': '10:20'},
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
    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 40,
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _brown, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (widget.hotel['color'] as Color).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                image: (widget.hotel['images'] as List?) != null && (widget.hotel['images'] as List).isNotEmpty
                    ? DecorationImage(
                        image: AssetImage((widget.hotel['images'] as List).first as String),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (widget.hotel['images'] as List?) == null || (widget.hotel['images'] as List).isEmpty
                  ? Icon(widget.hotel['icon'] as IconData, color: widget.hotel['color'] as Color, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.hotel['name'] as String,
                      style: const TextStyle(color: _brown, fontSize: 15, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                  const Text('กําลังออนไลน์ (พี่เลี้ยง)', style: TextStyle(color: _mutedBrown, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: _brown, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: _brown, size: 24),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? _brown : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(m['text'] as String, style: TextStyle(color: isMe ? Colors.white : _darkBrown, fontSize: 15)),
                      ),
                      const SizedBox(height: 4),
                      Text(m['time'] as String, style: const TextStyle(fontSize: 10, color: _mutedBrown)),
                    ],
                  ),
                );
              },
            ),
          ),
          // Input bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ข้อความหาพี่เลี้ยง...',
                        filled: true,
                        fillColor: _bgCream,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.send_rounded, color: _brown), onPressed: _send),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
