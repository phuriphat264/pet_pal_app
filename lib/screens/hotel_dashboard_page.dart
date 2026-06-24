// lib/screens/hotel_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/booking_repository.dart';
import '../services/chat_repository.dart';
import '../services/hotel_repository.dart';
import 'chat_room_page.dart';

class HotelDashboardPage extends StatefulWidget {
  const HotelDashboardPage({super.key});

  @override
  State<HotelDashboardPage> createState() => _HotelDashboardPageState();
}

class _HotelDashboardPageState extends State<HotelDashboardPage> {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _mutedBrown = Color(0xFF9E7A60);
  static const Color _green = Color(0xFF4CAF50);
  static const Color _orange = Color(0xFFFB8C00);

  Map<String, dynamic>? _hotel;
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;
  String? _error;

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
      final hotel = await context.read<HotelRepository>().fetchMyHotel();
      final bookings = await context.read<BookingRepository>().fetchHotelBookings(hotel['id'] as String);
      await context.read<ChatRepository>().loadThreads();
      if (!mounted) return;
      setState(() {
        _hotel = hotel;
        _bookings = bookings.map(hotelBookingFromJson).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'โหลดข้อมูลร้านไม่สำเร็จ: $e';
        _loading = false;
      });
    }
  }

  Future<void> _toggleRoom(String roomId, bool value) async {
    if (_hotel == null) return;
    try {
      await context.read<HotelRepository>().setRoomAvailability(_hotel!['id'] as String, roomId, value);
      setState(() {
        final room = (_hotel!['rooms'] as List).firstWhere((r) => r['id'] == roomId);
        room['available'] = value;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัปเดตห้องไม่สำเร็จ: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: _bgCream, body: Center(child: CircularProgressIndicator(color: _brown)));
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: _bgCream,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, style: const TextStyle(color: _mutedBrown), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _load, child: const Text('ลองอีกครั้ง')),
              ],
            ),
          ),
        ),
      );
    }

    final shopName = (_hotel?['name'] as String?)?.isNotEmpty == true ? _hotel!['name'] as String : 'ร้านของฉัน';
    final rooms = (_hotel?['rooms'] as List? ?? const []).cast<Map<String, dynamic>>();

    return Scaffold(
      backgroundColor: _bgCream,
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(shopName),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('📊 ภาพรวม'),
                    _buildOverview(),
                    _sectionHeader('🛏️ จัดการห้อง/บริการ'),
                    _buildRoomsSection(rooms),
                    _sectionHeader('📅 การจองลูกค้า'),
                    _buildBookingsSection(),
                    _sectionHeader('💬 แชทลูกค้า'),
                    _buildChatsSection(context.watch<ChatRepository>().threads),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String shopName) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _brown,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shopName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Text('เจ้าของร้าน', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Container(width: 4, height: 18, decoration: BoxDecoration(color: _brown, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    return Row(
      children: [
        Expanded(child: _statCard('การจองทั้งหมด', '${_bookings.length}', Icons.event_available_rounded, const Color(0xFF1E88E5))),
        const SizedBox(width: 12),
        Expanded(child: _statCard('รายได้รวม', '฿${_hotel?['price'] ?? 0}', Icons.payments_rounded, _green)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('คะแนนรีวิว', '${_hotel?['rating'] ?? 0}', Icons.star_rounded, _orange)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _darkBrown)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: _mutedBrown), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildRoomsSection(List<Map<String, dynamic>> rooms) {
    if (rooms.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: const Text('ยังไม่มีห้อง/บริการ — เพิ่มได้จากหน้าจัดการโรงแรม', style: TextStyle(color: _mutedBrown, fontSize: 13)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _brown.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: List.generate(rooms.length, (i) {
          final room = rooms[i];
          final isLast = i == rooms.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isLast ? null : const Border(bottom: BorderSide(color: _bgCream, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(room['type'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _darkBrown)),
                      const SizedBox(height: 3),
                      Text('฿${room['price']}/คืน', style: const TextStyle(fontSize: 12, color: _mutedBrown)),
                    ],
                  ),
                ),
                Switch(
                  value: room['available'] as bool,
                  activeThumbColor: _brown,
                  onChanged: (val) => _toggleRoom(room['id'] as String, val),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBookingsSection() {
    if (_bookings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: const Text('ยังไม่มีลูกค้าจองในตอนนี้', style: TextStyle(color: _mutedBrown, fontSize: 13)),
      );
    }
    return Column(
      children: _bookings.map((b) {
        final confirmed = b['status'] == 'confirmed';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: _brown.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: _brown.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.pets_rounded, color: _brown, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${b['customerName']} · ${b['petName']}',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _darkBrown)),
                    const SizedBox(height: 3),
                    Text('วันที่ ${b['date']}', style: const TextStyle(fontSize: 12, color: _mutedBrown)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (confirmed ? _green : _orange).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(b['statusLabel'] as String,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: confirmed ? _green : _orange)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChatsSection(List<Map<String, dynamic>> threads) {
    if (threads.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: const Text('ยังไม่มีลูกค้าทักแชทมา', style: TextStyle(color: _mutedBrown, fontSize: 13)),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _brown.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: List.generate(threads.length, (i) {
          final thread = threads[i];
          final isLast = i == threads.length - 1;
          final unread = thread['unreadCount'] as int;
          return InkWell(
            onTap: () async {
              await context.read<ChatRepository>().markThreadRead(thread['id'] as String);
              if (!context.mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailViewPage(threadId: thread['id'] as String, title: thread['customerName'] as String),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: isLast ? null : const Border(bottom: BorderSide(color: _bgCream, width: 1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: _brown.withValues(alpha: 0.08), shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded, color: _brown, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(thread['customerName'] as String,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _darkBrown)),
                        const SizedBox(height: 3),
                        Text((thread['lastMessage'] as String?) ?? 'ยังไม่มีข้อความ',
                            style: const TextStyle(fontSize: 12.5, color: _mutedBrown),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: _brown, shape: BoxShape.circle),
                      child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
