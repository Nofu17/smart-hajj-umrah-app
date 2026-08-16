import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'main.dart';
import 'data/database/database_helper.dart';
import 'data/models/ritual_model.dart';
import 'data/models/ritual_step_model.dart';
import 'data/models/dua_model.dart';
import 'services/prayer_service.dart';
import 'package:adhan/adhan.dart';
import 'notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// ═════════════════════════════════════════════════════════════
//  Ritual Screens - المناسك والأدعية ومواقيت الصلاة
//  تصميم احترافي محسّن مع الحفاظ على كل الوظائف
// ═════════════════════════════════════════════════════════════
class RitualScreens extends StatefulWidget {
  final String mode;
  const RitualScreens({super.key, required this.mode});

  @override
  State<RitualScreens> createState() => _RitualScreensState();
}

class _RitualScreensState extends State<RitualScreens>
    with SingleTickerProviderStateMixin {
  String? selectedHajj;
  int stepIdx = 0;
  int duaIdx = 0;

  // Database Variables
  List<RitualStepModel> currentSteps = [];
  List<DuaModel> duas = [];
  bool isLoading = true;

  // Prayer Variables
  PrayerTimes? prayerTimes;
  bool loadingPrayers = true;

  // Animation Controller
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _loadDuas();
    if (widget.mode == "prayer") {
      _loadPrayerTimes();
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDuas() async {
    final loadedDuas = await DatabaseHelper.instance.getAllDuas();
    setState(() {
      duas = loadedDuas;
      isLoading = false;
    });
  }

  Future<void> _loadRitualSteps(String ritualType) async {
    setState(() => isLoading = true);

    final rituals = await DatabaseHelper.instance.getAllRituals();
    final ritual = rituals.firstWhere(
          (r) => r.ritualType == ritualType,
      orElse: () => rituals.first,
    );

    final steps = await DatabaseHelper.instance.getStepsByRitualId(ritual.id!);

    setState(() {
      currentSteps = steps;
      stepIdx = 0;
      isLoading = false;
    });
  }

  Future<void> _loadPrayerTimes() async {
    setState(() => loadingPrayers = true);
    try {
      final times = await PrayerService.instance.calculatePrayerTimes();
      setState(() {
        prayerTimes = times;
        loadingPrayers = false;
      });
      print('✅ تم تحميل أوقات الصلاة وعرضها بنجاح دون التأثير على الإشعارات الأخرى');
    } catch (e) {
      print('❌ خطأ في تحميل أوقات الصلاة داخل الشاشة: $e');
      setState(() => loadingPrayers = false);
    }
  }

  void _handleNextStep() {
    if (stepIdx < currentSteps.length - 1) {
      setState(() => stepIdx++);
      HapticFeedback.selectionClick();
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final state = context.findAncestorStateOfType<SmartHajjAppState>()!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF40916C).withOpacity(0.2),
                    const Color(0xFF40916C).withOpacity(0.05),
                  ],
                ),
              ),
              child: const Icon(
                Icons.celebration_rounded,
                size: 50,
                color: Color(0xFF40916C),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              state.locale.languageCode == 'ar' ? 'تم بنجاح!' : 'Completed!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D2818),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              state.locale.languageCode == 'ar'
                  ? 'أكملت جميع الخطوات'
                  : 'You completed all steps',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2818),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                state.locale.languageCode == 'ar' ? 'حسناً' : 'OK',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<SmartHajjAppState>()!;
    final isRTL = state.locale.languageCode == 'ar' || state.locale.languageCode == 'ur';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F5F3),
        body: _buildContent(state, isRTL),
      ),
    );
  }

  Widget _buildContent(SmartHajjAppState state, bool isRTL) {
    switch (widget.mode) {
      case "dua":
        return _buildDuaView(state, isRTL);
      case "prayer":
        return _buildPrayerView(state, isRTL);
      default:
        return selectedHajj == null
            ? _buildHajjTypeSelection(state, isRTL)
            : _buildStepByStepRitual(state, isRTL);
    }
  }

 // الأدعية 💎 
Widget _buildDuaView(SmartHajjAppState state, bool isRTL) {
  if (isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF1B4332)));
  if (duas.isEmpty) return const Center(child: Text("No Duas Found"));

  final currentDua = duas[duaIdx % duas.length];
  bool isLast = duaIdx == (duas.length - 1);
  bool isArabic = state.locale.languageCode == 'ar';

  String activeTranslation = '';
  String pronunciation = currentDua.transliteration ?? ""; 

  if (!isArabic) {
    switch (state.locale.languageCode) {
      case 'en': activeTranslation = currentDua.translationEn; break;
      case 'ur': activeTranslation = currentDua.translationUr; break;
      case 'id': activeTranslation = currentDua.translationId; break;
      default: activeTranslation = currentDua.translationEn; 
    }
  }

  String copyLabel = isRTL ? "نسخ" : "Copy";

  return Scaffold(
    backgroundColor: const Color(0xFFF8FAF9),
    body: Stack(
      children: [
        // الخلفية العلوية
        Container(
          height: MediaQuery.of(context).size.height * 0.42,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF061A12), Color(0xFF1B4332)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(65)),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              // الهيدر: السهم الآن يمين (>) في العربي
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGlobalBackButton(isRTL),
                    Text(state.translate('dua').toUpperCase(), 
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
                    const SizedBox(width: 50), 
                  ],
                ),
              ),

              // البطاقة المركزية مع الترجمة والنطق
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(25, 10, 25, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(55),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40, offset: const Offset(0, 20))],
                  ),
                  child: Column(
                    children: [
                      _buildCounter(duaIdx + 1, duas.length),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                          child: Column(
                            children: [
                              const Icon(Icons.format_quote_rounded, color: Color(0xFFD8E2DC), size: 55),
                              const SizedBox(height: 10),
                              Text(
                                currentDua.arabicText,
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(fontSize: 28, height: 1.8, fontWeight: FontWeight.bold, color: Color(0xFF081C15), fontFamily: 'Amiri'),
                              ),
                              // إظهار الترجمة والنطق لغير العرب
                              if (!isArabic) ...[
                                if (pronunciation.isNotEmpty) ...[
                                  const SizedBox(height: 15),
                                  Text(pronunciation, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Color(0xFFC9A84C), fontWeight: FontWeight.w600, fontStyle: FontStyle.italic)),
                                ],
                                const SizedBox(height: 20),
                                Container(width: 40, height: 1, color: Colors.grey.shade100),
                                const SizedBox(height: 20),
                                Text(activeTranslation, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, color: Colors.grey.shade600, height: 1.5)),
                              ],
                            ],
                          ),
                        ),
                      ),
                      _buildMinimalCopyButton(currentDua.arabicText, activeTranslation, copyLabel),
                    ],
                  ),
                ),
              ),

              // شريط التنقل السفلي (بريميوم)
              _buildPremiumNavBar(isRTL, isLast, state),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildGlobalBackButton(bool isRTL) {
  return InkWell(
    onTap: () => Navigator.pop(context),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
      // Directionality تضمن أن السهم لليمين في العربي >
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Icon(
          isRTL ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_rounded, 
          color: Colors.white, 
          size: 18
        ),
      ),
    ),
  );
}

Widget _buildPremiumNavBar(bool isRTL, bool isLast, SmartHajjAppState state) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
    child: Row(
      children: [
        // زر السابق (السهم لليمين في العربي >)
        _navCircleButton(isRTL, () {
          if (duaIdx > 0) setState(() => duaIdx--);
        }),
        const SizedBox(width: 15),
        Expanded(
          child: _navMainButton(
            isLast ? (isRTL ? "إكمال" : "FINISH") : (isRTL ? "التالي" : "NEXT"),
            () {
              if (isLast) _showSuccessOverlay(state); 
              else setState(() => duaIdx++);
            }, 
            isLast
          ),
        ),
      ],
    ),
  );
}

Widget _navCircleButton(bool isRTL, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    child: Container(
      height: 65, width: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15)],
      ),
      // إزالة Directionality اليدوية وترك فلاتر يتعامل مع السهم
      child: const Icon(
        Icons.arrow_back_ios_new_rounded, // هذا السهم سينقلب لليمين تلقائياً في العربي
        color: Color(0xFF081C15), 
        size: 20
      ),
    ),
  );
}

// نافذة النجاح بالنص الصحيح: "تم إكمال الأدعية بنجاح"
void _showSuccessOverlay(SmartHajjAppState state) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 70, color: Color(0xFF1B4332)),
          const SizedBox(height: 20),
          Text(
            state.locale.languageCode == 'ar' ? "تم إكمال الأدعية بنجاح" : "All Duas Completed!", 
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 30),
          _navMainButton(state.locale.languageCode == 'ar' ? "رجوع" : "Back", () { 
            Navigator.pop(context); 
            Navigator.pop(context); 
          }, true),
        ],
      ),
    ),
  );
}

// دالة الـ Counter وزر النسخ
Widget _buildCounter(int current, int total) {
  return Container(
    margin: const EdgeInsets.only(top: 25),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(color: const Color(0xFFF1F5F3), borderRadius: BorderRadius.circular(15)),
    child: Text("$current  /  $total", style: const TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.w900, fontSize: 13)),
  );
}

Widget _buildMinimalCopyButton(String arabic, String trans, String label) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 25),
    child: InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: trans.isEmpty ? arabic : "$arabic\n\n$trans"));
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$label ✅"), behavior: SnackBarBehavior.floating, width: 100, backgroundColor: const Color(0xFF1B4332))
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.copy_rounded, color: Color(0xFFC9A84C), size: 16),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    ),
  );
}

Widget _navMainButton(String label, VoidCallback onTap, bool isFinish) {
  return InkWell(
    onTap: onTap,
    child: Container(
      height: 65,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFinish ? [const Color(0xFFC9A84C), const Color(0xFF8B6914)] : [const Color(0xFF081C15), const Color(0xFF1B4332)],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Center(
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
      ),
    ),
  );
}

  // ═════════════════════════════════════════════════════════════
  //  🕌 PRAYER TIMES SCREEN - مواقيت الصلاة محسّنة
  // ═════════════════════════════════════════════════════════════
  Widget _buildPrayerView(SmartHajjAppState state, bool isRTL) {
    if (loadingPrayers) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0D2818)),
      );
    }

    if (prayerTimes == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              state.locale.languageCode == 'ar'
                  ? 'تعذر تحميل أوقات الصلاة'
                  : 'Could not load prayer times',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadPrayerTimes,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(state.locale.languageCode == 'ar' ? 'إعادة المحاولة' : 'Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D2818),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      );
    }

    final prayers = [
      {'prayer': Prayer.fajr, 'time': prayerTimes!.fajr, 'icon': Icons.nightlight_round},
      {'prayer': Prayer.dhuhr, 'time': prayerTimes!.dhuhr, 'icon': Icons.wb_sunny_outlined},
      {'prayer': Prayer.asr, 'time': prayerTimes!.asr, 'icon': Icons.cloud_outlined},
      {'prayer': Prayer.maghrib, 'time': prayerTimes!.maghrib, 'icon': Icons.wb_twilight},
      {'prayer': Prayer.isha, 'time': prayerTimes!.isha, 'icon': Icons.nightlight_outlined},
    ];

    final currentPrayer = PrayerService.instance.getCurrentPrayer(prayerTimes!);
    final nextPrayer = PrayerService.instance.getNextPrayer(prayerTimes!);
    final timeUntilNext = PrayerService.instance.getTimeUntilNextPrayer(prayerTimes!);

    return Column(
      children: [
        // ── Header ──
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D2818), Color(0xFF1A4230)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        color: Colors.white.withOpacity(0.08),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                
                  Expanded(
                    child: Text(
                      state.translate('prayer'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),
          ),
        ),

        // ── Next Prayer Banner ──
        if (nextPrayer != null)
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D2818), Color(0xFF1A4230)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D2818).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  state.locale.languageCode == 'ar' ? 'الصلاة التالية' : 'Next Prayer',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                ),
                const SizedBox(height: 10),
                Text(
                  PrayerService.instance.getPrayerName(nextPrayer, state.locale.languageCode),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9A84C).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC9A84C).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_rounded, color: const Color(0xFFE8C96D), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _formatCountdown(timeUntilNext),
                        style: const TextStyle(
                          color: Color(0xFFE8C96D),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // ── Prayer Times List ──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: prayers.length,
            itemBuilder: (context, index) {
              final prayer = prayers[index]['prayer'] as Prayer;
              final time = prayers[index]['time'] as DateTime;
              final icon = prayers[index]['icon'] as IconData;

              final isCurrent = prayer == currentPrayer;
              final isNext = prayer == nextPrayer;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? const Color(0xFF0D2818).withOpacity(0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isCurrent
                        ? const Color(0xFF0D2818)
                        : (isNext
                        ? const Color(0xFFC9A84C).withOpacity(0.4)
                        : Colors.transparent),
                    width: isCurrent ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFF0D2818)
                          : const Color(0xFF0D2818).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isCurrent ? Colors.white : const Color(0xFF0D2818),
                      size: 26,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        PrayerService.instance.getPrayerName(
                          prayer,
                          state.locale.languageCode,
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                          color: isCurrent
                              ? const Color(0xFF0D2818)
                              : const Color(0xFF1A2E1F),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D2818),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            state.locale.languageCode == 'ar' ? 'الآن' : 'Now',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else if (isNext) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC9A84C),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            state.locale.languageCode == 'ar' ? 'التالية' : 'Next',
                            style: const TextStyle(
                              color: Color(0xFF3D2800),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Text(
                    _formatPrayerTime(time, state.locale.languageCode),
                    style: TextStyle(
                      fontSize: 18,
                      color: isCurrent
                          ? const Color(0xFF0D2818)
                          : const Color(0xFF1A2E1F),
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatPrayerTime(DateTime time, String languageCode) {
    final formatted = PrayerService.instance.formatTime(time);
    if (languageCode == 'ar' || languageCode == 'ur') {
      return PrayerService.instance.toArabicNumbers(formatted);
    }
    return formatted;
  }

  String _formatCountdown(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  // ═════════════════════════════════════════════════════════════
  //  🕋 HAJJ TYPE SELECTION - اختيار نوع النسك محسّن
  // ═════════════════════════════════════════════════════════════
 Widget _buildHajjTypeSelection(SmartHajjAppState state, bool isRTL) {
    final lang = state.locale.languageCode;

    final types = [
      {
        'key': 'umrah', 
        'icon': Icons.mosque_outlined, 
        'color': const Color(0xFF40916C),
        'desc': {
          'ar': 'زيارة خفيفة تؤدى في أي وقت',
          'en': 'A minor pilgrimage performed anytime',
          'ur': 'ایک چھوٹا عمرہ جو کسی بھی وقت کیا جا سکتا ہے',
          'id': 'Ziarah ringan yang dilakukan kapan saja'
        }
      },
      {
        'key': 'tamattu', 
        'icon': Icons.mosque_rounded, 
        'color': const Color(0xFF0D2818),
        'desc': {
          'ar': 'عمرة ثم تحلل ثم حج',
          'en': 'Umrah then Hajj',
          'ur': 'عمرہ پھر حج',
          'id': 'Umrah kemudian Haji'
        }
      },
      {
        'key': 'qiran', 
        'icon': Icons.mosque_sharp, 
        'color': const Color(0xFFC9A84C),
        'desc': {
          'ar': 'عمرة وحج معاً بدون تحلل',
          'en': 'Umrah and Hajj combined',
          'ur': 'عمرہ اور حج ایک ساتھ',
          'id': 'Umrah dan Haji digabungkan'
        }
      },
      {
        'key': 'ifrad', 
        'icon': Icons.mosque, 
        'color': const Color(0xFF7209B7),
        'desc': {
          'ar': 'حج فقط بدون عمرة',
          'en': 'Hajj only',
          'ur': 'صرف حج',
          'id': 'Hanya Haji'
        }
      },
    ];

    return Column(
      children: [
        // ── Header (تصحيح سهم الرجوع) ──
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0D2818), Color(0xFF1A4230)]),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                children: [
                  Row(
                    children: [
                      // سهم الرجوع للهيدر (تم تصحيحه ليشير للخارج دائماً)
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(13), color: Colors.white.withOpacity(0.08)),
                          child: Icon(
                            isRTL ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back_ios_new_rounded,
                            // في العربي الـ Directionality ستقلب الـ Back لليمين تلقائياً، 
                            // لذا نستخدم Arrow_Back لضمان الاتجاه الصحيح للرجوع
                            color: Colors.white, size: 18,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          state.translate('ritual'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 42),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isRTL ? "اختر نوع النسك" : "Choose Ritual Type",
                    style: const TextStyle(fontSize: 16, color: Color(0xFFE8C96D), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── القائمة (تصحيح أسهم البطاقات) ──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: types.length,
            itemBuilder: (context, index) {
              final type = types[index];
              final color = type['color'] as Color;
              final Map<String, String> descriptions = type['desc'] as Map<String, String>;

              return GestureDetector(
                onTap: () {
                  setState(() => selectedHajj = type['key'] as String);
                  _loadRitualSteps(type['key'] as String);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      // السهم داخل البطاقة (يجب أن يشير للداخل < في العربي)
                      Icon(
                        isRTL ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded,
                        color: Colors.grey.shade400, size: 16,
                      ),
                      const SizedBox(width: 15),
                      
                      // النصوص
                      Expanded(
                        child: Column(
                          crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.translate(type['key'] as String),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1F)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              descriptions[lang] ?? descriptions['en']!,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      
                      // الأيقونة
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(type['icon'] as IconData, color: color, size: 28),
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

  // ═════════════════════════════════════════════════════════════
  //  📋 STEP BY STEP RITUAL - الخطوات محسّنة
  // ═════════════════════════════════════════════════════════════
  Widget _buildStepByStepRitual(SmartHajjAppState state, bool isRTL) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0D2818)),
      );
    }
    if (currentSteps.isEmpty) {
      return Center(
        child: Text(
          state.locale.languageCode == 'ar' ? 'لا توجد خطوات' : 'No Steps',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      );
    }

    final currentStep = currentSteps[stepIdx];
    final title = state.locale.languageCode == 'ar'
        ? currentStep.titleAr
        : currentStep.titleEn;
    final description = state.locale.languageCode == 'ar'
        ? currentStep.descriptionAr
        : currentStep.descriptionEn;

    return Column(
      children: [
        // ── Header with Progress ──
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D2818), Color(0xFF1A4230)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                       // 📋 تعديل دالة الرجوع داخل الخطوات لتعود للقائمة
 
                      // داخل SafeArea في دالة _buildStepByStepRitual
                  GestureDetector(
                  onTap: () => setState(() => selectedHajj = null), 
                  child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: Colors.white.withOpacity(0.08),
                  ),
                  child: Icon(
                 // استخدام arrow_back لضمان أن الاتجاه في العربي يكون خروج (لليمين)
                 Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
                ),
             ),
           ),
                      Expanded(
                        child: Text(
                          state.translate(selectedHajj!),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9A84C).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFC9A84C).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          "${stepIdx + 1}/${currentSteps.length}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE8C96D),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (stepIdx + 1) / currentSteps.length,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      color: const Color(0xFFC9A84C),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Step Content ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D2818), Color(0xFF1A4230)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "${stepIdx + 1}",
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2E1F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Navigation Buttons ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                if (stepIdx > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => stepIdx--);
                        HapticFeedback.selectionClick();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        state.translate('back'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                if (stepIdx > 0) const SizedBox(width: 12),
                Expanded(
                  flex: stepIdx > 0 ? 2 : 1,
                  child: ElevatedButton(
                    onPressed: _handleNextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D2818),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      stepIdx == currentSteps.length - 1
                          ? state.translate('finish')
                          : state.translate('next'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}