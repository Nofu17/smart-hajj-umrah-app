import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'main.dart';
import 'ritual_screens.dart';
import 'map_safety_screens.dart';
import 'service_screens.dart';
import 'utility_screens.dart';
import 'settings/settings_screen.dart';

// ─────────────────────────────────────────────
//  شاشة اختيار اللغة
// ─────────────────────────────────────────────
class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});
  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  String? _selectedCode;

  final List<Map<String, String>> _languages = [
    {'name': 'العربية', 'sub': 'Arabic', 'code': 'ar', 'flag': '🇸🇦'},
    {'name': 'English', 'sub': 'English', 'code': 'en', 'flag': '🇬🇧'},
    {'name': 'اردو', 'sub': 'Urdu', 'code': 'ur', 'flag': '🇵🇰'},
    {'name': 'Bahasa Indonesia', 'sub': 'Indonesian', 'code': 'id', 'flag': '🇮🇩'},
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _selectLanguage(SmartHajjAppState state, String code) {
    setState(() => _selectedCode = code);
    state.setLocale(Locale(code));
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(milliseconds: 400), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const WelcomeScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<SmartHajjAppState>()!;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0D2818),
              const Color(0xFF1A4230),
              const Color(0xFF0D2818),
            ],
          ),
        ),
        child: Stack(children: [
          // خلفية النمط الإسلامي
          Positioned.fill(
            child: Opacity(opacity: 0.04, child: CustomPaint(painter: IslamicPatternPainter())),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(children: [
                  const SizedBox(height: 50),
                  // أيقونة مسجد
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        const Color(0xFFC9A84C).withOpacity(0.25),
                        const Color(0xFFC9A84C).withOpacity(0.05),
                        Colors.transparent,
                      ]),
                      boxShadow: [BoxShadow(color: const Color(0xFFC9A84C).withOpacity(0.25),
                          blurRadius: 50, spreadRadius: 5)],
                    ),
                    child: const Icon(Icons.mosque_rounded, size: 50, color: Color(0xFFD4AF37)),
                  ),
                  const SizedBox(height: 24),
                  Text('Choose Your Language',
                      style: TextStyle(color: const Color(0xFFE8C96D), fontSize: 24,
                          fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Text('اختر لغتك المفضلة',
                      style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 15)),
                  const SizedBox(height: 40),
                  // قائمة اللغات
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      itemCount: _languages.length,
                      itemBuilder: (context, i) {
                        final lang = _languages[i];
                        final isSelected = _selectedCode == lang['code'] ||
                            (_selectedCode == null && state.locale.languageCode == lang['code']);
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 500 + i * 100),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, child) => Opacity(
                            opacity: v,
                            child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child),
                          ),
                          child: GestureDetector(
                            onTap: () => _selectLanguage(state, lang['code']!),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: isSelected
                                    ? const Color(0xFFC9A84C).withOpacity(0.18)
                                    : Colors.white.withOpacity(0.07),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFC9A84C)
                                      : Colors.white.withOpacity(0.15),
                                  width: isSelected ? 2 : 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: const Color(0xFFC9A84C).withOpacity(0.2),
                                    blurRadius: 20, offset: const Offset(0, 6))]
                                    : [],
                              ),
                              child: Row(children: [
                                Text(lang['flag']!, style: const TextStyle(fontSize: 34)),
                                const SizedBox(width: 18),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(lang['name']!, style: TextStyle(
                                        color: Colors.white, fontSize: 18,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                                    Text(lang['sub']!, style: TextStyle(
                                        color: Colors.white.withOpacity(0.5), fontSize: 13)),
                                  ],
                                )),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: 30, height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? const Color(0xFFC9A84C) : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFFC9A84C)
                                          : Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: Color(0xFF0D2818), size: 16)
                                      : null,
                                ),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  شاشة الترحيب
// ─────────────────────────────────────────────
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<SmartHajjAppState>()!;
    final isRTL = state.locale.languageCode == 'ar' || state.locale.languageCode == 'ur';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF0D2818), Color(0xFF1A4230), Color(0xFF0D2818)],
            ),
          ),
          child: Stack(children: [
            Positioned.fill(
              child: Opacity(opacity: 0.04, child: CustomPaint(painter: IslamicPatternPainter())),
            ),
            SafeArea(
              child: Column(children: [
                const Spacer(flex: 2),
                // أيقونة
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) => Transform.scale(
                    scale: CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.elasticOut)).value,
                    child: Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          const Color(0xFFC9A84C).withOpacity(0.3),
                          const Color(0xFFC9A84C).withOpacity(0.08),
                          Colors.transparent,
                        ]),
                        boxShadow: [BoxShadow(color: const Color(0xFFC9A84C).withOpacity(0.3),
                            blurRadius: 60, spreadRadius: 10)],
                      ),
                      child: const Icon(Icons.mosque_rounded, size: 60, color: Color(0xFFD4AF37)),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                // البطاقة المركزية
                FadeTransition(
                  opacity: CurvedAnimation(parent: _ctrl,
                      curve: const Interval(0.3, 0.8, curve: Curves.easeOut)),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFC9A84C).withOpacity(0.25), width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2),
                          blurRadius: 30, offset: const Offset(0, 15))],
                    ),
                    child: Column(children: [
                      // خط فاصل مع نص
                      Row(children: [
                        Expanded(child: Divider(color: const Color(0xFFE8C96D).withOpacity(0.4), thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(state.translate('welcome'),
                              style: const TextStyle(color: Color(0xFFE8C96D),
                                  fontSize: 18, fontWeight: FontWeight.w300, letterSpacing: 2)),
                        ),
                        Expanded(child: Divider(color: const Color(0xFFE8C96D).withOpacity(0.4), thickness: 1)),
                      ]),
                      const SizedBox(height: 20),
                      Text(state.translate('app_title'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 28,
                              fontWeight: FontWeight.bold, height: 1.4)),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFC9A84C).withOpacity(0.15)),
                        ),
                        child: Text(state.translate('blessing_msg'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: const Color(0xFFE8C96D).withOpacity(0.85),
                                fontSize: 15, height: 1.7)),
                      ),
                    ]),
                  ),
                ),
                const Spacer(flex: 2),
                // زر البدء
                FadeTransition(
                  opacity: CurvedAnimation(parent: _ctrl,
                      curve: const Interval(0.6, 1, curve: Curves.easeOut)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pushReplacement(context, PageRouteBuilder(
                          pageBuilder: (_, a, __) => const HomeScreens(),
                          transitionsBuilder: (_, a, __, child) =>
                              FadeTransition(opacity: a, child: child),
                          transitionDuration: const Duration(milliseconds: 700),
                        ));
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFC9A84C), Color(0xFFE8C96D), Color(0xFFC9A84C)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [BoxShadow(color: const Color(0xFFC9A84C).withOpacity(0.45),
                              blurRadius: 25, spreadRadius: 2, offset: const Offset(0, 10))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(state.translate('start'),
                                style: const TextStyle(color: Color(0xFF0D2818),
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D2818).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isRTL ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                                color: const Color(0xFF0D2818), size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 44),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  رسم الخلفية الإسلامية
// ─────────────────────────────────────────────
class IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const spacing = 55.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), 12, paint);
        canvas.drawLine(Offset(x - 7, y), Offset(x + 7, y), paint);
        canvas.drawLine(Offset(x, y - 7), Offset(x, y + 7), paint);
        for (int j = 0; j < 8; j++) {
          final angle = j * math.pi / 4;
          final dx = math.cos(angle) * 20;
          final dy = math.sin(angle) * 20;
          canvas.drawCircle(Offset(x + dx, y + dy), 4, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
//  الشاشة الرئيسية
// ─────────────────────────────────────────────
class HomeScreens extends StatefulWidget {
  const HomeScreens({super.key});
  @override
  State<HomeScreens> createState() => _HomeScreensState();
}

class _HomeScreensState extends State<HomeScreens> {
  final _scroll = ScrollController();

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<SmartHajjAppState>()!;
    final isRTL = state.locale.languageCode == 'ar' || state.locale.languageCode == 'ur';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F5F3),
        body: CustomScrollView(
          controller: _scroll,
          slivers: [
            // ── SliverAppBar متحرك ──
            SliverAppBar(
              expandedHeight: 200, 
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFF0D2818),
              surfaceTintColor: Colors.transparent,
              // ── إصلاح زر الباك (الرجوع) ──
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () {
                  // يحاول يرجع للشاشة اللي قبلها في السجل
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    // إذا كنت في الهوم ومافي سجل، يرجعك لشاشة اختيار اللغة كخطوة أخيرة
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                    );
                  }
                },
              ),
              actions: [
                // ── زر الإعدادات الأنيق ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => SettingsScreen(onLocaleChanged: () => setState(() {})))),
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9A84C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFC9A84C).withOpacity(0.4), width: 1),
                        ),
                        child: const Icon(Icons.settings_suggest_rounded, color: Color(0xFFD4AF37), size: 24),
                      ),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 15),
                title: Text(state.translate('app_title'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                        color: Colors.white, letterSpacing: 0.3)),
                background: Stack(children: [
                  // خلفية الهيدر
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight, end: Alignment.bottomLeft,
                        colors: [Color(0xFF0D2818), Color(0xFF1A4230), Color(0xFF2D6A4F)],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(opacity: 0.05, child: CustomPaint(painter: IslamicPatternPainter())),
                  ),
                  // بطاقة الترحيب (نفس كودك الأصلي بالتمام)
                  Positioned(
                    bottom: 50, left: 16, right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFC9A84C).withOpacity(0.25)),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC9A84C).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.mosque_rounded, color: Color(0xFFD4AF37), size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(state.translate('app_title'),
                              style: const TextStyle(color: Colors.white, fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(state.translate('blessing_msg'),
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                        ])),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC9A84C).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('✦ ${state.translate("welcome")}',
                              style: const TextStyle(color: Color(0xFFE8C96D),
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
            // ── المحتوى ──
            SliverToBoxAdapter(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 20),

                // ── بانر الصلاة القادمة ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _PrayerBanner(state: state),
                ),

                const SizedBox(height: 22),

                // ── عنوان الخدمات ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Container(width: 4, height: 20, decoration: BoxDecoration(
                        color: const Color(0xFFC9A84C), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 10),
                    Text(state.translate('main_services'),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2E1F))),
                  ]),
                ),

                const SizedBox(height: 14),

                // ── شبكة الخدمات ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.0,
                    children: [
                      _ServiceCard(
                          cardKey: 'map', icon: '🗺️', isFeatured: true, state: state,
                          onTap: () => _navigate(const MapSafetyScreens(mode: "map"))),
                      _ServiceCard(
                          cardKey: 'group', icon: '👥', badge: true, state: state,
                          onTap: () => _navigate(const MapSafetyScreens(mode: "group"))),
                     _ServiceCard(
                     cardKey: 'counter',
                     icon: '🔢',
                     state: state,
                     onTap: () => _navigate(const ServiceScreens(mode: "counter")),
                    ),
                      _ServiceCard(
                          cardKey: 'ritual', icon: '📖', state: state,
                          onTap: () => _navigate(const RitualScreens(mode: "ritual"))),
                      _ServiceCard(
                          cardKey: 'prayer', icon: '🕐', state: state,
                          onTap: () => _navigate(const RitualScreens(mode: "prayer"))),
                      _ServiceCard(
                          cardKey: 'dua', icon: '🤲', state: state,
                          onTap: () => _navigate(const RitualScreens(mode: "dua"))),
                      _ServiceCard(
                          cardKey: 'services', icon: '🏥', state: state,
                          onTap: () => _navigate(const ServiceScreens(mode: "services"))),
                      _ServiceCard(
                          cardKey: 'qibla', icon: '🧭', state: state,
                          onTap: () => _navigate(const UtilityScreens(mode: "qibla"))),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ── زر الطوارئ ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _EmergencyButton(state: state,
                      onTap: () => _navigate(const UtilityScreens(mode: "emergency"))),
                ),

                const SizedBox(height: 30),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(Widget target) {
    HapticFeedback.selectionClick();
    Navigator.push(context, MaterialPageRoute(builder: (_) => target));
  }
}

// ─────────────────────────────────────────────
//  بانر الصلاة
// ─────────────────────────────────────────────
class _PrayerBanner extends StatelessWidget {
  final SmartHajjAppState state;
  const _PrayerBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final prayers = [
      {'icon': '🌙', 'key': 'p1', 'time': '05:10'},
      {'icon': '☀️', 'key': 'p2', 'time': '12:22'},
      {'icon': '🌤️', 'key': 'p3', 'time': '15:45'},
      {'icon': '🌅', 'key': 'p4', 'time': '18:15'},
      {'icon': '🌃', 'key': 'p5', 'time': '19:45'},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFFF8E7), const Color(0xFFFDF3D0)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC9A84C).withOpacity(0.3)),
        boxShadow: [BoxShadow(color: const Color(0xFFC9A84C).withOpacity(0.1),
            blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFC9A84C).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.access_time_rounded, color: Color(0xFF8B6914), size: 14),
              const SizedBox(width: 5),
              Text(state.translate('prayer_times'),
                  style: const TextStyle(color: Color(0xFF8B6914),
                      fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
          ),
          const Spacer(),
          Text(state.translate('makkah'),
              style: const TextStyle(color: Color(0xFF8B6914), fontSize: 12)),
          const SizedBox(width: 4),
          const Icon(Icons.location_on, color: Color(0xFFC9A84C), size: 14),
        ]),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: prayers.map((p) {
            final isCurrent = p['key'] == 'p4';
            return Column(children: [
              Text(p['icon']!, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text(state.translate(p['key']!),
                  style: TextStyle(
                      fontSize: 11,
                      color: isCurrent ? const Color(0xFF6B4A00) : const Color(0xFF8B6914).withOpacity(0.7),
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isCurrent ? const Color(0xFFC9A84C) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isCurrent ? null
                      : Border.all(color: const Color(0xFFC9A84C).withOpacity(0.3)),
                ),
                child: Text(p['time']!,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? const Color(0xFF3D2800) : const Color(0xFF8B6914))),
              ),
            ]);
          }).toList(),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
//  بطاقة الخدمة
// ─────────────────────────────────────────────
class _ServiceCard extends StatefulWidget {
  final String cardKey;
  final String icon;
  final bool isFeatured;
  final bool badge;
  final SmartHajjAppState state;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.cardKey,
    required this.icon,
    required this.state,
    required this.onTap,
    this.isFeatured = false,
    this.badge = false,
    super.key,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() { _pressed = true; _ctrl.forward(); }),
      onTapUp: (_) { setState(() => _pressed = false); _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () { setState(() => _pressed = false); _ctrl.reverse(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_pressed ? 0.96 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: widget.isFeatured
              ? const LinearGradient(
              begin: Alignment.topRight, end: Alignment.bottomLeft,
              colors: [Color(0xFF0D2818), Color(0xFF1A4230), Color(0xFF2D6A4F)])
              : const LinearGradient(
              colors: [Colors.white, Color(0xFFFAFCFB)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: widget.isFeatured
                ? const Color(0xFFC9A84C).withOpacity(0.3)
                : const Color(0xFF0D2818).withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isFeatured
                  ? const Color(0xFF0D2818).withOpacity(0.25)
                  : Colors.black.withOpacity(0.06),
              blurRadius: widget.isFeatured ? 20 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(children: [
          // الزاوية الزخرفية
          Positioned(
            top: 0, right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(22)),
              child: Container(
                width: 40, height: 40, // صغرنا حجم الزخرفة قليلاً
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    colors: [
                      (widget.isFeatured ? Colors.white : const Color(0xFF2D6A4F))
                          .withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12), // قللنا الـ padding من 18 إلى 12 لتوفير مساحة
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // الأيقونة مع badge
                Stack(children: [
                  Container(
                    width: 48, height: 48, // صغرنا الأيقونة قليلاً (من 56 إلى 48)
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: widget.isFeatured
                          ? const Color(0xFFC9A84C).withOpacity(0.15)
                          : const Color(0xFF2D6A4F).withOpacity(0.09),
                    ),
                    child: Center(
                      child: Text(widget.icon, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  if (widget.badge)
                    Positioned(
                      top: -2, right: -2,
                      child: Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF40916C),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ]),

                // الاسم والسهم
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // حل مشكلة النص الطويل باستخدام FittedBox
                    SizedBox(
                      height: 20, // تحديد ارتفاع ثابت للنص
                      child: FittedBox(
                        fit: BoxFit.scaleDown, // سيقوم بتصغير النص لو كان أطول من المساحة
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          widget.state.translate(widget.cardKey),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: widget.isFeatured ? Colors.white : const Color(0xFF1A2E1F),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isFeatured
                            ? const Color(0xFFC9A84C).withOpacity(0.2)
                            : const Color(0xFF0D2818).withOpacity(0.06),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: widget.isFeatured
                            ? const Color(0xFFE8C96D)
                            : const Color(0xFF3D5A47),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
// ─────────────────────────────────────────────
//  زر الطوارئ
// ─────────────────────────────────────────────
class _EmergencyButton extends StatefulWidget {
  final SmartHajjAppState state;
  final VoidCallback onTap;
  const _EmergencyButton({required this.state, required this.onTap});
  @override
  State<_EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<_EmergencyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2200))..repeat();
  }

  @override
  void dispose() { _shimmerCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.heavyImpact(); widget.onTap(); },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight, end: Alignment.bottomLeft,
            colors: [Color(0xFFC1121F), Color(0xFFE63946), Color(0xFFC1121F)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: const Color(0xFFE63946).withOpacity(0.38),
              blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: const Center(child: Text('🆘', style: TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.state.translate('emergency'),
                style: const TextStyle(color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(widget.state.translate('emergency_desc'),
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
          ])),
          AnimatedBuilder(
            animation: _shimmerCtrl,
            builder: (_, __) => Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12 + 0.1 * math.sin(_shimmerCtrl.value * math.pi * 2)),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 22),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  🔢 شاشة عداد الأشواط – كاملة ومحسّنة
// ─────────────────────────────────────────────
class LapCounterScreen extends StatefulWidget {
  const LapCounterScreen({super.key});
  @override
  State<LapCounterScreen> createState() => _LapCounterScreenState();
}

class _LapCounterScreenState extends State<LapCounterScreen>
    with SingleTickerProviderStateMixin {
  int _currentLap = 0;   // 0-6 → أشواط 1-7
  bool _isComplete = false;
  DateTime? _lastTap;
  String _ritualType = 'tawaf_umrah';

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // الأدعية لكل شوط (عربي)
  final List<String> _duas = [
    'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لَا شَرِيكَ لَكَ لَبَّيْكَ',
    'سُبْحَانَ اللَّهِ وَالْحَمْدُ لِلَّهِ وَلَا إِلَهَ إِلَّا اللَّهُ وَاللَّهُ أَكْبَرُ',
    'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
    'اللَّهُمَّ اجْعَلْهُ حَجًّا مَبْرُورًا وَسَعْيًا مَشْكُورًا وَذَنْبًا مَغْفُورًا',
    'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ',
    'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ',
    'رَبِّ اغْفِرْ وَارْحَمْ وَاعْفُ وَتَكَرَّمْ وَتَجَاوَزْ عَمَّا تَعْلَمُ، إِنَّكَ تَعْلَمُ مَا لَا نَعْلَمُ',
  ];

  final Map<String, Map<String, String>> _ritualTypes = {
    'tawaf_umrah':    {'ar': 'طواف العمرة',     'en': 'Umrah Tawaf',    'ur': 'عمرہ طواف',          'id': 'Tawaf Umrah'},
    'tawaf_qudum':    {'ar': 'طواف القدوم',     'en': 'Tawaf Al-Qudum', 'ur': 'طواف قدوم',          'id': 'Tawaf Qudum'},
    'tawaf_ifadah':   {'ar': 'طواف الإفاضة',    'en': 'Tawaf Ifadah',   'ur': 'طواف افاضہ',         'id': 'Tawaf Ifadah'},
    'tawaf_wada':     {'ar': 'طواف الوداع',     'en': 'Farewell Tawaf', 'ur': 'طواف وداع',          'id': 'Tawaf Wada'},
  };

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  void _countLap() {
    if (_isComplete) return;
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!).inMilliseconds < 800) return;
    _lastTap = now;

    HapticFeedback.mediumImpact();
    setState(() {
      if (_currentLap < 7) {
        _currentLap++;
        if (_currentLap == 7) {
          _isComplete = true;
          HapticFeedback.heavyImpact();
          Future.delayed(const Duration(milliseconds: 100), () {
            HapticFeedback.heavyImpact();
          });
        }
      }
    });
  }

  void _reset() {
    showDialog(
      context: context,
      builder: (_) {
        final state = context.findAncestorStateOfType<SmartHajjAppState>()!;
        final isAr = state.locale.languageCode == 'ar';
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isAr ? 'إعادة العداد' : 'Reset Counter',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(isAr ? 'هل تريد إعادة العداد من الصفر؟'
              : 'Are you sure you want to reset?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
                child: Text(state.translate('cancel'),
                    style: const TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () {
                setState(() { _currentLap = 0; _isComplete = false; });
                Navigator.pop(context);
                HapticFeedback.lightImpact();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D2818),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(state.translate('reset')),
            ),
          ],
        );
      },
    );
  }

  void _showTypeSelector(SmartHajjAppState state) {
    final isAr = state.locale.languageCode == 'ar';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text(isAr ? 'اختر نوع الطواف' : 'Select Tawaf Type',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._ritualTypes.entries.map((e) {
            final name = e.value[state.locale.languageCode] ?? e.value['ar']!;
            return ListTile(
              title: Text(name),
              leading: Icon(Icons.radio_button_checked,
                  color: _ritualType == e.key
                      ? const Color(0xFF0D2818) : Colors.grey.shade400),
              onTap: () {
                setState(() { _ritualType = e.key; _currentLap = 0; _isComplete = false; });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<SmartHajjAppState>()!;
    final isRTL = state.locale.languageCode == 'ar' || state.locale.languageCode == 'ur';
    final typeName = _ritualTypes[_ritualType]?[state.locale.languageCode]
        ?? _ritualTypes[_ritualType]!['ar']!;
    final duaText = _currentLap > 0 ? _duas[_currentLap - 1] : _duas[0];
    final progress = _currentLap / 7.0;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D2818),
        body: Column(children: [
          // ── رأس الشاشة ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D2818), Color(0xFF1A4230)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        color: Colors.white.withOpacity(0.08),
                      ),
                      child: Icon(
                        isRTL ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                        color: Colors.white, size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(children: [
                      Text(state.translate('counter'),
                          style: const TextStyle(color: Colors.white, fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => _showTypeSelector(state),
                        child: Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC9A84C).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFC9A84C).withOpacity(0.3)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(typeName,
                                style: const TextStyle(color: Color(0xFFE8C96D),
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down,
                                color: Color(0xFFE8C96D), size: 14),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                  GestureDetector(
                    onTap: _reset,
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        color: const Color(0xFFC9A84C).withOpacity(0.12),
                        border: Border.all(color: const Color(0xFFC9A84C).withOpacity(0.25)),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          color: Color(0xFFD4AF37), size: 22),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          // ── المحتوى الرئيسي ──
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF2F5F3),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(children: [

                  // ── دائرة التقدم ──
                  Center(
                    child: SizedBox(
                      width: 230, height: 230,
                      child: Stack(alignment: Alignment.center, children: [
                        // الحلقة الخارجية
                        SizedBox(
                          width: 230, height: 230,
                          child: CustomPaint(
                            painter: _CircularProgressPainter(
                                progress: progress,
                                bgColor: const Color(0xFFE0E8E4),
                                fgColor: _isComplete
                                    ? const Color(0xFF40916C)
                                    : const Color(0xFFC9A84C)),
                          ),
                        ),
                        // محتوى الدائرة
                        Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(
                            _isComplete ? '✓' : '${_currentLap}',
                            style: TextStyle(
                              fontSize: _isComplete ? 64 : 72,
                              fontWeight: FontWeight.bold,
                              color: _isComplete
                                  ? const Color(0xFF40916C)
                                  : const Color(0xFF0D2818),
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isComplete
                                ? (state.locale.languageCode == 'ar' ? 'اكتمل الطواف 🎉' : 'Tawaf Complete 🎉')
                                : (state.locale.languageCode == 'ar'
                                ? 'من ٧ أشواط'
                                : 'of 7 rounds'),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ]),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── مؤشرات الأشواط ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(7, (i) {
                      final done = i < _currentLap;
                      final current = i == _currentLap - 1 && !_isComplete;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        width: current ? 38 : 34,
                        height: current ? 38 : 34,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: done
                              ? const LinearGradient(
                              colors: [Color(0xFFC9A84C), Color(0xFFE8C96D)])
                              : null,
                          color: done ? null : const Color(0xFFE0E8E4),
                          border: Border.all(
                            color: current
                                ? const Color(0xFFC9A84C)
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: current
                              ? [BoxShadow(color: const Color(0xFFC9A84C).withOpacity(0.4),
                              blurRadius: 12)]
                              : [],
                        ),
                        child: Center(
                          child: Text('${i + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: done
                                    ? const Color(0xFF3D2800)
                                    : Colors.grey.shade500,
                              )),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // ── دعاء الشوط ──
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFC9A84C).withOpacity(0.2)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                          blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('📿', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          state.locale.languageCode == 'ar'
                              ? 'دعاء الشوط ${_currentLap > 0 ? _currentLap : 1}'
                              : 'Dua for Round ${_currentLap > 0 ? _currentLap : 1}',
                          style: const TextStyle(fontSize: 13,
                              color: Color(0xFF8B6914), fontWeight: FontWeight.bold),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Text(
                        duaText,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 16, height: 1.9,
                          color: Color(0xFF1A2E1F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 24),

                  // ── زر الضغط الكبير ──
                  if (!_isComplete)
                    GestureDetector(
                      onTap: _countLap,
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) => Container(
                          width: 170, height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Color(0xFF1A4230), Color(0xFF0D2818)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFC9A84C).withOpacity(
                                    0.15 + 0.15 * _pulseAnim.value),
                                blurRadius: 30 + 20 * _pulseAnim.value,
                                spreadRadius: 5 * _pulseAnim.value,
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFFC9A84C).withOpacity(
                                  0.3 + 0.2 * _pulseAnim.value),
                              width: 2.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🕋', style: TextStyle(fontSize: 40)),
                              const SizedBox(height: 8),
                              Text(
                                state.locale.languageCode == 'ar' ? 'اضغط للعدّ'
                                    : state.locale.languageCode == 'ur' ? 'شمار کریں'
                                    : state.locale.languageCode == 'id' ? 'Ketuk'
                                    : 'Tap to Count',
                                style: const TextStyle(
                                  color: Color(0xFFE8C96D),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                  // ── رسالة الاكتمال ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF40916C), Color(0xFF2D6A4F)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: const Color(0xFF40916C).withOpacity(0.3),
                            blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Column(children: [
                        const Text('🎉', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          state.locale.languageCode == 'ar'
                              ? 'تبارك الله! اكتمل طوافك'
                              : state.locale.languageCode == 'ur'
                              ? 'ماشاء اللہ! طواف مکمل ہوا'
                              : state.locale.languageCode == 'id'
                              ? 'Alhamdulillah! Tawaf Selesai'
                              : 'Alhamdulillah! Tawaf Complete',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.locale.languageCode == 'ar'
                              ? 'تقبل الله منك وأعظم أجرك'
                              : 'May Allah accept your worship',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() { _currentLap = 0; _isComplete = false; });
                            HapticFeedback.lightImpact();
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(state.translate('reset')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF2D6A4F),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ]),
                    ),

                  const SizedBox(height: 30),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// رسام حلقة التقدم
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color bgColor;
  final Color fgColor;
  const _CircularProgressPainter({
    required this.progress, required this.bgColor, required this.fgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width - 18) / 2;
    final strokeW = 14.0;

    final bg = Paint()
      ..color = bgColor
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..color = fgColor
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), radius, bg);

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle, sweepAngle, false, fg,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) =>
      old.progress != progress || old.fgColor != fgColor;
}

