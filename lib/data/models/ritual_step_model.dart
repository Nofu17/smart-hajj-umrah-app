class RitualStepModel {
  final int? id;
  final int ritualId;
  final int stepNumber;
  final String titleAr;
  final String titleEn;
  final String titleUr;
  final String titleId;
  final String descriptionAr;
  final String descriptionEn;
  final String descriptionUr;
  final String descriptionId;
  final String? imagePath;

  RitualStepModel({
    this.id,
    required this.ritualId,
    required this.stepNumber,
    required this.titleAr,
    required this.titleEn,
    required this.titleUr,
    required this.titleId,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.descriptionUr,
    required this.descriptionId,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ritual_id': ritualId,
      'step_number': stepNumber,
      'title_ar': titleAr,
      'title_en': titleEn,
      'title_ur': titleUr,
      'title_id': titleId,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'description_ur': descriptionUr,
      'description_id': descriptionId,
      'image_path': imagePath,
    };
  } 

  factory RitualStepModel.fromMap(Map<String, dynamic> map) {
    return RitualStepModel(
      id: map['id'],
      ritualId: map['ritual_id'],
      stepNumber: map['step_number'],
      titleAr: map['title_ar'],
      titleEn: map['title_en'],
      titleUr: map['title_ur'],
      titleId: map['title_id'],
      descriptionAr: map['description_ar'],
      descriptionEn: map['description_en'],
      descriptionUr: map['description_ur'],
      descriptionId: map['description_id'],
      imagePath: map['image_path'],
    );
  }
}