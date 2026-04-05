// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/live_cam_page.dart';
import 'screens/matching_page.dart';
import 'screens/pet_profile_page.dart';
import 'screens/hotel_list_page.dart';
import 'screens/notification_page.dart';
import 'screens/login_page.dart';
import 'screens/chat_room_page.dart';

void main() {
  runApp(const PetPalApp());
}

class PetPalApp extends StatelessWidget {
  const PetPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PetPal',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.kanitTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFFFF9F1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5C3D2E),
          primary: const Color(0xFF5C3D2E),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/home',
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const MainNavigation(),
      },
    );
  }
}

// ── Bottom Navigation Shell ───────────────────────────────────────

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          HomePage(),
          LiveCamPage(),
          ChatRoomPage(),
          MatchingPage(),
          PetProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF5C3D2E),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.videocam_outlined), activeIcon: Icon(Icons.videocam_rounded), label: 'ดูกล้อง'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), activeIcon: Icon(Icons.chat_bubble_rounded), label: 'แชท'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), activeIcon: Icon(Icons.auto_awesome_rounded), label: 'แมตช์นิสัย'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person_rounded), label: 'โปรไฟล์'),
        ],
      ),
    );
  }
}

// ── Home Page ─────────────────────────────────────────────────────

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color _brown = Color(0xFF5C3D2E);
  static const Color _darkBrown = Color(0xFF3D2316);
  static const Color _bgCream = Color(0xFFF5EFE8);
  static const Color _bgCard = Color(0xFFEDE2D5);
  static const Color _mutedBrown = Color(0xFF9E7A60);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildHeroCard(context),
              // ลบ _buildTodayStats ออกแล้ว
              _buildQuickActions(context),
              _buildTrustBanner(context),
              _buildNearbySection(context),
              _buildTipsSection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _brown,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _brown.withValues(alpha:0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Center(child: Icon(Icons.pets_rounded, color: Colors.white, size: 24)),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('สวัสดี, คุณภูริภัทร 👋',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _darkBrown)),
                  Text('วันนี้น้องของคุณเป็นอย่างไรบ้าง?',
                      style: TextStyle(fontSize: 14, color: _mutedBrown)),
                ],
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationPage())),
            child: Stack(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.06), blurRadius: 8)],
                  ),
                  child: const Icon(Icons.notifications_outlined, color: _brown, size: 22),
                ),
                Positioned(
                  top: 10, right: 10,
                  child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Card ─────────────────────────────────────────────────
  Widget _buildHeroCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B4226), Color(0xFF3D2316)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: const Color(0xFF5C3D2E).withValues(alpha:0.35),
                blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20, right: -20,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha:0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -30, right: 60,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha:0.04),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Color(0xFF81C784), size: 8),
                              SizedBox(width: 4),
                              Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('มะม่วงกำลังนอนหลับ 😴',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('ห้องนอน · กล้อง 1 · อัปเดต 2 นาทีที่แล้ว',
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha:0.65))),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.videocam, color: _brown, size: 16),
                                    SizedBox(width: 6),
                                    Text('ดู Live', style: TextStyle(color: _brown, fontSize: 14, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha:0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.notifications_active_outlined, color: Colors.white, size: 15),
                                  SizedBox(width: 5),
                                  Text('เรียกน้อง', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      const Text('🐶', style: TextStyle(fontSize: 72)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF81C784).withValues(alpha:0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('ปลอดภัย',
                            style: TextStyle(fontSize: 12, color: Color(0xFF81C784), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick Actions ─────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'icon': Icons.hotel_rounded, 'label': 'จองที่พัก', 'color': _brown, 'bg': Colors.white},
      {'icon': Icons.auto_awesome_rounded, 'label': 'แมตช์นิสัย', 'color': _brown, 'bg': Colors.white},
      {'icon': Icons.bathtub_rounded, 'label': 'อาบน้ำสปา', 'color': _brown, 'bg': Colors.white},
      {'icon': Icons.park_rounded, 'label': 'ฝากเลี้ยง', 'color': _brown, 'bg': Colors.white},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('บริการ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: actions.map((a) {
              return GestureDetector(
                onTap: () {
                  if (a['label'] == 'จองที่พัก') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HotelListPage()));
                  } else if (a['label'] == 'แมตช์นิสัย') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchingPage()));
                  }
                },
                child: Column(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: a['bg'] as Color,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: (a['color'] as Color).withValues(alpha:0.15), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 28),
                    ),
                    const SizedBox(height: 7),
                    Text(a['label'] as String,
                        style: const TextStyle(fontSize: 13, color: _mutedBrown, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Trust Banner ────────────────────────────────────────────────
  Widget _buildTrustBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _darkBrown,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _brown.withValues(alpha:0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('พันธสัญญาจาก PetPal', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('รับประกันดูแลน้องด้วยรัก ปลอดภัย 100% พร้อมวงเงินคุ้มครองและวิดีโออัปเดต 24 ชม.', style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Nearby Section ────────────────────────────────────────────
  Widget _buildNearbySection(BuildContext context) {
    final List<Map<String, dynamic>> nearby = [
      {'name': 'รพ.สัตว์แผ่นดินทอง', 'dist': '1.2 กม.', 'price': '฿320', 'icon': Icons.local_hospital_rounded, 'rating': '4.8', 'tag': 'ยอดนิยม', 'desc': 'รับฝากสุนัขและแมว มีหมอตรวจก่อนเข้าพัก', 'image': 'assets/images/hotel1_1.jpg'},
      {'name': 'Sky Cat Hotel', 'dist': '2.5 กม.', 'price': '฿300', 'icon': Icons.pets_rounded, 'rating': '4.9', 'tag': 'พรีเมียม', 'desc': 'โรงแรมแมวแอร์ 24 ชม. ลดก่อภูมิแพ้', 'image': 'assets/images/hotel2_1.jpg'},
      {'name': 'PigPao Pet Shop', 'dist': '3.1 กม.', 'price': '฿350', 'icon': Icons.store_rounded, 'rating': '4.7', 'tag': 'ราคาดี', 'desc': 'ไม่ขังกรง มีกล้องตลอด 24 ชม.', 'image': 'assets/images/hotel3_1.jpg'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              const Text('โรงแรมใกล้คุณ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HotelListPage())),
                child: const Text('ดูทั้งหมด',
                    style: TextStyle(fontSize: 14, color: _brown, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: nearby.length,
            itemBuilder: (_, i) {
              final h = nearby[i];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HotelListPage())),
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.07), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 105,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _bgCard,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                              child: h['image'] != null
                                  ? Image.asset(
                                      h['image'] as String,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (_, __, ___) => Center(child: Icon(h['icon'] as IconData, size: 46, color: _brown)),
                                    )
                                  : Center(child: Icon(h['icon'] as IconData, size: 46, color: _brown)),
                            ),
                          ),
                          Positioned(
                            top: 8, left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: _brown,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(h['tag'] as String, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(h['name'] as String,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _darkBrown),
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 11, color: Color(0xFFFFC107)),
                                  Text(' ${h['rating'] as String}',
                                      style: const TextStyle(fontSize: 10, color: _mutedBrown, fontWeight: FontWeight.w600)),
                                  const Text(' · ', style: TextStyle(fontSize: 10, color: _mutedBrown)),
                                  const Icon(Icons.location_on_outlined, size: 10, color: _mutedBrown),
                                  Text(h['dist'] as String, style: const TextStyle(fontSize: 10, color: _mutedBrown)),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(h['desc'] as String,
                                  style: const TextStyle(fontSize: 10, color: _mutedBrown, height: 1.3),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              const Spacer(),
                              Text('${h['price'] as String}/คืน',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _brown)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Tips Section ──────────────────────────────────────────────
  Widget _buildTipsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('เคล็ดลับดูแลน้อง',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
          const SizedBox(height: 12),
          _tipCard(Icons.restaurant_rounded, 'อาหารที่ดีสำหรับหมา',
              'อาหารสูตร adult ช่วยบำรุงกระดูกและขนให้แข็งแรง'),
          const SizedBox(height: 8),
          _tipCard(Icons.water_drop_rounded, 'น้ำสะอาดสำคัญมาก',
              'น้องหมาควรดื่มน้ำอย่างน้อย 50 มล. ต่อน้ำหนัก 1 กก. ต่อวัน'),
          const SizedBox(height: 8),
          _tipCard(Icons.directions_walk_rounded, 'ออกกำลังกายทุกวัน',
              'หมาขนาดกลางควรเดินอย่างน้อย 30 นาทีต่อวันเพื่อสุขภาพที่ดี'),
        ],
      ),
    );
  }

  Widget _tipCard(IconData icon, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: _bgCream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Icon(icon, color: _brown, size: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _darkBrown)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(fontSize: 13, color: _mutedBrown, height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: _mutedBrown, size: 18),
        ],
      ),
    );
  }
}