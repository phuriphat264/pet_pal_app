// lib/screens/pet_profile_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/booking_repository.dart';
import '../services/hotel_repository.dart';
import '../services/partner_repository.dart';
import '../services/pet_repository.dart';
import 'hotel_list_page.dart';
import 'hotel_partner_application_page.dart';
import 'partner_status_page.dart';
import 'hotel_dashboard_page.dart';

const List<String> _thaiMonthsAbbr = [
  'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
  'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
];

String _thaiShortDate(DateTime d) {
  final suffix = d.year == DateTime.now().year ? '' : ' ${(d.year + 543) % 100}';
  return '${d.day} ${_thaiMonthsAbbr[d.month - 1]}$suffix';
}

String _thaiStayRange(DateTime checkIn, DateTime checkOut) {
  if (checkIn.year == checkOut.year && checkIn.month == checkOut.month) {
    final suffix = checkIn.year == DateTime.now().year ? '' : ' ${(checkIn.year + 543) % 100}';
    return '${checkIn.day}-${checkOut.day} ${_thaiMonthsAbbr[checkIn.month - 1]}$suffix';
  }
  return '${_thaiShortDate(checkIn)} - ${_thaiShortDate(checkOut)}';
}

class PetProfilePage extends StatefulWidget {
  const PetProfilePage({super.key});

  @override
  State<PetProfilePage> createState() => _PetProfilePageState();
}

class _PetProfilePageState extends State<PetProfilePage> {
  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _bgCard = Color(0xFFEDE2D5);
  static const Color _bgLight = Color(0xFFE8D8C8);
  static const Color _mutedBrown = Color(0xFF9E7A60);
  static const Color _borderColor = Color(0xFFD9C5B2);

  int _selectedPet = 0;
  List<Map<String, dynamic>>? _pets;
  String? _error;
  Map<String, dynamic>? _partnerApp;
  bool _partnerLoading = true;
  List<Map<String, dynamic>>? _upcomingStays;

  @override
  void initState() {
    super.initState();
    _loadPets();
    _loadPartnerApp();
    _loadUpcomingStays();
  }

  // Pulls every booking, keeps only the ones that haven't checked out yet
  // and weren't cancelled, then resolves each hotel_id to a hotel name so
  // the "next stay" card can show real data instead of the old hardcoded
  // "15 เม.ย. นี้ ที่ Paw Paradise Resort" placeholder.
  Future<void> _loadUpcomingStays() async {
    final bookingRepo = context.read<BookingRepository>();
    final hotelRepo = context.read<HotelRepository>();
    try {
      final bookings = await bookingRepo.fetchMyBookings();
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      final upcoming = bookings.where((b) {
        final status = b['status'] as String?;
        if (status == 'cancelled' || status == 'completed') return false;
        final checkOut = DateTime.tryParse(b['check_out'] as String? ?? '');
        return checkOut != null && !checkOut.isBefore(todayDate);
      }).toList();

      final hotelNames = <String, String>{};
      for (final hotelId in upcoming.map((b) => b['hotel_id'] as String).toSet()) {
        try {
          final hotel = await hotelRepo.fetchHotel(hotelId);
          hotelNames[hotelId] = hotel['name'] as String? ?? 'โรงแรม';
        } catch (_) {
          hotelNames[hotelId] = 'โรงแรม';
        }
      }

      final resolved = upcoming.map((b) {
        return {
          'petId': b['pet_id'] as String?,
          'hotelName': hotelNames[b['hotel_id']] ?? 'โรงแรม',
          'checkIn': DateTime.parse(b['check_in'] as String),
          'checkOut': DateTime.parse(b['check_out'] as String),
          'status': b['status'] as String,
        };
      }).toList()
        ..sort((a, b) => (a['checkIn'] as DateTime).compareTo(b['checkIn'] as DateTime));

      if (!mounted) return;
      setState(() => _upcomingStays = resolved);
    } catch (_) {
      if (!mounted) return;
      setState(() => _upcomingStays = []);
    }
  }

  Future<void> _loadPets() async {
    setState(() => _error = null);
    try {
      final pets = await context.read<PetRepository>().fetchPets();
      if (!mounted) return;
      setState(() {
        _pets = pets;
        if (_selectedPet >= pets.length) _selectedPet = 0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'โหลดข้อมูลน้องไม่สำเร็จ ลองใหม่อีกครั้ง');
    }
  }

  Future<void> _loadPartnerApp() async {
    try {
      final app = await context.read<PartnerRepository>().fetchMyApplication();
      if (!mounted) return;
      setState(() {
        _partnerApp = app;
        _partnerLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _partnerLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBanner(),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildPartnerCard(),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildPetSection(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPetSection() {
    if (_error != null) {
      return Column(
        children: [
          Text(_error!, style: const TextStyle(color: _mutedBrown)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _loadPets, child: const Text('ลองใหม่')),
        ],
      );
    }
    if (_pets == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: _brown)),
      );
    }
    if (_pets!.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader('🐾 โปรไฟล์น้อง'),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                const Text('ยังไม่มีข้อมูลน้อง', style: TextStyle(color: _mutedBrown)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _showAddPetSheet,
                  style: ElevatedButton.styleFrom(backgroundColor: _brown),
                  child: const Text('เพิ่มน้อง', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final pet = _pets![_selectedPet];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(pet),
        _buildSectionHeader('🏥 สุขภาพและร่างกาย'),
        _buildHealthCards(pet),
        _buildTraitsSection(pet),
        _buildSectionHeader('⚡ กิจกรรมและการนอน'),
        _buildActivitySection(pet),
        _buildSectionHeader('📋 ข้อมูลทั่วไป'),
        _buildInfoSection(pet),
        _buildSectionHeader('🏥 ประวัติการรักษา'),
        _buildMedHistorySection(pet),
        _buildVetSection(pet),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader(Map<String, dynamic> pet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSectionHeader('🐾 โปรไฟล์น้อง'),
            GestureDetector(
              onTap: _showAddPetSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _brown,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: _brown.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('เพิ่มน้อง', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: _brown.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 84, height: 84,
                    decoration: BoxDecoration(
                      color: (pet['color'] as Color).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Icon(pet['icon'] as IconData, size: 42, color: _brown)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pet['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _darkBrown)),
                        const SizedBox(height: 2),
                        Text(pet['breed'], style: const TextStyle(fontSize: 15, color: _mutedBrown)),
                        const SizedBox(height: 4),
                        Text('เกิด ${pet['dob']}', style: const TextStyle(fontSize: 13, color: _mutedBrown)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 5, runSpacing: 4,
                          children: [
                            _petTag(pet['gender'] == 'ชาย' ? '♂ ชาย' : '♀ หญิง', pet['gender'] == 'ชาย' ? const Color(0xFF1A6FA8) : const Color(0xFFA81A6F)),
                            _petTag(pet['age'], _brown),
                            _petTag(pet['weight'], _mutedBrown),
                            _petTag(pet['neutered'], const Color(0xFF4CAF50)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showEditPetSheet(pet),
                    child: Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(color: _bgLight, shape: BoxShape.circle),
                      child: const Icon(Icons.edit_outlined, color: _brown, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildPetSelector(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _petTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }

  // ── Pet Selector ──────────────────────────────────────────────
  Widget _buildPetSelector() {
    final pets = _pets!;
    if (pets.length <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Row(
        children: List.generate(pets.length, (i) {
          final selected = i == _selectedPet;
          final isLast = i == pets.length - 1;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPet = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: isLast ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? _brown : _bgCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(pets[i]['icon'] as IconData, size: 18, color: selected ? Colors.white : _mutedBrown),
                    const SizedBox(width: 8),
                    Text(pets[i]['name'],
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : _mutedBrown)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Health Cards ──────────────────────────────────────────────
  Widget _buildHealthCards(Map<String, dynamic> pet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GridView.count(
        padding: EdgeInsets.zero,
        crossAxisCount: 2, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12, mainAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: [
          _statCard('น้ำหนัก', pet['weight'], Icons.scale_rounded, const Color(0xFF1E88E5)),
          _statCard('ส่วนสูง', pet['height'], Icons.straighten_rounded, const Color(0xFFFB8C00)),
          _statCard('อุณหภูมิ', pet['temp'], Icons.thermostat_rounded, const Color(0xFFE53935)),
          _statCard('ชีพจร', pet['heartRate'], Icons.favorite_rounded, const Color(0xFFD81B60)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
                Text(label, style: const TextStyle(fontSize: 12, color: _mutedBrown)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Traits Section ────────────────────────────────────────────
  Widget _buildTraitsSection(Map<String, dynamic> pet) {
    final traits = pet['traits'] as List<String>;
    final traitEmojis = {
      'ขี้เล่น': '🎾', 'ชอบน้ำ': '🏊', 'เป็นมิตร': '🤝',
      'กระฉับกระเฉง': '⚡', 'เงียบๆ': '😶', 'ขี้อาย': '🙈',
      'ชอบนอน': '🛋️', 'ฉลาด': '🧠', 'ชอบธรรมชาติ': '🌿',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (traits.isEmpty)
              const Text('ยังไม่ได้เลือกนิสัยของน้อง แก้ไขได้ที่ปุ่มแก้ไขด้านบน',
                  style: TextStyle(color: _mutedBrown, fontSize: 14)),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: traits.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _borderColor, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(traitEmojis[t] ?? '✨', style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 5),
                    Text(t, style: const TextStyle(fontSize: 14, color: _brown, fontWeight: FontWeight.w600)),
                  ],
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Activity Section ──────────────────────────────────────────
  Widget _buildActivitySection(Map<String, dynamic> pet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: (pet['activities'] as List).map((a) => Column(
                children: [
                  Text(a['value'],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _darkBrown)),
                  const SizedBox(height: 2),
                  Text(a['label'], style: const TextStyle(fontSize: 14, color: _mutedBrown)),
                ],
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Section ──────────────────────────────────────────────
  Widget _buildInfoSection(Map<String, dynamic> pet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('🪪 ไมโครชิป', pet['chip']),
            _infoRow('🍽️ อาหาร', pet['food']),
            _infoRow('⏰ มื้ออาหาร', pet['feedingTimes']),
            _infoRow('⚠️ แพ้', pet['allergies']),
            _infoRow('💉 วัคซีน', pet['vaccine']),
            _infoRow('✂️ ทำหมัน', pet['neutered']),
            _infoRow('🎨 สี', pet['color_desc']),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: _mutedBrown)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _darkBrown)),
        ],
      ),
    );
  }

  // ── Medical History ───────────────────────────────────────────
  Widget _buildMedHistorySection(Map<String, dynamic> pet) {
    final history = pet['medHistory'] as List;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('ยังไม่มีประวัติการรักษา', style: TextStyle(color: _mutedBrown, fontSize: 14)),
              ),
            ...List.generate(history.length, (i) {
              final h = history[i];
              final isLast = i == history.length - 1;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: _brown,
                          shape: BoxShape.circle,
                          border: Border.all(color: _bgLight, width: 2),
                        ),
                      ),
                      if (!isLast)
                        Container(width: 1.5, height: 40, color: _borderColor),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _bgCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h['event'],
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _darkBrown)),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 14, color: _mutedBrown),
                              const SizedBox(width: 4),
                              Text(h['date'], style: const TextStyle(fontSize: 13, color: _mutedBrown)),
                              const SizedBox(width: 8),
                              const Icon(Icons.local_hospital_outlined, size: 14, color: _mutedBrown),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(h['vet'],
                                    style: const TextStyle(fontSize: 13, color: _mutedBrown),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showAddMedicalHistorySheet(pet),
                icon: const Icon(Icons.add_circle_outline, size: 18, color: _brown),
                label: const Text('เพิ่มประวัติการรักษา', style: TextStyle(color: _brown)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMedicalHistorySheet(Map<String, dynamic> pet) {
    final eventCtrl = TextEditingController();
    final vetCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: _borderColor, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text('เพิ่มประวัติการรักษา${pet['name'] != null ? ' - ${pet['name']}' : ''}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
              const SizedBox(height: 16),
              Text('วันที่', style: const TextStyle(fontSize: 12, color: _mutedBrown, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setSheetState(() => selectedDate = picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Text(
                        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 14, color: _darkBrown),
                      ),
                      const Spacer(),
                      const Icon(Icons.calendar_today_outlined, size: 16, color: _mutedBrown),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _inputField('เหตุการณ์ / การรักษา', ctrl: eventCtrl, hint: 'เช่น ฉีดวัคซีนพิษสุนัขบ้า'),
              const SizedBox(height: 10),
              _inputField('สัตวแพทย์ / คลินิก (ไม่บังคับ)', ctrl: vetCtrl),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (eventCtrl.text.trim().isEmpty) return;
                    try {
                      await context.read<PetRepository>().addMedicalHistory(
                            petId: pet['id'] as String,
                            date:
                                '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                            event: eventCtrl.text.trim(),
                            vet: vetCtrl.text.trim(),
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _loadPets();
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brown,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('บันทึก', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Vet Section ───────────────────────────────────────────────
  Widget _buildVetSection(Map<String, dynamic> pet) {
    if (_upcomingStays == null) {
      return _vetCardShell(
        child: const Center(
          child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
        ),
      );
    }

    final stays = _upcomingStays!.where((s) => s['petId'] == pet['id']).toList();

    if (stays.isEmpty) {
      return _vetCardShell(
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.hotel_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('ยังไม่มีรอบฝากเลี้ยงที่จะถึง',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HotelListPage())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Text('จองที่พัก', style: TextStyle(color: _brown, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }

    if (stays.length == 1) {
      return _vetCardShell(child: _stayRow(stays.first));
    }

    return _vetCardShell(
      child: _StayCarousel(key: ValueKey(pet['id']), stays: stays, stayRowBuilder: _stayRow),
    );
  }

  Widget _vetCardShell({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _brown,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: _brown.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: child,
      ),
    );
  }

  Widget _stayRow(Map<String, dynamic> stay) {
    final checkIn = stay['checkIn'] as DateTime;
    final checkOut = stay['checkOut'] as DateTime;
    final label = stay['status'] == 'pending' ? 'รอบฝากเลี้ยงถัดไป (รอยืนยัน)' : 'รอบฝากเลี้ยงถัดไป';
    return Row(
      children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.hotel_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70), overflow: TextOverflow.ellipsis),
              Text(_thaiStayRange(checkIn, checkOut),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('ที่ ${stay['hotelName']}',
                  style: const TextStyle(fontSize: 12, color: Colors.white60), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('📅 บันทึกในปฏิทินแล้ว'),
                backgroundColor: _brown, duration: Duration(seconds: 1)),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Text('ตั้งเตือน', style: TextStyle(color: _brown, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ── Add Pet Sheet (ละเอียดขึ้น) ──────────────────────────────
  void _showAddPetSheet() {
    // นิสัยทั้งหมดที่เลือกได้
    final allTraits = ['ขี้เล่น', 'ชอบน้ำ', 'เป็นมิตร', 'กระฉับกระเฉง',
      'เงียบๆ', 'ขี้อาย', 'ชอบนอน', 'ฉลาด', 'ชอบธรรมชาติ'];
    final selectedTraits = <String>{};

    final nameCtrl = TextEditingController();
    final breedCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final foodCtrl = TextEditingController();
    final allergiesCtrl = TextEditingController();
    String selectedGender = 'ชาย';
    String selectedNeutered = 'ยังไม่ได้ทำหมัน';

    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          maxChildSize: 0.95,
          builder: (_, controller) => SingleChildScrollView(
            controller: controller,
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // handle bar
                Center(
                  child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: _borderColor, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                const Text('เพิ่มน้องใหม่',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
                const SizedBox(height: 4),
                const Text('กรอกข้อมูลน้องให้ครบเพื่อการดูแลที่ดีที่สุด',
                    style: TextStyle(fontSize: 12, color: _mutedBrown)),
                const SizedBox(height: 20),

                // ── ข้อมูลพื้นฐาน ─────────────────────────────
                _sectionLabel('📋 ข้อมูลพื้นฐาน'),
                const SizedBox(height: 10),
                _inputField('ชื่อน้อง', ctrl: nameCtrl, hint: 'เช่น มะม่วง'),
                const SizedBox(height: 10),
                _inputField('สายพันธุ์', ctrl: breedCtrl, hint: 'เช่น โกลเด้นรีทรีฟเวอร์'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _inputField('อายุ', ctrl: ageCtrl, hint: 'เช่น 3 ปี')),
                    const SizedBox(width: 10),
                    Expanded(child: _inputField('น้ำหนัก', ctrl: weightCtrl, hint: 'เช่น 28 กก.')),
                  ],
                ),
                const SizedBox(height: 10),

                // เพศ
                const Text('เพศ', style: TextStyle(fontSize: 12, color: _mutedBrown, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  children: ['ชาย', 'หญิง'].map((g) => Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => selectedGender = g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: EdgeInsets.only(right: g == 'ชาย' ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedGender == g ? _brown : _bgCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(g == 'ชาย' ? '♂ ชาย' : '♀ หญิง',
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: selectedGender == g ? Colors.white : _mutedBrown,
                              )),
                        ),
                      ),
                    ),
                  )).toList(),
                ),

                const SizedBox(height: 20),

                // ── สุขภาพ ────────────────────────────────────
                _sectionLabel('💊 สุขภาพ & อาหาร'),
                const SizedBox(height: 10),
                _inputField('อาหารที่กิน', ctrl: foodCtrl, hint: 'เช่น Royal Canin Adult'),
                const SizedBox(height: 10),
                _inputField('สิ่งที่แพ้', ctrl: allergiesCtrl, hint: 'เช่น ไก่ หรือ ไม่มี'),
                const SizedBox(height: 10),
                // ทำหมัน
                const Text('ทำหมัน', style: TextStyle(fontSize: 12, color: _mutedBrown, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  children: ['ทำหมันแล้ว', 'ยังไม่ได้ทำหมัน'].map((n) => Expanded(
                    child: GestureDetector(
                      onTap: () => setModalState(() => selectedNeutered = n),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: EdgeInsets.only(right: n == 'ทำหมันแล้ว' ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: selectedNeutered == n ? _brown : _bgCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(n,
                              style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600,
                                color: selectedNeutered == n ? Colors.white : _mutedBrown,
                              )),
                        ),
                      ),
                    ),
                  )).toList(),
                ),

                const SizedBox(height: 20),

                // ── นิสัย ─────────────────────────────────────
                _sectionLabel('🐾 นิสัยน้อง'),
                const SizedBox(height: 4),
                const Text('เลือกได้หลายอัน', style: TextStyle(fontSize: 11, color: _mutedBrown)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: allTraits.map((t) {
                    final sel = selectedTraits.contains(t);
                    return GestureDetector(
                      onTap: () => setModalState(() {
                        sel ? selectedTraits.remove(t) : selectedTraits.add(t);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: sel ? _brown : _bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? _brown : _borderColor),
                        ),
                        child: Text(t,
                            style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : _mutedBrown,
                            )),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),

                // ── บันทึก ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      try {
                        await context.read<PetRepository>().createPet(
                              name: name,
                              breed: breedCtrl.text.trim().isEmpty ? 'ไม่ระบุสายพันธุ์' : breedCtrl.text.trim(),
                              age: ageCtrl.text.trim().isEmpty ? 'ไม่ระบุอายุ' : ageCtrl.text.trim(),
                              weight: weightCtrl.text.trim().isEmpty ? '-' : weightCtrl.text.trim(),
                              gender: selectedGender,
                              neutered: selectedNeutered,
                              food: foodCtrl.text.trim().isEmpty ? 'ไม่ระบุ' : foodCtrl.text.trim(),
                              allergies: allergiesCtrl.text.trim().isEmpty ? 'ไม่มี' : allergiesCtrl.text.trim(),
                              traits: selectedTraits.toList(),
                            );
                        await _loadPets();
                        if (!mounted) return;
                        setState(() => _selectedPet = (_pets?.length ?? 1) - 1);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('🐾 เพิ่มน้อง $name แล้ว!'),
                              backgroundColor: _brown, duration: const Duration(seconds: 2)),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('เพิ่มน้องไม่สำเร็จ: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brown,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: const Text('บันทึกข้อมูลน้อง',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _brown,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'โปรไฟล์เจ้าของ',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: const BoxDecoration(color: _brown, shape: BoxShape.circle),
                      child: const Center(child: Icon(Icons.pets_rounded, color: Colors.white, size: 32)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.watch<AuthService>().currentUser?.name ?? 'ผู้ใช้',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown),
                              overflow: TextOverflow.ellipsis),
                          Text(context.watch<AuthService>().currentUser?.email ?? '',
                              style: const TextStyle(fontSize: 13, color: _mutedBrown),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _showEditProfileSheet,
                      icon: const Icon(Icons.edit_outlined, color: _brown, size: 20),
                    ),
                  ],
                ),
                const Divider(height: 24, color: _bgCream),
                _ownerActionTile(Icons.assignment_ind_outlined, 'ข้อมูลบัญชี', _showEditProfileSheet),
                _ownerActionTile(
                  Icons.lock_outline_rounded,
                  context.watch<AuthService>().currentUser?.hasPassword == true
                      ? 'เปลี่ยนรหัสผ่าน'
                      : 'ตั้งรหัสผ่าน (เข้าสู่ระบบด้วยอีเมลได้)',
                  _showSetPasswordSheet,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await context.read<AuthService>().logout();
                      if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    label: const Text('ออกจากระบบ',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Partner / Shop Owner Entry Point ───────────────────────────
  Widget _buildPartnerCard() {
    if (_partnerLoading) return const SizedBox.shrink();

    final status = _partnerApp?['status'] as String? ?? 'none';

    IconData icon;
    String title;
    String subtitle;
    VoidCallback onTap;

    switch (status) {
      case 'pending':
        icon = Icons.hourglass_top_rounded;
        title = 'ติดตามสถานะการสมัครเปิดร้าน';
        subtitle = 'คำขอของคุณอยู่ระหว่างตรวจสอบเอกสาร';
        onTap = () => _openPartnerPage(const PartnerStatusPage());
        break;
      case 'rejected':
        icon = Icons.hourglass_top_rounded;
        title = 'คำขอเปิดร้านไม่ผ่านการอนุมัติ';
        subtitle = 'แตะเพื่อดูรายละเอียดและส่งคำขอใหม่';
        onTap = () => _openPartnerPage(const PartnerStatusPage());
        break;
      case 'approved':
        icon = Icons.storefront_rounded;
        title = 'จัดการร้านของฉัน';
        final shopName = _partnerApp?['shopName'] as String? ?? '';
        subtitle = shopName.isEmpty ? 'เจ้าของร้าน · PetPal Partner' : '$shopName · เจ้าของร้าน';
        onTap = () => _openPartnerPage(const HotelDashboardPage());
        break;
      default:
        icon = Icons.storefront_rounded;
        title = 'สมัครเปิดร้านกับ PetPal';
        subtitle = 'เป็นพาร์ทเนอร์โรงแรม/ร้านดูแลสัตว์เลี้ยง รับลูกค้าผ่านแอป';
        onTap = () => _openPartnerPage(const HotelPartnerApplicationPage());
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _brown,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _brown.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  void _openPartnerPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) {
      if (mounted) _loadPartnerApp();
    });
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4, height: 18,
            decoration: BoxDecoration(color: _brown, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
        ],
      ),
    );
  }

  // ── Owner Section ─────────────────────────────────────────────

  Widget _ownerActionTile(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _brown),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontSize: 15, color: _darkBrown, fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, size: 20, color: _mutedBrown),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet() {
    final auth = context.read<AuthService>();
    final nameCtrl = TextEditingController(text: auth.currentUser?.name ?? '');
    final phoneCtrl = TextEditingController(text: auth.currentUser?.phone ?? '');
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: _borderColor, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('แก้ไขข้อมูลบัญชี', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
            const SizedBox(height: 16),
            _inputField('ชื่อ', ctrl: nameCtrl),
            const SizedBox(height: 10),
            _inputField('เบอร์โทร', ctrl: phoneCtrl),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await auth.updateProfile(
                      name: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brown,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('บันทึก', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetPasswordSheet() {
    final auth = context.read<AuthService>();
    final hasPassword = auth.currentUser?.hasPassword == true;
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    bool submitting = false;
    String? error;

    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> submit() async {
            if (newCtrl.text.length < 8) {
              setSheetState(() => error = 'รหัสผ่านใหม่ต้องมีอย่างน้อย 8 ตัวอักษร');
              return;
            }
            setSheetState(() {
              submitting = true;
              error = null;
            });
            try {
              await auth.setPassword(
                currentPassword: hasPassword ? currentCtrl.text : null,
                newPassword: newCtrl.text,
              );
              await auth.refreshCurrentUser();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(hasPassword ? '🔑 เปลี่ยนรหัสผ่านแล้ว' : '🔑 ตั้งรหัสผ่านแล้ว ใช้เข้าสู่ระบบด้วยอีเมลได้เลย'),
                      backgroundColor: _brown, duration: const Duration(seconds: 2)),
                );
              }
            } on AuthException catch (e) {
              setSheetState(() {
                error = e.message;
                submitting = false;
              });
            } catch (_) {
              setSheetState(() {
                error = 'บันทึกไม่สำเร็จ ลองใหม่อีกครั้ง';
                submitting = false;
              });
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: _borderColor, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Text(hasPassword ? 'เปลี่ยนรหัสผ่าน' : 'ตั้งรหัสผ่าน',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
                if (!hasPassword) ...[
                  const SizedBox(height: 6),
                  const Text('ตอนนี้คุณเข้าสู่ระบบด้วย Google/Facebook เท่านั้น ตั้งรหัสผ่านเพื่อเข้าสู่ระบบด้วยอีเมลได้ด้วย',
                      style: TextStyle(fontSize: 13, color: _mutedBrown)),
                ],
                const SizedBox(height: 16),
                if (hasPassword) ...[
                  _inputField('รหัสผ่านปัจจุบัน', ctrl: currentCtrl, obscure: true),
                  const SizedBox(height: 10),
                ],
                _inputField('รหัสผ่านใหม่', ctrl: newCtrl, hint: 'อย่างน้อย 8 ตัวอักษร', obscure: true),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitting ? null : submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brown,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('บันทึก', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Edit Pet Sheet ────────────────────────────────────────────
  void _showEditPetSheet(Map<String, dynamic> pet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final nameCtrl = TextEditingController(text: pet['name'] as String? ?? '');
        final weightCtrl = TextEditingController(text: pet['weight'] as String? ?? '');
        final heightCtrl = TextEditingController(text: pet['height'] as String? ?? '');
        final foodCtrl = TextEditingController(text: pet['food'] as String? ?? '');
        final allergiesCtrl = TextEditingController(text: pet['allergies'] as String? ?? '');
        final chipCtrl = TextEditingController(text: pet['chip'] as String? ?? '');
        final vaccineCtrl = TextEditingController(text: pet['vaccine'] as String? ?? '');
        final colorCtrl = TextEditingController(text: pet['color_desc'] as String? ?? '');
        final allTraits = ['ขี้เล่น', 'ชอบน้ำ', 'เป็นมิตร', 'กระฉับกระเฉง',
          'เงียบๆ', 'ขี้อาย', 'ชอบนอน', 'ฉลาด', 'ชอบธรรมชาติ'];
        final selectedTraits = {...(pet['traits'] as List<String>)};
        return StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: _borderColor, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text('แก้ไขข้อมูล ${pet['name']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
            const SizedBox(height: 16),
            _inputField('ชื่อน้อง', ctrl: nameCtrl, hint: pet['name'] as String?),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _inputField('น้ำหนัก', ctrl: weightCtrl, hint: pet['weight'] as String?)),
                const SizedBox(width: 10),
                Expanded(child: _inputField('ส่วนสูง', ctrl: heightCtrl, hint: pet['height'] as String?)),
              ],
            ),
            const SizedBox(height: 10),
            _inputField('อาหาร', ctrl: foodCtrl, hint: pet['food'] as String?),
            const SizedBox(height: 10),
            _inputField('สิ่งที่แพ้', ctrl: allergiesCtrl, hint: pet['allergies'] as String?),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _inputField('ไมโครชิป', ctrl: chipCtrl, hint: pet['chip'] as String?)),
                const SizedBox(width: 10),
                Expanded(child: _inputField('วัคซีน', ctrl: vaccineCtrl, hint: pet['vaccine'] as String?)),
              ],
            ),
            const SizedBox(height: 10),
            _inputField('สี', ctrl: colorCtrl, hint: pet['color_desc'] as String?),
            const SizedBox(height: 16),
            _sectionLabel('🐾 นิสัยน้อง'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: allTraits.map((t) {
                final sel = selectedTraits.contains(t);
                return GestureDetector(
                  onTap: () => setModalState(() {
                    sel ? selectedTraits.remove(t) : selectedTraits.add(t);
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? _brown : _bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? _brown : _borderColor),
                    ),
                    child: Text(t,
                        style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: sel ? Colors.white : _mutedBrown,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final updates = <String, dynamic>{
                    if (nameCtrl.text.trim().isNotEmpty) 'name': nameCtrl.text.trim(),
                    if (weightCtrl.text.trim().isNotEmpty) 'weight': weightCtrl.text.trim(),
                    if (heightCtrl.text.trim().isNotEmpty) 'height': heightCtrl.text.trim(),
                    if (foodCtrl.text.trim().isNotEmpty) 'food': foodCtrl.text.trim(),
                    if (allergiesCtrl.text.trim().isNotEmpty) 'allergies': allergiesCtrl.text.trim(),
                    if (chipCtrl.text.trim().isNotEmpty) 'chip_id': chipCtrl.text.trim(),
                    if (vaccineCtrl.text.trim().isNotEmpty) 'vaccine': vaccineCtrl.text.trim(),
                    if (colorCtrl.text.trim().isNotEmpty) 'color_desc': colorCtrl.text.trim(),
                    'traits': selectedTraits.toList(),
                  };
                  try {
                    await context.read<PetRepository>().updatePet(pet['id'] as String, updates);
                    await _loadPets();
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ บันทึกแล้ว'),
                          backgroundColor: _brown, duration: Duration(seconds: 1)),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('บันทึกไม่สำเร็จ: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brown,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('บันทึก', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
      );
      },
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _darkBrown));
  }

  Widget _inputField(String label, {TextEditingController? ctrl, String? hint, bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _mutedBrown, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(fontSize: 14, color: _darkBrown),
          decoration: InputDecoration(
            hintText: hint ?? label,
            hintStyle: const TextStyle(color: _mutedBrown, fontSize: 13),
            filled: true,
            fillColor: _bgCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
      ],
    );
  }
}

// Swipeable "next stay" card for when a pet has more than one upcoming
// booking -- separate StatefulWidget so its PageController/page index live
// independently of the parent's rebuilds (a ValueKey(petId) at the call
// site resets it cleanly when the selected pet changes).
class _StayCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> stays;
  final Widget Function(Map<String, dynamic> stay) stayRowBuilder;

  const _StayCarousel({super.key, required this.stays, required this.stayRowBuilder});

  @override
  State<_StayCarousel> createState() => _StayCarouselState();
}

class _StayCarouselState extends State<_StayCarousel> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 64,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.stays.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => widget.stayRowBuilder(widget.stays[i]),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.stays.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: active ? 0.9 : 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}