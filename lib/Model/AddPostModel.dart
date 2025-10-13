import 'package:cloud_firestore/cloud_firestore.dart';

class AddPost {
  final String postId;
  final String caption;
  final LocationModel location;
  final List<String> tags;
  final List<String> images;
  final DateTime? createdAt;
  final int likes;
  final int shares;
  final String userId;
  final int commentCount;
  final List<CommentModel> comments;

  AddPost({
    required this.postId,
    required this.caption,
    required this.location,
    required this.tags,
    required this.images,
    required this.userId,
    this.createdAt,
    this.likes = 0,
    this.shares = 0,
    this.commentCount = 0,
    this.comments = const [],
  });

  // Convert JSON → Model
  factory AddPost.fromJson(Map<String, dynamic> json, String id) {
    return AddPost(
      postId: id,
      caption: json['caption'] ?? '',
      location: LocationModel.fromJson(json['location'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      createdAt: json['timestamp'] != null
          ? (json['timestamp'] as Timestamp).toDate()
          : null,
      likes: json['likes'] ?? 0,
      shares: json['shares'] ?? 0,
      userId: json['userId'] ?? '',
      commentCount: json['commentCount'] ?? 0,
      comments: (json['comments'] as List<dynamic>?)
          ?.map((c) => CommentModel.fromJson(c))
          .toList() ??
          [],
    );
  }

  // Convert Model → JSON
  Map<String, dynamic> toJson() {
    return {
      'caption': caption,
      'location': location.toJson(),
      'tags': tags,
      'images': images,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': likes,
      'shares': shares,
      'userId': userId,
      'commentCount': commentCount,
      'comments': comments.map((c) => c.toJson()).toList(),
    };
  }
}

class LocationModel {
  final double latitude;
  final double longitude;
  final String address;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}

class CommentModel {
  final String commentId;
  final String userId;
  final String text;
  final DateTime createdAt;

  CommentModel({
    required this.commentId,
    required this.userId,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      commentId: json['commentId'] ?? '',
      userId: json['userId'] ?? '',
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'userId': userId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
