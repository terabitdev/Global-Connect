import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';




import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';




class GroupChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static CollectionReference get groupChatRoomsCollection =>
      _firestore.collection('groupChatRooms');

  static CollectionReference get usersCollection =>
      _firestore.collection('users');

  // Get user details by ID
  static Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      if (userId == 'system') {
        return {
          'fullName': 'System',
          'profileImage': '',
        };
      }

      DocumentSnapshot userDoc = await usersCollection.doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>?;
      }
      return {
        'fullName': 'Unknown User',
        'profileImage': '',
      };
    } catch (e) {
      print('❌ Error getting user details: $e');
      return {
        'fullName': 'Unknown User',
        'profileImage': '',
      };
    }
  }

  static Future<String?> uploadGroupImage(File imageFile) async {
    try {
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference storageRef = _storage
          .ref()
          .child('groupImages')
          .child('$fileName.jpg');

      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Group image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading group image: $e');
      return null;
    }
  }

  // Create Group Chat Room
  static Future<String?> createGroupChatRoom({
    required String groupName,
    required String groupDescription,
    required String groupType,
    required List<String> participantsList,
    File? groupImage,
  }) async {
    try {
      final String currentUserId = _auth.currentUser?.uid ?? '';
      if (currentUserId.isEmpty) {
        throw Exception('User not authenticated');
      }

      // Upload group image if provided
      String? groupImageUrl;
      if (groupImage != null) {
        groupImageUrl = await uploadGroupImage(groupImage);
      }

      // Generate group chat room ID
      final String groupChatRoomId = groupChatRoomsCollection.doc().id;

      // Add current user to participants list if not already included
      final List<String> allParticipants = [...participantsList];
      if (!allParticipants.contains(currentUserId)) {
        allParticipants.add(currentUserId);
      }

      // Create group chat room document
      final Map<String, dynamic> groupChatRoomData = {
        'id': groupChatRoomId,
        'groupName': groupName,
        'groupDescription': groupDescription,
        'groupType': groupType,
        'groupImageUrl': groupImageUrl ?? '',
        'participantsList': allParticipants,
        'lastMessage': '',
        'sentOn': Timestamp.now(),
        'createdBy': currentUserId,
        'createdAt': Timestamp.now(),
        'isActive': true,
      };

      await groupChatRoomsCollection
          .doc(groupChatRoomId)
          .set(groupChatRoomData);

      print('✅ Group chat room created successfully: $groupChatRoomId');
      return groupChatRoomId;
    } catch (e) {
      print('❌ Error creating group chat room: $e');
      return null;
    }
  }

  // Send message to group
  static Future<bool> sendGroupMessage({
    required String groupChatRoomId,
    required String message,
    required String senderId,
    String messageType = 'text',
    String? customLastMessage,
  }) async {
    try {
      final String messageId = Timestamp.now().millisecondsSinceEpoch.toString();

      await groupChatRoomsCollection
          .doc(groupChatRoomId)
          .collection('messages')
          .doc(messageId)
          .set({
        'id': messageId,
        'message': message,
        'senderId': senderId,
        'sentOn': Timestamp.now(),
        'messageType': messageType,
        'isRead': false,
      });

      // Update last message in group chat room
      await groupChatRoomsCollection.doc(groupChatRoomId).update({
        'lastMessage': customLastMessage ?? message,
        'sentOn': Timestamp.now(),
      });

      print('✅ Message sent to group successfully');
      return true;
    } catch (e) {
      print('❌ Error sending group message: $e');
      return false;
    }
  }

  // Add system message to group
  static Future<void> addSystemMessage({
    required String groupChatRoomId,
    required String message,
    bool updateLastMessage = true,
    String? customLastMessage,
  }) async {
    try {
      final String messageId = Timestamp.now().millisecondsSinceEpoch.toString();

      await groupChatRoomsCollection
          .doc(groupChatRoomId)
          .collection('messages')
          .doc(messageId)
          .set({
        'id': messageId,
        'message': message,
        'senderId': 'system',
        'sentOn': Timestamp.now(),
        'messageType': 'system',
        'isRead': false,
      });

      if (updateLastMessage) {
        await groupChatRoomsCollection.doc(groupChatRoomId).update({
          'lastMessage': customLastMessage ?? message,
          'sentOn': Timestamp.now(),
        });
      }

      print('✅ System message added: $message');
    } catch (e) {
      print('❌ Error adding system message: $e');
    }
  }

  // Get group messages stream (legacy - for backward compatibility)
  static Stream<QuerySnapshot> getGroupMessagesStream(String groupChatRoomId) {
    return groupChatRoomsCollection
        .doc(groupChatRoomId)
        .collection('messages')
        .orderBy('sentOn', descending: false)
        .snapshots();
  }

  // Get paginated messages for better performance
  static Future<Map<String, dynamic>> getMessagesPaginated(
    String groupChatRoomId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = groupChatRoomsCollection
          .doc(groupChatRoomId)
          .collection('messages')
          .orderBy('sentOn', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      QuerySnapshot snapshot = await query.get();
      
      List<dynamic> rawMessages = snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': data['id'] ?? doc.id,
              'senderId': data['senderId'] ?? '',
              'senderName': '', // Will be filled by provider
              'senderProfileImage': '', // Will be filled by provider
              'text': data['message'] ?? '',
              'sentOn': (data['sentOn'] as Timestamp?)?.toDate() ?? DateTime.now(),
              'messageType': data['messageType'] ?? 'text',
              'isRead': data['isRead'] ?? false,
            };
          })
          .toList()
          .reversed
          .toList(); // Reverse to show oldest first

      // Convert to Message objects will be done in provider
      return {
        'messages': rawMessages,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        'hasMore': snapshot.docs.length == limit,
      };
    } catch (e) {
      print('Error getting paginated group messages: $e');
      throw e;
    }
  }

  // Get stream of only new messages after a certain time
  static Stream<QuerySnapshot> getNewMessagesStream(String groupChatRoomId, DateTime afterTime) {
    return groupChatRoomsCollection
        .doc(groupChatRoomId)
        .collection('messages')
        .where('sentOn', isGreaterThan: Timestamp.fromDate(afterTime))
        .orderBy('sentOn', descending: false)
        .snapshots();
  }

  // Get user's group chat rooms stream
  static Stream<QuerySnapshot> getUserGroupChatRoomsStream() {
    final String currentUserId = _auth.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) {
      return const Stream.empty();
    }

    return groupChatRoomsCollection
        .where('participantsList', arrayContains: currentUserId)
        .where('isActive', isEqualTo: true)
        .orderBy('sentOn', descending: true)
        .snapshots();
  }

  // Add member to group
  static Future<bool> addMemberToGroup({
    required String groupChatRoomId,
    required String userId,
    required String userName,
  }) async {
    try {
      await groupChatRoomsCollection.doc(groupChatRoomId).update({
        'participantsList': FieldValue.arrayUnion([userId]),
      });

      await addSystemMessage(
        groupChatRoomId: groupChatRoomId,
        message: '$userName joined the group',
        updateLastMessage: true,
      );

      return true;
    } catch (e) {
      print('❌ Error adding member to group: $e');
      return false;
    }
  }

  // Remove member from group
  static Future<bool> removeMemberFromGroup({
    required String groupChatRoomId,
    required String userId,
    required String userName,
  }) async {
    try {
      await groupChatRoomsCollection.doc(groupChatRoomId).update({
        'participantsList': FieldValue.arrayRemove([userId]),
      });

      await addSystemMessage(
        groupChatRoomId: groupChatRoomId,
        message: '$userName left the group',
        updateLastMessage: true,
      );

      return true;
    } catch (e) {
      print('❌ Error removing member from group: $e');
      return false;
    }
  }

  // Get group details
  static Future<Map<String, dynamic>?> getGroupDetails(String groupChatRoomId) async {
    try {
      DocumentSnapshot doc = await groupChatRoomsCollection.doc(groupChatRoomId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('❌ Error getting group details: $e');
      return null;
    }
  }

  static Stream<Map<String, dynamic>?> getGroupDetailsStream(String groupChatRoomId) {
    final String currentUserId = _auth.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) {
      return const Stream.empty();
    }
    return groupChatRoomsCollection
        .doc(groupChatRoomId)
        .snapshots()
        .map((DocumentSnapshot doc) {
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      final List<dynamic> participants = data['participantsList'] ?? [];
      if (!participants.contains(currentUserId)) {
        print('❌ User not a participant of this group');
        return null;
      }

      return data;
    });
  }

  // Get all group member IDs
  static Future<List<String>> getGroupMembers(String groupChatRoomId) async {
    try {
      DocumentSnapshot doc = await groupChatRoomsCollection.doc(groupChatRoomId).get();
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>;
      final List<dynamic> participants = data['participantsList'] ?? [];
      final List<String> enabledUsers = [];

      await Future.wait(participants.map((participantId) async {
        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(participantId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            if (userData['isPushNotificationEnabled'] == true) {
              enabledUsers.add(participantId);
            }
          }
        } catch (e) {
          print('⚠️ Error fetching user $participantId: $e');
        }
      }));

      return enabledUsers;
    } catch (e) {
      print('❌ Error getting group members: $e');
      return [];
    }
  }


  // Add multiple members to group (avoiding duplicates)
  static Future<bool> addMembersToGroup({
    required String groupChatRoomId,
    required List<String> userIds,
    required List<String> userNames,
  }) async {
    try {
      // Get current members
      List<String> existingMembers = await getGroupMembers(groupChatRoomId);
      List<String> newMembers = [];
      List<String> newMemberNames = [];
      for (int i = 0; i < userIds.length; i++) {
        if (!existingMembers.contains(userIds[i])) {
          newMembers.add(userIds[i]);
          newMemberNames.add(userNames[i]);
        }
      }
      if (newMembers.isEmpty) {
        print('No new members to add.');
        return false;
      }
      await groupChatRoomsCollection.doc(groupChatRoomId).update({
        'participantsList': FieldValue.arrayUnion(newMembers),
      });

      print('✅ Added ${newMembers.length} new member(s) to group.');
      return true;
    } catch (e) {
      print('❌ Error adding members to group: $e');
      return false;
    }
  }

  // Delete group message
  static Future<void> deleteGroupMessage(String groupChatRoomId, String messageId) async {
    try {
      await groupChatRoomsCollection
          .doc(groupChatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();
      
      print('✅ Group message deleted successfully');
    } catch (e) {
      print('❌ Error deleting group message: $e');
      throw e;
    }
  }
}