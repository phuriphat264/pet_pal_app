import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/booking_repository.dart';
import '../services/chat_repository.dart';
import '../services/realtime_service.dart';
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

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _bookedHotelsWithoutThread = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final chatRepo = context.read<ChatRepository>();
      await chatRepo.loadThreads();
      final bookings = await context.read<BookingRepository>().fetchMyBookings();
      final threadHotelIds = chatRepo.threads.map((t) => t['hotelId']).toSet();
      final seen = <String>{};
      final bookedWithoutThread = <Map<String, dynamic>>[];
      for (final b in bookings) {
        final hotelId = b['hotel_id'] as String;
        if (threadHotelIds.contains(hotelId) || seen.contains(hotelId)) continue;
        seen.add(hotelId);
        bookedWithoutThread.add({'hotelId': hotelId});
      }
      if (!mounted) return;
      setState(() {
        _bookedHotelsWithoutThread = bookedWithoutThread;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'โหลดแชทไม่สำเร็จ: $e';
        _loading = false;
      });
    }
  }

  Future<void> _startChat(String hotelId) async {
    try {
      final thread = await context.read<ChatRepository>().createOrGetThread(hotelId);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatDetailViewPage(threadId: thread['id'] as String, title: thread['hotelName'] as String)),
      );
      if (mounted) _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เริ่มแชทไม่สำเร็จ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final threads = context.watch<ChatRepository>().threads;

    if (_loading) {
      return const Scaffold(backgroundColor: _bgCream, body: Center(child: CircularProgressIndicator(color: _brown)));
    }

    if (threads.isEmpty && _bookedHotelsWithoutThread.isEmpty) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: _bgCream,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _threadTile(threads[index]),
                  childCount: threads.length,
                ),
              ),
            ),
            if (_bookedHotelsWithoutThread.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('เริ่มแชทกับร้านที่จองไว้', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _darkBrown)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final hotelId = _bookedHotelsWithoutThread[index]['hotelId'] as String;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: OutlinedButton.icon(
                          onPressed: () => _startChat(hotelId),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          label: const Text('แชทกับร้านนี้'),
                          style: OutlinedButton.styleFrom(foregroundColor: _brown, side: const BorderSide(color: _brown)),
                        ),
                      );
                    },
                    childCount: _bookedHotelsWithoutThread.length,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _threadTile(Map<String, dynamic> thread) {
    final unread = thread['unreadCount'] as int;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: _brown.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 54, height: 54,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: _brown.withValues(alpha: 0.08)),
          child: const Icon(Icons.storefront_rounded, color: _brown, size: 24),
        ),
        title: Text(thread['hotelName'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkBrown)),
        subtitle: Text(
          (thread['lastMessage'] as String?) ?? 'ยังไม่มีข้อความ',
          style: const TextStyle(fontSize: 13, color: _mutedBrown),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: unread > 0
            ? Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: _brown, shape: BoxShape.circle),
                child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            : null,
        onTap: () async {
          await context.read<ChatRepository>().markThreadRead(thread['id'] as String);
          if (!context.mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailViewPage(threadId: thread['id'] as String, title: thread['hotelName'] as String),
            ),
          );
        },
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
  final String threadId;
  final String title;
  const ChatDetailViewPage({super.key, required this.threadId, required this.title});

  @override
  State<ChatDetailViewPage> createState() => _ChatDetailViewPageState();
}

class _ChatDetailViewPageState extends State<ChatDetailViewPage> {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _mutedBrown = Color(0xFF9E7A60);

  final TextEditingController _ctrl = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _myUserId = context.read<AuthService>().currentUser?.id;
    context.read<RealtimeService>().events.listen(_onRealtimeEvent);
    _load();
  }

  void _onRealtimeEvent(Map<String, dynamic> event) {
    if (event['type'] != 'chat_message') return;
    if (event['thread_id'] != widget.threadId) return;
    if (!mounted) return;
    setState(() => _messages.add(event['message'] as Map<String, dynamic>));
  }

  Future<void> _load() async {
    try {
      final messages = await context.read<ChatRepository>().fetchMessages(widget.threadId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(messages);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    try {
      final message = await context.read<ChatRepository>().sendMessage(widget.threadId, text);
      if (!mounted) return;
      setState(() => _messages.add(message));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ส่งข้อความไม่สำเร็จ: $e')));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
              width: 38, height: 38,
              decoration: BoxDecoration(color: _brown.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.storefront_rounded, color: _brown, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.title,
                  style: const TextStyle(color: _brown, fontSize: 15, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _brown))
                : _messages.isEmpty
                    ? const Center(child: Text('ยังไม่มีข้อความ เริ่มทักทายได้เลย', style: TextStyle(color: _mutedBrown)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final m = _messages[i];
                          final isMe = m['senderId'] == _myUserId;
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
                                  child: Text(m['body'] as String, style: TextStyle(color: isMe ? Colors.white : _darkBrown, fontSize: 15)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'พิมพ์ข้อความ...',
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
