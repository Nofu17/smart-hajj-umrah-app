class GroupMemberModel {
  final String? id;
  final String memberId;
  final String groupCode;
  final String memberName;
  final double latitude;
  final double longitude;
  final String role; 
  final DateTime joinedAt;
  final DateTime? lastLocationUpdate;

  GroupMemberModel({
    this.id,
    required this.memberId,
    required this.groupCode,
    required this.memberName,
    required this.latitude,
    required this.longitude,
    required this.role,
    required this.joinedAt,
    this.lastLocationUpdate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'member_id': memberId,
      'group_code': groupCode,
      'member_name': memberName,
      'latitude': latitude,
      'longitude': longitude,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
      'last_location_update': lastLocationUpdate?.toIso8601String(),
    };
  }

  factory GroupMemberModel.fromMap(Map<String, dynamic> map) {
    return GroupMemberModel(
      id: map['id']?.toString(),
      memberId: map['member_id'] ?? '',
      groupCode: map['group_code'],
      memberName: map['member_name'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      role: map['role'],
      joinedAt: DateTime.parse(map['joined_at']),
      lastLocationUpdate: map['last_location_update'] != null
          ? DateTime.parse(map['last_location_update'])
          : null,
    );
  } 
}