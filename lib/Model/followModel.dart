import 'package:cloud_firestore/cloud_firestore.dart';

class FollowModel {
  final String userId;
  final DateTime followedAt;

  FollowModel({
    required this.userId,
    required this.followedAt,
  });

  factory FollowModel.fromMap(Map<String, dynamic> data) {
    return FollowModel(
      userId: data['userId'] ?? '',
      followedAt: _parseDate(data['followedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'followedAt': Timestamp.fromDate(followedAt),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }
}