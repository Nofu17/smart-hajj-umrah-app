import '../main.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/prayer_service.dart';
import '../notification_service.dart';
// ─────────────────────────────────────────────
//  شاشة الإعدادات
// ─────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  final VoidCallback onLocaleChanged;
  const SettingsScreen({super.key, required this.onLocaleChanged});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
bool _prayerNotifications = true;
bool _sosNotifications = true; // هذا المتغير للـ SOS
  final List<Map<String, String>> _langs = [
    {'name': 'العربية', 'code': 'ar', 'flag': '🇸🇦', 'sub': 'Arabic'},
    {'name': 'English', 'code': 'en', 'flag': '🇬🇧', 'sub': 'English'},
    {'name': 'اردو', 'code': 'ur', 'flag': '🇵🇰', 'sub': 'Urdu'},
    {'name': 'Bahasa Indonesia', 'code': 'id', 'flag': '🇮🇩', 'sub': 'Indonesian'},
  ];
@override
void initState() {
  super.initState();
  _loadPrayerSettings();
}

_loadPrayerSettings() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _prayerNotifications = prefs.getBool('prayer_notif') ?? true;
    _sosNotifications = prefs.getBool('sos_notif') ?? true; // جلب حالة الـ SOS
  });
}
@override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<SmartHajjAppState>();
    
    // إذا لم يجد الـ state، يعرض واجهة فارغة مؤقتاً بدل ما ينهار
    if (state == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isRTL = state.locale.languageCode == 'ar' || state.locale.languageCode == 'ur';
    
    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F5F3),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D2818),
          foregroundColor: Colors.white,
          title: Text(state.translate('settings'),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          leading: IconButton(
            icon: Icon(isRTL ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // بانر اللغة
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D2818), Color(0xFF1A4230)],
                  begin: Alignment.topRight, end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: const Color(0xFF0D2818).withOpacity(0.25),
                    blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.language_rounded, color: Color(0xFFD4AF37), size: 28),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(state.translate('lang'),
                      style: const TextStyle(color: Colors.white, fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text(state.locale.languageCode.toUpperCase(),
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                      const SizedBox(height: 20),
            
           
                ]),
              ]),
            ),

            const SizedBox(height: 20),

            // قائمة اللغات
            ..._langs.map((l) {
              final isSelected = state.locale.languageCode == l['code'];
              return GestureDetector(
                onTap: () {
                  state.setLocale(Locale(l['code']!));
                  widget.onLocaleChanged();
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFC9A84C).withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFC9A84C) : Colors.grey.shade200,
                      width: isSelected ? 2 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: const Color(0xFFC9A84C).withOpacity(0.15),
                        blurRadius: 14, offset: const Offset(0, 5))]
                        : [BoxShadow(color: Colors.black.withOpacity(0.03),
                        blurRadius: 8)],
                  ),
                  child: Row(children: [
                    Text(l['flag']!, style: const TextStyle(fontSize: 30)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l['name']!,
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? const Color(0xFF3D2800) : Colors.grey.shade800)),
                      Text(l['sub']!,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    ])),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? const Color(0xFFC9A84C) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? const Color(0xFFC9A84C) : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                          color: Color(0xFF3D2800), size: 16)
                          : null,
                    ),
                  ]),
                ),
              );
            }).toList(),

            const SizedBox(height: 16),

            const SizedBox(height: 20),
            // ── قسم التحكم بالإشعارات ──
            // ── قسم التحكم بالإشعارات (مطور ومفصل) ──
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: Colors.grey.shade200),
  ),
  child: Column(
    children: [
// 1. زر إشعارات الصلاة
SwitchListTile(
  activeColor: const Color(0xFFC9A84C),
  contentPadding: EdgeInsets.zero,
  secondary: _settingsIcon(Icons.access_time_filled_rounded, const Color(0xFF0D2818)),
  title: Text(
    state.translate('prayer_notif'), // سيترجم لكل اللغات تلقائياً
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
  ),
  subtitle: Text(
    state.translate('prayer_desc'),
    style: const TextStyle(fontSize: 12),
  ),
 value: _prayerNotifications,
  onChanged: (bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prayer_notif', value);
    setState(() => _prayerNotifications = value);
    HapticFeedback.lightImpact();

    if (!value) {
      // إيقاف — إلغاء كل إشعارات الصلاة (IDs 1-5)
      final plugin = FlutterLocalNotificationsPlugin();
      for (int i = 1; i <= 5; i++) {
        await plugin.cancel(i);
      }
    } else {
      // تشغيل — إعادة جدولة نظيفة تماماً
      final plugin = FlutterLocalNotificationsPlugin();
      for (int i = 1; i <= 5; i++) await plugin.cancel(i); // مسح شامل أولاً

      final state = context.findAncestorStateOfType<SmartHajjAppState>()!;
      final lang = state.locale.languageCode;
      
      // هنا الخدمة PrayerService ستجلب الموقع الحالي تلقائياً وتجلب أوقات اليوم
      final times = await PrayerService.instance.calculatePrayerTimes();
      
      final names = {
        'ar': ['الفجر','الظهر','العصر','المغرب','العشاء'],
        'en': ['Fajr','Dhuhr','Asr','Maghrib','Isha'],
        'ur': ['فجر','ظہر','عصر','مغرب','عشاء'],
        'id': ['Subuh','Dzuhur','Ashar','Maghrib','Isya'],
      };
      
      final prayerNames = names[lang] ?? names['en']!;
      final prayerTimes = [times.fajr, times.dhuhr, times.asr, times.maghrib, times.isha];

      for (int i = 0; i < 5; i++) {
        await NotificationService.schedulePrayerReminder(
          i + 1,
          prayerNames[i],
          prayerTimes[i],
        );
      }
    }
  },
),
// 2. زر إشعارات الطوارئ SOS
SwitchListTile(
  activeColor: Colors.red.shade700,
  contentPadding: EdgeInsets.zero,
  secondary: _settingsIcon(Icons.emergency_share_rounded, Colors.red.shade900), 
  title: Text(
    state.translate('sos_notif'), // سيترجم لكل اللغات تلقائياً
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
  ),
  subtitle: Text(
    state.translate('sos_desc'),
    style: const TextStyle(fontSize: 12),
  ),
  value: _sosNotifications,
  onChanged: (bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sos_notif', value);
    
    // الاشتراك أو إلغاء الاشتراك في قناة الإشعارات الجماعية
    if (value) {
      await FirebaseMessaging.instance.subscribeToTopic("all_pilgrims");
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic("all_pilgrims");
    }
    
    setState(() => _sosNotifications = value);
    HapticFeedback.lightImpact();
  },
  ),
    ],
  ),
),
// ── معلومات التطبيق ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.mosque_rounded, const Color(0xFF0D2818),
                      state.translate('app_title'), 'v1.0.0'),
                  const Divider(height: 20),
                 
                  _infoRow(Icons.verified_rounded, const Color(0xFF40916C),
                      state.translate('version'), '1.0.0'), 
                  const Divider(height: 20),
                  _infoRow(Icons.wifi_off_rounded, const Color(0xFFC9A84C),
                      state.translate('offline_work'), 
                      state.translate('yes')), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, Color color, String label, String value) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(child: Text(label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
      Text(value,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600,
              fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _settingsIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
  
}