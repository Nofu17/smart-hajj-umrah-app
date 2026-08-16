class GroupModel {
  final String? id;
  final String groupCode;
  final String groupName;
  final String leaderName;
  final DateTime createdAt;
  final bool isActive;

  GroupModel({
    this.id,
    required this.groupCode,
    required this.groupName,
    required this.leaderName,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_code': groupCode,
      'group_name': groupName,
      'leader_name': leaderName,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  } 

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id']?.toString(),
      groupCode: map['group_code'],
      groupName: map['group_name'],
      leaderName: map['leader_name'],
      createdAt: DateTime.parse(map['created_at']),
      isActive: map['is_active'] == 1,
    );
  }
}