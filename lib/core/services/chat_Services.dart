import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:global_connect/core/const/firebase_Collection_Names.dart';

import '../../Model/chatRoomModel.dart';

class ChatServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final ChatServices _instance = ChatServices._internal();
  factory ChatServices() => _instance;
  ChatServices._internal();

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> sendMessage({
    required String chatroomId,
    required String text,
    required String receiverId,
    String messageType = 'text',
    String? customLastMessage,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Create message object
      final messageId = chatRoomsCollection
          .doc(chatroomId)
          .collection('messages')
          .doc()
          .id;

      final message = Message(
        id: messageId,
        text: text,
        sender: currentUserId!,
        receiver: receiverId,
        sentOn: DateTime.now(),
        isRead: false,
        messageType: messageType,
      );

      // Start a batch write
      WriteBatch batch = _firestore.batch();

      DocumentReference messageRef = chatRoomsCollection
          .doc(chatroomId)
          .collection('messages')
          .doc(messageId);

      batch.set(messageRef, message.toFirestore());

      DocumentReference chatroomRef = chatRoomsCollection.doc(chatroomId);

      batch.update(chatroomRef, {
        'lastMessage': customLastMessage ?? text,
        'sentOn': DateTime.now(),
      });

      // Commit the batch
      await batch.commit();

      print('Message sent successfully');
    } catch (e) {
      print('Error sending message: $e');
      throw e;
    }
  }

  // Create a new chatroom
  Future<String> createChatroom({
    required List<String> participantsList,
    String category = '',
  }) async {
    try {
      final chatroomId = chatRoomsCollection.doc().id;
      final chatroom = ChatRoom(
        id: chatroomId,
        participantsList: participantsList,
        lastMessage: '',
        sentOn: DateTime.now(),
      );

      await chatRoomsCollection.doc(chatroomId).set({
        ...chatroom.toFirestore(),
        'category': category,
      });

      return chatroomId;
    } catch (e) {
      print('Error creating chatroom: $e');
      throw e;
    }
  }

  // Send a post as a message
  Future<void> sendPostMessage({
    required String chatroomId,
    required String postId,
    required String postOwnerId,
    required String receiverId,
    String? customLastMessage,
  }) async {
    try {
      if (currentUserId.isEmpty) {
        throw Exception('User not authenticated');
      }

      // Create message object for post
      final messageId = chatRoomsCollection
          .doc(chatroomId)
          .collection('messages')
          .doc()
          .id;

      final message = Message(
        id: messageId,
        text: '', // Empty text for post messages
        sender: currentUserId,
        receiver: receiverId,
        sentOn: DateTime.now(),
        isRead: false,
        messageType: 'post',
        postId: postId,
        postOwnerId: postOwnerId,
      );

      // Start a batch write
      WriteBatch batch = _firestore.batch();

      DocumentReference messageRef = chatRoomsCollection
          .doc(chatroomId)
          .collection('messages')
          .doc(messageId);

      batch.set(messageRef, message.toFirestore());

      DocumentReference chatroomRef = chatRoomsCollection.doc(chatroomId);

      // Get sender name for last message
      final senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      
      String senderName = 'Someone';
      if (senderDoc.exists) {
        senderName = senderDoc.data()?['fullName'] ?? 'Someone';
      }

      batch.update(chatroomRef, {
        'lastMessage': customLastMessage ?? '$senderName shared a post',
        'sentOn': DateTime.now(),
      });

      // Commit the batch
      await batch.commit();

      print('Post shared successfully in chat');
    } catch (e) {
      print('Error sharing post in chat: $e');
      throw e;
    }
  }

  // Get messages stream for a chatroom (legacy - for backward compatibility)
  Stream<List<Message>> getMessagesStream(String chatroomId) {
    return chatRoomsCollection
        .doc(chatroomId)
        .collection('messages')
        .orderBy('sentOn', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Message.fromFirestore(doc, id: doc.id);
          }).toList();
        });
  }

  // Get paginated messages for better performance
  Future<Map<String, dynamic>> getMessagesPaginated(
    String chatroomId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = chatRoomsCollection
          .doc(chatroomId)
          .collection('messages')
          .orderBy('sentOn', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      QuerySnapshot snapshot = await query.get();
      
      List<Message> messages = snapshot.docs
          .map((doc) => Message.fromFirestore(doc, id: doc.id))
          .toList()
          .reversed
          .toList(); // Reverse to show oldest first

      return {
        'messages': messages,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        'hasMore': snapshot.docs.length == limit,
      };
    } catch (e) {
      print('Error getting paginated messages: $e');
      throw e;
    }
  }

  // Get stream of only new messages after a certain time
  Stream<List<Message>> getNewMessagesStream(String chatroomId, DateTime afterTime) {
    return chatRoomsCollection
        .doc(chatroomId)
        .collection('messages')
        .where('sentOn', isGreaterThan: Timestamp.fromDate(afterTime))
        .orderBy('sentOn', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Message.fromFirestore(doc, id: doc.id);
          }).toList();
        });
  }

  Future<void> markMessagesAsRead({
    required String chatroomId,
    required String senderId,
  }) async {
    try {
      QuerySnapshot unreadMessages = await chatRoomsCollection
          .doc(chatroomId)
          .collection('messages')
          .where('sender', isEqualTo: senderId)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();

      for (DocumentSnapshot doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Updated getUserChatrooms with better error handling
  Stream<List<ChatRoom>> getUserChatrooms() {
    if (currentUserId.isEmpty) {
      return Stream.value([]);
    }

    return chatRoomsCollection
        .where('participantsList', arrayContains: currentUserId)
        .orderBy('sentOn', descending: true)
        .snapshots()
        .handleError((error) {
          print('❌ Firestore Listen Error: $error');
          return null;
        })
        .where((snapshot) => snapshot != null)
        .map((snapshot) {
          final chatRooms = snapshot!.docs.map((doc) {
            print('Chat Room Doc ID: ${doc.id}');
            return ChatRoom.fromFirestore(doc, id: doc.id);
          }).toList();

          return chatRooms;
        });
  }

  Future<String?> getChatroomBetweenUsers(String otherUserId) async {
    try {
      if (currentUserId == null) return null;

      QuerySnapshot chatrooms = await chatRoomsCollection
          .where('participantsList', arrayContains: currentUserId)
          .get();

      for (DocumentSnapshot doc in chatrooms.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        List<dynamic> participants = data?['participantsList'] ?? [];

        if (participants.contains(otherUserId) && participants.length == 2) {
          return doc.id;
        }
      }
      return null;
    } catch (e) {
      print('Error checking chatroom: $e');
      return null;
    }
  }

  String generateChatroomId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort();
    return ids.join('_');
  }

  Future<String?> checkChatroomExists(String otherUserId) async {
    try {
      if (currentUserId == null) {
        throw Exception("User not authenticated");
      }

      String chatroomId = generateChatroomId(currentUserId!, otherUserId);
      DocumentSnapshot chatroomDoc = await chatRoomsCollection
          .doc(chatroomId)
          .get();

      if (chatroomDoc.exists) {
        return chatroomId;
      }
      
      return null;
    } catch (e) {
      print('Error checking chatroom existence: $e');
      return null;
    }
  }

  Future<String> getOrCreateChatroom(
    String otherUserId,
    String category,
  ) async {
    try {
      if (currentUserId == null) {
        throw Exception("User not authenticated");
      }

      String chatroomId = generateChatroomId(currentUserId!, otherUserId);

      DocumentSnapshot chatroomDoc = await chatRoomsCollection
          .doc(chatroomId)
          .get();

      if (chatroomDoc.exists) {
        return chatroomId;
      }

      // Create new chatroom with deterministic ID
      await chatRoomsCollection.doc(chatroomId).set({
        'id': chatroomId,
        'participantsList': [currentUserId, otherUserId],
        'lastMessage': '',
        'sentOn': DateTime.now(),
        'category': category,
      });

      return chatroomId;
    } catch (e) {
      print('Error getting or creating chatroom: $e');
      throw e;
    }
  }

  Stream<QuerySnapshot> getPrivateChatRoomsStream() {
    if (currentUserId.isEmpty) {
      return Stream.empty();
    }

    return chatRoomsCollection
        .where('participantsList', arrayContains: currentUserId)
        .orderBy('sentOn', descending: true)
        .snapshots();
  }

  /// Check if user is currently in a specific chatroom
  bool isUserInChatroom(String chatroomId) {
    // This is a simple implementation - you might want to track this in your app state
    // For now, we'll return false to always send notifications
    return false;
  }

  /// Get user details by user ID
  Future<DocumentSnapshot> getUserDetails(String userId) async {
    return await usersCollection.doc(userId).get();
  }

  /// Get other participant ID from participants list
  String getOtherParticipantId(List<dynamic> participantsList) {
    for (String participantId in participantsList) {
      if (participantId != currentUserId) {
        return participantId;
      }
    }
    return '';
  }

  /// Format timestamp to readable time string
  String formatTime(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return '';
    }

    DateTime now = DateTime.now();

    if (now.difference(dateTime).inDays == 0) {
      // Today - show time
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(dateTime).inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else {
      // Other days - show date
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// Delete a message from chatroom
  Future<void> deleteMessage(String chatroomId, String messageId) async {
    try {
      await chatRoomsCollection
          .doc(chatroomId)
          .collection('messages')
          .doc(messageId)
          .delete();
      
      print('Message deleted successfully');
    } catch (e) {
      print('Error deleting message: $e');
      throw e;
    }
  }


  /// Create chat room data model from document
  Future<Map<String, dynamic>?> processChatRoomDocument(
    QueryDocumentSnapshot doc,
  ) async {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> participantsList = data['participantsList'] ?? [];

      // Find other user ID (not current user)
      String otherUserId = getOtherParticipantId(participantsList);

      if (otherUserId.isNotEmpty) {
        // Get other user details
        DocumentSnapshot userDoc = await getUserDetails(otherUserId);

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          return {
            'id': doc.id,
            'name': userData['fullName'] ?? 'Unknown User',
            'lastMessage': data['lastMessage'] ?? '',
            'profileImage': userData['profileImageUrl'] ?? '',
            'time': formatTime(data['sentOn']),
            'isOnline': userData['isOnline'] ?? false,
            'status': userData['status'] ?? 'offline',
            'activityStatus': userData['appSettings'] != null 
                ? (userData['appSettings']['activityStatus'] ?? true)
                : true,
            'otherUserId': otherUserId,
            'sentOn': data['sentOn'],
          };
        }
      }
    } catch (e) {
      print('Error processing chat room document: $e');
    }
    return null;
  }
}
