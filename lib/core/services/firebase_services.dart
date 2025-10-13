import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../Model/EventModel.dart';
import '../../Model/localEvenModel.dart';
import '../../Model/restaurants_model.dart';
import '../../Model/userModel.dart';
import '../../Model/followModel.dart';
import '../../Model/connectionModel.dart';
import '../../Model/connectionNotificationModel.dart';
import '../../Provider/user_profile_provider.dart';
import '../const/firebase_Collection_Names.dart';

class FirebaseServices {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static FirebaseServices? _instance;
  static FirebaseServices get instance =>
      _instance ??= FirebaseServices._init();
  FirebaseServices._init();
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  //Events Getting Stream for database
  Stream<List<EventModel>> getEventsStream() {
    try {
      return eventsCollection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            print('✅ Events stream updated: ${snapshot.docs.length} events');
            return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
          });
    } catch (e) {
      print('❌ Error in events stream: $e');
      return Stream.error(e);
    }
  }

  //Getting current user from database
  Stream<UserModel?> getCurrentUserStream() {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user');
        return Stream.value(null);
      }
      return usersCollection.doc(currentUser.uid).snapshots().map((snapshot) {
        if (snapshot.exists) {
          print('✅ User data updated for: ${currentUser.uid}');
          final data = snapshot.data();
          return data != null ? UserModel.fromMap(data) : null;
        } else {
          print('❌ User document not found for: ${currentUser.uid}');
          return null;
        }
      });
    } catch (e) {
      print('❌ Error in user stream: $e');
      return Stream.error(e);
    }
  }

  Stream<int> getVisitedCountriesCountStream([String? userId]) {
    final String? uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(0);
    }
    return usersCollection
        .doc(uid)
        .collection('VisitedCountries')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<UserModel>> getAllUsersStream() {
    try {
      return usersCollection
          .where('role', isEqualTo: 'user')
          .where('isLocationSharingEnabled', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
        print('✅ Users stream updated: ${snapshot.docs.length} users');
        return snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .where((user) => user.uid != _auth.currentUser?.uid)
            .toList();
      });
    } catch (e) {
      print('❌ Error in users stream: $e');
      return Stream.error(e);
    }
  }

  static Future<bool> addTip({
    required String category,
    required String title,
    String? restaurantName,
    String? country,
    String? city,
    String? tipCity,
    String? address,
    required String tip,
    required bool countrymenOnly,
    double? latitude,
    double? longitude,
  }) async
  {
    try
    {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in');
        return false;
      }
      final Timestamp now = Timestamp.fromDate(DateTime.now());
      final Map<String, dynamic> tipData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'category': category,
        'title': title,
        'restaurantName': restaurantName,
        'country': country,
        'city': city,
        'tipCity': tipCity,
        'address': address,
        'tip': tip,
        'countrymenOnly': countrymenOnly,
        'createdBy': currentUser.uid,
        'createdAt': now,
        'likeCount': 0,
        'dislikeCount': 0,
        'userLikeMembers': [],
        'userDislikeMembers': [],
        'latitude': latitude,
        'longitude': longitude,

      };

      final DocumentReference userDocRef = usersTipsCollection
          .doc(currentUser.uid);

      final DocumentSnapshot userDoc = await userDocRef.get();

      if (userDoc.exists) {
        await userDocRef.update({
          'userTips': FieldValue.arrayUnion([tipData]),
        });
      } else {
        await userDocRef.set({
          'userTips': [tipData],
        });
      }

      print('✅ Tip added successfully');
      return true;
    } catch (e) {
      print('❌ Error adding tip: $e');
      return false;
    }
  }


  static Stream<List<Map<String, dynamic>>> getAllTipsStream() {
    try {
      return usersTipsCollection.snapshots().asyncMap((querySnapshot) async {
        List<Map<String, dynamic>> allTips = [];

        for (var doc in querySnapshot.docs) {
          if (doc.exists) {
            final data = doc.data();
            final List<dynamic> userTips = data['userTips'] ?? [];
            final String userId = doc.id;


            final userDetails = await getUserDetails(userId);

            for (var tip in userTips) {
              final tipWithUserInfo = Map<String, dynamic>.from(tip);
              tipWithUserInfo['userId'] = userId;

              // Add user details to tip
              if (userDetails != null) {
                tipWithUserInfo['userName'] = userDetails['fullName'] ?? 'Anonymous';
                tipWithUserInfo['userImage'] = userDetails['profileImageUrl'] ?? '';
                tipWithUserInfo['userHomeCity'] = userDetails['homeCity'] ?? '';
                tipWithUserInfo['userNationality'] = userDetails['nationality'] ?? '';
                tipWithUserInfo['userCountryFlag'] = getFlagByNationality(userDetails['nationality'] ?? '');
              } else {
                // Fallback values if user details not found
                tipWithUserInfo['userName'] = 'Anonymous';
                tipWithUserInfo['userImage'] = '';
                tipWithUserInfo['userHomeCity'] = '';
                tipWithUserInfo['userNationality'] = '';
                tipWithUserInfo['userCountryFlag'] = '🌍';
              }

              allTips.add(tipWithUserInfo);
            }
          }
        }

        // Sort by creation date (newest first)
        allTips.sort((a, b) {
          final aTime = a['createdAt'];
          final bTime = b['createdAt'];
          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }
          return 0;
        });

        return allTips;
      });
    } catch (e) {
      print('❌ Error getting tips stream: $e');
      return Stream.value([]);
    }
  }
  static Stream<List<RestaurantsModel>> getAllRestaurantsStream() {
    try {
      return FirebaseFirestore.instance
          .collection('restaurants')
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        print('✅ Restaurants stream updated: ${snapshot.docs.length} restaurants');
        return snapshot.docs
            .map((doc) => RestaurantsModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('❌ Error in restaurants stream: $e');
      return Stream.error(e);
    }
  }

  // Local Events stream for a city (sorted by createdAt ascending)
  static Stream<List<LocalEventModel>> getLocalEventsStream({
    required String cityName,
  }) {
    try {
      return FirebaseFirestore.instance
          .collection('localgroupchat')
          .doc(cityName)
          .collection('localEvent')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map<LocalEventModel>((doc) => LocalEventModel.fromDocument(doc))
              .toList());
    } catch (e) {
      return Stream.error(e);
    }
  }

  static Stream<List<Map<String, dynamic>>> getCurrentUserTipsStream() {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return Stream.value([]);
      }

      return usersTipsCollection.doc(currentUser.uid).snapshots().map((docSnapshot) {
        if (docSnapshot.exists && docSnapshot.data() != null) {
          final data = docSnapshot.data() as Map<String, dynamic>;
          final List<dynamic> userTips = data['userTips'] ?? [];

          return userTips.map((tip) => Map<String, dynamic>.from(tip)).toList();
        }
        return <Map<String, dynamic>>[];
      });
    } catch (e) {
      print('❌ Error getting user tips stream: $e');
      return Stream.value([]);
    }
  }

  static Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ Error getting user details: $e');
      return null;
    }
  }


  // Add these methods to your FirebaseServices class

// Like tip method
  static Future<bool> likeTip({
    required String tipOwnerId,
    required String tipId,
    required String currentUserId,
  }) async
  {
    try {
      final DocumentReference userDocRef = usersTipsCollection.doc(tipOwnerId);
      final DocumentSnapshot userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        print('❌ User document not found');
        return false;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      List<dynamic> userTips = userData['userTips'] ?? [];

      // Find the specific tip
      int tipIndex = userTips.indexWhere((tip) => tip['id'] == tipId);
      if (tipIndex == -1) {
        print('❌ Tip not found');
        return false;
      }

      Map<String, dynamic> tip = Map<String, dynamic>.from(userTips[tipIndex]);
      List<String> likeMembers = List<String>.from(tip['userLikeMembers'] ?? []);
      List<String> dislikeMembers = List<String>.from(tip['userDislikeMembers'] ?? []);

      // Remove from dislike if exists
      dislikeMembers.remove(currentUserId);

      // Toggle like
      if (likeMembers.contains(currentUserId)) {
        likeMembers.remove(currentUserId); // Unlike
        print('✅ Tip unliked by user: $currentUserId');
      } else {
        likeMembers.add(currentUserId); // Like
        print('✅ Tip liked by user: $currentUserId');
      }

      // Update counts and arrays
      tip['userLikeMembers'] = likeMembers;
      tip['userDislikeMembers'] = dislikeMembers;
      tip['likeCount'] = likeMembers.length;
      tip['dislikeCount'] = dislikeMembers.length;

      // Update the tip in the array
      userTips[tipIndex] = tip;

      // Update Firestore
      await userDocRef.update({'userTips': userTips});

      print('✅ Tip like status updated successfully');
      return true;
    } catch (e) {
      print('❌ Error liking tip: $e');
      return false;
    }
  }

// Dislike tip method
  static Future<bool> dislikeTip({
    required String tipOwnerId,
    required String tipId,
    required String currentUserId,
  }) async
  {
    try {
      final DocumentReference userDocRef = usersTipsCollection.doc(tipOwnerId);
      final DocumentSnapshot userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        print('❌ User document not found');
        return false;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      List<dynamic> userTips = userData['userTips'] ?? [];

      // Find the specific tip
      int tipIndex = userTips.indexWhere((tip) => tip['id'] == tipId);
      if (tipIndex == -1) {
        print('❌ Tip not found');
        return false;
      }

      Map<String, dynamic> tip = Map<String, dynamic>.from(userTips[tipIndex]);
      List<String> likeMembers = List<String>.from(tip['userLikeMembers'] ?? []);
      List<String> dislikeMembers = List<String>.from(tip['userDislikeMembers'] ?? []);

      // Remove from like if exists
      likeMembers.remove(currentUserId);

      // Toggle dislike
      if (dislikeMembers.contains(currentUserId)) {
        dislikeMembers.remove(currentUserId); // Un-dislike
        print('✅ Tip un-disliked by user: $currentUserId');
      } else {
        dislikeMembers.add(currentUserId); // Dislike
        print('✅ Tip disliked by user: $currentUserId');
      }

      // Update counts and arrays
      tip['userLikeMembers'] = likeMembers;
      tip['userDislikeMembers'] = dislikeMembers;
      tip['likeCount'] = likeMembers.length;
      tip['dislikeCount'] = dislikeMembers.length;

      // Update the tip in the array
      userTips[tipIndex] = tip;

      // Update Firestore
      await userDocRef.update({'userTips': userTips});

      print('✅ Tip dislike status updated successfully');
      return true;
    } catch (e) {
      print('❌ Error disliking tip: $e');
      return false;
    }
  }

  Future<bool> addUserToBlockList(String userIdToBlock) async {
    try {
      final currentUserId = getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('No user is currently logged in');
      }

      if (currentUserId == userIdToBlock) {
        throw Exception('Cannot block yourself');
      }

      // Reference to current user's document
      final userDocRef = usersCollection.doc(currentUserId);

      // Update the blocked_users array using arrayUnion to avoid duplicates
      await userDocRef.update({
        'blocked_users': FieldValue.arrayUnion([userIdToBlock])
      });

      print('Successfully added user $userIdToBlock to block list');
      return true;
    } catch (e) {
      print('Error adding user to block list: $e');
      return false;
    }
  }

  Future<bool> removeUserFromBlockList(String userIdToUnblock) async {
    try {
      final currentUserId = getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('No user is currently logged in');
      }

      if (currentUserId == userIdToUnblock) {
        throw Exception('Cannot unblock yourself');
      }

      // Reference to current user's document
      final userDocRef = usersCollection.doc(currentUserId);

      // Update the blocked_users array using arrayRemove to remove the user
      await userDocRef.update({
        'blocked_users': FieldValue.arrayRemove([userIdToUnblock])
      });

      print('Successfully removed user $userIdToUnblock from block list');
      return true;
    } catch (e) {
      print('Error removing user from block list: $e');
      return false;
    }
  }

  Future<bool> isUserBlocked(String userId) async {
    try {
      final currentUserId = getCurrentUserId();
      if (currentUserId == null) {
        return false;
      }

      final userDoc = await usersCollection.doc(currentUserId).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final blockedUsers = List<String>.from(userData['blocked_users'] ?? []);
        return blockedUsers.contains(userId);
      }

      return false;
    } catch (e) {
      print('Error checking if user is blocked: $e');
      return false;
    }
  }

  Stream<List<UserModel>> getBlockedUsersDetailsStream() {
    final currentUserId = getCurrentUserId();
    if (currentUserId == null) {
      return Stream.value([]);
    }
    return usersCollection.doc(currentUserId).snapshots().asyncMap((snapshot) async {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        final blockedUserIds = List<String>.from(data['blocked_users'] ?? []);

        if (blockedUserIds.isEmpty) return [];

        final query = await usersCollection
            .where(FieldPath.documentId, whereIn: blockedUserIds)
            .get();

        return query.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
      } else {
        return [];
      }
    });
  }

  // Follow functionality methods
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final doc = await usersCollection
          .doc(currentUserId)
          .collection('Following')
          .doc(targetUserId)
          .get();
      return doc.exists;
    } catch (e) {
      print('❌ Error checking following status: $e');
      return false;
    }
  }

  Future<void> addFollowing(String currentUserId, FollowModel followModel) async {
    try {
      await usersCollection
          .doc(currentUserId)
          .collection('Following')
          .doc(followModel.userId)
          .set(followModel.toMap());
      print('✅ Added to Following collection');
    } catch (e) {
      print('❌ Error adding following: $e');
      throw e;
    }
  }

  Future<void> addFollower(String targetUserId, FollowModel followerModel) async {
    try {
      await usersCollection
          .doc(targetUserId)
          .collection('Followers')
          .doc(followerModel.userId)
          .set(followerModel.toMap());
      print('✅ Added to Followers collection');
    } catch (e) {
      print('❌ Error adding follower: $e');
      throw e;
    }
  }

  Future<void> removeFollowing(String currentUserId, String targetUserId) async {
    try {
      await usersCollection
          .doc(currentUserId)
          .collection('Following')
          .doc(targetUserId)
          .delete();
      print('✅ Removed from Following collection');
    } catch (e) {
      print('❌ Error removing following: $e');
      throw e;
    }
  }

  Future<void> removeFollower(String targetUserId, String currentUserId) async {
    try {
      await usersCollection
          .doc(targetUserId)
          .collection('Followers')
          .doc(currentUserId)
          .delete();
      print('✅ Removed from Followers collection');
    } catch (e) {
      print('❌ Error removing follower: $e');
      throw e;
    }
  }

  Future<void> updateFollowingCount(String userId, int increment) async {
    try {
      final userDoc = await usersCollection.doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final socialStats = userData['socialStats'] as Map<String, dynamic>? ?? {};
        final currentCount = int.tryParse(socialStats['followingCount']?.toString() ?? '0') ?? 0;
        final newCount = (currentCount + increment).clamp(0, double.infinity).toInt();
        
        // Only update if the count actually changed
        if (newCount != currentCount) {
          await usersCollection.doc(userId).update({
            'socialStats.followingCount': newCount.toString(),
          });
          print('✅ Updated following count from $currentCount to: $newCount');
        }
      }
    } catch (e) {
      print('❌ Error updating following count: $e');
      throw e;
    }
  }

  Future<void> updateFollowersCount(String userId, int increment) async {
    try {
      final userDoc = await usersCollection.doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final socialStats = userData['socialStats'] as Map<String, dynamic>? ?? {};
        final currentCount = int.tryParse(socialStats['followersCount']?.toString() ?? '0') ?? 0;
        final newCount = (currentCount + increment).clamp(0, double.infinity).toInt();
        
        // Only update if the count actually changed
        if (newCount != currentCount) {
          await usersCollection.doc(userId).update({
            'socialStats.followersCount': newCount.toString(),
          });
          print('✅ Updated followers count from $currentCount to: $newCount');
        }
      }
    } catch (e) {
      print('❌ Error updating followers count: $e');
      throw e;
    }
  }

  // Connection functionality methods
  Future<ConnectionStatus> getConnectionStatus(String currentUserId, String targetUserId) async {
    try {
      // Check if there's a connection request from current user to target user
      final sentRequestDoc = await usersCollection
          .doc(currentUserId)
          .collection('SentConnectionRequests')
          .doc(targetUserId)
          .get();
      
      if (sentRequestDoc.exists) {
        final data = sentRequestDoc.data() as Map<String, dynamic>;
        final status = data['status'] as String;
        return ConnectionStatusExtension.fromString(status);
      }

      // Check if there's a connection request from target user to current user
      final receivedRequestDoc = await usersCollection
          .doc(currentUserId)
          .collection('ReceivedConnectionRequests')
          .doc(targetUserId)
          .get();

      if (receivedRequestDoc.exists) {
        final data = receivedRequestDoc.data() as Map<String, dynamic>;
        final status = data['status'] as String;
        return ConnectionStatusExtension.fromString(status);
      }

      return ConnectionStatus.none;
    } catch (e) {
      print('❌ Error checking connection status: $e');
      return ConnectionStatus.none;
    }
  }

  Future<void> sendConnectionRequest(String currentUserId, ConnectionModel connectionModel) async {
    try {
      // Check if request already exists to prevent duplicates
      final existingRequest = await usersCollection
          .doc(currentUserId)
          .collection('SentConnectionRequests')
          .doc(connectionModel.userId)
          .get();
          
      if (existingRequest.exists) {
        final data = existingRequest.data() as Map<String, dynamic>;
        if (data['status'] == 'pending') {
          print('⚠️ Connection request already exists');
          return;
        }
      }
      
      // Check if already connected
      final existingConnection = await usersCollection
          .doc(currentUserId)
          .collection('Connections')
          .doc(connectionModel.userId)
          .get();
          
      if (existingConnection.exists) {
        print('⚠️ Already connected to this user');
        return;
      }

      // Add to current user's SentConnectionRequests
      await usersCollection
          .doc(currentUserId)
          .collection('SentConnectionRequests')
          .doc(connectionModel.userId)
          .set(connectionModel.toJson());

      // Add to target user's ReceivedConnectionRequests
      await usersCollection
          .doc(connectionModel.userId)
          .collection('ReceivedConnectionRequests')
          .doc(currentUserId)
          .set(connectionModel.copyWith(userId: currentUserId).toJson());

      // Cloud function will automatically create notification when ReceivedConnectionRequests document is created
      
      print('✅ Connection request sent successfully');
    } catch (e) {
      print('❌ Error sending connection request: $e');
      throw e;
    }
  }

  Future<void> acceptConnectionRequest(String currentUserId, String requesterId) async {
    try {
      final acceptedAt = DateTime.now();
      
      // Update status in current user's ReceivedConnectionRequests
      await usersCollection
          .doc(currentUserId)
          .collection('ReceivedConnectionRequests')
          .doc(requesterId)
          .update({
            'status': 'accepted',
            'acceptedAt': Timestamp.fromDate(acceptedAt),
          });

      // Update status in requester's SentConnectionRequests
      await usersCollection
          .doc(requesterId)
          .collection('SentConnectionRequests')
          .doc(currentUserId)
          .update({
            'status': 'accepted',
            'acceptedAt': Timestamp.fromDate(acceptedAt),
          });

      // Find and update the pending connection request notification
      final notificationQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .where('type', isEqualTo: 'connection_request')
          .where('fromUserId', isEqualTo: requesterId)
          .where('status', isEqualTo: 'pending')
          .get();
          
      // Update notification status to accepted
      for (final notificationDoc in notificationQuery.docs) {
        await notificationDoc.reference.update({'status': 'accepted'});
      }

      // Add to both users' Connections collection
      final connectionData = {
        'userId': requesterId,
        'status': 'accepted',
        'requestedAt': Timestamp.fromDate(DateTime.now()),
        'acceptedAt': Timestamp.fromDate(acceptedAt),
      };

      await usersCollection
          .doc(currentUserId)
          .collection('Connections')
          .doc(requesterId)
          .set(connectionData);

      await usersCollection
          .doc(requesterId)
          .collection('Connections')
          .doc(currentUserId)
          .set({...connectionData, 'userId': currentUserId});

      // Update connection counts for both users
      await updateConnectionsCount(currentUserId, 1);
      await updateConnectionsCount(requesterId, 1);

      print('✅ Connection request accepted successfully');
    } catch (e) {
      print('❌ Error accepting connection request: $e');
      throw e;
    }
  }

  Future<void> removeConnection(String currentUserId, String targetUserId) async {
    try {
      // Check if connection exists first
      final connectionExists = await usersCollection
          .doc(currentUserId)
          .collection('Connections')
          .doc(targetUserId)
          .get();
          
      bool wasConnected = connectionExists.exists;

      // Remove from both users' Connections collection
      await usersCollection
          .doc(currentUserId)
          .collection('Connections')
          .doc(targetUserId)
          .delete();

      await usersCollection
          .doc(targetUserId)
          .collection('Connections')
          .doc(currentUserId)
          .delete();

      // Remove from request collections
      await usersCollection
          .doc(currentUserId)
          .collection('SentConnectionRequests')
          .doc(targetUserId)
          .delete();

      await usersCollection
          .doc(currentUserId)
          .collection('ReceivedConnectionRequests')
          .doc(targetUserId)
          .delete();

      await usersCollection
          .doc(targetUserId)
          .collection('SentConnectionRequests')
          .doc(currentUserId)
          .delete();

      await usersCollection
          .doc(targetUserId)
          .collection('ReceivedConnectionRequests')
          .doc(currentUserId)
          .delete();

      // Clean up related notifications
      await _cleanupConnectionNotifications(currentUserId, targetUserId);
      await _cleanupConnectionNotifications(targetUserId, currentUserId);

      // Update connection counts only if they were actually connected
      if (wasConnected) {
        await updateConnectionsCount(currentUserId, -1);
        await updateConnectionsCount(targetUserId, -1);
      }

      print('✅ Connection removed successfully');
    } catch (e) {
      print('❌ Error removing connection: $e');
      throw e;
    }
  }
  
  // Helper method to clean up connection-related notifications
  Future<void> _cleanupConnectionNotifications(String userId, String fromUserId) async {
    try {
      final notificationsQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('type', whereIn: ['connection_request', 'connection_accepted'])
          .where('fromUserId', isEqualTo: fromUserId)
          .get();
          
      for (final doc in notificationsQuery.docs) {
        await doc.reference.delete();
      }
      
      print('✅ Cleaned up notifications for user: $userId from: $fromUserId');
    } catch (e) {
      print('❌ Error cleaning up notifications: $e');
    }
  }

  /// Get all connected users for the current user
  Future<List<UserModel>> getConnectedUsers(String currentUserId) async {
    try {
      print('🔍 Getting connected users for: $currentUserId');
      
      // Get all connections from user's Connections subcollection
      final connectionsSnapshot = await usersCollection
          .doc(currentUserId)
          .collection('Connections')
          .where('status', isEqualTo: 'accepted')
          .get();
      
      if (connectionsSnapshot.docs.isEmpty) {
        print('📭 No connections found');
        return [];
      }
      
      // Get user IDs of all connected users
      final connectedUserIds = connectionsSnapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();
      
      print('👥 Found ${connectedUserIds.length} connected users');
      
      // Fetch user details for all connected users in batches (Firebase 'in' query limit is 10)
      List<UserModel> connectedUsers = [];
      
      for (int i = 0; i < connectedUserIds.length; i += 10) {
        final batch = connectedUserIds.sublist(
          i, 
          (i + 10).clamp(0, connectedUserIds.length)
        );
        
        final usersSnapshot = await usersCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        for (var doc in usersSnapshot.docs) {
          if (doc.exists) {
            final userData = doc.data() as Map<String, dynamic>;
            connectedUsers.add(UserModel.fromMap(userData));
          }
        }
      }
      
      print('✅ Successfully loaded ${connectedUsers.length} connected users');
      return connectedUsers;
    } catch (e) {
      print('❌ Error getting connected users: $e');
      return [];
    }
  }

  /// Get connected users stream for real-time updates
  Stream<List<UserModel>> getConnectedUsersStream(String currentUserId) {
    return usersCollection
        .doc(currentUserId)
        .collection('Connections')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        return <UserModel>[];
      }
      
      // Get user IDs of all connected users
      final connectedUserIds = snapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();
      
      // Fetch user details for all connected users in batches
      List<UserModel> connectedUsers = [];
      
      for (int i = 0; i < connectedUserIds.length; i += 10) {
        final batch = connectedUserIds.sublist(
          i, 
          (i + 10).clamp(0, connectedUserIds.length)
        );
        
        try {
          final usersSnapshot = await usersCollection
              .where(FieldPath.documentId, whereIn: batch)
              .get();
          
          for (var doc in usersSnapshot.docs) {
            if (doc.exists) {
              final userData = doc.data() as Map<String, dynamic>;
              connectedUsers.add(UserModel.fromMap(userData));
            }
          }
        } catch (e) {
          print('❌ Error fetching batch of connected users: $e');
        }
      }
      
      return connectedUsers;
    });
  }

  Future<void> updateConnectionsCount(String userId, int increment) async {
    try {
      final userDoc = await usersCollection.doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final socialStats = userData['socialStats'] as Map<String, dynamic>? ?? {};
        final currentCount = int.tryParse(socialStats['connectionsCount']?.toString() ?? '0') ?? 0;
        final newCount = (currentCount + increment).clamp(0, double.infinity).toInt();
        
        // Only update if the count actually changed
        if (newCount != currentCount) {
          await usersCollection.doc(userId).update({
            'socialStats.connectionsCount': newCount.toString(),
          });
          print('✅ Updated connections count from $currentCount to: $newCount');
        }
      }
    } catch (e) {
      print('❌ Error updating connections count: $e');
      throw e;
    }
  }

  // Get real-time connections count stream
  Stream<String> getConnectionsCountStream(String userId) {
    return usersCollection.doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        final userData = snapshot.data() as Map<String, dynamic>;
        final socialStats = userData['socialStats'] as Map<String, dynamic>? ?? {};
        return socialStats['connectionsCount']?.toString() ?? '0';
      }
      return '0';
    });
  }

  // Get real-time followers count stream
  Stream<String> getFollowersCountStream(String userId) {
    return usersCollection.doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        final userData = snapshot.data() as Map<String, dynamic>;
        final socialStats = userData['socialStats'] as Map<String, dynamic>? ?? {};
        return socialStats['followersCount']?.toString() ?? '0';
      }
      return '0';
    });
  }

  // Get real-time following count stream
  Stream<String> getFollowingCountStream(String userId) {
    return usersCollection.doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        final userData = snapshot.data() as Map<String, dynamic>;
        final socialStats = userData['socialStats'] as Map<String, dynamic>? ?? {};
        return socialStats['followingCount']?.toString() ?? '0';
      }
      return '0';
    });
  }

  // Get real-time posts count stream
  Stream<String> getPostsCountStream(String userId) {
    return usersCollection.doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        final userData = snapshot.data() as Map<String, dynamic>;
        final socialStats = userData['socialStats'] as Map<String, dynamic>? ?? {};
        return socialStats['postsCount']?.toString() ?? '0';
      }
      return '0';
    });
  }

  // Notification methods for connections
  Future<void> createConnectionNotification(ConnectionNotificationModel notification, String toUserId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(toUserId)
          .collection('notifications')
          .add(notification.toJson());
      
      print('✅ Connection notification created successfully');
    } catch (e) {
      print('❌ Error creating connection notification: $e');
      throw e;
    }
  }

  // Create follow notification
  Future<void> createFollowNotification(String fromUserId, String toUserId) async {
    try {
      // First check if the user has friendRequests enabled
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(toUserId)
          .get();
      
      final userData = userDoc.data();
      if (userData != null) {
        final appSettings = userData['appSettings'] as Map<String, dynamic>?;
        final friendRequestsEnabled = appSettings?['friendRequests'] ?? true;
        
        // Only create notification if friendRequests is enabled
        if (friendRequestsEnabled) {
          final notification = ConnectionNotificationModel.followNotification(
            fromUserId: fromUserId,
          );

          await FirebaseFirestore.instance
              .collection('users')
              .doc(toUserId)
              .collection('notifications')
              .add(notification.toJson());
          
          print('✅ Follow notification created successfully');
        } else {
          print('⚠️ Follow notification skipped - friendRequests disabled for user');
        }
      }
    } catch (e) {
      print('❌ Error creating follow notification: $e');
      throw e;
    }
  }

  // Create follow back notification
  Future<void> createFollowBackNotification(String fromUserId, String toUserId) async {
    try {
      // First check if the user has friendRequests enabled
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(toUserId)
          .get();
      
      final userData = userDoc.data();
      if (userData != null) {
        final appSettings = userData['appSettings'] as Map<String, dynamic>?;
        final friendRequestsEnabled = appSettings?['friendRequests'] ?? true;
        
        // Only create notification if friendRequests is enabled
        if (friendRequestsEnabled) {
          final notification = ConnectionNotificationModel.followBackNotification(
            fromUserId: fromUserId,
          );

          await FirebaseFirestore.instance
              .collection('users')
              .doc(toUserId)
              .collection('notifications')
              .add(notification.toJson());
          
          print('✅ Follow back notification created successfully');
        } else {
          print('⚠️ Follow back notification skipped - friendRequests disabled for user');
        }
      }
    } catch (e) {
      print('❌ Error creating follow back notification: $e');
      throw e;
    }
  }

  // Create like notification
  Future<void> createLikeNotification(String fromUserId, String toUserId, String postId, String? postImageUrl) async {
    try {
      // Don't create notification if user likes their own post
      if (fromUserId == toUserId) {
        print('User liked their own post, skipping notification');
        return;
      }

      final notification = ConnectionNotificationModel.likeNotification(
        fromUserId: fromUserId,
        postId: postId,
        postImageUrl: postImageUrl,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(toUserId)
          .collection('notifications')
          .add(notification.toJson());
      
      print('✅ Like notification created successfully');
    } catch (e) {
      print('❌ Error creating like notification: $e');
      throw e;
    }
  }

  // Create comment notification
  Future<void> createCommentNotification(String fromUserId, String toUserId, String postId, String? postImageUrl, String? commentText) async {
    try {
      // Don't create notification if user comments on their own post
      if (fromUserId == toUserId) {
        print('User commented on their own post, skipping notification');
        return;
      }

      final notification = ConnectionNotificationModel.commentNotification(
        fromUserId: fromUserId,
        postId: postId,
        postImageUrl: postImageUrl,
        commentText: commentText,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(toUserId)
          .collection('notifications')
          .add(notification.toJson());
      
      print('✅ Comment notification created successfully');
    } catch (e) {
      print('❌ Error creating comment notification: $e');
      throw e;
    }
  }

  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      
      print('✅ Notification marked as read');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      throw e;
    }
  }

  Stream<List<ConnectionNotificationModel>> getConnectionNotificationsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('type', whereIn: ['connection_request', 'connection_accepted', 'follow', 'follow_back', 'like', 'comment'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ConnectionNotificationModel.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Future<void> updateNotificationStatus(String userId, String notificationId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'status': status});
      
      print('✅ Notification status updated to: $status');
    } catch (e) {
      print('❌ Error updating notification status: $e');
      throw e;
    }
  }

  // Create event notification for specific user
  Future<void> createEventNotificationForUser(String userId, Map<String, dynamic> notificationData) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add(notificationData);
      
      print('✅ Event notification created for user: $userId');
    } catch (e) {
      print('❌ Error creating event notification: $e');
      throw e;
    }
  }

  // Create event notification for all users
  Future<void> createEventNotificationForAllUsers(Map<String, dynamic> notificationData) async {
    try {
      // Get all users
      final usersSnapshot = await usersCollection.where('role', isEqualTo: 'user').get();
      
      final batch = FirebaseFirestore.instance.batch();
      
      for (final userDoc in usersSnapshot.docs) {
        final notificationRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .doc();
        
        batch.set(notificationRef, notificationData);
      }
      
      await batch.commit();
      print('✅ Event notification created for all users');
    } catch (e) {
      print('❌ Error creating event notification for all users: $e');
      throw e;
    }
  }

  // Get user info for notifications
  Future<Map<String, String>> getUserInfoForNotification(String userId) async {
    try {
      final userDoc = await usersCollection.doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return {
          'name': userData['fullName'] ?? 'Unknown User',
          'image': userData['profileImageUrl'] ?? '',
        };
      }
      return {'name': 'Unknown User', 'image': ''};
    } catch (e) {
      print('❌ Error getting user info for notification: $e');
      return {'name': 'Unknown User', 'image': ''};
    }
  }

}






//this is code for deleting user account
class UserAccountService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  Future<void> _deleteSubcollection(String path) async {
    final collectionRef = _firestore.collection(path);
    final snapshots = await collectionRef.get();

    // Delete all documents in batches
    for (final doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  Future<bool> deleteUserAccount( ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }

      final userId = currentUser.uid;
      await _deleteSubcollection('users/$userId/VisitedCountries');
      await _firestore.collection('users').doc(userId).delete();


      try {
        await _storage.ref().child('profile_images/$userId').delete();
      } catch (e) {

        print('No profile image to delete or error deleting: $e');
      }

      await _deleteUserRelatedData(userId);
      await currentUser.delete();
      print('User account successfully deleted');

      return true;
    } catch (e) {
      print('Error deleting user account: $e');
      return false;
    }
  }

  Future<void> _deleteUserRelatedData(String userId) async {
    try {
      final batch = _firestore.batch();

      // 1. Delete tips where document ID == userId
      final userTipDoc = await _firestore.collection('tips').doc(userId).get();
      if (userTipDoc.exists) {
        batch.delete(userTipDoc.reference);
      }

      // 2. Remove user from userLikeMembers and userDislikeMembers in all tips
      final tipsQuery = await _firestore.collection('tips').get();
      for (var doc in tipsQuery.docs) {
        final data = doc.data();
        final likeList = List<String>.from(data['userLikeMembers'] ?? []);
        final dislikeList = List<String>.from(data['userDislikeMembers'] ?? []);
        final updates = <String, dynamic>{};

        if (likeList.contains(userId)) {
          updates['userLikeMembers'] = FieldValue.arrayRemove([userId]);
        }
        if (dislikeList.contains(userId)) {
          updates['userDislikeMembers'] = FieldValue.arrayRemove([userId]);
        }

        if (updates.isNotEmpty) {
          batch.update(doc.reference, updates);
        }
      }

      // 3. Remove current user ID from other users' blockedUsers array
      final usersQuery = await _firestore.collection('users').get();
      for (var doc in usersQuery.docs) {
        final data = doc.data();
        final blockedUsers = List<String>.from(data['blocked_users'] ?? []);
        if (blockedUsers.contains(userId)) {
          batch.update(doc.reference, {
            'blocked_users': FieldValue.arrayRemove([userId])
          });
        }
      }

      // 4. Remove user from participantsList in groupChatRooms
      // final groupChats = await _firestore.collection('groupChatRooms').get();
      // for (var doc in groupChats.docs) {
      //   final participants = List<String>.from(doc.data()['participantsList'] ?? []);
      //   if (participants.contains(userId)) {
      //     batch.update(doc.reference, {
      //       'participantsList': FieldValue.arrayRemove([userId])
      //     });
      //   }
      // }

      // 5. Remove user from participantsList in chatrooms
      final chatRooms = await _firestore.collection('chatrooms').get();
      for (var doc in chatRooms.docs) {
        final participants = List<String>.from(doc.data()['participantsList'] ?? []);
        if (participants.contains(userId)) {
          batch.update(doc.reference, {
            'participantsList': FieldValue.arrayRemove([userId])
          });
        }
      }

      // 6. Remove user from participantsList in localgroupchat
      final localGroups = await _firestore.collection('localgroupchat').get();
      for (var doc in localGroups.docs) {
        final participants = List<String>.from(doc.data()['participantsList'] ?? []);
        if (participants.contains(userId)) {
          batch.update(doc.reference, {
            'participantsList': FieldValue.arrayRemove([userId])
          });
        }
      }

      // Commit batch delete/update
      await batch.commit();

      print('User-related data cleanup completed for userId: $userId');
    } catch (e) {
      print('Error deleting user related data: $e');
    }
  }

}

