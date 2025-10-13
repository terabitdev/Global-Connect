import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Model/notification_Model.dart';
import '../Model/connectionNotificationModel.dart';
import '../Model/followModel.dart';
import '../Model/userModel.dart';
import '../core/services/firebase_services.dart';


class NotificationScreenProvider extends ChangeNotifier {
  bool isNotificationOn = true;
  bool _isAccepting = false;
  final Map<String, bool> _followStatusByUserId = {};
  final Set<String> _loadingFollowStatusUserIds = {};
  
  // Cache for notification-specific data to avoid unnecessary rebuilds
  final Map<String, Map<String, String>> _userInfoCache = {};
  
  // Track if we're in the middle of an operation to prevent shimmer
  bool _isPerformingOperation = false;

  bool get isAccepting => _isAccepting;
  bool get isPerformingOperation => _isPerformingOperation;

  // Expose cached follow status
  bool? getFollowStatus(String userId) => _followStatusByUserId[userId];
  bool isFollowStatusLoading(String userId) => _loadingFollowStatusUserIds.contains(userId);

  // Ensure follow status is loaded without causing UI flicker
  Future<void> ensureFollowStatusLoaded(String targetUserId) async {
    try {
      if (_followStatusByUserId.containsKey(targetUserId) || _loadingFollowStatusUserIds.contains(targetUserId)) {
        return;
      }
      _loadingFollowStatusUserIds.add(targetUserId);
      
      // Use post frame callback to avoid calling notifyListeners during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _followStatusByUserId[targetUserId] = false;
      } else {
        final following = await FirebaseServices.instance.isFollowing(currentUser.uid, targetUserId);
        _followStatusByUserId[targetUserId] = following;
      }
    } catch (e) {
      print('❌ Error loading follow status: $e');
    } finally {
      _loadingFollowStatusUserIds.remove(targetUserId);
      // Use post frame callback to avoid calling notifyListeners during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Stream<List<NotificationModel>> getNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('type', whereNotIn: [
          'connection_request', 
          'connection_accepted', 
          'follow', 
          'follow_back', 
          'like', 
          'comment'
        ]) // Exclude all social activity notifications - only show system/admin/event notifications
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        // Only include notifications that are specifically for events/admin/system messages
        final type = data['type'] as String?;
        return type != null && (
          type == 'event' ||
          type == 'system' ||
          type == 'admin' ||
          type == 'announcement'
        );
      }).map((doc) {
        return NotificationModel.fromMap(doc.data());
      }).toList();
    });
  }

  // Get connection notifications for current user
  Stream<List<ConnectionNotificationModel>> getConnectionNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseServices.instance.getConnectionNotificationsStream(user.uid);
  }

  // Accept connection request
  Future<void> acceptConnectionRequest(ConnectionNotificationModel notification) async {
    try {
      _isAccepting = true;
      _isPerformingOperation = true;
      
      // Use post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      await FirebaseServices.instance.acceptConnectionRequest(
        currentUser.uid,
        notification.fromUserId,
      );

      // Update notification status to accepted
      await FirebaseServices.instance.updateNotificationStatus(
        currentUser.uid,
        notification.id,
        'accepted',
      );

      print('✅ Connection request accepted successfully');
    } catch (e) {
      print('❌ Error accepting connection request: $e');
      throw e;
    } finally {
      _isAccepting = false;
      _isPerformingOperation = false;
      
      // Use post frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  // Decline connection request
  Future<void> declineConnectionRequest(ConnectionNotificationModel notification) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Update notification status to declined
      await FirebaseServices.instance.updateNotificationStatus(
        currentUser.uid,
        notification.id,
        'declined',
      );

      // Remove from received requests
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('ReceivedConnectionRequests')
          .doc(notification.fromUserId)
          .delete();

      // Remove from sent requests
      await FirebaseFirestore.instance
          .collection('users')
          .doc(notification.fromUserId)
          .collection('SentConnectionRequests')
          .doc(currentUser.uid)
          .delete();

      print('✅ Connection request declined successfully');
    } catch (e) {
      print('❌ Error declining connection request: $e');
      throw e;
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseServices.instance.markNotificationAsRead(user.uid, notificationId);
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Follow back a user
  Future<void> followBackUser(String targetUserId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Optimistically update cache first for immediate UI feedback
      _isPerformingOperation = true;
      _followStatusByUserId[targetUserId] = true;
      notifyListeners();

      // Check if already following
      final isFollowing = await FirebaseServices.instance.isFollowing(currentUser.uid, targetUserId);
      if (isFollowing) {
        print('Already following this user');
        return;
      }

      // Create follow models
      final followModel = FollowModel(
        userId: targetUserId,
        followedAt: DateTime.now(),
      );

      final followerModel = FollowModel(
        userId: currentUser.uid,
        followedAt: DateTime.now(),
      );

      // Add to current user's Following subcollection
      await FirebaseServices.instance.addFollowing(currentUser.uid, followModel);

      // Add to target user's Followers subcollection
      await FirebaseServices.instance.addFollower(targetUserId, followerModel);

      // Update counts
      await FirebaseServices.instance.updateFollowingCount(currentUser.uid, 1);
      await FirebaseServices.instance.updateFollowersCount(targetUserId, 1);

      // Create follow back notification for the original follower
      await FirebaseServices.instance.createFollowBackNotification(currentUser.uid, targetUserId);

      // Remove the original follow notification from current user's notifications
      await _removeOriginalFollowNotification(currentUser.uid, targetUserId);

      print('✅ Followed back successfully');
    } catch (e) {
      print('❌ Error following back user: $e');
      // Revert optimistic update on error
      _followStatusByUserId[targetUserId] = false;
      notifyListeners();
      throw e;
    } finally {
      _isPerformingOperation = false;
      notifyListeners();
    }
  }

  // Remove original follow notification when user follows back
  Future<void> _removeOriginalFollowNotification(String currentUserId, String targetUserId) async {
    try {
      // Find and delete the original follow notification
      final notificationsQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .where('type', isEqualTo: 'follow')
          .where('fromUserId', isEqualTo: targetUserId)
          .get();

      for (final doc in notificationsQuery.docs) {
        await doc.reference.delete();
      }

      print('✅ Removed original follow notification');
    } catch (e) {
      print('❌ Error removing original follow notification: $e');
    }
  }

  // Check following status for a user
  Future<bool> isFollowingUser(String targetUserId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;
      return await FirebaseServices.instance.isFollowing(currentUser.uid, targetUserId);
    } catch (e) {
      print('❌ Error checking follow status: $e');
      return false;
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(String targetUserId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Optimistically update cache first for immediate UI feedback
      _isPerformingOperation = true;
      _followStatusByUserId[targetUserId] = false;
      notifyListeners();

      // Remove from current user's Following
      await FirebaseServices.instance.removeFollowing(currentUser.uid, targetUserId);

      // Remove from target user's Followers
      await FirebaseServices.instance.removeFollower(targetUserId, currentUser.uid);

      // Update counts
      await FirebaseServices.instance.updateFollowingCount(currentUser.uid, -1);
      await FirebaseServices.instance.updateFollowersCount(targetUserId, -1);

      print('✅ Unfollowed user successfully');
    } catch (e) {
      print('❌ Error unfollowing user: $e');
      // Revert optimistic update on error
      _followStatusByUserId[targetUserId] = true;
      notifyListeners();
      throw e;
    } finally {
      _isPerformingOperation = false;
      notifyListeners();
    }
  }

  // Get cached user info for notifications
  Map<String, String>? getCachedUserInfo(String userId) {
    return _userInfoCache[userId];
  }

  // Cache user info to avoid repeated API calls
  void cacheUserInfo(String userId, Map<String, String> userInfo) {
    _userInfoCache[userId] = userInfo;
  }

  // Get user data for profile navigation
  Future<UserModel?> getUserData(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        // Add the uid to the data map since fromMap expects it to be in the data
        userData['uid'] = userDoc.id;
        return UserModel.fromMap(userData);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user data: $e');
      throw e;
    }
  }

  // Clear caches when needed
  void clearCaches() {
    _userInfoCache.clear();
    _followStatusByUserId.clear();
    _loadingFollowStatusUserIds.clear();
  }
}
