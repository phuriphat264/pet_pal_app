// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'data/care_tips_data.dart';
import 'screens/call_page.dart';
import 'screens/care_tip_detail_page.dart';
import 'screens/live_cam_page.dart';
import 'screens/matching_page.dart';
import 'screens/pet_profile_page.dart';
import 'screens/hotel_list_page.dart';
import 'screens/notification_page.dart';
import 'screens/login_page.dart';
import 'screens/chat_room_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/hotel_detail_page.dart';
import 'services/admin_user_repository.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/booking_repository.dart';
import 'services/call_service.dart';
import 'services/camera_repository.dart';
import 'services/chat_repository.dart';
import 'services/hotel_repository.dart';
import 'services/notification_repository.dart';
import 'services/partner_repository.dart';
import 'services/pet_repository.dart';
import 'services/realtime_service.dart';
import 'utils/pet_pal_image.dart';
import 'utils/reloadable.dart';
import 'utils/role_router.dart';

// Lets CallService push the incoming-call screen from anywhere in the app
// (not just while a chat thread is open), since a call invite can arrive
// while the user is on any tab.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final authService = AuthService();
  await authService.bootstrap();
  runApp(PetPalApp(authService: authService));
}

class PetPalApp extends StatelessWidget {
  final AuthService authService;
  /// Test-only: overrides the HTTP client used for both the API and direct
  /// (presigned-URL) uploads, so widget tests can fake the backend instead
  /// of hitting the network.
  final http.Client? httpClient;
  const PetPalApp({super.key, required this.authService, this.httpClient});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: authService),
        Provider<ApiClient>(create: (_) => ApiClient(authService: authService, client: httpClient)),
        Provider<HotelRepository>(create: (ctx) => HotelRepository(ctx.read<ApiClient>())),
        Provider<PetRepository>(create: (ctx) => PetRepository(ctx.read<ApiClient>())),
        Provider<BookingRepository>(create: (ctx) => BookingRepository(ctx.read<ApiClient>())),
        Provider<PartnerRepository>(
          create: (ctx) => PartnerRepository(ctx.read<ApiClient>(), uploadClient: httpClient),
        ),
        Provider<CameraRepository>(create: (ctx) => CameraRepository(ctx.read<ApiClient>())),
        Provider<AdminUserRepository>(create: (ctx) => AdminUserRepository(ctx.read<ApiClient>())),
        Provider<RealtimeService>(
          create: (_) => RealtimeService(authService: authService),
          dispose: (_, service) => service.dispose(),
        ),
        ChangeNotifierProvider<ChatRepository>(
          create: (ctx) => ChatRepository(client: ctx.read<ApiClient>(), realtime: ctx.read<RealtimeService>()),
        ),
        ChangeNotifierProvider<NotificationRepository>(
          create: (ctx) => NotificationRepository(client: ctx.read<ApiClient>(), realtime: ctx.read<RealtimeService>()),
        ),
        ChangeNotifierProvider<CallService>(
          create: (ctx) => CallService(client: ctx.read<ApiClient>(), realtime: ctx.read<RealtimeService>()),
        ),
      ],
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
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
        home: authService.isLoggedIn ? homeForRole(authService.role) : const LoginPage(),
        routes: {
          '/login': (_) => const LoginPage(),
          '/home': (_) => const MainNavigation(),
        },
        builder: (context, child) => _IncomingCallListener(child: child),
      ),
    );
  }
}

// Watches CallService globally and pushes the incoming-call screen the
// moment an invite arrives, regardless of which tab/screen is on top.
class _IncomingCallListener extends StatefulWidget {
  final Widget? child;
  const _IncomingCallListener({required this.child});

  @override
  State<_IncomingCallListener> createState() => _IncomingCallListenerState();
}

class _IncomingCallListenerState extends State<_IncomingCallListener> {
  bool _showingIncoming = false;
  bool _listening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_listening) return;
    _listening = true;
    context.read<CallService>().addListener(_onCallChanged);
  }

  void _onCallChanged() {
    final call = context.read<CallService>();
    if (call.state == CallState.ringingIncoming && !_showingIncoming) {
      _showingIncoming = true;
      rootNavigatorKey.currentState
          ?.push(MaterialPageRoute(builder: (_) => const IncomingCallPage()))
          .then((_) => _showingIncoming = false);
    }
  }

  @override
  void dispose() {
    context.read<CallService>().removeListener(_onCallChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox.shrink();
}

// ── Bottom Navigation Shell ───────────────────────────────────────

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final _liveCamKey = GlobalKey<State<LiveCamPage>>();
  final _chatKey = GlobalKey<State<ChatRoomPage>>();

  @override
  void initState() {
    super.initState();
    context.read<NotificationRepository>().loadNotifications();
  }

  // LiveCamPage/ChatRoomPage stay mounted inside the IndexedStack (so their
  // initState only ever runs once) -- without this, switching back to their
  // tab after booking a hotel elsewhere would show stale data.
  void _reloadTab(int index) {
    if (index == 1) (_liveCamKey.currentState as Reloadable?)?.reload();
    if (index == 2) (_chatKey.currentState as Reloadable?)?.reload();
  }

  void _switchTab(int index) {
    setState(() => _selectedIndex = index);
    _reloadTab(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomePage(onSwitchTab: _switchTab),
          LiveCamPage(key: _liveCamKey),
          ChatRoomPage(key: _chatKey),
          MatchingPage(),
          PetProfilePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _switchTab,
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
  final void Function(int)? onSwitchTab;
  const HomePage({super.key, this.onSwitchTab});

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
              _buildTipsSection(context),
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
          Expanded(
            child: Row(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('สวัสดี, คุณ${(context.watch<AuthService>().currentUser?.name ?? "ผู้ใช้").trim().split(' ').first} 👋',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _darkBrown)),
                      const Text('วันนี้น้องของคุณเป็นอย่างไรบ้าง?',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(fontSize: 14, color: _mutedBrown)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
                if (context.watch<NotificationRepository>().unreadCount > 0)
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
  Future<Map<String, dynamic>> _loadHeroData(BuildContext context) async {
    final pets = await context.read<PetRepository>().fetchPets();
    final bookings = await context.read<BookingRepository>().fetchMyBookings();
    final activeBookings = bookings.where((b) => b['status'] != 'cancelled').toList();

    String? hotelName;
    int cameraCount = 0;
    if (activeBookings.isNotEmpty) {
      final hotelId = activeBookings.first['hotel_id'] as String;
      try {
        final hotel = await context.read<HotelRepository>().fetchHotel(hotelId);
        hotelName = hotel['name'] as String?;
      } catch (_) {}
      try {
        final cameras = await context.read<CameraRepository>().fetchCamerasForHotel(hotelId);
        cameraCount = cameras.length;
      } catch (_) {
        // no cameras registered yet for this hotel -- not fatal
      }
    }

    return {
      'pet': pets.isNotEmpty ? pets.first : null,
      'hotelName': hotelName,
      'cameraCount': cameraCount,
    };
  }

  Widget _buildHeroCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _loadHeroData(context),
        builder: (context, snapshot) {
          final data = snapshot.data;
          final pet = data?['pet'] as Map<String, dynamic>?;
          final hotelName = data?['hotelName'] as String?;
          final cameraCount = (data?['cameraCount'] as int?) ?? 0;
          return _heroCardContent(context, pet: pet, hotelName: hotelName, cameraCount: cameraCount);
        },
      ),
    );
  }

  Widget _heroCardContent(
    BuildContext context, {
    required Map<String, dynamic>? pet,
    required String? hotelName,
    required int cameraCount,
  }) {
    final hasCamera = cameraCount > 0;
    final titleText = pet != null ? '${pet['name']}กำลังนอนหลับ 😴' : 'เพิ่มน้องตัวแรกของคุณ 🐾';
    final String subtitleText;
    if (pet == null) {
      subtitleText = 'เพิ่มข้อมูลสัตว์เลี้ยงเพื่อดู Live';
    } else if (hotelName == null) {
      subtitleText = 'ยังไม่มีการจองที่พัก';
    } else if (!hasCamera) {
      subtitleText = '$hotelName · ยังไม่มีกล้องเชื่อมต่อ';
    } else {
      subtitleText = '$hotelName · กล้อง $cameraCount ตัว';
    }

    return Container(
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
                        Text(titleText,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(subtitleText,
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha:0.65))),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => onSwitchTab?.call(pet == null ? 4 : 1),
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
                      Icon(
                        pet != null ? pet['icon'] as IconData : Icons.pets_rounded,
                        color: Colors.white,
                        size: 64,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (hasCamera ? const Color(0xFF81C784) : Colors.white).withValues(alpha:0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(hasCamera ? 'ปลอดภัย' : 'ยังไม่เชื่อมต่อ',
                            style: TextStyle(fontSize: 12, color: hasCamera ? const Color(0xFF81C784) : Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  // ── Quick Actions ─────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'icon': Icons.hotel_rounded, 'label': 'จองที่พัก', 'color': _brown, 'bg': Colors.white},
      {'icon': Icons.auto_awesome_rounded, 'label': 'แมตช์นิสัย', 'color': _brown, 'bg': Colors.white},
      {'icon': Icons.bathtub_rounded, 'label': 'อาบน้ำสปา', 'color': _brown, 'bg': Colors.white},
      {'icon': Icons.park_rounded, 'label': 'พาเดินเล่น', 'color': _brown, 'bg': Colors.white},
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
                    onSwitchTab?.call(3);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${a['label']} — เร็วๆ นี้ 🚀'),
                      backgroundColor: _brown,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 2),
                    ));
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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<HotelRepository>().fetchHotels(),
      builder: (context, snapshot) {
        final nearby = (snapshot.data ?? const <Map<String, dynamic>>[]).take(3).toList();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: _brown)),
          );
        }
        return _buildNearbyList(context, nearby);
      },
    );
  }

  Widget _buildNearbyList(BuildContext context, List<Map<String, dynamic>> nearby) {
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
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HotelDetailPage(hotel: h))),
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
                              child: h['images'] != null && (h['images'] as List).isNotEmpty
                                  ? PetPalImage(
                                      path: (h['images'] as List).first as String,
                                      errorBuilder: (_, e, s) => Center(child: Icon(h['icon'] as IconData, size: 46, color: _brown)),
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
                              child: Text(
                                (h['tags'] as List?)?.isNotEmpty == true ? (h['tags'] as List).first.toString() : 'Pet Hotel',
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                              ),
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
                                  Text(' ${h['rating']}',
                                      style: const TextStyle(fontSize: 10, color: _mutedBrown, fontWeight: FontWeight.w600)),
                                  const Text(' · ', style: TextStyle(fontSize: 10, color: _mutedBrown)),
                                  const Icon(Icons.location_on_outlined, size: 10, color: _mutedBrown),
                                  Expanded(
                                    child: Text(h['distance']?.toString() ?? '',
                                        style: const TextStyle(fontSize: 10, color: _mutedBrown),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(h['description']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 10, color: _mutedBrown, height: 1.3),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              const Spacer(),
                              Text('฿${h['price']}/คืน',
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
  Widget _buildTipsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('เคล็ดลับดูแลน้อง',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown)),
          const SizedBox(height: 12),
          for (final tip in careTips) ...[
            _tipCard(context, tip),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _tipCard(BuildContext context, CareTip tip) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CareTipDetailPage(tip: tip))),
      child: Container(
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
              child: Center(child: Icon(tip.icon, color: _brown, size: 28)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tip.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _darkBrown)),
                  const SizedBox(height: 4),
                  Text(tip.summary,
                      style: const TextStyle(fontSize: 13, color: _mutedBrown, height: 1.4)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _mutedBrown, size: 18),
          ],
        ),
      ),
    );
  }
}