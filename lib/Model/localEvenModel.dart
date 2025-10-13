import 'package:cloud_firestore/cloud_firestore.dart';
class LocalEventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String location;
  final String imageUrl;
  final String category;
  final String createdById;
  final int maxAttendees;
  final DateTime createdAt;
  final List<String> attendeesIds;
  final double? latitude;
  final double? longitude;

  LocalEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.createdById,
    required this.imageUrl,
    required this.category,
    required this.maxAttendees,
    required this.createdAt,
    required this.attendeesIds,
    this.latitude,
    this.longitude,
  });

  /// Convert model to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'time': time,
      'location': location,
      'imageUrl': imageUrl,
      'createdById': createdById,
      'category': category,
      'maxAttendees': maxAttendees,
      'createdAt': Timestamp.fromDate(createdAt),
      'attendeesIds': attendeesIds,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Create model from Firebase DocumentSnapshot
  factory LocalEventModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocalEventModel(
      id: data['id'] ?? doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'] ?? '',
      location: data['location'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? '',
      maxAttendees: data['maxAttendees'] ?? 0,
      createdById: data['createdById'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      attendeesIds: List<String>.from(data['attendeesIds'] ?? []),
      latitude: (data['latitude'] != null)
          ? (data['latitude'] as num).toDouble()
          : null,
      longitude: (data['longitude'] != null)
          ? (data['longitude'] as num).toDouble()
          : null,
    );
  }

  /// Create model from Map
  factory LocalEventModel.fromMap(Map<String, dynamic> map) {
    return LocalEventModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      createdById: map['createdById'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] is Timestamp)
          ? (map['date'] as Timestamp).toDate()
          : DateTime.tryParse(map['date'].toString()) ?? DateTime.now(),
      time: map['time'] ?? '',
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? '',
      maxAttendees: map['maxAttendees'] ?? 0,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now(),
      attendeesIds: List<String>.from(map['attendeesIds'] ?? []),
      latitude: (map['latitude'] != null)
          ? (map['latitude'] as num).toDouble()
          : null,
      longitude: (map['longitude'] != null)
          ? (map['longitude'] as num).toDouble()
          : null,
    );
  }
}



