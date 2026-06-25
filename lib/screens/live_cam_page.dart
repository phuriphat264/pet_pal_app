import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../services/booking_repository.dart';
import '../services/camera_repository.dart';
import '../services/hotel_repository.dart';
import '../utils/reloadable.dart';
import 'hotel_list_page.dart';

class LiveCamPage extends StatefulWidget {
  const LiveCamPage({super.key});

  @override
  State<LiveCamPage> createState() => _LiveCamPageState();
}

class _LiveCamPageState extends State<LiveCamPage> implements Reloadable {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _mutedBrown = Color(0xFF9E7A60);

  List<Map<String, dynamic>>? _bookedHotels; // [{hotel, cameras}]
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Future<void> reload() => _load();

  Future<void> _load() async {
    setState(() {
      _bookedHotels = null;
      _error = null;
    });
    try {
      final bookings = await context.read<BookingRepository>().fetchMyBookings();
      final hotelIds = <String>{
        for (final b in bookings)
          if (b['status'] != 'cancelled') b['hotel_id'] as String,
      };

      final hotelRepo = context.read<HotelRepository>();
      final cameraRepo = context.read<CameraRepository>();
      final result = <Map<String, dynamic>>[];
      for (final hotelId in hotelIds) {
        final hotel = await hotelRepo.fetchHotel(hotelId);
        List<Map<String, dynamic>> cameras = [];
        try {
          cameras = await cameraRepo.fetchCamerasForHotel(hotelId);
        } catch (_) {
          // no cameras registered yet for this hotel -- not fatal
        }
        result.add({'hotel': hotel, 'cameras': cameras});
      }

      if (!mounted) return;
      setState(() => _bookedHotels = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'โหลดข้อมูลไม่สำเร็จ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: _bgCream,
        body: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(_error!, style: const TextStyle(color: _mutedBrown))),
          ),
        ]),
      );
    }
    if (_bookedHotels == null) {
      return Scaffold(
        backgroundColor: _bgCream,
        body: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator(color: _brown)),
          ),
        ]),
      );
    }
    if (_bookedHotels!.isEmpty) return _buildEmptyState();

    return Scaffold(
      backgroundColor: _bgCream,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.92,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = _bookedHotels![index];
                    final hotel = entry['hotel'] as Map<String, dynamic>;
                    final cameras = entry['cameras'] as List<Map<String, dynamic>>;
                    return _monitorTile(hotel, cameras);
                  },
                  childCount: _bookedHotels!.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _imageProvider(String path) {
    if (path.startsWith('http')) return NetworkImage(path);
    return AssetImage(path);
  }

  Widget _monitorTile(Map<String, dynamic> hotel, List<Map<String, dynamic>> cameras) {
    final hasCamera = cameras.isNotEmpty;
    final images = hotel['images'] as List;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CameraFeedPage(hotel: hotel, cameras: cameras)),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFF1B1410)),
            if (images.isNotEmpty)
              Opacity(
                opacity: 0.5,
                child: Image(image: _imageProvider(images.first as String), fit: BoxFit.cover),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.05), Colors.black.withValues(alpha: 0.85)],
                ),
              ),
            ),
            Positioned(
              top: 10, left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasCamera ? const Color(0xFFBF4A30) : Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(color: hasCamera ? Colors.white : Colors.white54, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(hasCamera ? 'LIVE' : 'OFFLINE',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10, right: 10,
              child: Icon(hasCamera ? Icons.videocam_rounded : Icons.videocam_off_rounded, color: Colors.white70, size: 18),
            ),
            Positioned(
              left: 12, right: 12, bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel['name'] as String,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasCamera ? 'พร้อมดูสด' : 'ยังไม่มีกล้องติดตั้ง',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                    decoration: BoxDecoration(color: _brown.withValues(alpha: 0.05), shape: BoxShape.circle),
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
  final List<Map<String, dynamic>> cameras;
  const CameraFeedPage({super.key, required this.hotel, required this.cameras});

  @override
  State<CameraFeedPage> createState() => _CameraFeedPageState();
}

class _CameraFeedPageState extends State<CameraFeedPage> with TickerProviderStateMixin {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _mutedBrown = Color(0xFF9E7A60);
  static const Color _alertRed = Color(0xFFBF4A30);

  late AnimationController _pulseCtrl;

  VlcPlayerController? _vlcController;
  VideoPlayerController? _videoController;
  String? _streamError;
  bool _connecting = true;
  bool _isDemoFootage = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900), lowerBound: 0.6, upperBound: 1.0)..repeat(reverse: true);
    _connectToCamera();
  }

  Future<void> _connectToCamera() async {
    if (widget.cameras.isEmpty) {
      // No camera registered for this room yet -- play bundled demo footage
      // so the live-cam UI/UX can be reviewed before real hardware is wired in.
      // Uses video_player (not flutter_vlc_player) because the VLC plugin's
      // PlatformView can't establish its method channel under the current
      // Flutter/Impeller embedding -- video_player handles local asset
      // playback natively and doesn't need VLC's RTSP-only capabilities here.
      final controller = VideoPlayerController.asset('assets/videos/demo_cat_cam.mp4');
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      _videoController = controller;
      setState(() {
        _isDemoFootage = true;
        _connecting = false;
      });
      return;
    }
    final cameraId = widget.cameras.first['id'] as String;
    try {
      final streamUrl = await context.read<CameraRepository>().fetchStreamUrl(cameraId);
      _vlcController = VlcPlayerController.network(
        streamUrl,
        hwAcc: HwAcc.full,
        autoPlay: true,
        options: VlcPlayerOptions(),
      );
      if (!mounted) return;
      setState(() => _connecting = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _streamError = 'เชื่อมต่อกล้องไม่ได้: $e\n(ตรวจสอบว่ามือถือ/อุปกรณ์อยู่เครือข่ายเดียวกับกล้อง)';
        _connecting = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _vlcController?.dispose();
    _videoController?.dispose();
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
                  if (_hasPlayer) _buildSignalBar(),
                  const SizedBox(height: 20),
                  _buildStatusCard(),
                  const SizedBox(height: 20),
                  if (_hasPlayer) _buildControlsSection(),
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
            icon: const Icon(Icons.refresh_rounded, color: _brown, size: 22),
            onPressed: () {
              setState(() {
                _connecting = true;
                _streamError = null;
                _vlcController?.dispose();
                _vlcController = null;
                _videoController?.dispose();
                _videoController = null;
              });
              _connectToCamera();
            },
          ),
        ],
      ),
    );
  }

  bool get _hasPlayer => _vlcController != null || _videoController != null;

  Widget _buildVideoPlayer() {
    Widget content;
    if (_connecting) {
      content = const Center(child: CircularProgressIndicator(color: Colors.white));
    } else if (_streamError != null) {
      content = Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_rounded, color: Colors.white70, size: 40),
            const SizedBox(height: 12),
            Text(_streamError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      );
    } else if (_videoController != null) {
      content = AspectRatio(
        aspectRatio: 16 / 9,
        child: VideoPlayer(_videoController!),
      );
    } else if (_vlcController == null) {
      content = const Center(
        child: Text('ยังไม่มีกล้องติดตั้งสำหรับห้องนี้', style: TextStyle(color: Colors.white70)),
      );
    } else {
      content = VlcPlayer(
        controller: _vlcController!,
        aspectRatio: 16 / 9,
        placeholder: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Container(
      width: double.infinity,
      height: 240,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          content,
          if (_hasPlayer && !_connecting && _streamError == null)
            Positioned(
              top: 12, left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _alertRed, borderRadius: BorderRadius.circular(4)),
                child: Row(
                  children: [
                    ScaleTransition(
                      scale: _pulseCtrl,
                      child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    ),
                    const SizedBox(width: 6),
                    Text(_isDemoFootage ? 'DEMO' : 'LIVE', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
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
          Text('สตรีมตรงจากกล้องผ่านเครือข่ายเดียวกัน', style: TextStyle(fontSize: 12, color: _brown, fontWeight: FontWeight.w600)),
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
      child: Row(
        children: [
          const Icon(Icons.pets, color: _brown),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isDemoFootage
                  ? 'ยังไม่มีกล้องติดตั้งในห้องนี้ -- นี่คือวิดีโอตัวอย่าง (Demo) ทีมงานจะแจ้งเมื่อกล้องจริงพร้อมใช้งาน'
                  : 'น้องกำลังนอนพักผ่อนอย่างมีความสุขค่ะ',
              style: const TextStyle(color: _darkBrown, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
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
}
