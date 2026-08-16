class LapSessionModel {
  final int? id;
  final String ritualType;
  final int currentLap;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isComplete;

  LapSessionModel({
    this.id,
    required this.ritualType,
    required this.currentLap,
    required this.startTime,
    this.endTime,
    this.isComplete = false,
  });

  // ✅  
  LapSessionModel copyWith({
    int? id,
    String? ritualType,
    int? currentLap,
    DateTime? startTime,
    DateTime? endTime,
    bool? isComplete,
  }) {
    return LapSessionModel(
      id: id ?? this.id,
      ritualType: ritualType ?? this.ritualType,
      currentLap: currentLap ?? this.currentLap,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  // ✅ أضف هذه الدالة
  int get durationInSeconds {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inSeconds;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ritual_type': ritualType,
      'current_lap': currentLap,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'is_complete': isComplete ? 1 : 0,
    };
  }

  factory LapSessionModel.fromMap(Map<String, dynamic> map) {
    return LapSessionModel(
      id: map['id'],
      ritualType: map['ritual_type'],
      currentLap: map['current_lap'],
      startTime: DateTime.parse(map['start_time']),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      isComplete: map['is_complete'] == 1,
    );
  }
} 