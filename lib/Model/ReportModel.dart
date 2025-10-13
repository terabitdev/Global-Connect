import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportContentType {
  post,
  tip,
}

class ReportModel {
  final String reportId;
  final String contentId; // Can be postId or tipId
  final String contentOwnerId; // Can be postOwnerId or tipOwnerId
  final ReportContentType contentType; // post or tip
  final String reportedBy;
  final String reportedByName;
  final String reportedByEmail;
  final String reason;
  final String additionalDetails;
  final DateTime timestamp;
  final String status;
  final String? adminNotes;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  ReportModel({
    required this.reportId,
    required this.contentId,
    required this.contentOwnerId,
    required this.contentType,
    required this.reportedBy,
    required this.reportedByName,
    required this.reportedByEmail,
    required this.reason,
    required this.additionalDetails,
    required this.timestamp,
    this.status = 'pending',
    this.adminNotes,
    this.reviewedAt,
    this.reviewedBy,
  });

  // Convert from Firestore document
  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      reportId: doc.id,
      contentId: data['contentId'] ?? '',
      contentOwnerId: data['contentOwnerId'] ?? '',
      contentType: ReportContentType.values.firstWhere(
        (type) => type.name == (data['contentType'] ?? 'post'),
        orElse: () => ReportContentType.post,
      ),
      reportedBy: data['reportedBy'] ?? '',
      reportedByName: data['reportedByName'] ?? '',
      reportedByEmail: data['reportedByEmail'] ?? '',
      reason: data['reason'] ?? '',
      additionalDetails: data['additionalDetails'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      adminNotes: data['adminNotes'],
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'],
    );
  }

  // Convert from JSON
  factory ReportModel.fromJson(Map<String, dynamic> json, String id) {
    return ReportModel(
      reportId: id,
      contentId: json['contentId'] ?? '',
      contentOwnerId: json['contentOwnerId'] ?? '',
      contentType: ReportContentType.values.firstWhere(
        (type) => type.name == (json['contentType'] ?? 'post'),
        orElse: () => ReportContentType.post,
      ),
      reportedBy: json['reportedBy'] ?? '',
      reportedByName: json['reportedByName'] ?? '',
      reportedByEmail: json['reportedByEmail'] ?? '',
      reason: json['reason'] ?? '',
      additionalDetails: json['additionalDetails'] ?? '',
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      status: json['status'] ?? 'pending',
      adminNotes: json['adminNotes'],
      reviewedAt: json['reviewedAt'] != null
          ? (json['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: json['reviewedBy'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'contentId': contentId,
      'contentOwnerId': contentOwnerId,
      'contentType': contentType.name,
      'reportedBy': reportedBy,
      'reportedByName': reportedByName,
      'reportedByEmail': reportedByEmail,
      'reason': reason,
      'additionalDetails': additionalDetails,
      'timestamp': FieldValue.serverTimestamp(),
      'status': status,
      'adminNotes': adminNotes,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
    };
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'reportId': reportId,
      'contentId': contentId,
      'contentOwnerId': contentOwnerId,
      'contentType': contentType.name,
      'reportedBy': reportedBy,
      'reportedByName': reportedByName,
      'reportedByEmail': reportedByEmail,
      'reason': reason,
      'additionalDetails': additionalDetails,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'adminNotes': adminNotes,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
    };
  }

  // Create copy with updated fields
  ReportModel copyWith({
    String? reportId,
    String? contentId,
    String? contentOwnerId,
    ReportContentType? contentType,
    String? reportedBy,
    String? reportedByName,
    String? reportedByEmail,
    String? reason,
    String? additionalDetails,
    DateTime? timestamp,
    String? status,
    String? adminNotes,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    return ReportModel(
      reportId: reportId ?? this.reportId,
      contentId: contentId ?? this.contentId,
      contentOwnerId: contentOwnerId ?? this.contentOwnerId,
      contentType: contentType ?? this.contentType,
      reportedBy: reportedBy ?? this.reportedBy,
      reportedByName: reportedByName ?? this.reportedByName,
      reportedByEmail: reportedByEmail ?? this.reportedByEmail,
      reason: reason ?? this.reason,
      additionalDetails: additionalDetails ?? this.additionalDetails,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      adminNotes: adminNotes ?? this.adminNotes,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }
}