import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

class QiblaService {
  static QiblaService? _instance;
  static QiblaService get instance => _instance ??= QiblaService._();

  QiblaService._();

  // إحداثيات الكعبة المشرفة
  final double kaabaLat = 21.4225;
  final double kaabaLng = 39.8262;

  // ✅ الحصول على الموقع الحالي
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  // ✅ حساب اتجاه القبلة (المعادلة الصحيحة)
  double calculateQiblaDirection(double userLat, double userLng) {
    // تحويل إلى Radians
    final lat1 = _degreesToRadians(userLat);
    final lng1 = _degreesToRadians(userLng);
    final lat2 = _degreesToRadians(kaabaLat);
    final lng2 = _degreesToRadians(kaabaLng);

    // حساب الفرق في خطوط الطول
    final dLng = lng2 - lng1;

    // ✅ معادلة Great Circle Bearing الصحيحة
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    // حساب الزاوية
    double bearing = math.atan2(y, x);

    // تحويل من Radians إلى Degrees
    bearing = _radiansToDegrees(bearing);

    // تحويل إلى 0-360
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  // ✅ حساب المسافة إلى مكة (بالكيلومتر)
  double calculateDistanceToKaaba(double userLat, double userLng) {
    return Geolocator.distanceBetween(
      userLat,
      userLng,
      kaabaLat,
      kaabaLng,
    ) / 1000;
  }

  // تحويل درجات إلى Radians
  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  // تحويل Radians إلى درجات
  double _radiansToDegrees(double radians) {
    return radians * 180.0 / math.pi;
  }

  // ✅ الحصول على اتجاه نصي (4 لغات)
  String getDirectionText(double degrees, String languageCode) {
    final directions = {
      'ar': [
        'شمال',
        'شمال شرقي',
        'شرق',
        'جنوب شرقي',
        'جنوب',
        'جنوب غربي',
        'غرب',
        'شمال غربي'
      ],
      'en': [
        'North',
        'Northeast',
        'East',
        'Southeast',
        'South',
        'Southwest',
        'West',
        'Northwest'
      ],
      'ur': [
        'شمال',
        'شمال مشرق',
        'مشرق',
        'جنوب مشرق',
        'جنوب',
        'جنوب مغرب',
        'مغرب',
        'شمال مغرب'
      ],
      'id': [
        'Utara',
        'Timur Laut',
        'Timur',
        'Tenggara',
        'Selatan',
        'Barat Daya',
        'Barat',
        'Barat Laut'
      ],
    };

    final index = ((degrees + 22.5) / 45).floor() % 8;
    return directions[languageCode]?[index] ?? directions['en']![index];
  }

  // ✅ تنسيق المسافة (4 لغات)
  String formatDistance(double km, String languageCode) {
    if (km < 1) {
      final meters = (km * 1000).round();
      switch (languageCode) {
        case 'ar':
          return '$meters متر';
        case 'ur':
          return '$meters میٹر';
        case 'id':
          return '$meters meter';
        default:
          return '$meters m';
      }
    } else {
      final rounded = km.toStringAsFixed(1);
      switch (languageCode) {
        case 'ar':
          return '$rounded كم';
        case 'ur':
          return '$rounded کلومیٹر';
        case 'id':
          return '$rounded km';
        default:
          return '$rounded km';
      }
    }
  }

  // ✅ تحويل الأرقام للعربية
  String toArabicNumbers(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩', '٫'];

    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], arabic[i]);
    }
    return input;
  }

  // ✅ تنسيق الوقت (للصلاة)
  String formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}