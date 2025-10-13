import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionModel {
  final String userId;
  final String status; // 'pending', 'accepted'
  final DateTime requestedAt;
  final DateTime? acceptedAt;

  ConnectionModel({
    required this.userId,
    required this.status,
    required this.requestedAt,
    this.acceptedAt,
  });

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'status': status,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
    };
  }

  // Create from Firebase JSON
  factory ConnectionModel.fromJson(Map<String, dynamic> json) {
    return ConnectionModel(
      userId: json['userId'] ?? '',
      status: json['status'] ?? 'pending',
      requestedAt: (json['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (json['acceptedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Create a copy with updated fields
  ConnectionModel copyWith({
    String? userId,
    String? status,
    DateTime? requestedAt,
    DateTime? acceptedAt,
  }) {
    return ConnectionModel(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }
}

// Enum for connection status
enum ConnectionStatus {
  none,        // No connection
  pending,     // Request sent but not accepted
  accepted,    // Connection established
}

extension ConnectionStatusExtension on ConnectionStatus {
  String get value {
    switch (this) {
      case ConnectionStatus.none:
        return 'none';
      case ConnectionStatus.pending:
        return 'pending';
      case ConnectionStatus.accepted:
        return 'accepted';
    }
  }

  static ConnectionStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return ConnectionStatus.pending;
      case 'accepted':
        return ConnectionStatus.accepted;
      default:
        return ConnectionStatus.none;
    }
  }
}