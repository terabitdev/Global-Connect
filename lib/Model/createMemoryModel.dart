import 'package:cloud_firestore/cloud_firestore.dart';

class CreateMemoryModel {
  final String memoryId;
  final String memoryName;
  final DateTime startDate;
  final DateTime endDate;
  final String country;
  final PrivacySetting privacy;
  final List<TripStop> tripStops;
  final String? coverImageUrl;
  final List<String> mediaImageUrls;
  final String caption;
  final DateTime? createdAt;
  final String userId;
  final List<String> viewedBy;

  CreateMemoryModel({
    required this.memoryId,
    required this.memoryName,
    required this.startDate,
    required this.endDate,
    required this.country,
    required this.privacy,
    required this.caption,
    required this.userId,
    this.mediaImageUrls = const [],
    this.tripStops = const [],
    this.viewedBy = const [],
    this.coverImageUrl,
    this.createdAt,
  });


  factory CreateMemoryModel.fromJson(Map<String, dynamic> json, String id) {
    return CreateMemoryModel(
      memoryId: id,
      memoryName: json['memoryName'] ?? '',
      startDate: json['startDate'] != null
          ? (json['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? (json['endDate'] as Timestamp).toDate()
          : DateTime.now(),
      country: json['country'] ?? '',
      privacy: PrivacySetting.values.firstWhere(
        (e) => e.toString().split('.').last == json['privacy'],
        orElse: () => PrivacySetting.private,
      ),
      tripStops:
          (json['tripStops'] as List<dynamic>?)
              ?.map((stop) => TripStop.fromJson(stop))
              .toList() ??
          [],
      coverImageUrl: json['coverImageUrl'],
      mediaImageUrls: json['mediaImageUrls'] != null
          ? List<String>.from(json['mediaImageUrls'])
          : [],
      caption: json['caption'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      userId: json['userId'] ?? '',
      viewedBy: json['viewedBy'] != null
          ? List<String>.from(json['viewedBy'])
          : [],
    );
  }

  // Convert Model → JSON
  Map<String, dynamic> toJson() {
    return {
      'memoryName': memoryName,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'country': country,
      'privacy': privacy.toString().split('.').last,
      'tripStops': tripStops.map((stop) => stop.toJson()).toList(),
      'coverImageUrl': coverImageUrl,
      'mediaImageUrls': mediaImageUrls,
      'caption': caption,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': userId,
      'viewedBy': viewedBy,
    };
  }

  // Copy with method for easy updates
  CreateMemoryModel copyWith({
    String? memoryId,
    String? memoryName,
    DateTime? startDate,
    DateTime? endDate,
    String? country,
    PrivacySetting? privacy,
    List<TripStop>? tripStops,
    String? coverImageUrl,
    List<String>? mediaImageUrls,
    String? caption,
    DateTime? createdAt,
    String? userId,
    List<String>? viewedBy,
  }) {
    return CreateMemoryModel(
      memoryId: memoryId ?? this.memoryId,
      memoryName: memoryName ?? this.memoryName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      country: country ?? this.country,
      privacy: privacy ?? this.privacy,
      tripStops: tripStops ?? this.tripStops,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      mediaImageUrls: mediaImageUrls ?? this.mediaImageUrls,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      viewedBy: viewedBy ?? this.viewedBy,
    );
  }
}

class TripStop {
  final String stopId;
  final String country;
  final String? city;
  final DateTime fromDate;
  final DateTime toDate;
  final int order;

  TripStop({
    required this.stopId,
    required this.country,
    required this.fromDate,
    required this.toDate,
    required this.order,
    this.city,
  });

  // Convert JSON → Model
  factory TripStop.fromJson(Map<String, dynamic> json) {
    return TripStop(
      stopId: json['stopId'] ?? '',
      country: json['country'] ?? '',
      city: json['city'],
      fromDate: json['fromDate'] != null
          ? (json['fromDate'] as Timestamp).toDate()
          : DateTime.now(),
      toDate: json['toDate'] != null
          ? (json['toDate'] as Timestamp).toDate()
          : DateTime.now(),
      order: json['order'] ?? 0,
    );
  }

  // Convert Model → JSON
  Map<String, dynamic> toJson() {
    return {
      'stopId': stopId,
      'country': country,
      'city': city,
      'fromDate': Timestamp.fromDate(fromDate),
      'toDate': Timestamp.fromDate(toDate),
      'order': order,
    };
  }

  // Copy with method
  TripStop copyWith({
    String? stopId,
    String? country,
    String? city,
    DateTime? fromDate,
    DateTime? toDate,
    int? order,
  }) {
    return TripStop(
      stopId: stopId ?? this.stopId,
      country: country ?? this.country,
      city: city ?? this.city,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      order: order ?? this.order,
    );
  }
}

enum PrivacySetting {
  private,
  public;

  String get displayName {
    switch (this) {
      case PrivacySetting.private:
        return 'Private';
      case PrivacySetting.public:
        return 'Public';
    }
  }

  String get description {
    switch (this) {
      case PrivacySetting.private:
        return 'Only you can see this memory';
      case PrivacySetting.public:
        return 'Anyone can discover and view';
    }
  }
}
