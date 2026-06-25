// lib/screens/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../utils/role_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  // ─── Palette ────────────────────────────────────────────────────
  static const Color _brown      = Color(0xFF6B4226);
  static const Color _darkBrown  = Color(0xFF3B2010);
  static const Color _bgCream    = Color(0xFFF7F1EA);
  static const Color _bgCard     = Color(0xFFFFFBF7);
  static const Color _mutedBrown = Color(0xFFA07850);
  static const Color _accent     = Color(0xFFD4845A);
  static const Color _border     = Color(0xFFE2D0BC);

  // ─── State ──────────────────────────────────────────────────────
  late TabController _tabController;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  bool _obscure  = true;
  bool _loading  = false;
  int  _tabIndex = 0;

  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus  = FocusNode();
  final _nameFocus  = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() => _tabIndex = _tabController.index);
          _runSlide();
        }
      });

    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    _fadeCtrl.forward();
    _slideCtrl.forward();
  }

  void _runSlide() {
    _slideCtrl.reset();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _onLogin() async {
    FocusScope.of(context).unfocus();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      _showError('กรุณากรอกอีเมลและรหัสผ่าน');
      return;
    }

    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      await auth.login(email: email, password: password);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => homeForRole(auth.role)));
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onRegister() async {
    FocusScope.of(context).unfocus();
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    if (name.isEmpty || email.isEmpty || password.length < 8) {
      _showError('กรุณากรอกข้อมูลให้ครบ และรหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร');
      return;
    }

    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      await auth.register(email: email, password: password, name: name);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => homeForRole(auth.role)));
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onGoogleLogin() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final serverClientId = dotenv.env['GOOGLE_SERVER_CLIENT_ID'];
      if (serverClientId == null || serverClientId.isEmpty) {
        _showError('ยังไม่ได้ตั้งค่า Google Sign-In (GOOGLE_SERVER_CLIENT_ID ใน .env)');
        return;
      }
      final googleSignIn = GoogleSignIn(scopes: const ['email'], serverClientId: serverClientId);
      final account = await googleSignIn.signIn();
      if (account == null) return; // user cancelled the picker
      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        _showError('ไม่สามารถรับ Google ID token ได้');
        return;
      }
      final auth = context.read<AuthService>();
      await auth.loginWithGoogle(idToken: idToken);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => homeForRole(auth.role)));
    } on AuthException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('เข้าสู่ระบบด้วย Google ไม่สำเร็จ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Forgot password ────────────────────────────────────────────
  void _showForgotPasswordSheet() {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    final codeCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    int step = 0; // 0 = request code, 1 = enter code + new password
    bool submitting = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgCream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> requestCode() async {
            final email = emailCtrl.text.trim();
            if (email.isEmpty) {
              setSheetState(() => error = 'กรุณากรอกอีเมล');
              return;
            }
            setSheetState(() {
              submitting = true;
              error = null;
            });
            try {
              await sheetContext.read<AuthService>().forgotPassword(email: email);
              setSheetState(() {
                submitting = false;
                step = 1;
              });
            } catch (_) {
              setSheetState(() {
                submitting = false;
                // Still advance -- the backend always returns success here
                // to avoid leaking which emails are registered.
                step = 1;
              });
            }
          }

          Future<void> confirmReset() async {
            final code = codeCtrl.text.trim();
            final newPassword = newPassCtrl.text;
            if (code.isEmpty || newPassword.length < 8) {
              setSheetState(() => error = 'กรุณากรอกโค้ดและรหัสผ่านใหม่อย่างน้อย 8 ตัวอักษร');
              return;
            }
            setSheetState(() {
              submitting = true;
              error = null;
            });
            try {
              await sheetContext.read<AuthService>().resetPassword(token: code, newPassword: newPassword);
              if (!sheetContext.mounted) return;
              Navigator.pop(sheetContext);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🔑 เปลี่ยนรหัสผ่านสำเร็จแล้ว เข้าสู่ระบบได้เลย')),
              );
            } on AuthException catch (e) {
              setSheetState(() {
                error = e.message;
                submitting = false;
              });
            } catch (_) {
              setSheetState(() {
                error = 'เปลี่ยนรหัสผ่านไม่สำเร็จ ลองขอโค้ดใหม่อีกครั้ง';
                submitting = false;
              });
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(sheetContext).viewInsets.bottom + 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step == 0 ? 'ลืมรหัสผ่าน' : 'ตั้งรหัสผ่านใหม่',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _darkBrown),
                ),
                const SizedBox(height: 6),
                Text(
                  step == 0
                      ? 'กรอกอีเมลที่ใช้สมัคร เราจะส่งโค้ดสำหรับตั้งรหัสผ่านใหม่ไปให้'
                      : 'กรอกโค้ดที่ได้รับ และตั้งรหัสผ่านใหม่',
                  style: const TextStyle(fontSize: 13, color: _mutedBrown),
                ),
                const SizedBox(height: 16),
                if (step == 0)
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'อีเมล', border: OutlineInputBorder()),
                  )
                else ...[
                  TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(labelText: 'โค้ดยืนยัน', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'รหัสผ่านใหม่', border: OutlineInputBorder()),
                    onSubmitted: (_) => confirmReset(),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitting ? null : (step == 0 ? requestCode : confirmReset),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text(step == 0 ? 'ส่งโค้ด' : 'ยืนยันรหัสผ่านใหม่',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgCream,
      body: Stack(
        children: [
          Positioned(top: -60, right: -60, child: _blob(200, _accent.withValues(alpha: 0.12))),
          Positioned(bottom: 120, left: -80, child: _blob(240, _brown.withValues(alpha: 0.08))),
          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 44),
                    _buildHero(),
                    const SizedBox(height: 40),
                    _buildTabBar(),
                    const SizedBox(height: 28),
                    SlideTransition(
                      position: _slideAnim,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                        child: _tabIndex == 0 ? _buildLoginCard() : _buildRegisterCard(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    _buildGoogleButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero ─────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Column(
      children: [
        SizedBox(
          width: 96, height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(width: 96, height: 96, decoration: BoxDecoration(shape: BoxShape.circle, color: _brown.withValues(alpha: 0.08))),
              Container(width: 76, height: 76, decoration: BoxDecoration(shape: BoxShape.circle, color: _brown.withValues(alpha: 0.12))),
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5E3C), Color(0xFF5C3218)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: _brown.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6))],
                ),
                child: const Center(child: Icon(Icons.pets_rounded, color: Colors.white, size: 28)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('PetPal',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: _darkBrown, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        const Text('ดูแลลูกรักด้วยใจ', style: TextStyle(fontSize: 16, color: _mutedBrown, letterSpacing: 0.2)),
      ],
    );
  }

  // ─── Tab Bar ──────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(color: _border.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B5E3C), Color(0xFF5C3218)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: _brown.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: _mutedBrown,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.1),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: const [
          Tab(text: 'เข้าสู่ระบบ'),
          Tab(text: 'สมัครสมาชิก'),
        ],
      ),
    );
  }

  // ─── Login Card ───────────────────────────────────────────────────
  Widget _buildLoginCard() {
    return _card(
      key: const ValueKey('login'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('อีเมล'),
          const SizedBox(height: 8),
          _inputField(
            hint: 'your@email.com',
            icon: Icons.email_outlined,
            controller: _emailCtrl,
            focusNode: _emailFocus,
            nextFocus: _passFocus,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 18),
          _label('รหัสผ่าน'),
          const SizedBox(height: 8),
          _inputField(
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            controller: _passCtrl,
            focusNode: _passFocus,
            obscure: _obscure,
            trailing: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: _mutedBrown),
            ),
          ),
          const SizedBox(height: 24),
          _primaryButton(label: 'เข้าสู่ระบบ', onTap: _loading ? null : _onLogin),
          const SizedBox(height: 18),
          Center(
            child: GestureDetector(
              onTap: _loading ? null : _showForgotPasswordSheet,
              child: const Text('ลืมรหัสผ่าน?',
                  style: TextStyle(fontSize: 14, color: _accent, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Register Card ────────────────────────────────────────────────
  Widget _buildRegisterCard() {
    return _card(
      key: const ValueKey('register'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('ชื่อ-นามสกุล'),
          const SizedBox(height: 8),
          _inputField(
            hint: 'ชื่อของคุณ',
            icon: Icons.person_outline_rounded,
            controller: _nameCtrl,
            focusNode: _nameFocus,
            nextFocus: _emailFocus,
          ),
          const SizedBox(height: 18),
          _label('อีเมล'),
          const SizedBox(height: 8),
          _inputField(
            hint: 'your@email.com',
            icon: Icons.email_outlined,
            controller: _emailCtrl,
            focusNode: _emailFocus,
            nextFocus: _passFocus,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 18),
          _label('รหัสผ่าน'),
          const SizedBox(height: 8),
          _inputField(
            hint: 'อย่างน้อย 8 ตัวอักษร',
            icon: Icons.lock_outline_rounded,
            controller: _passCtrl,
            focusNode: _passFocus,
            obscure: _obscure,
            trailing: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: _mutedBrown),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 12, color: _mutedBrown),
              const SizedBox(width: 5),
              Text('รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร',
                  style: TextStyle(fontSize: 13, color: _mutedBrown.withValues(alpha: 0.9))),
            ],
          ),
          const SizedBox(height: 24),
          _primaryButton(label: 'สร้างบัญชีใหม่', onTap: _loading ? null : _onRegister),
        ],
      ),
    );
  }

  // ─── Reusable Widgets ─────────────────────────────────────────────

  Widget _blob(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }

  Widget _card({required Widget child, Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1),
        boxShadow: [BoxShadow(color: _brown.withValues(alpha: 0.07), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _darkBrown, letterSpacing: 0.1));
  }

  Widget _inputField({
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    bool obscure = false,
    Widget? trailing,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _bgCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
        onSubmitted: (_) {
          if (nextFocus != null) FocusScope.of(context).requestFocus(nextFocus);
        },
        style: const TextStyle(fontSize: 16, color: _darkBrown, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: Padding(padding: const EdgeInsets.only(left: 4), child: Icon(icon, color: _mutedBrown, size: 20)),
          suffixIcon: trailing != null ? Padding(padding: const EdgeInsets.only(right: 4), child: trailing) : null,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: _mutedBrown.withValues(alpha: 0.6), fontSize: 16, fontWeight: FontWeight.w400),
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
        ),
      ),
    );
  }

  Widget _primaryButton({required String label, VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ).copyWith(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          shadowColor: WidgetStateProperty.all(Colors.transparent),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: onTap == null
                ? LinearGradient(colors: [_mutedBrown, _mutedBrown.withValues(alpha: 0.8)])
                : const LinearGradient(
                    colors: [Color(0xFF8B5E3C), Color(0xFF5C3218)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: onTap != null
                ? [BoxShadow(color: _brown.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5))]
                : [],
          ),
          child: Container(
            alignment: Alignment.center,
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(label,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: _border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('หรือเข้าสู่ระบบด้วย',
              style: TextStyle(fontSize: 14, color: _mutedBrown.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
        ),
        Expanded(child: Divider(color: _border, thickness: 1)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : _onGoogleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _darkBrown,
          elevation: 2,
          shadowColor: _brown.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: _border, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 22, height: 22, child: Image.asset('assets/images/google_logo.png')),
            const SizedBox(width: 12),
            const Text('เข้าสู่ระบบด้วย Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
