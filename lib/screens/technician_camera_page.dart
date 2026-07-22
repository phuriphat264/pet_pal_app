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
import 'live_cam_page.dart' show CameraFeedPage;

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
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() => _search = _searchCtrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  Map<String, dynamic> _hotelById(String hotelId) {
    return _hotels.firstWhere((h) => h['id'] == hotelId, orElse: () => const {'name': 'ไม่ทราบโรงแรม', 'images': []});
  }

  String _hotelName(String hotelId) => _hotelById(hotelId)['name'] as String? ?? 'ไม่ทราบโรงแรม';

  // Groups this technician's cameras by hotel, sorted by hotel name, so a
  // long camera list stays scannable once there are many hotels -- matches
  // the same grouping used in the admin camera-status tab.
  List<MapEntry<String, List<Map<String, dynamic>>>> get _groupedByHotel {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final cam in _cameras ?? const <Map<String, dynamic>>[]) {
      map.putIfAbsent(cam['hotelId'] as String, () => []).add(cam);
    }
    final entries = map.entries.where((e) {
      if (_search.isEmpty) return true;
      return _hotelName(e.key).toLowerCase().contains(_search);
    }).toList();
    entries.sort((a, b) => _hotelName(a.key).compareTo(_hotelName(b.key)));
    return entries;
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

  void _openEditCameraSheet(Map<String, dynamic> cam) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddCameraSheet(hotels: _hotels, onCreated: _load, existingCamera: cam),
    );
  }

  void _openSetupHelpSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _SetupHelpSheet(),
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
            onPressed: _openSetupHelpSheet,
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'วิธีติดตั้งกล้อง',
          ),
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

    final groups = _groupedByHotel;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'ค้นหาชื่อโรงแรม',
              prefixIcon: const Icon(Icons.search_rounded, color: _mutedBrown),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: _searchCtrl.clear),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: groups.isEmpty
              ? const Center(child: Text('ไม่พบโรงแรมที่ค้นหา', style: TextStyle(color: _mutedBrown)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                    itemCount: groups.length,
                    itemBuilder: (ctx, i) => _hotelGroup(groups[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _hotelGroup(MapEntry<String, List<Map<String, dynamic>>> entry) {
    final cams = entry.value;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: _brown.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Text(_hotelName(entry.key), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _darkBrown)),
            subtitle: Text('${cams.length} กล้อง', style: const TextStyle(fontSize: 12.5, color: _mutedBrown)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: cams.map(_cameraCard).toList(),
          ),
        ),
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
          Text('${cam['protocol']}://${cam['ipAddress']}:${cam['port']}${cam['streamPath'] ?? ''}',
              style: const TextStyle(fontSize: 12.5, color: _mutedBrown)),
          if ((cam['lastError'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(cam['lastError'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFFE53935))),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CameraFeedPage(hotel: _hotelById(cam['hotelId'] as String), cameras: [cam]),
                  ),
                ),
                icon: const Icon(Icons.play_circle_outline_rounded, color: _brown),
                tooltip: 'ดูสด',
              ),
              IconButton(
                onPressed: () => _openEditCameraSheet(cam),
                icon: const Icon(Icons.edit_outlined, color: _brown),
                tooltip: 'แก้ไข',
              ),
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
  final Map<String, dynamic>? existingCamera;
  const _AddCameraSheet({required this.hotels, required this.onCreated, this.existingCamera});

  @override
  State<_AddCameraSheet> createState() => _AddCameraSheetState();
}

class _AddCameraSheetState extends State<_AddCameraSheet> {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _mutedBrown = Color(0xFF9E7A60);
  static const Color _borderColor = Color(0xFFD9C5B2);

  late final _nameCtrl = TextEditingController(text: _existing?['name'] as String?);
  late final _ipCtrl = TextEditingController(text: _existing?['ipAddress'] as String?);
  late final _portCtrl = TextEditingController(text: '${_existing?['port'] ?? 554}');
  late final _streamPathCtrl = TextEditingController(text: _existing?['streamPath'] as String?);
  late final _usernameCtrl = TextEditingController(
    text: (_existing?['username'] as String?)?.isNotEmpty == true ? _existing!['username'] as String : 'petpal',
  );
  final _passwordCtrl = TextEditingController();

  Map<String, dynamic>? get _existing => widget.existingCamera;
  bool get _isEditing => _existing != null;

  late String _hotelId = (_existing?['hotelId'] as String?) ?? widget.hotels.first['id'] as String;
  late String _protocol = (_existing?['protocol'] as String?) ?? 'rtsp';
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
      if (_isEditing) {
        final updates = <String, dynamic>{
          'name': _nameCtrl.text.trim(),
          'ip_address': _ipCtrl.text.trim(),
          'port': port,
          'protocol': _protocol,
          'stream_path': _streamPathCtrl.text.trim().isEmpty ? null : _streamPathCtrl.text.trim(),
          'username': _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim(),
        };
        if (_passwordCtrl.text.trim().isNotEmpty) updates['password'] = _passwordCtrl.text.trim();
        await context.read<CameraRepository>().updateCamera(_existing!['id'] as String, updates);
      } else {
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
      }
      await widget.onCreated();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกไม่สำเร็จ: $e'), backgroundColor: Colors.redAccent),
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
                Text(_isEditing ? 'แก้ไขกล้อง' : 'เพิ่มกล้องใหม่',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _darkBrown)),
                const SizedBox(height: 16),
                _label('โรงแรม'),
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      widget.hotels.firstWhere((h) => h['id'] == _hotelId, orElse: () => const {'name': 'ไม่ทราบโรงแรม'})['name']
                          as String,
                      style: const TextStyle(fontSize: 14, color: _darkBrown, fontWeight: FontWeight.w600),
                    ),
                  )
                else
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
                _field('ชื่อผู้ใช้', _usernameCtrl, hint: 'petpal'),
                const SizedBox(height: 12),
                _field('รหัสผ่าน${_isEditing ? ' (เว้นว่างถ้าไม่เปลี่ยน)' : ' (ถ้ามี)'}', _passwordCtrl,
                    hint: '••••••', obscure: true),
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
                        : Text(_isEditing ? 'บันทึกการแก้ไข' : 'บันทึกกล้อง', style: const TextStyle(fontWeight: FontWeight.w700)),
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

// Step-by-step onboarding guide for a technician wiring up a new Tapo C210 --
// matches the app's actual current flow (direct RTSP credentials entered
// here), not the future edge-server/MediaMTX architecture described in the
// camera-feature spec doc, which hasn't been built yet.
class _SetupHelpSheet extends StatelessWidget {
  const _SetupHelpSheet();

  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _mutedBrown = Color(0xFF9E7A60);

  static const List<(String, String)> _steps = [
    (
      'เชื่อมกล้องเข้า WiFi โรงแรม',
      'เปิดแอป Tapo บนมือถือ → เพิ่มอุปกรณ์ใหม่ → สแกน QR ที่ตัวกล้อง C210 → เชื่อมกล้องเข้า WiFi ของโรงแรมนั้น (ใช้บัญชี Tapo cloud login ได้บัญชีเดียวกับทุกโรงแรม ไม่ต้องสมัครใหม่ทุกที่)',
    ),
    (
      'สร้างบัญชี RTSP แยกในกล้อง',
      'ในแอป Tapo เข้า การตั้งค่าขั้นสูง (Advanced Settings) > Camera Account แล้วตั้ง username/password สำหรับ RTSP โดยเฉพาะ (คนละชุดกับบัญชี Tapo cloud) — credential ชุดนี้ต้องใช้กรอกในแอปนี้',
    ),
    (
      'หา IP address ของกล้อง',
      'ดูได้จากหน้าตั้งค่า router ของโรงแรม หรือในแอป Tapo > การตั้งค่าอุปกรณ์ > สถานะเครือข่าย แนะนำให้ตั้งเป็น IP แบบจอง (static/reserved) ที่ router จะได้ไม่เปลี่ยนภายหลัง',
    ),
    (
      'เพิ่มกล้องในแอปนี้',
      'กดปุ่ม + มุมล่างขวา เลือกโรงแรม กรอกชื่อกล้อง, IP address, Port (ปกติ 554), เลือก Protocol เป็น RTSP แล้วใส่ username/password ที่สร้างไว้ในขั้นตอนที่ 2',
    ),
    (
      'ทดสอบการเชื่อมต่อ',
      'กด "บันทึกกล้อง" แล้วกด "ทดสอบการเชื่อมต่อ" ที่การ์ดกล้อง ถ้าขึ้น "เชื่อมต่อสำเร็จ" คือเสร็จเรียบร้อย ลูกค้าที่จองห้องนี้จะดูกล้องได้ทันที',
    ),
  ];

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
                const Text('วิธีติดตั้งกล้องใหม่', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _darkBrown)),
                const SizedBox(height: 4),
                const Text('สำหรับกล้อง TP-Link Tapo C210', style: TextStyle(fontSize: 13, color: _mutedBrown)),
                const SizedBox(height: 20),
                for (var i = 0; i < _steps.length; i++) _stepTile(i + 1, _steps[i].$1, _steps[i].$2),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _brown.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: _brown, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ไม่ต้องกังวลเรื่องโควตาสตรีมพร้อมกันของกล้อง (main stream 2 สาย + sub stream 2 สาย) เพราะระบบเปิดให้ลูกค้าดูได้ทีละ 1 คนต่อห้องอยู่แล้ว',
                          style: TextStyle(fontSize: 12.5, color: _darkBrown, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stepTile(int number, String title, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: _brown, shape: BoxShape.circle),
            child: Text('$number', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _darkBrown)),
                const SizedBox(height: 4),
                Text(detail, style: const TextStyle(fontSize: 13, color: _mutedBrown, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
