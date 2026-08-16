import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;



class PrayerService {
  // ✅ Singleton - تصحيح
  static final PrayerService instance = PrayerService._();

  PrayerService._();
Future<void> scheduleAllPrayers(String languageCode) async {
  // 1. حساب المواقيت بناءً على الموقع الحقيقي الحالي (GPS)
  final prayerTimes = await calculatePrayerTimes();
  final notifications = FlutterLocalNotificationsPlugin();

  // مصفوفة الصلوات التي نريد جدولتها
  List<Prayer> prayers = [Prayer.fajr, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha];

  // قاموس العناوين
  Map<String, String> alertTitles = {
    'ar': 'حان وقت الأذان 🕋',
    'en': 'Time for Prayer 🕋',
    'id': 'Waktu Shalat 🕋',
    'ur': 'نماز کا وقت 🕋',
  };

  for (var p in prayers) {
    final time = prayerTimes.timeForPrayer(p);
    
    // تأكدي أن الوقت مستقبلي
    if (time != null && time.isAfter(DateTime.now())) {
      
      // ✅ التعديل الأهم: مسح أي جدولة قديمة لهذا المعرف (Index) لمنع التداخل
      // صلاة الفجر تأخذ ID رقم 1، الظهر 2، وهكذا...
      await notifications.cancel(p.index);

      String prayerName = getPrayerName(p, languageCode);
      String title = alertTitles[languageCode] ?? alertTitles['en']!;

      // تحديد وقت الإشعار (مباشرة وقت الأذان، أو اطرحي 10 دقائق كما فعلنا سابقاً)
      // هنا سنستخدم وقت الأذان الفعلي
      final tzScheduled = tz.TZDateTime.from(time, tz.local);

      await notifications.zonedSchedule(
        p.index, 
        title,
        languageCode == 'ar' ? 'الآن أذان صلاة $prayerName' : 'It is now $prayerName time',
        tzScheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'prayer_channel',    // ID القناة
            'Prayer Times',    // اسم القناة
            importance: Importance.max,
            priority: Priority.high,
            // تم إزالة سطر rawResourceSound واستبداله بصوت النظام الافتراضي
            playSound: true, 
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentSound: true, 
            presentAlert: true
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
}
  // الإحداثيات الافتراضية (مكة المكرمة)
  final double defaultLat = 21.4225;
  final double defaultLng = 39.8262;

  // ✅ Cache للموقع
  Position? _cachedPosition;
  DateTime? _lastLocationUpdate;

  // ✅ الحصول على الموقع الحالي - مع Timeout وCache
  Future<Position?> getCurrentLocation() async {
    try {
      // استخدام الـ Cache إذا كان حديثاً (أقل من 5 دقائق)
      if (_cachedPosition != null && _lastLocationUpdate != null) {
        final diff = DateTime.now().difference(_lastLocationUpdate!);
        if (diff.inMinutes < 5) {
          return _cachedPosition;
        }
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // ✅ Timeout 5 ثواني
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );

      // حفظ في الـ Cache
      _cachedPosition = position;
      _lastLocationUpdate = DateTime.now();

      return position;
    } catch (e) {
      return null;
    }
  }

  // ✅ حساب أوقات الصلاة
  Future<PrayerTimes> calculatePrayerTimes({
    double? latitude,
    double? longitude,
    DateTime? date,
  }) async {
    double lat = latitude ?? defaultLat;
    double lng = longitude ?? defaultLng;

    if (latitude == null || longitude == null) {
      try {
        final position = await getCurrentLocation();
        if (position != null) {
          lat = position.latitude;
          lng = position.longitude;
        }
      } catch (e) {
        // استخدام مكة كـ Fallback
      }
    }

    final params = CalculationMethod.umm_al_qura.getParameters();
    params.madhab = Madhab.shafi;

    final coordinates = Coordinates(lat, lng);

    final calculationDate = date ?? DateTime.now();
    final dateComponents = DateComponents(
      calculationDate.year,
      calculationDate.month,
      calculationDate.day,
    );

    final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

    return prayerTimes;
  }

  // ✅ تنسيق الوقت
  String formatTime(DateTime time, {bool is24Hour = false}) {
    if (is24Hour) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
    }
  }

  // ✅ تحويل الأرقام للعربية
  String toArabicNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], arabic[i]);
    }
    return input;
  }

  // الحصول على الصلاة الحالية
  Prayer? getCurrentPrayer(PrayerTimes prayerTimes) {
    return prayerTimes.currentPrayer();
  }

Prayer? getNextPrayer(PrayerTimes prayerTimes) {
    final next = prayerTimes.nextPrayer();
    // إذا رجع none = انتهت صلوات اليوم، الصلاة القادمة هي فجر الغد
    if (next == Prayer.none) return Prayer.fajr;
    return next;
  }

  Duration getTimeUntilNextPrayer(PrayerTimes prayerTimes) {
    final next = prayerTimes.nextPrayer();

    if (next == Prayer.none) {
      // احسب وقت فجر الغد
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowPrayers = PrayerTimes(
        Coordinates(defaultLat, defaultLng),
        DateComponents(tomorrow.year, tomorrow.month, tomorrow.day),
        CalculationMethod.umm_al_qura.getParameters(),
      );
      final fajrTomorrow = tomorrowPrayers.fajr;
      return fajrTomorrow.difference(DateTime.now());
    }

    final nextPrayerTime = prayerTimes.timeForPrayer(next);
    if (nextPrayerTime == null) return Duration.zero;
    return nextPrayerTime.difference(DateTime.now());
  }

  // ✅ ترجمة اسم الصلاة - محسّنة
  String getPrayerName(Prayer prayer, String languageCode) {
    final names = {
      'ar': {
        Prayer.fajr: 'الفجر',
        Prayer.sunrise: 'الشروق',
        Prayer.dhuhr: 'الظهر',
        Prayer.asr: 'العصر',
        Prayer.maghrib: 'المغرب',
        Prayer.isha: 'العشاء',
      },
      'en': {
        Prayer.fajr: 'Fajr',
        Prayer.sunrise: 'Sunrise',
        Prayer.dhuhr: 'Dhuhr',
        Prayer.asr: 'Asr',
        Prayer.maghrib: 'Maghrib',
        Prayer.isha: 'Isha',
      },
      'ur': {
        Prayer.fajr: 'فجر',
        Prayer.sunrise: 'طلوع آفتاب',
        Prayer.dhuhr: 'ظہر',
        Prayer.asr: 'عصر',
        Prayer.maghrib: 'مغرب',
        Prayer.isha: 'عشاء',
      },
      'id': {
        Prayer.fajr: 'Subuh',
        Prayer.sunrise: 'Terbit',
        Prayer.dhuhr: 'Dzuhur',
        Prayer.asr: 'Ashar',
        Prayer.maghrib: 'Maghrib',
        Prayer.isha: 'Isya',
      },
    };

    return names[languageCode]?[prayer] ?? names['en']?[prayer] ?? prayer.name;
  }
} 