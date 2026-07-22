// Admin shell: review and approve/reject partner (shop) applications.
// This is the real counterpart to the old client-side "(Demo) simulate
// approval" button -- only an admin account can move an application from
// pending to approved/rejected now.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/admin_payment_repository.dart';
import '../services/admin_user_repository.dart';
import '../services/auth_service.dart';
import '../services/camera_repository.dart';
import '../services/hotel_repository.dart';
import '../services/partner_repository.dart';
import '../utils/pet_pal_image.dart';

const Map<String, Color> _paymentStatusColors = {
  'successful': Color(0xFF4CAF50),
  'pending': Color(0xFFFB8C00),
  'failed': Color(0xFFE53935),
  'expired': Color(0xFF9E7A60),
  'refunded': Color(0xFF29508A),
};

const Map<String, Color> _cameraStatusColors = {
  'online': Color(0xFF4CAF50),
  'offline': Color(0xFF9E7A60),
  'error': Color(0xFFE53935),
  'unregistered': Color(0xFFFB8C00),
};

const Map<String, String> _cameraStatusLabelsTh = {
  'online': 'ออนไลน์',
  'offline': 'ออฟไลน์',
  'error': 'มีปัญหา',
  'unregistered': 'ยังไม่ทดสอบ',
};

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _mutedBrown = Color(0xFF9E7A60);
  static const Color _green = Color(0xFF4CAF50);
  static const Color _red = Color(0xFFE53935);
  static const Color _orange = Color(0xFFFB8C00);

  final List<String> _statuses = const ['pending', 'approved', 'rejected'];
  // 0 = home menu, 1 = partner applications, 2 = technicians, 3 = camera status, 4 = finance
  int _section = 0;
  int _tab = 0;
  List<Map<String, dynamic>>? _applications;
  String? _error;
  bool _busyId(String id) => _busyIds.contains(id);
  final Set<String> _busyIds = {};

  List<Map<String, dynamic>>? _technicians;
  String? _technicianError;

  List<Map<String, dynamic>>? _cameras;
  List<Map<String, dynamic>>? _cameraHotels;
  List<Map<String, dynamic>>? _cameraTechnicians;
  String? _cameraError;
  final Set<String> _testingCameraIds = {};

  List<Map<String, dynamic>>? _payments;
  Map<String, dynamic>? _financeReport;
  String? _financeError;
  final Set<String> _refundingIds = {};

  void _openSection(int section) {
    setState(() => _section = section);
    if (section == 1 && _applications == null) _load();
    if (section == 2 && _technicians == null) _loadTechnicians();
    if (section == 3 && _cameras == null) _loadCameraStatus();
    if (section == 4 && _payments == null) _loadFinance();
  }

  Future<void> _loadTechnicians() async {
    setState(() {
      _technicians = null;
      _technicianError = null;
    });
    try {
      final techs = await context.read<AdminUserRepository>().fetchUsersByRole('technician');
      if (!mounted) return;
      setState(() => _technicians = techs);
    } catch (e) {
      if (!mounted) return;
      setState(() => _technicianError = 'โหลดรายชื่อช่างไม่สำเร็จ: $e');
    }
  }

  Future<void> _loadCameraStatus() async {
    setState(() {
      _cameras = null;
      _cameraError = null;
    });
    try {
      final results = await Future.wait([
        context.read<CameraRepository>().fetchCameras(),
        context.read<HotelRepository>().fetchHotels(availableOnly: false),
        context.read<AdminUserRepository>().fetchUsersByRole('technician'),
      ]);
      if (!mounted) return;
      setState(() {
        _cameras = results[0];
        _cameraHotels = results[1];
        _cameraTechnicians = results[2];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cameraError = 'โหลดข้อมูลกล้องไม่สำเร็จ: $e');
    }
  }

  Future<void> _testCameraConnection(String cameraId) async {
    setState(() => _testingCameraIds.add(cameraId));
    try {
      final result = await context.read<CameraRepository>().testConnection(cameraId);
      if (!mounted) return;
      setState(() {
        final idx = _cameras!.indexWhere((c) => c['id'] == cameraId);
        if (idx != -1) _cameras![idx] = result['camera'] as Map<String, dynamic>;
      });
    } catch (e) {
      _showError('ทดสอบไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _testingCameraIds.remove(cameraId));
    }
  }

  Future<void> _loadFinance() async {
    setState(() {
      _payments = null;
      _financeReport = null;
      _financeError = null;
    });
    try {
      final results = await Future.wait([
        context.read<AdminPaymentRepository>().fetchPayments(),
        context.read<AdminPaymentRepository>().fetchFinanceReport(),
      ]);
      if (!mounted) return;
      setState(() {
        _payments = results[0] as List<Map<String, dynamic>>;
        _financeReport = results[1] as Map<String, dynamic>;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _financeError = 'โหลดข้อมูลการเงินไม่สำเร็จ: $e');
    }
  }

  Future<void> _refundPayment(String paymentId) async {
    setState(() => _refundingIds.add(paymentId));
    try {
      await context.read<AdminPaymentRepository>().refundPayment(paymentId);
      await _loadFinance();
    } catch (e) {
      _showError('คืนเงินไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _refundingIds.remove(paymentId));
    }
  }

  Future<void> _addTechnician() async {
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เพิ่มบัญชีช่างใหม่'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ชื่อช่าง')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'อีเมล')),
              TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'รหัสผ่าน (อย่างน้อย 8 ตัว)')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'เบอร์โทร (ไม่บังคับ)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('สร้างบัญชี')),
        ],
      ),
    );
    if (confirmed != true) return;

    if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || passwordCtrl.text.length < 8) {
      _showError('กรุณากรอกชื่อ อีเมล และรหัสผ่านอย่างน้อย 8 ตัวอักษร');
      return;
    }

    try {
      await context.read<AdminUserRepository>().createTechnician(
            email: emailCtrl.text.trim(),
            password: passwordCtrl.text,
            name: nameCtrl.text.trim(),
            phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
          );
      await _loadTechnicians();
    } catch (e) {
      _showError('สร้างบัญชีช่างไม่สำเร็จ: $e');
    }
  }

  Future<void> _load() async {
    setState(() {
      _applications = null;
      _error = null;
    });
    try {
      final apps = await context.read<PartnerRepository>().fetchApplications(status: _statuses[_tab]);
      if (!mounted) return;
      setState(() => _applications = apps);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'โหลดคำขอไม่สำเร็จ: $e');
    }
  }

  Future<void> _approve(String id) async {
    setState(() => _busyIds.add(id));
    try {
      await context.read<PartnerRepository>().approveApplication(id);
      await _load();
    } catch (e) {
      _showError('อนุมัติไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  Future<void> _reject(String id) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ระบุเหตุผลที่ปฏิเสธ'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'เช่น เอกสารไม่ชัดเจน'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()),
            child: const Text('ยืนยันปฏิเสธ'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    setState(() => _busyIds.add(id));
    try {
      await context.read<PartnerRepository>().rejectApplication(id, reason);
      await _load();
    } catch (e) {
      _showError('ปฏิเสธไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: _bgCream,
        elevation: 0,
        foregroundColor: _darkBrown,
        leading: _section == 0
            ? null
            : IconButton(
                onPressed: () => setState(() => _section = 0),
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'กลับหน้าเมนู',
              ),
        title: Text(
            switch (_section) {
              0 => 'แผงควบคุมแอดมิน',
              1 => 'คำขอเปิดร้าน',
              2 => 'จัดการบัญชีช่าง',
              3 => 'สถานะกล้อง',
              _ => 'การเงิน',
            },
            style: const TextStyle(fontWeight: FontWeight.w700, color: _darkBrown)),
        actions: [
          if (_section == 2)
            IconButton(onPressed: _addTechnician, icon: const Icon(Icons.person_add_alt_1_rounded)),
          IconButton(
            onPressed: () async {
              await context.read<AuthService>().logout();
              if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: _section == 0
          ? _buildHomeMenu()
          : Column(
              children: [
                if (_section == 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Row(
                      children: List.generate(_statuses.length, (i) {
                        const labels = ['รอตรวจสอบ', 'อนุมัติแล้ว', 'ปฏิเสธ'];
                        final selected = i == _tab;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _tab = i);
                              _load();
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selected ? _brown : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Text(labels[i],
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: selected ? Colors.white : _mutedBrown)),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                Expanded(
                  child: switch (_section) {
                    1 => _buildBody(),
                    2 => _buildTechniciansBody(),
                    3 => _buildCameraStatusBody(),
                    _ => _buildFinanceBody(),
                  },
                ),
              ],
            ),
    );
  }

  // Big, plain-language icon cards instead of cramped tabs -- meant for
  // non-technical staff who just need "where do I click for X" at a glance.
  Widget _buildHomeMenu() {
    final items = [
      (
        icon: Icons.storefront_rounded,
        color: _brown,
        title: 'คำขอเปิดร้าน',
        subtitle: 'ตรวจสอบและอนุมัติร้านค้าที่สมัครเข้าร่วม',
        section: 1,
      ),
      (
        icon: Icons.engineering_rounded,
        color: const Color(0xFF29508A),
        title: 'บัญชีช่าง',
        subtitle: 'เพิ่ม/ลบสิทธิ์ช่างเทคนิคที่ดูแลกล้อง',
        section: 2,
      ),
      (
        icon: Icons.videocam_rounded,
        color: _green,
        title: 'สถานะกล้อง',
        subtitle: 'ดูว่ากล้องของแต่ละโรงแรมออนไลน์อยู่ไหม',
        section: 3,
      ),
      (
        icon: Icons.payments_rounded,
        color: _orange,
        title: 'การเงิน',
        subtitle: 'รายได้ ยอดชำระเงิน และคืนเงินให้ลูกค้า',
        section: 4,
      ),
    ];

    return GridView.count(
      padding: const EdgeInsets.all(20),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.95,
      children: [
        for (final item in items)
          GestureDetector(
            onTap: () => _openSection(item.section),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: _brown.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: item.color.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(item.icon, color: item.color, size: 26),
                  ),
                  const Spacer(),
                  Text(item.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _darkBrown)),
                  const SizedBox(height: 4),
                  Text(item.subtitle, style: const TextStyle(fontSize: 12, color: _mutedBrown, height: 1.35)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFinanceBody() {
    if (_financeError != null) {
      return Center(child: Text(_financeError!, style: const TextStyle(color: _mutedBrown)));
    }
    if (_payments == null || _financeReport == null) {
      return const Center(child: CircularProgressIndicator(color: _brown));
    }

    final report = _financeReport!;
    return RefreshIndicator(
      onRefresh: _loadFinance,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text('สรุปรายได้ ${report['periodDays']} วันล่าสุด',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _darkBrown)),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: [
              _statCard('รายได้รวม', '฿${(report['totalRevenueThb'] as double).toStringAsFixed(0)}', _brown),
              _statCard('ชำระสำเร็จ', '${report['successfulCount']} รายการ', _green),
              _statCard('รอดำเนินการ', '${report['pendingCount']} รายการ', _orange),
              _statCard('ไม่สำเร็จ/คืนเงิน', '${(report['failedCount'] as int) + (report['refundedCount'] as int)} รายการ', _red),
            ],
          ),
          const SizedBox(height: 20),
          const Text('รายการชำระเงินล่าสุด',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _darkBrown)),
          const SizedBox(height: 10),
          if (_payments!.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('ยังไม่มีรายการชำระเงิน', style: TextStyle(color: _mutedBrown))),
            )
          else
            ..._payments!.map(_paymentRow),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: _mutedBrown)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _paymentRow(Map<String, dynamic> payment) {
    final id = payment['id'] as String;
    final status = payment['status'] as String;
    final refunding = _refundingIds.contains(id);
    final color = _paymentStatusColors[status] ?? _mutedBrown;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _brown.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(payment['customerName'] as String? ?? 'ลูกค้า',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _darkBrown)),
                const SizedBox(height: 2),
                Text(payment['hotelName'] as String? ?? '-', style: const TextStyle(fontSize: 12, color: _mutedBrown)),
                const SizedBox(height: 4),
                Text('฿${(payment['amountThb'] as double).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _darkBrown)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Text(adminPaymentStatusLabelTh[status] ?? status,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
              ),
              if (status == 'successful') ...[
                const SizedBox(height: 6),
                refunding
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : TextButton(
                        onPressed: () => _refundPayment(id),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                        child: const Text('คืนเงิน', style: TextStyle(color: _red, fontSize: 12)),
                      ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechniciansBody() {
    if (_technicianError != null) {
      return Center(child: Text(_technicianError!, style: const TextStyle(color: _mutedBrown)));
    }
    if (_technicians == null) {
      return const Center(child: CircularProgressIndicator(color: _brown));
    }
    if (_technicians!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('ยังไม่มีบัญชีช่าง', style: TextStyle(color: _mutedBrown)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _addTechnician,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('เพิ่มบัญชีช่าง'),
              style: ElevatedButton.styleFrom(backgroundColor: _brown, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadTechnicians,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: _technicians!.length,
        itemBuilder: (ctx, i) {
          final tech = _technicians![i];
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
                  decoration: BoxDecoration(color: _brown.withValues(alpha: 0.08), shape: BoxShape.circle),
                  child: const Icon(Icons.engineering_rounded, color: _brown, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tech['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _darkBrown)),
                      const SizedBox(height: 2),
                      Text(tech['email'] as String, style: const TextStyle(fontSize: 12.5, color: _mutedBrown)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      await context.read<AdminUserRepository>().updateUserRole(tech['id'] as String, 'customer');
                      await _loadTechnicians();
                    } catch (e) {
                      _showError('ลบสิทธิ์ช่างไม่สำเร็จ: $e');
                    }
                  },
                  child: const Text('ลบสิทธิ์ช่าง', style: TextStyle(color: _red)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCameraStatusBody() {
    if (_cameraError != null) {
      return Center(child: Text(_cameraError!, style: const TextStyle(color: _mutedBrown)));
    }
    if (_cameras == null || _cameraHotels == null || _cameraTechnicians == null) {
      return const Center(child: CircularProgressIndicator(color: _brown));
    }

    final technicianNames = {
      for (final t in _cameraTechnicians!) t['id'] as String: t['name'] as String,
    };
    final camerasByHotel = <String, List<Map<String, dynamic>>>{
      for (final h in _cameraHotels!) h['id'] as String: [],
    };
    for (final cam in _cameras!) {
      final hotelId = cam['hotelId'] as String?;
      camerasByHotel.putIfAbsent(hotelId ?? '', () => []).add(cam);
    }

    if (_cameraHotels!.isEmpty) {
      return const Center(child: Text('ยังไม่มีโรงแรมในระบบ', style: TextStyle(color: _mutedBrown)));
    }

    return RefreshIndicator(
      onRefresh: _loadCameraStatus,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: _cameraHotels!.length,
        itemBuilder: (ctx, i) {
          final hotel = _cameraHotels![i];
          final cams = camerasByHotel[hotel['id'] as String] ?? const [];
          return _hotelCameraCard(hotel, cams, technicianNames);
        },
      ),
    );
  }

  Widget _hotelCameraCard(
    Map<String, dynamic> hotel,
    List<Map<String, dynamic>> cams,
    Map<String, String> technicianNames,
  ) {
    final counts = <String, int>{};
    for (final cam in cams) {
      final status = cam['status'] as String;
      counts[status] = (counts[status] ?? 0) + 1;
    }
    final summary = counts.entries
        .map((e) => '${e.value} ${_cameraStatusLabelsTh[e.key] ?? e.key}')
        .join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _brown.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hotel['name'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _darkBrown)),
          const SizedBox(height: 4),
          Text(
            cams.isEmpty ? 'ยังไม่มีกล้องติดตั้ง' : summary,
            style: const TextStyle(fontSize: 12.5, color: _mutedBrown),
          ),
          if (cams.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...cams.map((cam) => _cameraStatusRow(cam, technicianNames)),
          ],
        ],
      ),
    );
  }

  Widget _cameraStatusRow(Map<String, dynamic> cam, Map<String, String> technicianNames) {
    final id = cam['id'] as String;
    final status = cam['status'] as String;
    final techId = cam['assignedTechnicianId'] as String?;
    final techName = techId == null ? 'ยังไม่มีช่างรับผิดชอบ' : (technicianNames[techId] ?? 'ไม่ทราบชื่อช่าง');
    final lastError = cam['lastError'] as String?;
    final testing = _testingCameraIds.contains(id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(cam['name'] as String,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _darkBrown)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (_cameraStatusColors[status] ?? _mutedBrown).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_cameraStatusLabelsTh[status] ?? status,
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700, color: _cameraStatusColors[status] ?? _mutedBrown)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('ช่างรับผิดชอบ: $techName', style: const TextStyle(fontSize: 12, color: _mutedBrown)),
                if (lastError != null && lastError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(lastError, style: const TextStyle(fontSize: 11.5, color: _red)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          testing
              ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _brown))
              : IconButton(
                  onPressed: () => _testCameraConnection(id),
                  icon: const Icon(Icons.wifi_tethering_rounded, color: _brown, size: 20),
                  tooltip: 'ทดสอบการเชื่อมต่อ',
                ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: _mutedBrown)));
    }
    if (_applications == null) {
      return const Center(child: CircularProgressIndicator(color: _brown));
    }
    if (_applications!.isEmpty) {
      return const Center(child: Text('ไม่มีคำขอในหมวดนี้', style: TextStyle(color: _mutedBrown)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: _applications!.length,
        itemBuilder: (ctx, i) => _applicationCard(_applications![i]),
      ),
    );
  }

  Widget _applicationCard(Map<String, dynamic> app) {
    final id = app['id'] as String;
    final status = app['status'] as String;
    final docs = [app['docIdCardUrl'], app['docBusinessLicenseUrl'], app['docShopPhotoUrl']]
        .whereType<String>()
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _brown.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(app['shopName'] as String,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _darkBrown)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(app['serviceType'] as String,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _statusColor(status))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(app['address'] as String, style: const TextStyle(fontSize: 12.5, color: _mutedBrown)),
          const SizedBox(height: 2),
          Text(app['phone'] as String, style: const TextStyle(fontSize: 12.5, color: _mutedBrown)),
          if ((app['description'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(app['description'] as String, style: const TextStyle(fontSize: 12.5, color: _darkBrown)),
          ],
          if (status == 'rejected' && (app['rejectionReason'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text('เหตุผล: ${app['rejectionReason']}', style: const TextStyle(fontSize: 12.5, color: _red)),
          ],
          if (docs.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(width: 64, height: 64, child: PetPalImage(path: docs[i])),
                ),
              ),
            ),
          ],
          if (status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busyId(id) ? null : () => _reject(id),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: _red)),
                    child: const Text('ปฏิเสธ', style: TextStyle(color: _red, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busyId(id) ? null : () => _approve(id),
                    style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
                    child: _busyId(id)
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('อนุมัติ', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return _green;
      case 'rejected':
        return _red;
      default:
        return _orange;
    }
  }
}
