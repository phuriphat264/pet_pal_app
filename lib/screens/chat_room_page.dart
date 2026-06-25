import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/booking_repository.dart';
import '../services/call_service.dart';
import '../services/chat_repository.dart';
import '../services/hotel_repository.dart';
import '../services/pet_repository.dart';
import '../services/realtime_service.dart';
import '../utils/reloadable.dart';
import 'call_page.dart';
import 'hotel_list_page.dart';

ImageProvider _hotelImageProvider(String path) {
  return path.startsWith('http') ? NetworkImage(path) : AssetImage(path) as ImageProvider;
}

String _formatPetDetails(Map<String, dynamic> pet) {
  return '📋 ข้อมูลสัตว์เลี้ยง: ${pet['name']}\n'
      'สายพันธุ์: ${pet['breed']}\n'
      'อายุ: ${pet['age']}\n'
      'น้ำหนัก: ${pet['weight']}\n'
      'เพศ: ${pet['gender']} (${pet['neutered']})\n'
      'อาหาร: ${pet['food']}\n'
      'อาการแพ้: ${pet['allergies']}\n'
      'วัคซีน: ${pet['vaccine']}'
      '${(pet['traits'] as List).isNotEmpty ? '\nบุคลิก: ${(pet['traits'] as List).join(', ')}' : ''}';
}

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({super.key});
  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> implements Reloadable {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _mutedBrown = Color(0xFF9E7A60);

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _bookedHotelsWithoutThread = [];
  Map<String, String?> _hotelImages = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Future<void> reload() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final chatRepo = context.read<ChatRepository>();
      await chatRepo.loadThreads();
      final bookings = await context.read<BookingRepository>().fetchMyBookings();
      final threadHotelIds = chatRepo.threads.map((t) => t['hotelId'] as String).toSet();
      final seen = <String>{};
      for (final b in bookings) {
        final hotelId = b['hotel_id'] as String;
        if (threadHotelIds.contains(hotelId) || seen.contains(hotelId)) continue;
        seen.add(hotelId);
      }

      final hotelRepo = context.read<HotelRepository>();
      final images = <String, String?>{};
      final bookedWithoutThread = <Map<String, dynamic>>[];
      for (final hotelId in {...threadHotelIds, ...seen}) {
        try {
          final hotel = await hotelRepo.fetchHotel(hotelId);
          final hotelImages = hotel['images'] as List?;
          images[hotelId] = (hotelImages != null && hotelImages.isNotEmpty) ? hotelImages.first as String : null;
          if (seen.contains(hotelId)) {
            bookedWithoutThread.add({'hotelId': hotelId, 'hotelName': hotel['name'] as String});
          }
        } catch (_) {
          images[hotelId] = null;
        }
      }

      if (!mounted) return;
      setState(() {
        _bookedHotelsWithoutThread = bookedWithoutThread;
        _hotelImages = images;
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
        MaterialPageRoute(
          builder: (_) => ChatDetailViewPage(
            threadId: thread['id'] as String,
            title: thread['hotelName'] as String,
            hotelImage: _hotelImages[hotelId],
          ),
        ),
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
                  (context, index) => index < threads.length
                      ? _threadTile(threads[index])
                      : _threadTile({
                          'id': null,
                          'hotelId': _bookedHotelsWithoutThread[index - threads.length]['hotelId'],
                          'hotelName': _bookedHotelsWithoutThread[index - threads.length]['hotelName'],
                          'lastMessage': null,
                          'unreadCount': 0,
                        }),
                  childCount: threads.length + _bookedHotelsWithoutThread.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _threadTile(Map<String, dynamic> thread) {
    final unread = thread['unreadCount'] as int;
    final hotelImage = _hotelImages[thread['hotelId']];
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
          width: 60, height: 60,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: _brown.withValues(alpha: 0.08)),
          child: hotelImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image(
                    image: _hotelImageProvider(hotelImage),
                    width: 60, height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.storefront_rounded, color: _brown, size: 24),
                  ),
                )
              : const Icon(Icons.storefront_rounded, color: _brown, size: 24),
        ),
        title: Text(thread['hotelName'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkBrown)),
        subtitle: Text(
          (thread['lastMessage'] as String?) ?? 'ยังไม่มีข้อความ',
          style: const TextStyle(fontSize: 13, color: _mutedBrown),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (unread > 0) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: _brown, shape: BoxShape.circle),
                child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right_rounded, color: _brown),
          ],
        ),
        onTap: () async {
          final threadId = thread['id'] as String?;
          if (threadId == null) {
            await _startChat(thread['hotelId'] as String);
            return;
          }
          await context.read<ChatRepository>().markThreadRead(threadId);
          if (!context.mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailViewPage(
                threadId: threadId,
                title: thread['hotelName'] as String,
                hotelImage: hotelImage,
              ),
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
  final String? hotelImage;
  const ChatDetailViewPage({super.key, required this.threadId, required this.title, this.hotelImage});

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
    await _sendText(text);
  }

  Future<void> _sendText(String text) async {
    try {
      final message = await context.read<ChatRepository>().sendMessage(widget.threadId, text);
      if (!mounted) return;
      setState(() => _messages.add(message));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ส่งข้อความไม่สำเร็จ: $e')));
    }
  }

  Future<void> _startCall(CallType type) async {
    final call = context.read<CallService>();
    if (call.state != CallState.idle) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กำลังมีสายอยู่')));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CallPage()));
    try {
      await call.startCall(widget.threadId, type);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('โทรไม่สำเร็จ: $e')));
    }
  }

  Future<void> _sharePet() async {
    List<Map<String, dynamic>> pets;
    try {
      pets = await context.read<PetRepository>().fetchPets();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('โหลดข้อมูลสัตว์เลี้ยงไม่สำเร็จ: $e')));
      return;
    }
    if (pets.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่มีข้อมูลสัตว์เลี้ยง กรุณาเพิ่มในหน้าโปรไฟล์ก่อน')),
      );
      return;
    }
    if (!mounted) return;
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('เลือกสัตว์เลี้ยงที่จะส่งข้อมูล',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _darkBrown)),
            ),
            for (final pet in pets)
              ListTile(
                leading: Icon(pet['icon'] as IconData, color: _brown),
                title: Text(pet['name'] as String),
                subtitle: Text(pet['breed'] as String),
                onTap: () => Navigator.pop(sheetContext, pet),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected == null) return;
    await _sendText(_formatPetDetails(selected));
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
              child: widget.hotelImage != null
                  ? ClipOval(
                      child: Image(
                        image: _hotelImageProvider(widget.hotelImage!),
                        width: 38, height: 38,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(Icons.storefront_rounded, color: _brown, size: 18),
                      ),
                    )
                  : const Icon(Icons.storefront_rounded, color: _brown, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.title,
                  style: const TextStyle(color: _brown, fontSize: 15, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_rounded, color: _brown, size: 22),
            tooltip: 'โทรเสียง',
            onPressed: () => _startCall(CallType.audio),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: _brown, size: 24),
            tooltip: 'วิดีโอคอล',
            onPressed: () => _startCall(CallType.video),
          ),
        ],
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
                  IconButton(
                    icon: const Icon(Icons.pets_rounded, color: _brown),
                    tooltip: 'ส่งข้อมูลสัตว์เลี้ยง',
                    onPressed: _sharePet,
                  ),
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
