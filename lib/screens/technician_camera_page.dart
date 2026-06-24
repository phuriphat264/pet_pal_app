// Technician shell: register and manage IP cameras for hotels/rooms.
// No real camera hardware exists yet -- "test connection" performs a real
// TCP-reachability probe on the backend, not a video stream; this screen
// is the registration/management system the technician will use once
// physical cameras are actually wired up.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/camera_repository.dart';
import '../services/hotel_repository.dart';

const Map<String, Color> _statusColors = {
  'online': Color(0xFF4CAF50),
  'offline': Color(0xFF9E7A60),
  'error': Color(0xFFE53935),
  'unregistered': Color(0xFFFB8C00),
};

const Map<String, String> _statusLabelsTh = {
  'online': 'ออนไลน์',
  'offline': 'ออฟไลน์',
  'error': 'มีปัญหา',
  'unregistered': 'ยังไม่ทดสอบ',
};

class TechnicianCameraPage extends StatefulWidget {
  const TechnicianCameraPage({super.key});

  @override
  State<TechnicianCameraPage> createState() => _TechnicianCameraPageState();
}

class _TechnicianCameraPageState extends State<TechnicianCameraPage> {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _mutedBrown = Color(0xFF9E7A60);

  List<Map<String, dynamic>>? _cameras;
  List<Map<String, dynamic>> _hotels = [];
  String? _error;
  final Set<String> _testingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _cameras = null;
      _error = null;
    });
    try {
      final hotels = await context.read<HotelRepository>().fetchHotels(availableOnly: false);
      final cameras = await context.read<CameraRepository>().fetchCameras();
      if (!mounted) return;
      setState(() {
        _hotels = hotels;
        _cameras = cameras;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'โหลดข้อมูลไม่สำเร็จ: $e');
    }
  }

  String _hotelName(String hotelId) {
    final hotel = _hotels.firstWhere((h) => h['id'] == hotelId, orElse: () => const {});
    return hotel['name'] as String? ?? 'ไม่ทราบโรงแรม';
  }

  Future<void> _testConnection(String cameraId) async {
    setState(() => _testingIds.add(cameraId));
    try {
      final result = await context.read<CameraRepository>().testConnection(cameraId);
      if (!mounted) return;
      setState(() {
        final idx = _cameras!.indexWhere((c) => c['id'] == cameraId);
        if (idx != -1) _cameras![idx] = result['camera'] as Map<String, dynamic>;
      });
      final success = result['success'] as bool;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'เชื่อมต่อสำเร็จ' : 'เชื่อมต่อไม่สำเร็จ: ${result['message']}'),
        backgroundColor: success ? const Color(0xFF4CAF50) : Colors.redAccent,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ทดสอบไม่สำเร็จ: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _testingIds.remove(cameraId));
    }
  }

  Future<void> _deleteCamera(String cameraId) async {
    try {
      await context.read<CameraRepository>().deleteCamera(cameraId);
      if (!mounted) return;
      setState(() => _cameras!.removeWhere((c) => c['id'] == cameraId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบไม่สำเร็จ: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _openAddCameraSheet() {
    if (_hotels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่มีโรงแรมในระบบให้เลือก')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddCameraSheet(hotels: _hotels, onCreated: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: _bgCream,
        elevation: 0,
        foregroundColor: _darkBrown,
        title: const Text('จัดการกล้อง (ช่าง)', style: TextStyle(fontWeight: FontWeight.w700, color: _darkBrown)),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: _brown,
        onPressed: _openAddCameraSheet,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: _mutedBrown)));
    }
    if (_cameras == null) {
      return const Center(child: CircularProgressIndicator(color: _brown));
    }
    if (_cameras!.isEmpty) {
      return const Center(child: Text('ยังไม่มีกล้องในระบบ — แตะปุ่ม + เพื่อเพิ่ม', style: TextStyle(color: _mutedBrown)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
        itemCount: _cameras!.length,
        itemBuilder: (ctx, i) => _cameraCard(_cameras![i]),
      ),
    );
  }

  Widget _cameraCard(Map<String, dynamic> cam) {
    final id = cam['id'] as String;
    final status = cam['status'] as String;
    final testing = _testingIds.contains(id);

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
                child: Text(cam['name'] as String,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _darkBrown)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (_statusColors[status] ?? _mutedBrown).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_statusLabelsTh[status] ?? status,
                    style: TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w700, color: _statusColors[status] ?? _mutedBrown)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(_hotelName(cam['hotelId'] as String), style: const TextStyle(fontSize: 12.5, color: _mutedBrown)),
          const SizedBox(height: 2),
          Text('${cam['protocol']}://${cam['ipAddress']}:${cam['port']}${cam['streamPath'] ?? ''}',
              style: const TextStyle(fontSize: 12.5, color: _mutedBrown)),
          if ((cam['lastError'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(cam['lastError'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFFE53935))),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: testing ? null : () => _testConnection(id),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: _brown)),
                  child: testing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('ทดสอบการเชื่อมต่อ', style: TextStyle(color: _brown, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () => _deleteCamera(id),
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE53935)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddCameraSheet extends StatefulWidget {
  final List<Map<String, dynamic>> hotels;
  final Future<void> Function() onCreated;
  const _AddCameraSheet({required this.hotels, required this.onCreated});

  @override
  State<_AddCameraSheet> createState() => _AddCameraSheetState();
}

class _AddCameraSheetState extends State<_AddCameraSheet> {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _mutedBrown = Color(0xFF9E7A60);
  static const Color _borderColor = Color(0xFFD9C5B2);

  final _nameCtrl = TextEditingController();
  final _ipCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '554');
  final _streamPathCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  late String _hotelId = widget.hotels.first['id'] as String;
  String _protocol = 'rtsp';
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ipCtrl.dispose();
    _portCtrl.dispose();
    _streamPathCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _ipCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อกล้องและ IP address'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    final port = int.tryParse(_portCtrl.text.trim()) ?? 554;

    setState(() => _submitting = true);
    try {
      await context.read<CameraRepository>().createCamera(
            hotelId: _hotelId,
            name: _nameCtrl.text.trim(),
            ipAddress: _ipCtrl.text.trim(),
            port: port,
            protocol: _protocol,
            streamPath: _streamPathCtrl.text.trim().isEmpty ? null : _streamPathCtrl.text.trim(),
            username: _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim(),
            password: _passwordCtrl.text.trim().isEmpty ? null : _passwordCtrl.text.trim(),
          );
      await widget.onCreated();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เพิ่มกล้องไม่สำเร็จ: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _bgCream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('เพิ่มกล้องใหม่', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _darkBrown)),
                const SizedBox(height: 16),
                _label('โรงแรม'),
                _dropdown(
                  value: _hotelId,
                  items: widget.hotels.map((h) => h['id'] as String).toList(),
                  labelFor: (id) => widget.hotels.firstWhere((h) => h['id'] == id)['name'] as String,
                  onChanged: (v) => setState(() => _hotelId = v!),
                ),
                const SizedBox(height: 12),
                _field('ชื่อกล้อง', _nameCtrl, hint: 'เช่น กล้องห้อง VIP 1'),
                const SizedBox(height: 12),
                _field('IP Address', _ipCtrl, hint: 'เช่น 192.168.1.50'),
                const SizedBox(height: 12),
                _field('Port', _portCtrl, hint: '554', keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _label('โปรโตคอล'),
                Wrap(
                  spacing: 8,
                  children: ['rtsp', 'http', 'onvif'].map((p) {
                    final selected = p == _protocol;
                    return GestureDetector(
                      onTap: () => setState(() => _protocol = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: selected ? _brown : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? _brown : _borderColor),
                        ),
                        child: Text(p.toUpperCase(),
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : _mutedBrown)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                _field('Stream path (ถ้ามี)', _streamPathCtrl, hint: '/stream1'),
                const SizedBox(height: 12),
                _field('ชื่อผู้ใช้ (ถ้ามี)', _usernameCtrl, hint: 'admin'),
                const SizedBox(height: 12),
                _field('รหัสผ่าน (ถ้ามี)', _passwordCtrl, hint: '••••••', obscure: true),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: _brown, foregroundColor: Colors.white),
                    child: _submitting
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('บันทึกกล้อง', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 12, color: _mutedBrown, fontWeight: FontWeight.w500)),
      );

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, TextInputType? keyboardType, bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _borderColor)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required String Function(String) labelFor,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((id) => DropdownMenuItem(value: id, child: Text(labelFor(id)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
