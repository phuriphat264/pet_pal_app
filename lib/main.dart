// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/live_cam_page.dart';
import 'screens/matching_page.dart';
import 'screens/pet_profile_page.dart';
import 'screens/hotel_list_page.dart';
import 'screens/notification_page.dart';
import 'screens/login_page.dart';

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
      initialRoute: '/login',
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
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.videocam_outlined), activeIcon: Icon(Icons.videocam), label: 'กล้อง'),
          BottomNavigationBarItem(icon: Icon(Icons.pets_outlined), activeIcon: Icon(Icons.pets), label: 'จับคู่'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'โปรไฟล์'),
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
              _buildTodayStats(),
              _buildQuickActions(context),
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
          // Avatar + greeting
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _brown,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _brown.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Center(child: Text('🐾', style: TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('สวัสดี, คุณภูริภัทร 👋',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _darkBrown)),
                  Text('วันนี้น้องของคุณเป็นอย่างไรบ้าง?',
                      style: TextStyle(fontSize: 11, color: _mutedBrown)),
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
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                  ),
                  child: const Icon(Icons.notifications_outlined, color: _brown, size: 20),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: Color(0xFFE57373), shape: BoxShape.circle),
                  ),
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
            BoxShadow(color: const Color(0xFF5C3D2E).withOpacity(0.35),
                blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(
          children: [
            // decorative circles
            Positioned(
              top: -20, right: -20,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -30, right: 60,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
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
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Color(0xFF81C784), size: 7),
                              SizedBox(width: 4),
                              Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text('มะม่วงกำลังนอนหลับ 😴',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('ห้องนอน · กล้อง 1 · อัปเดต 2 นาทีที่แล้ว',
                            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.65))),
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
                                    Icon(Icons.videocam, color: _brown, size: 14),
                                    SizedBox(width: 6),
                                    Text('ดู Live', style: TextStyle(color: _brown, fontSize: 12, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.notifications_active_outlined, color: Colors.white, size: 13),
                                  SizedBox(width: 5),
                                  Text('เรียกน้อง', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
                      const Text('🐶', style: TextStyle(fontSize: 64)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF81C784).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('ปลอดภัย',
                            style: TextStyle(fontSize: 10, color: Color(0xFF81C784), fontWeight: FontWeight.w600)),
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

  // ── Today Stats ───────────────────────────────────────────────
  Widget _buildTodayStats() {
    final stats = [
      {'icon': '🌡️', 'value': '26°C', 'label': 'อุณหภูมิ', 'color': const Color(0xFFFF7043)},
      {'icon': '😴', 'value': '4 ชม.', 'label': 'นอนแล้ว', 'color': const Color(0xFF7E57C2)},
      {'icon': '🐾', 'value': '2.3 กม.', 'label': 'เดินวันนี้', 'color': const Color(0xFF26A69A)},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: List.generate(stats.length, (i) {
          final s = stats[i];
          final color = s['color'] as Color;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text(s['icon'] as String, style: const TextStyle(fontSize: 16))),
                  ),
                  const SizedBox(height: 8),
                  Text(s['value'] as String,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _darkBrown)),
                  Text(s['label'] as String,
                      style: const TextStyle(fontSize: 10, color: _mutedBrown)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Quick Actions ─────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'icon': Icons.search_rounded, 'label': 'หาที่พัก', 'color': const Color(0xFF7CB9A8), 'bg': const Color(0xFFE8F5F2)},
      {'icon': Icons.favorite_border_rounded, 'label': 'จับคู่', 'color': const Color(0xFFE8936A), 'bg': const Color(0xFFFDF0E8)},
      {'icon': Icons.medical_services_outlined, 'label': 'นัดหมอ', 'color': const Color(0xFF9B7EC8), 'bg': const Color(0xFFF3EEFB)},
      {'icon': Icons.shopping_bag_outlined, 'label': 'ร้านค้า', 'color': const Color(0xFFD4956A), 'bg': const Color(0xFFFBF0E5)},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('บริการ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _darkBrown)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: actions.map((a) {
              return GestureDetector(
                onTap: () {
                  if (a['label'] == 'หาที่พัก') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HotelListPage()));
                  } else if (a['label'] == 'แจ้งเตือน') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage()));
                  }
                },
                child: Column(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: a['bg'] as Color,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: (a['color'] as Color).withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 26),
                    ),
                    const SizedBox(height: 7),
                    Text(a['label'] as String,
                        style: const TextStyle(fontSize: 11, color: _mutedBrown, fontWeight: FontWeight.w600)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Nearby Section ────────────────────────────────────────────
  Widget _buildNearbySection(BuildContext context) {
    final nearby = [
      {'name': 'Paw Paradise', 'dist': '0.8 กม.', 'price': '฿650', 'emoji': '🏡', 'rating': '4.9', 'tag': 'ยอดนิยม'},
      {'name': 'Happy Paws', 'dist': '1.5 กม.', 'price': '฿450', 'emoji': '🐕', 'rating': '4.7', 'tag': 'ราคาดี'},
      {'name': 'Pet Oasis', 'dist': '3.0 กม.', 'price': '฿800', 'emoji': '🌿', 'rating': '4.6', 'tag': 'พรีเมียม'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              const Text('โรงแรมใกล้คุณ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _darkBrown)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HotelListPage())),
                child: const Text('ดูทั้งหมด',
                    style: TextStyle(fontSize: 12, color: _brown, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 175,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: nearby.length,
            itemBuilder: (_, i) {
              final h = nearby[i];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HotelListPage())),
                child: Container(
                  width: 148,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 90,
                            decoration: BoxDecoration(
                              color: _bgCard,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                            ),
                            child: Center(child: Text(h['emoji']!, style: const TextStyle(fontSize: 40))),
                          ),
                          Positioned(
                            top: 8, left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: _brown,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(h['tag']!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(h['name']!,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _darkBrown),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 11, color: Color(0xFFFFC107)),
                                Text(' ${h['rating']!}',
                                    style: const TextStyle(fontSize: 10, color: _mutedBrown, fontWeight: FontWeight.w600)),
                                const Text(' · ', style: TextStyle(fontSize: 10, color: _mutedBrown)),
                                const Icon(Icons.location_on_outlined, size: 10, color: _mutedBrown),
                                Text(h['dist']!, style: const TextStyle(fontSize: 10, color: _mutedBrown)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${h['price']!}/คืน',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _brown)),
                          ],
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _darkBrown)),
          const SizedBox(height: 12),
          _tipCard('🍖', 'อาหารที่ดีสำหรับหมา',
              'อาหารสูตร adult ช่วยบำรุงกระดูกและขนให้แข็งแรง', const Color(0xFFFBEDE5)),
          const SizedBox(height: 8),
          _tipCard('💧', 'น้ำสะอาดสำคัญมาก',
              'น้องหมาควรดื่มน้ำอย่างน้อย 50 มล. ต่อน้ำหนัก 1 กก. ต่อวัน', const Color(0xFFE5F0FB)),
          const SizedBox(height: 8),
          _tipCard('🚶', 'ออกกำลังกายทุกวัน',
              'หมาขนาดกลางควรเดินอย่างน้อย 30 นาทีต่อวันเพื่อสุขภาพที่ดี', const Color(0xFFE8F5E9)),
        ],
      ),
    );
  }

  Widget _tipCard(String emoji, String title, String body, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _darkBrown)),
                const SizedBox(height: 3),
                Text(body,
                    style: const TextStyle(fontSize: 11, color: _mutedBrown, height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: _mutedBrown, size: 18),
        ],
      ),
    );
  }
}