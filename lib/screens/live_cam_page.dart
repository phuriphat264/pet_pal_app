// lib/screens/live_cam_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'hotel_list_page.dart';

class LiveCamPage extends StatefulWidget {
  const LiveCamPage({super.key});

  @override
  State<LiveCamPage> createState() => _LiveCamPageState();
}

class _LiveCamPageState extends State<LiveCamPage>
    with TickerProviderStateMixin {
  // ─── Palette ───────────────────────────────────────────────────
  static const Color _brown      = Color(0xFF6B4226);
  static const Color _darkBrown  = Color(0xFF3B2010);
  static const Color _deepBrown  = Color(0xFF2A1608);
  static const Color _bgCream    = Color(0xFFF7F1EA);
  static const Color _bgCard     = Color(0xFFFFFBF7);
  static const Color _mutedBrown = Color(0xFFA07850);
  static const Color _border     = Color(0xFFE2D0BC);
  static const Color _alertRed   = Color(0xFFBF4A30);

  // ─── State ────────────────────────────────────────────────────
  bool _hasActiveBooking = false; // สถานะเบื้องต้น: ยังไม่จอง
  bool _isMicOn      = false;
  bool _isRecording  = false;
  bool _isFullscreen = false;
  bool _showControls = true;

  late AnimationController _controlsFadeCtrl;
  late Animation<double> _controlsFadeAnim;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // กล้องเดียว — ห้องที่น้องอยู่
  static const String _camImageUrl =
      'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=800&q=80';
  static const String _roomLabel = 'ห้องนอน';
  static const String _petStatus = 'กำลังนอนพักผ่อน';
  static const bool   _isSafe    = true;

  @override
  void initState() {
    super.initState();

    _controlsFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _controlsFadeAnim = CurvedAnimation(
        parent: _controlsFadeCtrl, curve: Curves.easeOut);
    _controlsFadeCtrl.forward();

    // Pulse for REC dot
    _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
        lowerBound: 0.6,
        upperBound: 1.0)
      ..repeat(reverse: true);
    _pulseAnim = _pulseCtrl;
  }

  @override
  void dispose() {
    _controlsFadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ───────────────────────────────────────────────────
  void _toast(String msg, {Color? bg}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      backgroundColor: bg ?? _deepBrown,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      duration: const Duration(seconds: 2),
    ));
  }

  void _onVideoTap() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _controlsFadeCtrl.forward();
    } else {
      _controlsFadeCtrl.reverse();
    }
  }

  void _onMicTap() {
    setState(() => _isMicOn = !_isMicOn);
    _toast(_isMicOn ? '🎙️ เปิดไมค์แล้ว — น้องได้ยินคุณ' : '🔇 ปิดไมค์แล้ว');
  }

  void _onRecordTap() {
    setState(() => _isRecording = !_isRecording);
    _toast(
      _isRecording ? '🔴 เริ่มบันทึกวิดีโอ' : '⏹️ บันทึกเสร็จแล้ว',
      bg: _isRecording ? _alertRed : _deepBrown,
    );
  }

  void _onCaptureTap() {
    HapticFeedback.lightImpact();
    _toast('📸 บันทึกภาพแล้ว');
  }

  void _onCallTap() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                  color: _alertRed.withValues(alpha:0.12),
                  shape: BoxShape.circle),
              child: const Icon(Icons.notifications_active_rounded,
                  color: _alertRed, size: 30),
            ),
            const SizedBox(height: 14),
            const Text('เรียกน้อง',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _darkBrown)),
            const SizedBox(height: 6),
            const Text(
              'ส่งสัญญาณเสียงเรียกน้องผ่านลำโพงกล้อง',
              style: TextStyle(fontSize: 15, color: _mutedBrown),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('ยกเลิก',
                        style: TextStyle(
                            color: _mutedBrown, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _toast('🔔 ส่งสัญญาณเรียกน้องแล้ว!',
                          bg: _alertRed);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _alertRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('เรียกเลย',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_hasActiveBooking) return _buildEmptyState();

    return Scaffold(
      backgroundColor: _bgCream,
      body: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                decoration: BoxDecoration(color: _border.withValues(alpha:0.3), shape: BoxShape.circle),
                child: const Icon(Icons.videocam_off_rounded, size: 50, color: _brown),
              ),
              const SizedBox(height: 24),
              const Text('ยังไม่มีกล้อง Live Cam', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _darkBrown)),
              const SizedBox(height: 12),
              const Text('คุณสามารถดูน้องๆ ผ่านกล้องได้สดตลอด 24 ชั่วโมง เมื่อทำการจองและเข้าพักที่โรงแรมสัตว์เลี้ยง', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: _mutedBrown, height: 1.5)),
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
                child: const Text('ดูตัวอย่างหน้ากล้อง (Demo)', style: TextStyle(color: _mutedBrown)),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // ─── AppBar ────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 16,
        right: 16,
      ),
      color: _bgCream,
      child: Row(
        children: [
          _circleBtn(
            onTap: () => Navigator.maybePop(context),
            child: const Icon(Icons.chevron_left_rounded,
                color: _brown, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Live Cam',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _darkBrown,
                    letterSpacing: -0.3),
              ),
              Text(
                '$_roomLabel · 24 ชั่วโมง',
                style: const TextStyle(fontSize: 13, color: _mutedBrown),
              ),
            ],
          ),
          const Spacer(),
          _circleBtn(
            onTap: () => _showSettingsSheet(context),
            child: const Icon(Icons.tune_rounded, color: _brown, size: 18),
          ),
          const SizedBox(width: 8),
          _circleBtn(
            onTap: () => _showPetSheet(context),
            child: const Text('🐶', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: _border.withValues(alpha:0.5),
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }

  // ─── Video Player ──────────────────────────────────────────────
  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: _onVideoTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: _isFullscreen ? 380 : 280,
        color: _deepBrown,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Feed image
            Image.network(
              _camImageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (ctx, child, progress) {
                if (progress == null) return child;
                return _videoPlaceholder(loading: true);
              },
              errorBuilder: (ctx, err, stack) =>
                  _videoPlaceholder(loading: false),
            ),

            // Top + bottom gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha:0.55),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha:0.55),
                  ],
                  stops: const [0, 0.28, 0.72, 1],
                ),
              ),
            ),

            // LIVE / REC badge
            Positioned(
              top: 12, left: 12,
              child: _isRecording ? _buildRecBadge() : _buildLiveBadge(),
            ),

            // Fullscreen icon top-right
            Positioned(
              top: 12, right: 12,
              child: FadeTransition(
                opacity: _controlsFadeAnim,
                child: GestureDetector(
                  onTap: () => setState(() => _isFullscreen = !_isFullscreen),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha:0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isFullscreen
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                      color: Colors.white.withValues(alpha:0.9),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),

            // Mic indicator bottom-left
            if (_isMicOn)
              Positioned(
                bottom: 14, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha:0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic_rounded, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text('ไมค์เปิดอยู่',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),

            // Timestamp bottom-right
            Positioned(
              bottom: 14, right: 12,
              child: Text(
                '00:14:38',
                style: TextStyle(
                    color: Colors.white.withValues(alpha:0.7),
                    fontSize: 13,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFD43D2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(color: Colors.white),
          SizedBox(width: 5),
          Text('LIVE',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildRecBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha:0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 7, height: 7,
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 5),
          const Text('REC',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _videoPlaceholder({required bool loading}) {
    return Container(
      color: const Color(0xFF2A1608),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              loading ? Icons.videocam_rounded : Icons.videocam_off_rounded,
              color: Colors.white30,
              size: 52,
            ),
            const SizedBox(height: 10),
            Text(
              loading ? 'กำลังโหลดภาพ...' : 'ไม่สามารถเชื่อมต่อได้',
              style: const TextStyle(color: Colors.white38, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Signal Bar ───────────────────────────────────────────────
  Widget _buildSignalBar() {
    return Container(
      color: _deepBrown,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          const Icon(Icons.signal_wifi_4_bar_rounded,
              color: Color(0xFFC8845A), size: 16),
          const SizedBox(width: 6),
          const Text(
            'สัญญาณดี · 1080p · 30fps',
            style: TextStyle(fontSize: 13, color: Color(0xFFB8926C)),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              4,
              (i) => Container(
                width: 3,
                height: 5.0 + (i * 3.5),
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: i < 1
                      ? const Color(0xFF6B4226)
                      : const Color(0xFFC8845A),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Status Card ──────────────────────────────────────────────
  Widget _buildStatusCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isSafe
              ? const Color(0xFFEEF7ED)
              : const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isSafe
                ? const Color(0xFF81C784).withValues(alpha:0.5)
                : const Color(0xFFFFB74D).withValues(alpha:0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: _isSafe
                    ? const Color(0xFFC8E6C4)
                    : const Color(0xFFFFE0B2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isSafe
                    ? Icons.check_circle_outline_rounded
                    : Icons.warning_amber_rounded,
                color: _isSafe
                    ? const Color(0xFF388E3C)
                    : const Color(0xFFF57C00),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _petStatus,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _isSafe
                          ? const Color(0xFF2E6B28)
                          : const Color(0xFF8B4000),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'อัปเดตเมื่อ 2 นาทีที่แล้ว',
                    style: TextStyle(fontSize: 13, color: _mutedBrown),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _isSafe
                    ? const Color(0xFF81C784).withValues(alpha:0.2)
                    : const Color(0xFFFFB74D).withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isSafe ? 'ปลอดภัย' : 'ตรวจสอบ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _isSafe
                      ? const Color(0xFF2E6B28)
                      : const Color(0xFF8B4000),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Controls ─────────────────────────────────────────────────
  Widget _buildControlsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ควบคุม',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _darkBrown,
                letterSpacing: 0.1),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: _brown.withValues(alpha:0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _controlBtn(
                  icon: _isMicOn
                      ? Icons.mic_rounded
                      : Icons.mic_off_rounded,
                  label: _isMicOn ? 'ปิดไมค์' : 'พูดคุย',
                  color: _isMicOn
                      ? const Color(0xFF3B7A3B)
                      : _brown,
                  onTap: _onMicTap,
                  active: _isMicOn,
                ),
                _controlBtn(
                  icon: _isRecording
                      ? Icons.stop_rounded
                      : Icons.fiber_manual_record_rounded,
                  label: _isRecording ? 'หยุด' : 'บันทึก',
                  color: _isRecording ? _alertRed : _brown,
                  onTap: _onRecordTap,
                  active: _isRecording,
                ),
                _controlBtn(
                  icon: Icons.photo_camera_outlined,
                  label: 'ถ่ายรูป',
                  color: _brown,
                  onTap: _onCaptureTap,
                ),
                _controlBtn(
                  icon: Icons.notifications_active_rounded,
                  label: 'เรียกน้อง',
                  color: _alertRed,
                  onTap: _onCallTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: active ? color : color.withValues(alpha:0.12),
              shape: BoxShape.circle,
              boxShadow: active
                  ? [
                      BoxShadow(
                          color: color.withValues(alpha:0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              color: active ? Colors.white : color,
              size: 28,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? color : _mutedBrown,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Timeline ─────────────────────────────────────────────────
  Widget _buildTimelineSection() {
    final List<Map<String, dynamic>> events = [
      {'time': '22:30', 'event': 'พาเข้าห้องนอนเรียบร้อย', 'icon': Icons.bed_rounded},
      {'time': '22:35', 'event': 'ห่มผ้าให้น้องแล้ว หลับสนิทค่ะ', 'icon': Icons.nights_stay_rounded},
      {'time': '07:30', 'event': 'น้องตื่นแล้ว อารมณ์ดีมาก', 'icon': Icons.wb_sunny_rounded},
      {'time': '08:00', 'event': 'ทานข้าวเช้าหมดชามเลยค่ะ', 'icon': Icons.restaurant_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สมุดบันทึกจากพี่เลี้ยง',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _darkBrown,
                letterSpacing: 0.1),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: _brown.withValues(alpha:0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: List.generate(events.length, (i) {
                final e = events[i];
                final isLast = i == events.length - 1;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: _bgCream,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _border),
                          ),
                          child: Center(
                            child: Icon(e['icon'] as IconData, size: 20, color: _brown),
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 1.5,
                            height: 28,
                            color: _border,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            top: 8, bottom: isLast ? 0 : 24),
                        child: Row(
                          children: [
                            Text(
                              e['event'] as String,
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: _darkBrown,
                                  fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Text(
                              e['time'] as String,
                              style: const TextStyle(
                                  fontSize: 13, color: _mutedBrown),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Settings Sheet ───────────────────────────────────────────
  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: _border,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            const Text('ตั้งค่ากล้อง',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _darkBrown)),
            const SizedBox(height: 16),
            _settingTile(Icons.hd_rounded, 'ความละเอียด', '1080p'),
            _settingTile(Icons.nightlight_round, 'โหมดกลางคืน', 'อัตโนมัติ'),
            _settingTile(Icons.volume_up_rounded, 'เสียงจากกล้อง', 'เปิด'),
            _settingTile(Icons.rotate_right_rounded, 'หมุนภาพ', '0°'),
          ],
        ),
      ),
    );
  }

  Widget _settingTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: _border.withValues(alpha:0.5),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _brown, size: 18),
          ),
          const SizedBox(width: 12),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  color: _darkBrown,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value,
              style: const TextStyle(fontSize: 15, color: _mutedBrown)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded,
              color: _mutedBrown, size: 18),
        ],
      ),
    );
  }

  // ─── Pet Sheet ────────────────────────────────────────────────
  void _showPetSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(
              width: 76, height: 76,
              decoration: BoxDecoration(
                  color: _border.withValues(alpha:0.4),
                  shape: BoxShape.circle),
              child: const Center(
                  child: Text('🐶', style: TextStyle(fontSize: 48))),
            ),
            const SizedBox(height: 12),
            const Text('มะม่วง',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _darkBrown)),
            const SizedBox(height: 3),
            const Text('โกลเด้นรีทรีฟเวอร์ · 3 ปี',
                style: TextStyle(fontSize: 15, color: _mutedBrown)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                  color: _bgCream,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _petStat('น้ำหนัก', '28 กก.'),
                  Container(width: 1, height: 32, color: _border),
                  _petStat('วัคซีน', 'ครบแล้ว ✓'),
                  Container(width: 1, height: 32, color: _border),
                  _petStat('รับกลับ', '15 เม.ย.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _petStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _darkBrown)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 13, color: _mutedBrown)),
      ],
    );
  }
}

// ─── Pulse Dot Widget ──────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
        lowerBound: 0.5,
        upperBound: 1.0)
      ..repeat(reverse: true);
    _anim = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7, height: 7,
        decoration:
            BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}