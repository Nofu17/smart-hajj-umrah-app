import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // تهيئة المناطق الزمنية مرة واحدة فقط
    tz_data.initializeTimeZones();

    // ← هذا السطر المهم: يحدد المنطقة الزمنية الصحيحة
    tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _notificationsPlugin.initialize(initSettings);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // إنشاء القنوات
const AndroidNotificationChannel sosChannel = AndroidNotificationChannel(
  'sos_channel',
  'SOS Alerts',
  description: 'Important emergency alerts',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

    const AndroidNotificationChannel prayerChannel = AndroidNotificationChannel(
      'prayer_channel',
      'Prayer Times',
      description: 'Prayer reminders',
      importance: Importance.max,
      playSound: true,
    );

    const AndroidNotificationChannel distanceChannel =
        AndroidNotificationChannel(
      'distance_channel',
      'تنبيهات الابتعاد عن المجموعة',
      description: 'تنبيهك عند الابتعاد عن القائد',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(sosChannel);
    await androidPlugin?.createNotificationChannel(prayerChannel);
    await androidPlugin?.createNotificationChannel(distanceChannel);
  }

  // إشعار الابتعاد
  static Future<void> triggerDistanceAlert(int distance) async {
    await _notificationsPlugin.show(
      888,
      '⚠️ تنبيه ابتعاد!',
      'لقد ابتعدت عن القائد مسافة $distance متر. يرجى العودة فوراً.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'distance_channel',
          'تنبيهات الابتعاد عن المجموعة',
          importance: Importance.high,
          priority: Priority.high,
          onlyAlertOnce: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // إشعار SOS
  static Future<void> triggerSOSAlert({String? senderName, required String langCode}) async {
    String title = '';
    String body = '';

    if (langCode == 'ar') {
      title = '⚠️ نداء استغاثة (SOS)';
      body = senderName != null ? 'العضو $senderName يحتاج إلى مساعدة عاجلة!' : 'أحد أعضاء المجموعة يحتاج مساعدة.';
    } else if (langCode == 'ur') {
      title = '⚠️ ہنگامی الرٹ (SOS)';
      body = senderName != null ? 'ممبر $senderName کو فوری مدد کی ضرورت ہے!' : 'گروپ کے کسی رکن کو مدد کی ضرورت ہے۔';
    } else if (langCode == 'id') {
      title = '⚠️ Peringatan Darurat (SOS)';
      body = senderName != null ? 'Anggota $senderName membutuhkan bantuan segera!' : 'Seseorang di grup membutuhkan bantuan.';
    } else { 
      title = '⚠️ Emergency Alert (SOS)';
      body = senderName != null ? 'Member $senderName needs urgent help!' : 'A group member needs assistance.';
    }

    await _notificationsPlugin.show(
      911,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sos_channel',
          'SOS Alerts',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: true,
        ),
      ),
    );
  }

  static Future<void> showConfirmationNotification(String langCode) async {
  String title;
  String body;

  // تحديد المحتوى بناءً على اللغة المطلوبة
  switch (langCode) {
    case 'ar':
      title = '⚠️ نداء استغاثة (SOS)';
      body = 'تم إرسال موقعك الحالي للقائد وفريق المساعدة.. ابقَ في مكانك';
      break;
    case 'en':
      title = '⚠️ SOS Alert';
      body = 'Your current location has been sent to the leader and support team.. stay where you are';
      break;
    case 'ur': // أردو
      title = '⚠️ ہنگامی مدد (SOS)';
      body = 'آپ کی موجودہ جگہ لیڈر اور امدادی ٹیم کو بھیج دی گئی ہے.. وہیں رکیں';
      break;
    case 'id': // إندونيسي
      title = '⚠️ Peringatan SOS';
      body = 'Lokasi Anda saat ini telah dikلمirim ke pemimpin dan tim bantuan.. tetaplah di tempat Anda';
      break;
    default:
      title = '⚠️ SOS Alert';
      body = 'Your location has been sent to the leader and support team';
  }

  await _notificationsPlugin.show(
    99,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'sos_channel',
        'SOS Alerts',
        importance: Importance.max,
        priority: Priority.max,
        // هذه تضمن ظهور الأيقونة الصغيرة بجانب الإشعار
        icon: '@mipmap/ic_launcher', 
      ),
    ),
  );
}

  // جدولة إشعار الصلاة
static Future<void> schedulePrayerReminder(
  int id,
  String prayerName,
  DateTime prayerTime,
) async {
  // 1. مسح الإشعار القديم لهذا الـ ID فوراً لمنع التداخل
  await _notificationsPlugin.cancel(id);
  
  // 2. تحديد وقت التنبيه (قبل الأذان بـ 10 دقائق)
  var scheduledDateTime = prayerTime.subtract(const Duration(minutes: 10));
  
  // 3. إذا كان وقت الصلاة قد مضى اليوم، لا تجدوله لليوم (سيتم تحديثه غداً عند فتح التطبيق)
  if (scheduledDateTime.isBefore(DateTime.now())) {
    return; 
  }

  final tzScheduled = tz.TZDateTime.from(scheduledDateTime, tz.local);

  try {
    await _notificationsPlugin.zonedSchedule(
      id,
      '🕋 $prayerName',
      _getPrayerBody(prayerName),
      tzScheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel',
          'Prayer Times',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      // ← حذفنا سطر التكرار اليومي لأنه يسبب ثبات الوقت وهو ما أدى لخطئك السابق
    );
    print('✅ تم جدولة $prayerName في الوقت الدقيق: $tzScheduled');
  } catch (e) {
    print('❌ فشل جدولة $prayerName: $e');
  }
}
  static String _getPrayerBody(String name) {
    final arabicNames = ['الفجر', 'الظهر', 'العصر', 'المغرب', 'العشاء'];
    final urduNames = ['فجر', 'ظہر', 'عصر', 'مغرب', 'عشاء'];
    final idNames = ['Subuh', 'Dzuhur', 'Ashar', 'Maghrib', 'Isya'];

    if (arabicNames.contains(name)) return 'الأذان بعد 10 دقائق — حافظ على صلاتك 🤲';
    if (urduNames.contains(name)) return 'اذان میں 10 منٹ باقی ہیں 🤲';
    if (idNames.contains(name)) return 'Adzan dalam 10 menit — jangan lewatkan 🤲';
    return 'Prayer in 10 minutes — time to prepare 🤲';
  }
}