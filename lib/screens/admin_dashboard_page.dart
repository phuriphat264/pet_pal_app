// Admin shell: review and approve/reject partner (shop) applications.
// This is the real counterpart to the old client-side "(Demo) simulate
// approval" button -- only an admin account can move an application from
// pending to approved/rejected now.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/partner_repository.dart';
import '../utils/pet_pal_image.dart';

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
  int _tab = 0;
  List<Map<String, dynamic>>? _applications;
  String? _error;
  bool _busyId(String id) => _busyIds.contains(id);
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _load();
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
        title: const Text('คำขอเปิดร้าน (แอดมิน)', style: TextStyle(fontWeight: FontWeight.w700, color: _darkBrown)),
        actions: [
          IconButton(
            onPressed: () async {
              await context.read<AuthService>().logout();
              if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
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
                              fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : _mutedBrown)),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(child: _buildBody()),
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
