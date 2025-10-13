class NotificationModel {
  final DateTime createdAt;
  final String eventCity;
  final String eventDate;
  final String eventId;
  final String eventName;
  final String eventTime;
  final bool isRead;
  final String message;
  final String targetAudience;
  final String title;
  final String type;

  NotificationModel({
    required this.createdAt,
    required this.eventCity,
    required this.eventDate,
    required this.eventId,
    required this.eventName,
    required this.eventTime,
    required this.isRead,
    required this.message,
    required this.targetAudience,
    required this.title,
    required this.type,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      createdAt: map['createdAt'].toDate(),
      eventCity: map['eventCity'] ?? '',
      eventDate: map['eventDate'] ?? '',
      eventId: map['eventId'] ?? '',
      eventName: map['eventName'] ?? '',
      eventTime: map['eventTime'] ?? '',
      isRead: map['isRead'] ?? false,
      message: map['message'] ?? '',
      targetAudience: map['targetAudience'] ?? '',
      title: map['title'] ?? '',
      type: map['type'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt,
      'eventCity': eventCity,
      'eventDate': eventDate,
      'eventId': eventId,
      'eventName': eventName,
      'eventTime': eventTime,
      'isRead': isRead,
      'message': message,
      'targetAudience': targetAudience,
      'title': title,
      'type': type,
    };
  }
}
