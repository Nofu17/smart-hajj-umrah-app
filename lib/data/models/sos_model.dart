class SOSModel {
  final int? id;
  final String groupCode;
  final String memberName;
  final double latitude;
  final double longitude;
  final String timestamp;
  final bool isResolved;

  SOSModel({
    this.id,
    required this.groupCode,
    required this.memberName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.isResolved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_code': groupCode,
      'member_name': memberName,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'is_resolved': isResolved ? 1 : 0,
    };
  }

  factory SOSModel.fromMap(Map<String, dynamic> map) {
    return SOSModel(
      id: map['id'],
      groupCode: map['group_code'],
      memberName: map['member_name'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      timestamp: map['timestamp'],
      isResolved: map['is_resolved'] == 1,
    );
  }
} 