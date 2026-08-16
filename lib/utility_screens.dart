import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'services/qibla_service.dart';
import 'services/firebase_service.dart';
import 'data/database/database_helper.dart';
import 'data/models/sos_model.dart';
import 'notification_service.dart';

class UtilityScreens extends StatefulWidget {
  final String mode;
  const UtilityScreens({super.key, required this.mode});

  @override
  State<UtilityScreens> createState() => _UtilityScreensState();
}

class _UtilityScreensState extends State<UtilityScreens> {
  bool isLoading = false;

  void showLoading() {
    if (mounted) {
      setState(() => isLoading = true);
    }
  }

  void hideLoading() {
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<SmartHajjAppState>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text(state.translate(widget.mode)),
        centerTitle: true,
        backgroundColor: state.primaryGreen,
      ),
      body: widget.mode == "qibla"
          ? const QiblaCompassScreen()
          : _buildEmergencyScreen(state),
    );
  }

  // --- شاشة الطوارئ ---
Widget _buildEmergencyScreen(SmartHajjAppState state) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final isTablet = screenWidth > 600;

  return Stack(
    children: [
      // الواجهة الأساسية
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade900,
              Colors.red.shade700,
              Colors.red.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // أيقونة الطوارئ
              Container(
                padding: EdgeInsets.all(isTablet ? 50 : 40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: isTablet ? 120 : 100,
                  color: Colors.white,
                ),
              ),

              SizedBox(height: screenHeight * 0.05),

              Text(
                state.translate('emergency'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 38 : 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: Text(
                  state.locale.languageCode == 'ar'
                      ? 'سيتم إرسال موقعك الحالي لأفراد المجموعة'
                      : state.locale.languageCode == 'ur'
                          ? 'آپ کی موجودہ جگہ گروپ کے اراکین کو بھیج دی جائے گی'
                          : state.locale.languageCode == 'id'
                              ? 'Lokasi Anda saat ini akan dikirim ke anggota grup'
                              : 'Your current location will be sent to group members',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isTablet ? 18 : 16,
                    height: 1.6,
                  ),
                ),
              ),

              const Spacer(),

              // زر SOS
              GestureDetector(
                onTap: () async {
                  showLoading();

                  try {
                    final prefs = await SharedPreferences.getInstance();
                    final groupCode = prefs.getString('current_group_code');
                    final memberName = prefs.getString('member_name');

                    if (groupCode == null || memberName == null) {
                      hideLoading();
                      
                      final msg = state.locale.languageCode == 'ar'
                          ? 'يجب الانضمام لمجموعة أولاً'
                          : state.locale.languageCode == 'en'
                              ? 'You must join a group first'
                              : 'پہلے گروپ میں شامل ہونا ضروری ہے';

                      // تأكدي من كتابة ScaffoldMessenger بشكل صحيح هنا
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          backgroundColor: Colors.orange.shade700,
                        ),
                      );
                      return;
                    }

                    // 1. نرسل للفايربيس أولاً
await FirebaseService.instance.sendSOS(groupCode, memberName.trim());

// 2. أظهر إشعار التأكيد فوراً للمرسل
await NotificationService.showConfirmationNotification(state.locale.languageCode);

hideLoading();

final successMsg = state.locale.languageCode == 'ar'
    ? 'تم إرسال نداء الاستغاثة بنجاح'
    : 'SOS signal sent successfully';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(successMsg),
                        backgroundColor: Colors.green.shade700,
                      ),
                    );
                  } catch (e) {
                    hideLoading();
                    
                    final errorMsg = state.locale.languageCode == 'ar'
                        ? 'حدث خطأ أثناء إرسال الإشارة'
                        : 'An error occurred';

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMsg),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }},
                child: Container(
                  width: isTablet ? 240 : 200,
                  height: isTablet ? 240 : 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(
                        fontSize: isTablet ? 70 : 60,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.04),

              Text(
                state.locale.languageCode == 'ar'
                    ? 'اضغط للإرسال'
                    : state.locale.languageCode == 'ur'
                        ? 'بھیجنے کے لیے ٹیپ کریں'
                        : state.locale.languageCode == 'id'
                            ? 'Ketuk untuk mengirim'
                            : 'Tap to send',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: isTablet ? 16 : 14,
                ),
              ),

              SizedBox(height: screenHeight * 0.08),
            ],
          ),
        ),
      ),

      // طبقة التحميل
      if (isLoading)
        Container(
          color: Colors.black.withOpacity(0.4),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
    ],
  );
}}

// --- شاشة بوصلة القبلة ---


class QiblaCompassScreen extends StatefulWidget {
  const QiblaCompassScreen({super.key});

  @override
  State<QiblaCompassScreen> createState() => _QiblaCompassScreenState();
}

class _QiblaCompassScreenState extends State<QiblaCompassScreen> {
  double? compassHeading;
  double? qiblaDirection;
  Position? userPosition;
  double? distanceToKaaba;
bool isLoading = false;

void showLoading() {
  setState(() => isLoading = true);
}

void hideLoading() {
  setState(() => isLoading = false);
}
  String? errorMessage;
  StreamSubscription<CompassEvent>? compassSubscription;

  @override
  void initState() {
    super.initState();
    _initializeQibla();
  }

  @override
  void dispose() {
    compassSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeQibla() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        errorMessage = 'location_denied';
        isLoading = false;
      });
      return;
    }

    final position = await QiblaService.instance.getCurrentLocation();

    if (position == null) {
      setState(() {
        errorMessage = 'location_error';
        isLoading = false;
      });
      return;
    }

    final qibla = QiblaService.instance.calculateQiblaDirection(
      position.latitude,
      position.longitude,
    );
    final distance = QiblaService.instance.calculateDistanceToKaaba(
      position.latitude,
      position.longitude,
    );

    setState(() {
      userPosition = position;
      qiblaDirection = qibla;
      distanceToKaaba = distance;
      isLoading = false;
    });

    compassSubscription = FlutterCompass.events?.listen((event) {
      if (mounted) setState(() => compassHeading = event.heading);
    });
  }

  String _getTranslation(String key, SmartHajjAppState state) {
    final translations = {
      'locating': {
        'ar': 'جاري تحديد الموقع...',
        'en': 'Locating...',
        'ur': 'مقام کی تلاش جاری ہے...',
        'id': 'Mencari lokasi...',
      },
      'location_denied': {
        'ar': 'يرجى تفعيل خدمة الموقع',
        'en': 'Please enable location services',
        'ur': 'براہ کرم لوکیشن سروس فعال کریں',
        'id': 'Harap aktifkan layanan lokasi',
      },
      'retry': {
        'ar': 'إعادة المحاولة',
        'en': 'Retry',
        'ur': 'دوبارہ کوشش کریں',
        'id': 'Coba Lagi',
      },
      'compass_unavailable': {
        'ar': 'البوصلة غير متاحة',
        'en': 'Compass not available',
        'ur': 'قطب نما دستیاب نہیں',
        'id': 'Kompas tidak tersedia',
      },
      'distance_to_kaaba': {
        'ar': 'المسافة إلى الكعبة',
        'en': 'Distance to Kaaba',
        'ur': 'کعبہ تک فاصلہ',
        'id': 'Jarak ke Ka\'bah',
      },
      'qibla_direction': {
        'ar': 'اتجاه القبلة',
        'en': 'Qibla Direction',
        'ur': 'قبلہ کی سمت',
        'id': 'Arah Kiblat',
      },
      'calibration_hint': {
        'ar': 'حرّك الجهاز بشكل ∞ لمعايرة البوصلة',
        'en': 'Move device in ∞ pattern to calibrate',
        'ur': 'کیلیبریشن کے لیے ڈیوائس کو ∞ کی شکل میں گھمائیں',
        'id': 'Gerakkan perangkat dalam pola ∞ untuk kalibrasi',
      },
    };

    return translations[key]?[state.locale.languageCode] ??
        translations[key]?['en'] ??
        key;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<SmartHajjAppState>()!;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    // حساب أحجام متجاوبة
    final compassSize = isTablet 
        ? screenWidth * 0.5 
        : screenWidth * 0.75;
    final iconSize = isTablet ? 120.0 : 100.0;
    final arrowSize = isTablet ? 40.0 : 30.0;

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: state.primaryGreen, strokeWidth: 4),
            SizedBox(height: screenHeight * 0.03),
            Text(
              _getTranslation('locating', state),
              style: TextStyle(fontSize: isTablet ? 18 : 16),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: isTablet ? 80 : 64,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: screenHeight * 0.03),
              Text(
                _getTranslation('location_denied', state),
                style: TextStyle(fontSize: isTablet ? 18 : 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.03),
              ElevatedButton.icon(
                onPressed: _initializeQibla,
                icon: Icon(Icons.refresh, size: isTablet ? 24 : 20),
                label: Text(
                  _getTranslation('retry', state),
                  style: TextStyle(fontSize: isTablet ? 18 : 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.08,
                    vertical: screenHeight * 0.02,
                    
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (qiblaDirection == null || compassHeading == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_off,
              size: isTablet ? 80 : 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              _getTranslation('compass_unavailable', state),
              style: TextStyle(fontSize: isTablet ? 18 : 16),
            ),
          ],
        ),
      );
    }

    final angleToQibla = (qiblaDirection! - compassHeading!) % 360;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            state.primaryGreen,
            const Color(0xFF2D4F39),
            const Color(0xFF1B3022),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(height: screenHeight * 0.02),

                // معلومات المسافة
                Container(
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: state.goldColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.place,
                            color: state.goldColor,
                            size: isTablet ? 24 : 20,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Flexible(
                            child: Text(
                              _getTranslation('distance_to_kaaba', state),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: isTablet ? 16 : 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          QiblaService.instance.formatDistance(
                            distanceToKaaba!,
                            state.locale.languageCode,
                          ),
                          style: TextStyle(
                            color: state.goldColor,
                            fontSize: isTablet ? 36 : 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                // البوصلة
                SizedBox(
                  width: compassSize.clamp(250.0, 400.0),
                  height: compassSize.clamp(250.0, 400.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // الدائرة الخارجية
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: state.goldColor.withOpacity(0.5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: state.goldColor.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),

                      // علامات الاتجاهات
                      Transform.rotate(
                        angle: -compassHeading! * (math.pi / 180),
                        child: Container(
                          width: compassSize.clamp(250.0, 400.0),
                          height: compassSize.clamp(250.0, 400.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                          child: Stack(
                            children: [
                              // N
                              Positioned(
                                top: 10,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    'N',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: isTablet ? 28 : 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              // S
                              Positioned(
                                bottom: 10,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    'S',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: isTablet ? 24 : 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              // E
                              Positioned(
                                right: 10,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: Text(
                                    'E',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: isTablet ? 24 : 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              // W
                              Positioned(
                                left: 10,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: Text(
                                    'W',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: isTablet ? 24 : 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // سهم القبلة
                      Transform.rotate(
                        angle: angleToQibla * (math.pi / 180),
                        child: Icon(
                          Icons.navigation,
                          size: iconSize,
                          color: state.goldColor,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),

                      // أيقونة الكعبة في المركز
                      Container(
                        padding: EdgeInsets.all(isTablet ? 18 : 15),
                        decoration: BoxDecoration(
                          color: state.primaryGreen,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: state.goldColor,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.mosque,
                          color: state.goldColor,
                          size: arrowSize,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                // معلومات الاتجاه
                Container(
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: state.goldColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.explore,
                            color: state.goldColor,
                            size: isTablet ? 24 : 20,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Flexible(
                            child: Text(
                              _getTranslation('qibla_direction', state),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: isTablet ? 16 : 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          QiblaService.instance.getDirectionText(
                            qiblaDirection!,
                            state.locale.languageCode,
                          ),
                          style: TextStyle(
                            color: state.goldColor,
                            fontSize: isTablet ? 32 : 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        '${qiblaDirection!.toStringAsFixed(1)}°',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: isTablet ? 18 : 16,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // تلميح المعايرة
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.white.withOpacity(0.5),
                        size: isTablet ? 18 : 16,
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: Text(
                          _getTranslation('calibration_hint', state),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: isTablet ? 14 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}