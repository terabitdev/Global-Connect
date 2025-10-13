
import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String city;
  final DateTime createdAt;
  final String createdBy;
  final String createdByEmail;
  final String date;
  final String description;
  final String eventName;
  final String eventType;

  final bool featuredEvent;
  final List<String> images;
  final String ticketLink;
  final String time;
  final DateTime? updatedAt;
  final String venue;

  EventModel({
    required this.id,
    required this.city,
    required this.createdAt,
    required this.createdBy,
    required this.createdByEmail,
    required this.date,
    required this.description,
    required this.eventName,
    required this.eventType,
    required this.featuredEvent,
    required this.images,
    required this.ticketLink,
    required this.time,
    this.updatedAt,
    required this.venue,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      return EventModel(
        id: doc.id,
        city: data['city'] ?? '',
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        createdBy: data['createdBy'] ?? '',
        createdByEmail: data['createdByEmail'] ?? '',
        date: data['date'] ?? '',
        description: data['description'] ?? '',
        eventName: data['eventName'] ?? '',
        eventType: data['eventType'] ?? '',
        featuredEvent: data['featuredEvent'] ?? false,
        images: data['images'] != null
            ? List<String>.from(data['images'])
            : [],
        ticketLink: data['ticketLink'] ?? '',
        time: data['time'] ?? '',
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] as Timestamp).toDate()
            : null,
        venue: data['venue'] ?? '',
      );
    } catch (e) {
      print('❌ Error creating EventModel from Firestore: $e');
      throw Exception('Failed to parse event data: $e');
    }
  }


  factory EventModel.fromMap(Map<String, dynamic> map, String documentId) {
    return EventModel(
      id: documentId,
      city: map['city'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] is String
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      createdBy: map['createdBy'] ?? '',
      createdByEmail: map['createdByEmail'] ?? '',
      date: map['date'] ?? '',
      description: map['description'] ?? '',
      eventName: map['eventName'] ?? '',
      eventType: map['eventType'] ?? '',
      featuredEvent: map['featuredEvent'] ?? false,
      images: map['images'] != null ? List<String>.from(map['images']) : [],
      ticketLink: map['ticketLink'] ?? '',
      time: map['time'] ?? '',
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : map['updatedAt'] is String
          ? DateTime.tryParse(map['updatedAt'])
          : null,
      venue: map['venue'] ?? '',
    );
  }

}
