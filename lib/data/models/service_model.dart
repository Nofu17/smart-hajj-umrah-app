class ServiceModel {
  final int? id;
  final String serviceType; // 'hospital', 'water', 'lost_found', 'transport'
  final String nameAr;
  final String nameEn;
  final String nameUr;
  final String nameId;
  final String descriptionAr;
  final String descriptionEn;
  final String descriptionUr;
  final String descriptionId;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;
  final String? location;
  final bool is24Hour;

  ServiceModel({
    this.id,
    required this.serviceType,
    required this.nameAr,
    required this.nameEn,
    required this.nameUr,
    required this.nameId,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.descriptionUr,
    required this.descriptionId,
    this.phoneNumber,
    this.latitude,
    this.longitude,
    this.location,
    this.is24Hour = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_type': serviceType,
      'name_ar': nameAr,
      'name_en': nameEn,
      'name_ur': nameUr,
      'name_id': nameId,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'description_ur': descriptionUr,
      'description_id': descriptionId,
      'phone_number': phoneNumber,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'is_24_hour': is24Hour ? 1 : 0,
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'],
      serviceType: map['service_type'],
      nameAr: map['name_ar'],
      nameEn: map['name_en'],
      nameUr: map['name_ur'],
      nameId: map['name_id'],
      descriptionAr: map['description_ar'],
      descriptionEn: map['description_en'],
      descriptionUr: map['description_ur'],
      descriptionId: map['description_id'],
      phoneNumber: map['phone_number'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      location: map['location'],
      is24Hour: map['is_24_hour'] == 1,
    );
  }

  // Helper method للحصول على الاسم حسب اللغة
  String getName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return nameAr;
      case 'en':
        return nameEn;
      case 'ur':
        return nameUr;
      case 'id':
        return nameId;
      default:
        return nameEn;
    }
  }

  // Helper method للحصول على الوصف حسب اللغة
  String getDescription(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return descriptionAr;
      case 'en':
        return descriptionEn;
      case 'ur':
        return descriptionUr;
      case 'id':
        return descriptionId;
      default:
        return descriptionEn;
    }
  }
} 