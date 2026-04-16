import 'package:flutter/material.dart';
import '../data/hotel_data.dart';
import 'hotel_list_page.dart';

class LiveCamPage extends StatefulWidget {
  const LiveCamPage({super.key});

  @override
  State<LiveCamPage> createState() => _LiveCamPageState();
}

class _LiveCamPageState extends State<LiveCamPage> {
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
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: DecorationImage(
                            image: AssetImage((hotel['images'] as List).first as String),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      title: Text(hotel['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _darkBrown)),
                      subtitle: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.circle, color: Colors.green, size: 10),
                              SizedBox(width: 6),
                              Text('เชื่อมต่อแล้ว · ห้องนอน', style: TextStyle(fontSize: 13, color: _mutedBrown)),
                            ],
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: _brown),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CameraFeedPage(hotel: hotel)));
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
              Icon(Icons.videocam_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Live Cam',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'ติดตามน้องๆ ของคุณผ่านกล้องวงจรปิดแบบเรียลไทม์',
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
                    child: const Icon(Icons.videocam_off_rounded, size: 50, color: _brown),
                  ),
                  const SizedBox(height: 24),
                  const Text('ยังไม่มีกล้อง Live Cam', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _darkBrown)),
                  const SizedBox(height: 12),
                  const Text('คุณสามารถดูน้องๆ ผ่านกล้องได้สดตลอด 24 ชั่วโมง เมื่อทำการจองและเข้าพักที่โรงแรมสัตว์เลี้ยง', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: _mutedBrown, height: 1.5)),
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

class CameraFeedPage extends StatefulWidget {
  final Map<String, dynamic> hotel;
  const CameraFeedPage({super.key, required this.hotel});

  @override
  State<CameraFeedPage> createState() => _CameraFeedPageState();
}

class _CameraFeedPageState extends State<CameraFeedPage> with TickerProviderStateMixin {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _mutedBrown = Color(0xFF9E7A60);
  static const Color _alertRed = Color(0xFFBF4A30);

  bool _isMicOn      = false;
  bool _isRecording  = false;

  late AnimationController _pulseCtrl;

  static const String _camImageUrl = 'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=800&q=80';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900), lowerBound: 0.6, upperBound: 1.0)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg, {Color? bg}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: bg ?? _darkBrown,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildVideoPlayer(),
                  _buildSignalBar(),
                  const SizedBox(height: 20),
                  _buildStatusCard(),
                  const SizedBox(height: 20),
                  _buildControlsSection(),
                  const SizedBox(height: 20),
                  _buildTimelineSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 8, left: 4, right: 12),
      color: _bgCream,
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.chevron_left_rounded, color: _brown, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.hotel['name'] as String,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _darkBrown),
                    overflow: TextOverflow.ellipsis),
                const Text('ห้องนอน · 24 ชั่วโมง', style: TextStyle(fontSize: 11, color: _mutedBrown)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: _brown, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: _brown, size: 22),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      width: double.infinity,
      height: 240,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(_camImageUrl, fit: BoxFit.cover, width: double.infinity),
          Positioned(
            top: 12, left: 12,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _alertRed, borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    children: [
                      ScaleTransition(
                        scale: _pulseCtrl,
                        child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      ),
                      const SizedBox(width: 6),
                      const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(4)),
                  child: const Text('10:45:22', style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
              child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _brown.withValues(alpha: 0.1),
      child: const Row(
        children: [
          Icon(Icons.wifi, size: 16, color: _brown),
          SizedBox(width: 8),
          Text('สัญญาณดีเยี่ยม (45ms)', style: TextStyle(fontSize: 12, color: _brown, fontWeight: FontWeight.w600)),
          Spacer(),
          Text('HD 1080p', style: TextStyle(fontSize: 12, color: _brown, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: const Row(
        children: [
          Icon(Icons.pets, color: _brown),
          SizedBox(width: 12),
          Expanded(child: Text('น้องกำลังนอนพักผ่อนอย่างมีความสุขค่ะ', style: TextStyle(color: _darkBrown, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildControlsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _controlBtn(Icons.mic, 'พูดคุย', _isMicOn, () => setState(() => _isMicOn = !_isMicOn)),
        _controlBtn(Icons.videocam, 'บันทึก', _isRecording, () => setState(() => _isRecording = !_isRecording)),
        _controlBtn(Icons.photo_camera, 'ถ่ายรูป', false, () => _toast('บันทึกรูปภาพเรียบร้อย')),
        _controlBtn(Icons.notifications_active, 'เรียก', false, () => _toast('ส่งสัญญาณเรียกน้องแล้ว')),
      ],
    );
  }

  Widget _controlBtn(IconData icon, String label, bool active, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: active ? _brown : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: active ? Colors.white : _brown),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: _mutedBrown, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTimelineSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, size: 18, color: _mutedBrown),
              SizedBox(width: 8),
              Text('ไทม์ไลน์วันนี้', style: TextStyle(fontWeight: FontWeight.bold, color: _darkBrown)),
            ],
          ),
          const SizedBox(height: 16),
          _timelineItem('10:00', 'ทานอาหารเช้าเรียบร้อย (หมดเกลี้ยง!)'),
          _timelineItem('09:30', 'พาออกไปวิ่งเล่นสนามหญ้าและอาบแดด'),
          _timelineItem('08:00', 'ตื่นนอนและทำความสะอาดตัวเบื้องต้น'),
        ],
      ),
    );
  }

  Widget _timelineItem(String time, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(time, style: const TextStyle(fontSize: 12, color: _mutedBrown, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Expanded(child: Text(detail, style: const TextStyle(fontSize: 13, color: _darkBrown))),
        ],
      ),
    );
  }
}