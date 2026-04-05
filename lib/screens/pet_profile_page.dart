// lib/screens/pet_profile_page.dart
import 'package:flutter/material.dart';

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

  // ── ข้อมูลสัตว์เลี้ยง ─────────────────────────────────────────
  final List<Map<String, dynamic>> _pets = [
    {
      'name': 'มะม่วง',
      'breed': 'โกลเด้นรีทรีฟเวอร์',
      'age': '3 ปี',
      'weight': '28 กก.',
      'height': '60 ซม.',
      'icon': Icons.pets_rounded,
      'color': const Color(0xFFD4956A),
      'gender': 'ชาย',
      'dob': '12 มี.ค. 65',
      'color_desc': 'สีทอง',
      'vaccine': 'ครบแล้ว',
      'nextVet': '15 เม.ย. 68',
      'lastVet': '10 ม.ค. 68',
      'chip': 'TH-2024-001234',
      'allergies': 'ไม่มี',
      'food': 'Royal Canin Adult',
      'feedingTimes': '2 ครั้ง/วัน',
      'neutered': 'ยังไม่ได้ทำหมัน',
      // นิสัย
      'traits': ['ขี้เล่น', 'ชอบน้ำ', 'เป็นมิตร', 'กระฉับกระเฉง'],
      // ประวัติการรักษา
      'medHistory': [
        {'date': '10 ม.ค. 68', 'event': 'ฉีดวัคซีนประจำปี', 'vet': 'ร้านสัตวแพทย์ใจดี'},
        {'date': '5 ต.ค. 67', 'event': 'ตรวจสุขภาพทั่วไป', 'vet': 'โรงพยาบาลสัตว์เมืองไทย'},
        {'date': '20 ก.ค. 67', 'event': 'กำจัดเห็บหมัด', 'vet': 'ร้านสัตวแพทย์ใจดี'},
      ],
      'health': [
        {'label': 'น้ำหนัก', 'value': '28 กก.', 'icon': '⚖️'},
        {'label': 'ส่วนสูง', 'value': '60 ซม.', 'icon': '📏'},
        {'label': 'อุณหภูมิ', 'value': '38.5°C', 'icon': '🌡️'},
        {'label': 'ชีพจร', 'value': '80 bpm', 'icon': '💓'},
      ],
      'activities': [
        {'label': 'เดินวันนี้', 'value': '2.3 กม.'},
        {'label': 'แคลอรี่', 'value': '320 kcal'},
        {'label': 'นอนหลับ', 'value': '8 ชม.'},
      ],
    },
    {
      'name': 'ช็อคโกแลต',
      'breed': 'มิเนเจอร์ ชเนาเซอร์',
      'age': '5 ปี',
      'weight': '8 กก.',
      'height': '35 ซม.',
      'icon': Icons.pets_rounded,
      'color': const Color(0xFF6B4F3A),
      'gender': 'หญิง',
      'dob': '3 พ.ค. 63',
      'color_desc': 'สีเทาเข้ม',
      'vaccine': 'ครบแล้ว',
      'nextVet': '20 มิ.ย. 68',
      'lastVet': '15 ธ.ค. 67',
      'chip': 'TH-2021-005678',
      'allergies': 'ไก่',
      'food': "Hill's Science Diet",
      'feedingTimes': '2 ครั้ง/วัน',
      'neutered': 'ทำหมันแล้ว',
      'traits': ['เงียบๆ', 'ขี้อาย', 'เป็นมิตร', 'ชอบนอน'],
      'medHistory': [
        {'date': '15 ธ.ค. 67', 'event': 'ฉีดวัคซีนประจำปี', 'vet': 'โรงพยาบาลสัตว์เมืองไทย'},
        {'date': '8 ส.ค. 67', 'event': 'ผ่าตัดทำหมัน', 'vet': 'คลินิกสัตว์เลี้ยงรัก'},
      ],
      'health': [
        {'label': 'น้ำหนัก', 'value': '8 กก.', 'icon': '⚖️'},
        {'label': 'ส่วนสูง', 'value': '35 ซม.', 'icon': '📏'},
        {'label': 'อุณหภูมิ', 'value': '38.2°C', 'icon': '🌡️'},
        {'label': 'ชีพจร', 'value': '90 bpm', 'icon': '💓'},
      ],
      'activities': [
        {'label': 'เดินวันนี้', 'value': '1.1 กม.'},
        {'label': 'แคลอรี่', 'value': '180 kcal'},
        {'label': 'นอนหลับ', 'value': '10 ชม.'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final pet = _pets[_selectedPet];
    return Scaffold(
      backgroundColor: _bgCream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildOwnerSection(),
              _buildHeader(pet),
              _buildPetSelector(),
              _buildHealthCards(pet),
              _buildTraitsSection(pet),
              _buildActivitySection(pet),
              _buildInfoSection(pet),
              _buildMedHistorySection(pet),
              _buildVetSection(pet),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader(Map<String, dynamic> pet) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('โปรไฟล์น้อง',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _darkBrown)),
              GestureDetector(
                onTap: _showAddPetSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _brown,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: _brown.withValues(alpha:0.3), blurRadius: 8, offset: const Offset(0, 3))],
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (pet['color'] as Color).withValues(alpha:0.2),
                  (pet['color'] as Color).withValues(alpha:0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: (pet['color'] as Color).withValues(alpha:0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 84, height: 84,
                  decoration: BoxDecoration(
                    color: (pet['color'] as Color).withValues(alpha:0.25),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: (pet['color'] as Color).withValues(alpha:0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Center(child: Icon(pet['icon'] as IconData, size: 46, color: _brown)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pet['name'],
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _darkBrown)),
                      const SizedBox(height: 2),
                      Text(pet['breed'],
                          style: const TextStyle(fontSize: 15, color: _mutedBrown)),
                      const SizedBox(height: 4),
                      Text('เกิด ${pet['dob']}',
                          style: const TextStyle(fontSize: 13, color: _mutedBrown)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 5, runSpacing: 4,
                        children: [
                          _petTag(pet['gender'] == 'ชาย' ? '♂ ชาย' : '♀ หญิง',
                              pet['gender'] == 'ชาย' ? const Color(0xFF1A6FA8) : const Color(0xFFA81A6F)),
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
          ),
        ],
      ),
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
    if (_pets.length <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: List.generate(_pets.length, (i) {
          final selected = i == _selectedPet;
          return GestureDetector(
            onTap: () => setState(() => _selectedPet = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? _brown : _bgCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(_pets[i]['icon'] as IconData, size: 18, color: selected ? Colors.white : _mutedBrown),
                  const SizedBox(width: 6),
                  Text(_pets[i]['name'],
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : _mutedBrown)),
                ],
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('สุขภาพ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _darkBrown)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10,
            childAspectRatio: 1.8,
            children: (pet['health'] as List).map((h) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Row(
                children: [
                  Text(h['icon'], style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(h['value'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
                      Text(h['label'],
                          style: const TextStyle(fontSize: 13, color: _mutedBrown)),
                    ],
                  ),
                ],
              ),
            )).toList(),
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
            const Row(
              children: [
                Text('🐾', style: TextStyle(fontSize: 20)),
                SizedBox(width: 6),
                Text('นิสัยน้อง',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _darkBrown)),
              ],
            ),
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('กิจกรรมวันนี้',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _darkBrown)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
            const Row(
              children: [
                Text('📋', style: TextStyle(fontSize: 20)),
                SizedBox(width: 6),
                Text('ข้อมูลทั่วไป',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _darkBrown)),
              ],
            ),
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
            const Row(
              children: [
                Text('🏥', style: TextStyle(fontSize: 20)),
                SizedBox(width: 6),
                Text('ประวัติการรักษา',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _darkBrown)),
              ],
            ),
            const SizedBox(height: 12),
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
          ],
        ),
      ),
    );
  }

  // ── Vet Section ───────────────────────────────────────────────
  Widget _buildVetSection(Map<String, dynamic> pet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha:0.4), width: 0.5),
          boxShadow: [BoxShadow(color: const Color(0xFFFFD700).withValues(alpha:0.15), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE082),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.hotel_rounded, color: Color(0xFF8B6914), size: 28),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('รอบฝากเลี้ยงถัดไป',
                    style: TextStyle(fontSize: 14, color: Color(0xFF8B6914))),
                const Text('15 เม.ย. นี้',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF5A3E0A))),
                const Text('ที่ Paw Paradise Resort',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9B7A2A))),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📅 บันทึกในปฏิทินแล้ว'),
                    backgroundColor: Color(0xFF5C3D2E), duration: Duration(seconds: 1)),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B6914),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('ตั้งเตือน',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
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
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🐾 เพิ่มน้องแล้ว!'),
                            backgroundColor: _brown, duration: Duration(seconds: 1)),
                      );
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

  // ── Owner Section ─────────────────────────────────────────────
  Widget _buildOwnerSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('โปรไฟล์เจ้าของ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _darkBrown)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: const BoxDecoration(
                        color: _brown,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: Icon(Icons.pets_rounded, color: Colors.white, size: 32)),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('คุณภูริภัทร',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
                          Text('Pet Owner (Premium Member)',
                              style: TextStyle(fontSize: 13, color: _mutedBrown)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined, color: _brown, size: 20),
                    ),
                  ],
                ),
                const Divider(height: 24, color: _bgCream),
                _ownerActionTile(Icons.assignment_ind_outlined, 'ข้อมูลบัญชี'),
                _ownerActionTile(Icons.payment_rounded, 'วิธีการชำระเงิน'),
                _ownerActionTile(Icons.settings_outlined, 'การตั้งค่าระบบ'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    label: const Text('ออกจากระบบ',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _ownerActionTile(IconData icon, String title) {
    return Padding(
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
      builder: (ctx) => Padding(
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
            _inputField('ชื่อน้อง', hint: pet['name']),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _inputField('น้ำหนัก', hint: pet['weight'])),
                const SizedBox(width: 10),
                Expanded(child: _inputField('ส่วนสูง', hint: pet['height'])),
              ],
            ),
            const SizedBox(height: 10),
            _inputField('อาหาร', hint: pet['food']),
            const SizedBox(height: 10),
            _inputField('สิ่งที่แพ้', hint: pet['allergies']),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ บันทึกแล้ว'),
                        backgroundColor: _brown, duration: Duration(seconds: 1)),
                  );
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

  Widget _sectionLabel(String label) {
    return Text(label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _darkBrown));
  }

  Widget _inputField(String label, {TextEditingController? ctrl, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _mutedBrown, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
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