import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:smart_hajj_umrah_app/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupTrackingScreen extends StatefulWidget {
  const GroupTrackingScreen({super.key});

  @override
  State<GroupTrackingScreen> createState() => _GroupTrackingScreenState();
}

class _GroupTrackingScreenState extends State<GroupTrackingScreen> {
  final TextEditingController _codeController = TextEditingController();
  String? groupCode;
  final String myUid = FirebaseAuth.instance.currentUser?.uid ?? "unknown";
  StreamSubscription<Position>? _positionStream;

  @override
  void dispose() {
    _positionStream?.cancel(); // إيقاف التتبع عند الخروج من الشاشة
    super.dispose();
  }

  // 1. طلب إذن الموقع
  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  // 2. دالة التتبع الذكي (تحديث كل 10 ثواني + حساب المسافة)
void _startLiveTracking(String code) async {
   final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('member_name') ?? 'Member';

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(code)
        .collection('members')
        .doc(myUid)
        .set({
      'uid': myUid,
      'name': savedName,
      'role': 'member',
      'latitude': 0.0,
      'longitude': 0.0,
      'lastUpdate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      intervalDuration: const Duration(seconds: 10),
    );

    _positionStream = Geolocator.getPositionStream(
            locationSettings: locationSettings)
        .listen((Position myPos) async {
      try {
        // الآن update يشتغل لأن الـ document موجود
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(code)
            .collection('members')
            .doc(myUid)
            .update({
          'latitude': myPos.latitude,
          'longitude': myPos.longitude,
          'lastUpdate': FieldValue.serverTimestamp(),
        });

        print("📡 تم تحديث موقعك في الفايربيس: ${myPos.latitude}");

        //  جلب موقع القائد وحساب المسافة (تنبيه الـ 10 أمتار)
        var leaderSnapshot = await FirebaseFirestore.instance
            .collection('groups')
            .doc(code)
            .collection('members')
            .where('role', isEqualTo: 'leader')
            .limit(1)
            .get();

        if (leaderSnapshot.docs.isNotEmpty) {
          var leaderData = leaderSnapshot.docs.first.data();
          
          if (leaderData['latitude'] != null && leaderData['longitude'] != null) {
            double distance = Geolocator.distanceBetween(
              myPos.latitude, myPos.longitude, 
              leaderData['latitude'], leaderData['longitude']
            );

            print("📏 المسافة بينك وبين القائد: ${distance.toInt()} متر");

            if (distance > 10) {
              _triggerDistanceAlert(distance);
            }
          }
        }
      } catch (e) {
        print("❌ خطأ أثناء التتبع اللحظي: $e");
      }
    });
  }

void _triggerDistanceAlert(double dist) {
    // 1. تنبيه داخل التطبيق (SnackBar)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("⚠️ تنبيه: ابتعدت عن القائد مسافة ${dist.toInt()} متر!"),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );

    // 2. إشعار محلي (استدعاء الدالة الصحيحة الآن)
    NotificationService.triggerDistanceAlert(dist.toInt()); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تتبع المجموعة المباشر")),
      body: groupCode == null ? _buildJoinUI() : _buildLiveMap(),
    );
  }

  // واجهة الانضمام
  Widget _buildJoinUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_alt, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                hintText: "أدخل كود المجموعة (مثلاً: HAJJ2026)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
       onPressed: () async {
  // 1. التأكد من أن خدمة الـ GPS تعمل في الجوال
  bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!isServiceEnabled) {
     await Geolocator.openLocationSettings();
     return;
  }

  // 2. إذا كانت تعمل، نبدأ التتبع
  if (_codeController.text.isNotEmpty) {
    setState(() => groupCode = _codeController.text);
    _startLiveTracking(_codeController.text); 
  }
},
              child: const Text("انضمام وتفعيل التتبع"),
            ),
          ],
        ),
      ),
    );
  }

  // واجهة الخريطة
  // واجهة الخريطة - تم تعديل المسار ليتوافق مع دالة التتبع
  Widget _buildLiveMap() {
    return StreamBuilder<QuerySnapshot>(
      // التعديل هنا: يجب أن يقرأ من مجموعة members داخل المجموعات
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(groupCode) // الكود الذي أدخله المستخدم
          .collection('members')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        List<Marker> markers = snapshot.data!.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          
          // ملاحظة: تأكدي أن FirebaseService يخزن الـ ID في الحقل المناسب
          // إذا كنتِ تستخدمين doc.id قارني به
          bool isMe = doc.id == myUid; 

          return Marker(
            point: LatLng(data['latitude'] ?? 0.0, data['longitude'] ?? 0.0),
            child: Icon(
              isMe ? Icons.my_location : Icons.person_pin_circle,
              color: isMe ? Colors.blue : Colors.red,
              size: 40,
            ),
          );
        }).toList();

        return FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(21.4225, 39.8262),
            initialZoom: 18,
          ),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
            MarkerLayer(markers: markers),
          ],
        );
      },
    );
    
  }}
  