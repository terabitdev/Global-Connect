import 'package:cloud_firestore/cloud_firestore.dart';

class TipsModel {
  final String id;
  final String category;
  final String title;
  final String? restaurantName;
  final String? country;
  final String? city;
  final String? tipCity;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String tip;
  final bool countrymenOnly;
  final String createdBy;
  final DateTime createdAt;
  final int likeCount;
  final int dislikeCount;
  final List<String> userLikeMembers;
  final List<String> userDislikeMembers;

  TipsModel({
    required this.id,
    required this.category,
    required this.title,
    this.restaurantName,
    this.country,
    this.city,
    this.tipCity,
    this.address,
    this.latitude,
    this.longitude,
    required this.tip,
    required this.countrymenOnly,
    required this.createdBy,
    required this.createdAt,
    required this.likeCount,
    required this.dislikeCount,
    required this.userLikeMembers,
    required this.userDislikeMembers,
  });

  factory TipsModel.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      return TipsModel(
        id: doc.id,
        category: data['category'] ?? '',
        title: data['title'] ?? '',
        restaurantName: data['restaurantName'],
        country: data['country'],
        city: data['city'],
        tipCity: data['tipCity'],
        address: data['address'],
        latitude: data['latitude']?.toDouble(),
        longitude: data['longitude']?.toDouble(),
        tip: data['tip'] ?? '',
        countrymenOnly: data['countrymenOnly'] ?? false,
        createdBy: data['createdBy'] ?? '',
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        likeCount: data['likeCount'] ?? 0,
        dislikeCount: data['dislikeCount'] ?? 0,
        userLikeMembers: data['userLikeMembers'] != null
            ? List<String>.from(data['userLikeMembers'])
            : [],
        userDislikeMembers: data['userDislikeMembers'] != null
            ? List<String>.from(data['userDislikeMembers'])
            : [],
      );
    } catch (e) {
      print('❌ Error creating TipsModel from Firestore: $e');
      throw Exception('Failed to parse tip data: $e');
    }
  }

  factory TipsModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TipsModel(
      id: documentId,
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      restaurantName: map['restaurantName'],
      country: map['country'],
      city: map['city'],
      tipCity: map['tipCity'],
      address: map['address'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      tip: map['tip'] ?? '',
      countrymenOnly: map['countrymenOnly'] ?? false,
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] is String
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      likeCount: map['likeCount'] ?? 0,
      dislikeCount: map['dislikeCount'] ?? 0,
      userLikeMembers: map['userLikeMembers'] != null
          ? List<String>.from(map['userLikeMembers'])
          : [],
      userDislikeMembers: map['userDislikeMembers'] != null
          ? List<String>.from(map['userDislikeMembers'])
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'title': title,
      'restaurantName': restaurantName,
      'country': country,
      'city': city,
      'tipCity': tipCity,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'tip': tip,
      'countrymenOnly': countrymenOnly,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'likeCount': likeCount,
      'dislikeCount': dislikeCount,
      'userLikeMembers': userLikeMembers,
      'userDislikeMembers': userDislikeMembers,
    };
  }


  bool hasUserLiked(String userId) {
    return userLikeMembers.contains(userId);
  }

  bool hasUserDisliked(String userId) {
    return userDislikeMembers.contains(userId);
  }


  TipsModel copyWith({
    String? id,
    String? category,
    String? title,
    String? restaurantName,
    String? country,
    String? city,
    String? tipCity,
    String? address,
    double? latitude,
    double? longitude,
    String? tip,
    bool? countrymenOnly,
    String? createdBy,
    DateTime? createdAt,
    int? likeCount,
    int? dislikeCount,
    List<String>? userLikeMembers,
    List<String>? userDislikeMembers,
  }) {
    return TipsModel(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      restaurantName: restaurantName ?? this.restaurantName,
      country: country ?? this.country,
      city: city ?? this.city,
      tipCity: tipCity ?? this.tipCity,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tip: tip ?? this.tip,
      countrymenOnly: countrymenOnly ?? this.countrymenOnly,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      userLikeMembers: userLikeMembers ?? this.userLikeMembers,
      userDislikeMembers: userDislikeMembers ?? this.userDislikeMembers,
    );
  }
}

