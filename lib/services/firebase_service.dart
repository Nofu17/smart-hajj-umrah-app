import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/widgets.dart';
import '../notification_service.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  FirebaseService._init();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

   // دالة مساعدة للحصول على اللغة الحالية 
  String _getCurrentLang() {
    // يمكنك تمرير اللغة من الـ state أو استخدام Locale الحالية
    return WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  }

  // ==================== Auth ====================
  
  Future<String> getDeviceID() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
    return _auth.currentUser!.uid;
  }

  // ==================== Groups ====================

  // إنشاء مجموعة جديدة
  Future<void> createFirebaseGroup(String groupCode, String leaderName) async {
    final myID = await getDeviceID();

    await _db.collection('groups').doc(groupCode).set({
      'leaderName': leaderName,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });

    await _db
        .collection('groups')
        .doc(groupCode)
        .collection('members')
        .doc(myID)
        .set({
      'name': leaderName,
      'role': 'leader',
      'latitude': 0.0,
      'longitude': 0.0,
      'lastUpdate': FieldValue.serverTimestamp(),
    });

    print('✅ مجموعة $groupCode تم إنشاؤها بنجاح');
  }

  // الانضمام لمجموعة
  Future<bool> joinFirebaseGroup(String groupCode, String memberName) async {
    final myID = await getDeviceID();

    // تحقق من وجود المجموعة
    final groupDoc = await _db.collection('groups').doc(groupCode).get();
    if (!groupDoc.exists) {
      print('❌ المجموعة $groupCode غير موجودة');
      return false;
    }

    final data = groupDoc.data();
    if (data == null || data['isActive'] != true) {
      print('❌ المجموعة $groupCode غير نشطة');
      return false;
    }

    // إضافة العضو
    await _db
        .collection('groups')
        .doc(groupCode)
        .collection('members')
        .doc(myID)
        .set({
      'name': memberName,
      'role': 'member',
      'latitude': 0.0,
      'longitude': 0.0,
      'lastUpdate': FieldValue.serverTimestamp(),
    });

    print('✅ تم الانضمام للمجموعة $groupCode');
    return true;
  }

  // ==================== Location ====================


  Future<void> updateMyLocation(String groupCode) async {
    final lang = _getCurrentLang();
    try {
      final myID = await getDeviceID();
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _db
          .collection('groups')
          .doc(groupCode)
          .collection('members')
          .doc(myID)
          .set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // رسالة النجاح باللغات الأربع للـ Console
      print(lang == 'ar' ? '✅ تم تحديث الموقع بنجاح' : 
            lang == 'ur' ? '✅ مقام کی کامیابی سے تجدید ہوگئی' :
            lang == 'id' ? '✅ Lokasi berhasil diperbarui' : 
            '✅ Location updated successfully');

    } catch (e) {
      print(lang == 'ar' ? '❌ خطأ في تحديث الموقع: $e' : 
            lang == 'ur' ? '❌ مقام کی تجدید میں خرابی: $e' :
            lang == 'id' ? '❌ Gagal memperbarui lokasi: $e' : 
            '❌ Error updating location: $e');
    }
  }

  // ==================== Emergency (SOS) ====================

Future<void> sendSOS(String groupCode, String memberName) async {
  try {
    // 1. الحصول على المعرف واللغة
    final String myID = _auth.currentUser?.uid ?? await getDeviceID();
    String lang = _getCurrentLang();

    // 2. الحصول على الموقع
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 5),
    ).catchError((_) => Position(
      latitude: 21.4225, longitude: 39.8262,
      timestamp: DateTime.now(), accuracy: 0, altitude: 0, 
      heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0
    ));

    // 3. الإرسال للفايربيس (ليراه بقية أعضاء المجموعة)
    await _db.collection('groups').doc(groupCode).collection('sos_alerts').add({
      'memberID': myID,
      'member_name': memberName, 
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
      'isResolved': false, 
    });

    // 4. إظهار إشعار التأكيد (تم إرسال موقعك.. ابقَ في مكانك)
    await NotificationService.showConfirmationNotification(lang);

    print('✅ SOS Sent and confirmation shown locally');
  } catch (e) {
    print('❌ SOS Error: $e');
  }
}
  // ==================== Cleanup ====================

  // مغادرة المجموعة
  Future<void> leaveGroup(String groupCode) async {
    final myID = await getDeviceID();
    await _db
        .collection('groups')
        .doc(groupCode)
        .collection('members')
        .doc(myID)
        .delete();

    print('✅ تم مغادرة المجموعة $groupCode');
  }

  // حذف المجموعة (للقائد فقط)
  Future<void> deleteGroup(String groupCode) async {
    await _db.collection('groups').doc(groupCode).update({
      'isActive': false,
    });

    print('✅ تم إيقاف المجموعة $groupCode');
  }
}