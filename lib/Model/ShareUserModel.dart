class ShareUserModel {
  final String id;
  final String name;
  final String avatar;
  final String? username;
  final bool isOnline;
  final String? lastSeen;
  final bool isMutualFriend;

  ShareUserModel({
    required this.id,
    required this.name,
    required this.avatar,
    this.username,
    this.isOnline = false,
    this.lastSeen,
    this.isMutualFriend = false,
  });

  ShareUserModel copyWith({
    String? id,
    String? name,
    String? avatar,
    String? username,
    bool? isOnline,
    String? lastSeen,
    bool? isMutualFriend,
  }) {
    return ShareUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      username: username ?? this.username,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isMutualFriend: isMutualFriend ?? this.isMutualFriend,
    );
  }

  String get displayName {
    if (username != null && username!.isNotEmpty) {
      return '@$username';
    }
    return name;
  }

  String get statusText {
    if (isOnline) {
      return 'Online';
    } else if (lastSeen != null) {
      return 'Last seen $lastSeen';
    }
    return '';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'username': username,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'isMutualFriend': isMutualFriend,
    };
  }

  factory ShareUserModel.fromMap(Map<String, dynamic> map) {
    return ShareUserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      avatar: map['avatar'] ?? '',
      username: map['username'],
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'],
      isMutualFriend: map['isMutualFriend'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShareUserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}