class DuaModel {
  final int? id;
  final String arabicText;
  final String transliteration;
  final String translationAr;
  final String translationEn;
  final String translationUr;
  final String translationId;
  final String? source;

  DuaModel({
    this.id,
    required this.arabicText,
    required this.transliteration,
    required this.translationAr,
    required this.translationEn,
    required this.translationUr,
    required this.translationId,
    this.source,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'arabic_text': arabicText,
      'transliteration': transliteration,
      'translation_ar': translationAr,
      'translation_en': translationEn,
      'translation_ur': translationUr,
      'translation_id': translationId,
      'source': source,
    };
  }

  factory DuaModel.fromMap(Map<String, dynamic> map) {
    return DuaModel(
      id: map['id'],
      arabicText: map['arabic_text'],
      transliteration: map['transliteration'],
      translationAr: map['translation_ar'],
      translationEn: map['translation_en'],
      translationUr: map['translation_ur'],
      translationId: map['translation_id'],
      source: map['source'],
    );
  }
} 