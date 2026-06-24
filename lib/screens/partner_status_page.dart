// lib/screens/partner_status_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/partner_repository.dart';
import 'hotel_dashboard_page.dart';

class PartnerStatusPage extends StatefulWidget {
  const PartnerStatusPage({super.key});

  @override
  State<PartnerStatusPage> createState() => _PartnerStatusPageState();
}

class _PartnerStatusPageState extends State<PartnerStatusPage> {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _mutedBrown = Color(0xFF9E7A60);
  static const Color _borderColor = Color(0xFFD9C5B2);
  static const Color _green = Color(0xFF4CAF50);
  static const Color _red = Color(0xFFE53935);

  Map<String, dynamic>? _application;
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
      final app = await context.read<PartnerRepository>().fetchMyApplication();
      if (!mounted) return;
      setState(() {
        _application = app;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'โหลดสถานะไม่สำเร็จ: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: _bgCream,
        elevation: 0,
        foregroundColor: _darkBrown,
        title: const Text('สถานะการสมัครเปิดร้าน',
            style: TextStyle(fontWeight: FontWeight.w700, color: _darkBrown)),
        actions: [
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _brown));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: const TextStyle(color: _mutedBrown), textAlign: TextAlign.center),
        ),
      );
    }
    if (_application == null) {
      return const Center(
        child: Text('ไม่พบคำขอเปิดร้าน', style: TextStyle(color: _mutedBrown)),
      );
    }

    final status = _application!['status'] as String;
    final approved = status == 'approved';
    final rejected = status == 'rejected';
    final shopName = (_application!['shopName'] as String).isEmpty ? 'ร้านของคุณ' : _application!['shopName'] as String;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: _brown.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: (rejected ? _red : (approved ? _green : _brown)).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    rejected ? Icons.cancel_rounded : (approved ? Icons.verified_rounded : Icons.hourglass_top_rounded),
                    color: rejected ? _red : (approved ? _green : _brown),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shopName,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _darkBrown)),
                      const SizedBox(height: 4),
                      Text(
                        rejected
                            ? (_application!['rejectionReason'] as String? ?? 'คำขอไม่ได้รับการอนุมัติ')
                            : (approved ? 'อนุมัติแล้ว พร้อมเริ่มรับลูกค้า 🎉' : 'อยู่ระหว่างตรวจสอบเอกสาร'),
                        style: TextStyle(
                            fontSize: 13,
                            color: rejected ? _red : (approved ? _green : _mutedBrown),
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('ขั้นตอนการสมัคร',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _darkBrown)),
          const SizedBox(height: 16),

          _timelineStep(
            icon: Icons.check_circle_rounded,
            title: 'ส่งคำขอสำเร็จ',
            subtitle: 'ระบบได้รับข้อมูลร้านและเอกสารของคุณแล้ว',
            done: true,
            isLast: false,
          ),
          _timelineStep(
            icon: approved
                ? Icons.check_circle_rounded
                : (rejected ? Icons.cancel_rounded : Icons.hourglass_top_rounded),
            title: 'อยู่ระหว่างตรวจสอบ',
            subtitle: 'ทีมงาน PetPal ตรวจสอบความถูกต้องของเอกสาร (1-2 วันทำการ)',
            done: approved || rejected,
            isLast: false,
          ),
          _timelineStep(
            icon: approved ? Icons.celebration_rounded : (rejected ? Icons.cancel_rounded : Icons.flag_outlined),
            title: 'ผลการพิจารณา',
            subtitle: approved
                ? 'ยินดีด้วย! ร้านของคุณได้รับการอนุมัติแล้ว'
                : (rejected ? 'คำขอไม่ผ่านการอนุมัติ กรุณาแก้ไขและส่งใหม่' : 'รอผลการพิจารณาจากทีมงาน'),
            done: approved || rejected,
            isLast: true,
          ),

          const SizedBox(height: 28),

          if (!approved)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _load,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _brown, width: 1.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('ตรวจสอบสถานะอีกครั้ง',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _brown)),
              ),
            ),

          if (approved)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HotelDashboardPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brown,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('ไปที่หน้าจัดการร้าน',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _timelineStep({required IconData icon, required String title, required String subtitle, required bool done, required bool isLast}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: done ? _green.withValues(alpha: 0.12) : _brown.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: done ? _green : _brown),
            ),
            if (!isLast)
              Container(width: 1.5, height: 48, color: _borderColor),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24, top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _darkBrown)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12.5, color: _mutedBrown, height: 1.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
