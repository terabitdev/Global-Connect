import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String? id;
  final String name;
  final String lastMessage;
  final String profileImage;
  final String time;
  final bool isOnline;
  final String? status;
  final bool activityStatus;
  final String? otherUserId;
  final DateTime? lastMessageTime;

  ChatModel({
    this.id,
    required this.name,
    required this.lastMessage,
    required this.profileImage,
    required this.time,
    this.status,
    required this.isOnline,
    this.activityStatus = true,
    this.otherUserId,
    this.lastMessageTime,
  });

  ChatModel copyWith({
    String? id,
    String? name,
    String? lastMessage,
    String? profileImage,
    String? time,
    String? status,
    bool? isOnline,
    bool? activityStatus,
    String? otherUserId,
    DateTime? lastMessageTime,
  }) {
    return ChatModel(
      id: id ?? this.id,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      profileImage: profileImage ?? this.profileImage,
      time: time ?? this.time,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      activityStatus: activityStatus ?? this.activityStatus,
      otherUserId: otherUserId ?? this.otherUserId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }
}

class ChatRoom {
  final String id;
  final List<String> participantsList;
  final String lastMessage;
  final DateTime sentOn;

  ChatRoom({
    required this.id,
    required this.participantsList,
    required this.lastMessage,
    required this.sentOn,
  });

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'participantsList': participantsList,
      'lastMessage': lastMessage,
      'sentOn': Timestamp.fromDate(sentOn),
    };
  }

  // Create from Firestore document
  factory ChatRoom.fromFirestore(DocumentSnapshot doc, {required String id}) {
    final data = doc.data() as Map<String, dynamic>;

    return ChatRoom(
      id: id,
      participantsList: List<String>.from(data['participantsList'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      sentOn: (data['sentOn'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Copy with method for easy updates
  ChatRoom copyWith({
    String? id,
    List<String>? participantsList,
    String? lastMessage,
    DateTime? sentOn,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      participantsList: participantsList ?? this.participantsList,
      lastMessage: lastMessage ?? this.lastMessage,
      sentOn: sentOn ?? this.sentOn,
    );
  }
}

class Message {
  final String id;
  final String text;
  final String sender;
  final String receiver;
  final DateTime sentOn;
  final bool isRead;
  final String messageType;
  final String? postId;
  final String? postOwnerId;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.receiver,
    required this.sentOn,
    required this.isRead,
    this.messageType = 'text',
    this.postId,
    this.postOwnerId,
  });

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'text': text,
      'sender': sender,
      'receiver': receiver,
      'sentOn': Timestamp.fromDate(sentOn),
      'isRead': isRead,
      'messageType': messageType,
      if (postId != null) 'postId': postId,
      if (postOwnerId != null) 'postOwnerId': postOwnerId,
    };
  }

  // Create from Firestore document
  factory Message.fromFirestore(DocumentSnapshot doc, {String? id}) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Message(
      id: id ?? doc.id,
      text: data['text'] ?? '',
      sender: data['sender'] ?? '',
      receiver: data['receiver'] ?? '',
      sentOn: (data['sentOn'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      messageType: data['messageType'] ?? 'text',
      postId: data['postId'],
      postOwnerId: data['postOwnerId'],
    );
  }
}

class GroupChatModel {
  final String id;
  final String groupName;
  final String groupDescription;
  final String groupType;
  final String groupImageUrl;
  final List<String> participantsList;
  final String lastMessage;
  final DateTime? sentOn;
  final String createdBy;
  final DateTime? createdAt;
  final bool isActive;

  GroupChatModel({
    required this.id,
    required this.groupName,
    required this.groupDescription,
    required this.groupType,
    required this.groupImageUrl,
    required this.participantsList,
    required this.lastMessage,
    this.sentOn,
    required this.createdBy,
    this.createdAt,
    this.isActive = true,
  });

  // Convert GroupChatModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'groupName': groupName,
      'groupDescription': groupDescription,
      'groupType': groupType,
      'groupImageUrl': groupImageUrl,
      'participantsList': participantsList,
      'lastMessage': lastMessage,
      'sentOn': sentOn != null ? Timestamp.fromDate(sentOn!) : null,
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'isActive': isActive,
    };
  }

  // Create GroupChatModel from Firestore Map
  factory GroupChatModel.fromFirestore(Map<String, dynamic> data) {
    return GroupChatModel(
      id: data['id'] ?? '',
      groupName: data['groupName'] ?? '',
      groupDescription: data['groupDescription'] ?? '',
      groupType: data['groupType'] ?? 'public',
      groupImageUrl: data['groupImageUrl'] ?? '',
      participantsList: List<String>.from(data['participantsList'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      sentOn: data['sentOn'] != null
          ? (data['sentOn'] as Timestamp).toDate()
          : null,
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
    );
  }

  // Create GroupChatModel from Firestore DocumentSnapshot
  factory GroupChatModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupChatModel.fromFirestore(data);
  }

  // CopyWith method for updating specific fields
  GroupChatModel copyWith({
    String? id,
    String? groupName,
    String? groupDescription,
    String? groupType,
    String? groupImageUrl,
    List<String>? participantsList,
    String? lastMessage,
    DateTime? sentOn,
    String? createdBy,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return GroupChatModel(
      id: id ?? this.id,
      groupName: groupName ?? this.groupName,
      groupDescription: groupDescription ?? this.groupDescription,
      groupType: groupType ?? this.groupType,
      groupImageUrl: groupImageUrl ?? this.groupImageUrl,
      participantsList: participantsList ?? this.participantsList,
      lastMessage: lastMessage ?? this.lastMessage,
      sentOn: sentOn ?? this.sentOn,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'GroupChatModel(id: $id, groupName: $groupName, groupType: $groupType, participantsCount: ${participantsList.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupChatModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class GroupMessageModel {
  final String id;
  final String message;
  final String senderId;
  final String senderName;
  final DateTime sentOn;
  final String messageType;
  final bool isRead;

  GroupMessageModel({
    required this.id,
    required this.message,
    required this.senderId,
    required this.senderName,
    required this.sentOn,
    this.messageType = 'text',
    this.isRead = false,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'message': message,
      'senderId': senderId,
      'senderName': senderName,
      'sentOn': Timestamp.fromDate(sentOn),
      'messageType': messageType,
      'isRead': isRead,
    };
  }

  // Create from Firestore Map
  factory GroupMessageModel.fromFirestore(Map<String, dynamic> data) {
    return GroupMessageModel(
      id: data['id'] ?? '',
      message: data['message'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      sentOn: (data['sentOn'] as Timestamp).toDate(),
      messageType: data['messageType'] ?? 'text',
      isRead: data['isRead'] ?? false,
    );
  }

  // Create from DocumentSnapshot
  factory GroupMessageModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupMessageModel.fromFirestore(data);
  }

  @override
  String toString() {
    return 'GroupMessageModel(id: $id, senderId: $senderId, message: $message)';
  }
}