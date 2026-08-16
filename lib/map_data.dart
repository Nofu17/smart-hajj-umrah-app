import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MapPOI {
  final String id;
  final String nameAr;
  final String nameEn;
  final LatLng location;
  final String category; // gate, toilet, zamzam, medical, elevator
  final int floor; // -1: basement, 0: ground, 1-5: floors
  final IconData icon;
  final Color color;

  MapPOI({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.location,
    required this.category,
    required this.floor,
    required this.icon,
    required this.color,
  });
}

class HaramMapData {
  // إحداثيات الحرم المكي (تقريبية)
  static const LatLng kaaba = LatLng(21.4225, 39.8262);

  // نقاط الاهتمام (POIs)
  static final List<MapPOI> pois = [
    // الأبواب الرئيسية
    MapPOI(
      id: 'gate_1',
      nameAr: 'باب الملك فهد',
      nameEn: 'King Fahd Gate',
      location: LatLng(21.4230, 39.8265),
      category: 'gate',
      floor: 0,
      icon: Icons.door_front_door,
      color: Color(0xFF0D7C66),
    ),
    MapPOI(
      id: 'gate_2',
      nameAr: 'باب العمرة',
      nameEn: 'Umrah Gate',
      location: LatLng(21.4220, 39.8260),
      category: 'gate',
      floor: 0,
      icon: Icons.door_front_door,
      color: Color(0xFF0D7C66),
    ),
    MapPOI(
      id: 'gate_3',
      nameAr: 'باب السلام',
      nameEn: 'Peace Gate',
      location: LatLng(21.4228, 39.8258),
      category: 'gate',
      floor: 0,
      icon: Icons.door_front_door,
      color: Color(0xFF0D7C66),
    ),

    // زمزم
    MapPOI(
      id: 'zamzam_1',
      nameAr: 'مياه زمزم',
      nameEn: 'Zamzam Water',
      location: LatLng(21.4226, 39.8263),
      category: 'zamzam',
      floor: 0,
      icon: Icons.water_drop,
      color: Color(0xFF2196F3),
    ),
    MapPOI(
      id: 'zamzam_2',
      nameAr: 'مياه زمزم - الطابق الأول',
      nameEn: 'Zamzam Water - Floor 1',
      location: LatLng(21.4224, 39.8264),
      category: 'zamzam',
      floor: 1,
      icon: Icons.water_drop,
      color: Color(0xFF2196F3),
    ),

    // دورات المياه
    MapPOI(
      id: 'toilet_1',
      nameAr: 'دورات المياه - رجال',
      nameEn: 'Restroom - Men',
      location: LatLng(21.4232, 39.8267),
      category: 'toilet',
      floor: 0,
      icon: Icons.wc,
      color: Color(0xFF795548),
    ),
    MapPOI(
      id: 'toilet_2',
      nameAr: 'دورات المياه - نساء',
      nameEn: 'Restroom - Women',
      location: LatLng(21.4218, 39.8256),
      category: 'toilet',
      floor: 0,
      icon: Icons.wc,
      color: Color(0xFFE91E63),
    ),

    // الخدمات الطبية
    MapPOI(
      id: 'medical_1',
      nameAr: 'العيادة الطبية',
      nameEn: 'Medical Clinic',
      location: LatLng(21.4235, 39.8270),
      category: 'medical',
      floor: 0,
      icon: Icons.local_hospital,
      color: Color(0xFFE53935),
    ),

    // المصاعد
    MapPOI(
      id: 'elevator_1',
      nameAr: 'المصعد 1',
      nameEn: 'Elevator 1',
      location: LatLng(21.4227, 39.8266),
      category: 'elevator',
      floor: 0,
      icon: Icons.elevator,
      color: Color(0xFF9C27B0),
    ),
    MapPOI(
      id: 'elevator_2',
      nameAr: 'المصعد 2',
      nameEn: 'Elevator 2',
      location: LatLng(21.4223, 39.8259),
      category: 'elevator',
      floor: 0,
      icon: Icons.elevator,
      color: Color(0xFF9C27B0),
    ),
  ];
  
  // فلترة حسب الطابق
  static List<MapPOI> getPOIsByFloor(int floor) {
    return pois.where((poi) => poi.floor == floor).toList();
  }

  // فلترة حسب الفئة
  static List<MapPOI> getPOIsByCategory(String category) {
    return pois.where((poi) => poi.category == category).toList();
  }
} 