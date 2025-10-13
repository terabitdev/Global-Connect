import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionNotificationModel {
  final String id;
  final String type;
  final String fromUserId;
  final DateTime createdAt;
  final bool isRead;
  final String status;
  final String? postId;  // For like/comment notifications
  final String? postImageUrl;  // For showing post preview
  final String? commentText;  // For displaying comment content

  ConnectionNotificationModel({
    required this.id,
    required this.type,
    required this.fromUserId,
    required this.createdAt,
    this.isRead = false,
    this.status = 'pending',
    this.postId,
    this.postImageUrl,
    this.commentText,
  });

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'fromUserId': fromUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'status': status,
      if (postId != null) 'postId': postId,
      if (postImageUrl != null) 'postImageUrl': postImageUrl,
      if (commentText != null) 'commentText': commentText,
    };
  }

  // Create from Firebase JSON
  factory ConnectionNotificationModel.fromJson(Map<String, dynamic> json, String docId) {
    return ConnectionNotificationModel(
      id: docId,
      type: json['type'] ?? '',
      fromUserId: json['fromUserId'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
      status: json['status'] ?? 'pending',
      postId: json['postId'],
      postImageUrl: json['postImageUrl'],
      commentText: json['commentText'],
    );
  }

  // Create a copy with updated fields
  ConnectionNotificationModel copyWith({
    String? id,
    String? type,
    String? fromUserId,
    DateTime? createdAt,
    bool? isRead,
    String? status,
    String? postId,
    String? postImageUrl,
    String? commentText,
  }) {
    return ConnectionNotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      fromUserId: fromUserId ?? this.fromUserId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
      postId: postId ?? this.postId,
      postImageUrl: postImageUrl ?? this.postImageUrl,
      commentText: commentText ?? this.commentText,
    );
  }

  // Factory method for connection request
  factory ConnectionNotificationModel.connectionRequest({
    required String fromUserId,
  }) {
    return ConnectionNotificationModel(
      id: '',
      type: 'connection_request',
      fromUserId: fromUserId,
      createdAt: DateTime.now(),
      isRead: false,
      status: 'pending',
    );
  }

  // Factory method for connection accepted
  factory ConnectionNotificationModel.connectionAccepted({
    required String fromUserId,
  }) {
    return ConnectionNotificationModel(
      id: '',
      type: 'connection_accepted',
      fromUserId: fromUserId,
      createdAt: DateTime.now(),
      isRead: false,
      status: 'accepted',
    );
  }

  // Factory method for follow notification
  factory ConnectionNotificationModel.followNotification({
    required String fromUserId,
  }) {
    return ConnectionNotificationModel(
      id: '',
      type: 'follow',
      fromUserId: fromUserId,
      createdAt: DateTime.now(),
      isRead: false,
      status: 'active',
    );
  }

  // Factory method for follow back notification
  factory ConnectionNotificationModel.followBackNotification({
    required String fromUserId,
  }) {
    return ConnectionNotificationModel(
      id: '',
      type: 'follow_back',
      fromUserId: fromUserId,
      createdAt: DateTime.now(),
      isRead: false,
      status: 'active',
    );
  }

  // Factory method for like notification
  factory ConnectionNotificationModel.likeNotification({
    required String fromUserId,
    required String postId,
    String? postImageUrl,
  }) {
    return ConnectionNotificationModel(
      id: '',
      type: 'like',
      fromUserId: fromUserId,
      createdAt: DateTime.now(),
      isRead: false,
      status: 'active',
      postId: postId,
      postImageUrl: postImageUrl,
    );
  }

  // Factory method for comment notification
  factory ConnectionNotificationModel.commentNotification({
    required String fromUserId,
    required String postId,
    String? postImageUrl,
    String? commentText,
  }) {
    return ConnectionNotificationModel(
      id: '',
      type: 'comment',
      fromUserId: fromUserId,
      createdAt: DateTime.now(),
      isRead: false,
      status: 'active',
      postId: postId,
      postImageUrl: postImageUrl,
      commentText: commentText,
    );
  }
}