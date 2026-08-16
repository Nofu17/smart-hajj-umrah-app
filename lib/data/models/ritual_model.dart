class RitualModel {
  final int? id;
  final String ritualType; // 'umrah', 'tamattu', 'qiran', 'ifrad'
  final String nameAr;
  final String nameEn;
  final String nameUr;
  final String nameId;
  final int totalSteps;

  RitualModel({
    this.id,
    required this.ritualType,
    required this.nameAr,
    required this.nameEn,
    required this.nameUr,
    required this.nameId,
    required this.totalSteps,
  });

  // تحويل Object إلى Map (للحفظ في Database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ritual_type': ritualType,
      'name_ar': nameAr,
      'name_en': nameEn,
      'name_ur': nameUr, 
      'name_id': nameId,
      'total_steps': totalSteps,
    };
  }

  // تحويل Map إلى Object (القراءة من Database)
  factory RitualModel.fromMap(Map<String, dynamic> map) {
    return RitualModel(
      id: map['id'],
      ritualType: map['ritual_type'],
      nameAr: map['name_ar'],
      nameEn: map['name_en'],
      nameUr: map['name_ur'],
      nameId: map['name_id'],
      totalSteps: map['total_steps'],
    );
  }
}