import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class SocialStats {
  final String postsCount;
  final String followersCount;
  final String followingCount;
  final String connectionsCount;

  const SocialStats({
    this.postsCount = '0',
    this.followersCount = '0',
    this.followingCount = '0',
    this.connectionsCount = '0',
  });

  factory SocialStats.fromMap(Map<String, dynamic> data) {
    return SocialStats(
      postsCount: data['postsCount']?.toString() ?? '0',
      followersCount: data['followersCount']?.toString() ?? '0',
      followingCount: data['followingCount']?.toString() ?? '0',
      connectionsCount: data['connectionsCount']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postsCount': postsCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'connectionsCount': connectionsCount,
    };
  }

  SocialStats copyWith({
    String? postsCount,
    String? followersCount,
    String? followingCount,
    String? connectionsCount,
  }) {
    return SocialStats(
      postsCount: postsCount ?? this.postsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      connectionsCount: connectionsCount ?? this.connectionsCount,
    );
  }
}

class AppSettings {
  final bool privateAccount;
  final bool publicProfile;
  final bool showTravelMap;
  final bool showTravelStats;
  final bool activityStatus;
  final bool autoDetectCities;
  final bool travelNotification;
  final bool locationSharing;
  final bool friendRequests;
  final bool newTipsAndEvents;

  const AppSettings({
    this.privateAccount = true,
    this.publicProfile = true,
    this.showTravelMap = true,
    this.showTravelStats = true,
    this.activityStatus = true,
    this.autoDetectCities = true,
    this.travelNotification = true,
    this.locationSharing = true,
    this.friendRequests = true,
    this.newTipsAndEvents = true,
  });

  factory AppSettings.fromMap(Map<String, dynamic> data) {
    return AppSettings(
      privateAccount: data['privateAccount'] ?? true,
      publicProfile: data['publicProfile'] ?? true,
      showTravelMap: data['showTravelMap'] ?? true,
      showTravelStats: data['showTravelStats'] ?? true,
      activityStatus: data['activityStatus'] ?? true,
      autoDetectCities: data['autoDetectCities'] ?? true,
      travelNotification: data['travelNotification'] ?? true,
      locationSharing: data['locationSharing'] ?? true,
      friendRequests: data['friendRequests'] ?? true,
      newTipsAndEvents: data['newTipsAndEvents'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'privateAccount': privateAccount,
      'publicProfile': publicProfile,
      'showTravelMap': showTravelMap,
      'showTravelStats': showTravelStats,
      'activityStatus': activityStatus,
      'autoDetectCities': autoDetectCities,
      'travelNotification': travelNotification,
      'locationSharing': locationSharing,
      'friendRequests': friendRequests,
      'newTipsAndEvents': newTipsAndEvents,
    };
  }

  AppSettings copyWith({
    bool? privateAccount,
    bool? publicProfile,
    bool? showTravelMap,
    bool? showTravelStats,
    bool? activityStatus,
    bool? autoDetectCities,
    bool? travelNotification,
    bool? locationSharing,
    bool? friendRequests,
    bool? newTipsAndEvents,
  }) {
    return AppSettings(
      privateAccount: privateAccount ?? this.privateAccount,
      publicProfile: publicProfile ?? this.publicProfile,
      showTravelMap: showTravelMap ?? this.showTravelMap,
      showTravelStats: showTravelStats ?? this.showTravelStats,
      activityStatus: activityStatus ?? this.activityStatus,
      autoDetectCities: autoDetectCities ?? this.autoDetectCities,
      travelNotification: travelNotification ?? this.travelNotification,
      locationSharing: locationSharing ?? this.locationSharing,
      friendRequests: friendRequests ?? this.friendRequests,
      newTipsAndEvents: newTipsAndEvents ?? this.newTipsAndEvents,
    );
  }
}

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final DateTime? dateOfBirth;
  final String nationality;
  final String homeCity;
  final DateTime createdAt;
  final String role;
  final double? latitude;
  final double? longitude;
  final String? currentAddress;
  final DateTime? lastLocationUpdate;
  final bool isLocationSharingEnabled;
  final bool pauseMyVisibility;
  final bool isPushNotificationEnabled;
  final double visibilityRadius;
  final String? profileImageUrl;
  final String? bio;
  final String? currentCity;
  final String? currentCountry;
  final List<String> blockedUsers;
  final SocialStats socialStats;
  final AppSettings appSettings;
  final String feed;
  final String status;
  final DateTime? lastSeen;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.dateOfBirth,
    required this.nationality,
    required this.homeCity,
    required this.createdAt,
    this.role = 'user',
    this.latitude,
    this.currentCity,
    this.currentCountry,
    this.longitude,
    this.currentAddress,
    this.lastLocationUpdate,
    this.isLocationSharingEnabled = false,
    this.pauseMyVisibility = false,
    this.isPushNotificationEnabled = true,
    this.visibilityRadius = 5.0,
    this.profileImageUrl,
    this.bio,
    this.blockedUsers = const [],
    this.socialStats = const SocialStats(),
    this.appSettings = const AppSettings(),
    this.feed = 'Global',
    this.status = 'offline',
    this.lastSeen,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? 'Unknown',
      dateOfBirth: _parseDate(data['dateOfBirth']),
      nationality: data['nationality'] ?? '',
      homeCity: data['homeCity'] ?? '',
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      role: data['role'] ?? 'user',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      currentAddress: data['currentAddress'],
      lastLocationUpdate: _parseDate(data['lastLocationUpdate']),
      isLocationSharingEnabled: data['isLocationSharingEnabled'] ?? false,
      pauseMyVisibility: data['pauseMyVisibility'] ?? false,
      isPushNotificationEnabled: data['isPushNotificationEnabled'] ?? true,
      visibilityRadius: data['visibilityRadius']?.toDouble() ?? 5.0,
      profileImageUrl: data['profileImageUrl'],
      bio: data['bio'],
      currentCity: data['currentCity'],
      currentCountry: data['currentCountry'],
      blockedUsers: data['blocked_users'] != null
          ? List<String>.from(data['blocked_users'])
          : [],
      socialStats: data['socialStats'] != null
          ? SocialStats.fromMap(data['socialStats'])
          : const SocialStats(),
      appSettings: data['appSettings'] != null
          ? AppSettings.fromMap(data['appSettings'])
          : const AppSettings(),
      feed: data['feed'] ?? 'Global',
      status: data['status'] ?? 'offline',
      lastSeen: _parseDate(data['lastSeen']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth != null
          ? _formatDateOfBirth(dateOfBirth!)
          : null,
      'nationality': nationality,
      'homeCity': homeCity,
      'createdAt': _formatCreatedAt(createdAt),
      'role': role,
      'latitude': latitude,
      'longitude': longitude,
      'currentAddress': currentAddress,
      'lastLocationUpdate': lastLocationUpdate != null
          ? _formatCreatedAt(lastLocationUpdate!)
          : null,
      'isLocationSharingEnabled': isLocationSharingEnabled,
      'pauseMyVisibility': pauseMyVisibility,
      'isPushNotificationEnabled': isPushNotificationEnabled,
      'visibilityRadius': visibilityRadius,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'currentCity': currentCity,
      'currentCountry': currentCountry,
      'blocked_users': blockedUsers,
      'socialStats': socialStats.toMap(),
      'appSettings': appSettings.toMap(),
      'feed': feed,
      'status': status,
      'lastSeen': lastSeen != null ? _formatCreatedAt(lastSeen!) : null,
    };
  }

  // ✅ Helper to parse Timestamp or String into DateTime
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        // Try ISO8601 first
        return DateTime.parse(value);
      } catch (_) {
        try {
          // Fallback to your custom format (e.g., July 14, 2025 at 10:25:41 AM UTC+5)
          final fallbackFormat = DateFormat(
            "MMMM d, yyyy 'at' h:mm:ss a 'UTC+5'",
          );
          return fallbackFormat.parse(value);
        } catch (e) {
          print('❌ Failed to parse date string: $value');
          return null;
        }
      }
    } else {
      return null;
    }
  }

  // ✅ Format DateTime to yyyy-MM-dd for dateOfBirth
  String _formatDateOfBirth(DateTime dateTime) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    return formatter.format(dateTime);
  }

  // ✅ Format DateTime to readable string for createdAt/lastLocationUpdate
  String _formatCreatedAt(DateTime dateTime) {
    final DateFormat formatter = DateFormat(
      'MMMM d, yyyy \'at\' h:mm:ss a \'UTC+5\'',
    );
    return formatter.format(dateTime);
  }

  // ✅ Calculate age
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  // ✅ Get DOB formatted
  String get formattedDateOfBirth {
    if (dateOfBirth == null) return 'Not provided';
    return '${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}';
  }

  // ✅ Location helpers
  bool get hasLocation => latitude != null && longitude != null;

  String get locationCoordinates {
    if (!hasLocation) return 'Location not available';
    return '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';
  }

  String get formattedLastLocationUpdate {
    if (lastLocationUpdate == null) return 'Never updated';
    final now = DateTime.now();
    final difference = now.difference(lastLocationUpdate!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  // ✅ Push notification helper
  String get pushNotificationStatus {
    return isPushNotificationEnabled ? 'Enabled' : 'Disabled';
  }

  // ✅ Online status helper
  bool get isOnline => status == 'online';

  String get formattedLastSeen {
    if (status == 'online') return 'Online';
    if (lastSeen == null) return 'Offline';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen!);

    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays}d ago';
    } else {
      return 'Last seen ${(difference.inDays / 7).floor()}w ago';
    }
  }

  // ✅ Update location
  UserModel updateLocation({
    required double latitude,
    required double longitude,
    String? address,
  }) {
    return copyWith(
      latitude: latitude,
      longitude: longitude,
      currentAddress: address,
      lastLocationUpdate: DateTime.now(),
    );
  }

  // ✅ Toggle push notifications
  UserModel togglePushNotifications() {
    return copyWith(isPushNotificationEnabled: !isPushNotificationEnabled);
  }

  // ✅ Update online status
  UserModel setOnlineStatus() {
    return copyWith(status: 'online', lastSeen: DateTime.now());
  }

  UserModel setOfflineStatus() {
    return copyWith(status: 'offline', lastSeen: DateTime.now());
  }

  // ✅ Update app settings
  UserModel updateAppSettings(AppSettings newSettings) {
    return copyWith(appSettings: newSettings);
  }

  // ✅ Toggle specific app setting
  UserModel toggleAppSetting(String settingName) {
    AppSettings newSettings = appSettings;
    
    switch (settingName) {
      case 'privateAccount':
        newSettings = appSettings.copyWith(privateAccount: !appSettings.privateAccount);
        break;
      case 'publicProfile':
        newSettings = appSettings.copyWith(publicProfile: !appSettings.publicProfile);
        break;
      case 'showTravelMap':
        newSettings = appSettings.copyWith(showTravelMap: !appSettings.showTravelMap);
        break;
      case 'showTravelStats':
        newSettings = appSettings.copyWith(showTravelStats: !appSettings.showTravelStats);
        break;
      case 'activityStatus':
        newSettings = appSettings.copyWith(activityStatus: !appSettings.activityStatus);
        break;
      case 'autoDetectCities':
        newSettings = appSettings.copyWith(autoDetectCities: !appSettings.autoDetectCities);
        break;
      case 'travelNotification':
        newSettings = appSettings.copyWith(travelNotification: !appSettings.travelNotification);
        break;
      case 'locationSharing':
        newSettings = appSettings.copyWith(locationSharing: !appSettings.locationSharing);
        break;
      case 'friendRequests':
        newSettings = appSettings.copyWith(friendRequests: !appSettings.friendRequests);
        break;
      case 'newTipsAndEvents':
        newSettings = appSettings.copyWith(newTipsAndEvents: !appSettings.newTipsAndEvents);
        break;
    }
    
    return copyWith(appSettings: newSettings);
  }

  // ✅ CopyWith
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    DateTime? dateOfBirth,
    String? nationality,
    String? homeCity,
    DateTime? createdAt,
    String? role,
    double? latitude,
    double? longitude,
    String? currentAddress,
    DateTime? lastLocationUpdate,
    bool? isLocationSharingEnabled,
    bool? pauseMyVisibility,
    bool? isPushNotificationEnabled,
    double? visibilityRadius,
    String? profileImageUrl,
    String? bio,
    String? currentCity,
    String? currentCountry,
    List<String>? blockedUsers,
    SocialStats? socialStats,
    AppSettings? appSettings,
    String? feed,
    String? status,
    DateTime? lastSeen,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationality: nationality ?? this.nationality,
      homeCity: homeCity ?? this.homeCity,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      currentAddress: currentAddress ?? this.currentAddress,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      isLocationSharingEnabled:
          isLocationSharingEnabled ?? this.isLocationSharingEnabled,
      pauseMyVisibility: pauseMyVisibility ?? this.pauseMyVisibility,
      isPushNotificationEnabled:
          isPushNotificationEnabled ??
          this.isPushNotificationEnabled,
      visibilityRadius: visibilityRadius ?? this.visibilityRadius,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      currentCity: currentCity ?? this.currentCity,
      currentCountry: currentCountry ?? this.currentCountry,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      socialStats: socialStats ?? this.socialStats,
      appSettings: appSettings ?? this.appSettings,
      feed: feed ?? this.feed,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
