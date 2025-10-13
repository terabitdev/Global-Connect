import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';

import '../Model/userModel.dart';
import '../Model/localEvenModel.dart';
import '../core/services/GroupChatService.dart';
import '../core/services/NotificationService/NotificationService.dart';

class Message {
  final String id;
  final String? messageId;
  final String senderId;
  final String senderName;
  final String senderProfileImage;
  final String text;
  final DateTime sentOn;
  final String messageType;
  final bool isRead;

  Message({
    required this.id,
    this.messageId,
    required this.senderId,
    required this.senderName,
    required this.senderProfileImage,
    required this.text,
    required this.sentOn,
    required this.messageType,
    required this.isRead,
  });
}

class GroupChatProvider extends ChangeNotifier {
  String? _groupImageUrl;
  List<Message> _messages = [];
  bool _isLoading = true;
  String? _error;
  bool _hasMoreMessages = true;
  int _messagesLimit = 20;
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  String? _createdById;
  String? _currentGroupName;
  String? _currentGroupId;
  Set<String> _pendingMessages = {}; // Track pending messages
  List<LocalEventModel> _currentEvents = []; // Group events
  StreamSubscription<QuerySnapshot>? _eventsSubscription;
  bool get hasMessageText => _hasMessageText;
  bool _hasMessageText = false;

  // File upload state
  File? _selectedFile;
  String? _selectedFileType;
  bool _isUploadingFile = false;
  double _uploadProgress = 0.0;
  Map<String, bool> _messageRetryStatus = {};
  Map<String, double> _messageUploadProgress = {};
  Map<String, String> _optimisticToDocIdMapping = {}; // Maps custom messageId to real docId

  // User info
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final String _currentUserName = FirebaseAuth.instance.currentUser?.displayName ?? '';
  final String _currentUserImage = FirebaseAuth.instance.currentUser?.photoURL ?? '';

  // Cache for user details to avoid repeated API calls
  final Map<String, Map<String, dynamic>> _userCache = {};
  List<UserModel> _groupMembers = [];

  // Notification service
  final NotificationService _notificationService = NotificationService.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ✅ ADD MESSAGE CONTROLLER (like ChatController)
  final TextEditingController messageController = TextEditingController();

  // Getters
  List<UserModel> get groupMembers => _groupMembers;
  String? get groupImageUrl => _groupImageUrl;
  String? get createdById => _createdById;
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading && _messages.isEmpty; // Only show overlay when no messages yet
  String? get error => _error;
  bool get hasMoreMessages => _hasMoreMessages;
  bool get isLoadingMore => _isLoadingMore;
  String get currentUserId => _currentUserId;
  String get currentUserName => _currentUserName;
  String get currentUserImage => _currentUserImage;
  String? get currentGroupName => _currentGroupName;
  String? get currentGroupId => _currentGroupId;
  bool get hasPendingMessages => _pendingMessages.isNotEmpty;
  List<dynamic> get currentTimelineItems => _buildCombinedTimeline();
  File? get selectedFile => _selectedFile;
  String? get selectedFileType => _selectedFileType;
  bool get isUploadingFile => _isUploadingFile;
  double get uploadProgress => _uploadProgress;

  // Helper methods to get message states
  bool isMessageOptimistic(String messageId) {
    return _optimisticToDocIdMapping.containsKey(messageId);
  }

  bool isMessageUploading(String messageId) {
    return _messageUploadProgress.containsKey(messageId);
  }

  double getMessageUploadProgress(String messageId) {
    return _messageUploadProgress[messageId] ?? 0.0;
  }

  bool isMessageFailed(String messageId) {
    return _messageRetryStatus[messageId] ?? false;
  }

  // Helper method to get current user's name
  Future<String> _getCurrentUserName() async {
    if (_currentUserId.isEmpty) return 'Someone';
    
    try {
      // Use the cached user data method
      final userData = await _getCachedUserData(_currentUserId);
      return userData['fullName'] ?? 'Someone';
    } catch (e) {
      print('Error getting current user name: $e');
      return 'Someone';
    }
  }
  void _setupMessageControllerListener() {
    messageController.addListener(() {
      final hasText = messageController.text.trim().isNotEmpty;
      if (_hasMessageText != hasText) {
        _hasMessageText = hasText;
        notifyListeners();
      }
    });
  }

  Future<void> fetchGroupMembers(String groupChatRoomId, {String? groupName}) async {
    _isLoading = true;
    _currentGroupId = groupChatRoomId;

    // ✅ SET GROUP NAME IMMEDIATELY if provided
    if (groupName != null && groupName.isNotEmpty) {
      _currentGroupName = groupName;
    }

    notifyListeners();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('groupChatRooms')
          .doc(groupChatRoomId)
          .get();

      final data = doc.data();
      if (data == null) {
        _groupMembers = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      _groupImageUrl = data['groupImageUrl'] as String?;
      _createdById = data['createdBy'] as String?;

      if (_currentGroupName == null || _currentGroupName!.isEmpty) {
        _currentGroupName = data['groupName'] as String?;
      }

      final List<dynamic> participantIds = data['participantsList'] ?? [];

      final List<UserModel> members = [];

      for (String uid in participantIds) {
        if (_userCache.containsKey(uid)) {
          final cachedData = _userCache[uid]!;
          members.add(UserModel.fromMap(cachedData));
        } else {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            _userCache[uid] = userData;
            members.add(UserModel.fromMap(userData));
          }
        }
      }

      _groupMembers = members;
    } catch (e) {
      print('❌ Error fetching group members: $e');
      _groupMembers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // Initialize chat with optimized loading
  void initializeChat(String groupChatRoomId, {String? groupName}) {
    _isLoading = true;
    _error = null;
    _currentGroupId = groupChatRoomId;
    if (groupName != null && groupName.isNotEmpty) {
      _currentGroupName = groupName;
    }
    notifyListeners();
    _setupMessageControllerListener();
    _loadInitialMessages(groupChatRoomId);
    _loadGroupEvents(groupChatRoomId);
  }

  // Load initial messages with pagination
  Future<void> _loadInitialMessages(String groupChatRoomId) async {
    try {
      final result = await GroupChatService.getMessagesPaginated(
        groupChatRoomId, 
        limit: _messagesLimit
      );
      
      final rawMessages = result['messages'] as List<dynamic>;
      _lastDocument = result['lastDocument'];
      _hasMoreMessages = result['hasMore'];
      
      // Convert raw data to Message objects
      _messages = await _convertRawToMessages(rawMessages);
      
      // Start listening to new messages only
      _listenToNewMessages(groupChatRoomId);
      
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      print('❌ Error loading initial messages: $e');
      _error = 'Error loading messages: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Convert raw message data to Message objects
  Future<List<Message>> _convertRawToMessages(List<dynamic> rawMessages) async {
    List<Message> messages = [];
    
    for (dynamic rawMessage in rawMessages) {
      final senderId = rawMessage['senderId'] ?? '';
      
      // Get user details from cache or fetch
      Map<String, dynamic>? userDetails = _userCache[senderId];
      if (userDetails == null && senderId.isNotEmpty) {
        userDetails = await GroupChatService.getUserDetails(senderId);
        if (userDetails != null) {
          _userCache[senderId] = userDetails;
        }
      }
      
      final message = Message(
        id: rawMessage['id'] ?? '',
        senderId: senderId,
        senderName: userDetails?['fullName'] ?? 'Unknown User',
        senderProfileImage: userDetails?['profileImageUrl'] ?? '',
        text: rawMessage['text'] ?? '',
        sentOn: rawMessage['sentOn'] ?? DateTime.now(),
        messageType: rawMessage['messageType'] ?? 'text',
        isRead: rawMessage['isRead'] ?? false,
      );
      
      messages.add(message);
    }
    
    return messages;
  }

  // Cache user details for messages to avoid repeated API calls
  Future<void> _cacheUserDetailsForMessages(List<Message> messages) async {
    final Set<String> userIds = messages.map((m) => m.senderId).toSet();
    
    for (String userId in userIds) {
      if (!_userCache.containsKey(userId)) {
        final userDetails = await GroupChatService.getUserDetails(userId);
        if (userDetails != null) {
          _userCache[userId] = userDetails;
        }
      }
    }
  }

  // Load more messages for pagination
  Future<void> loadMoreMessages() async {
    if (_currentGroupId == null || !_hasMoreMessages || _isLoadingMore) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      final result = await GroupChatService.getMessagesPaginated(
        _currentGroupId!,
        limit: _messagesLimit,
        startAfter: _lastDocument,
      );
      
      final rawOlderMessages = result['messages'] as List<dynamic>;
      _lastDocument = result['lastDocument'];
      _hasMoreMessages = result['hasMore'];
      
      // Convert raw data to Message objects
      final olderMessages = await _convertRawToMessages(rawOlderMessages);
      
      // Insert older messages at the beginning
      _messages.insertAll(0, olderMessages);
      
    } catch (e) {
      print('❌ Error loading more messages: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Listen to real-time new messages only
  void _listenToNewMessages(String groupChatRoomId) {
    _messagesSubscription?.cancel();
    
    final lastMessageTime = _messages.isNotEmpty 
        ? _messages.last.sentOn 
        : DateTime.now().subtract(Duration(seconds: 1));
    
    _messagesSubscription = GroupChatService.getNewMessagesStream(groupChatRoomId, lastMessageTime).listen(
      (querySnapshot) async {
        try {
          List<Message> newMessages = [];

          // Process each new message document
          for (var doc in querySnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final senderId = data['senderId'] ?? '';
            
            Map<String, dynamic>? userDetails = _userCache[senderId];
            if (userDetails == null && senderId.isNotEmpty) {
              userDetails = await GroupChatService.getUserDetails(senderId);
              if (userDetails != null) {
                _userCache[senderId] = userDetails;
              }
            }

            final message = Message(
              id: data['id'] ?? doc.id,
              senderId: senderId,
              senderName: userDetails?['fullName'] ?? 'Unknown User',
              senderProfileImage: userDetails?['profileImageUrl'] ?? '',
              text: data['message'] ?? '',
              sentOn: (data['sentOn'] as Timestamp?)?.toDate() ?? DateTime.now(),
              messageType: data['messageType'] ?? 'text',
              isRead: data['isRead'] ?? false,
            );

            newMessages.add(message);
          }

          if (newMessages.isNotEmpty) {
            // Remove temp messages before adding real ones
            _messages.removeWhere((msg) => msg.id.startsWith('temp_'));
            _messages.addAll(newMessages);
            notifyListeners();
          }

        } catch (e) {
          print('❌ Error processing new messages: $e');
          _error = 'Error loading new messages: $e';
          notifyListeners();
        }
      },
      onError: (error) {
        print('❌ New messages stream error: $error');
        _error = 'Error loading new messages: $error';
        notifyListeners();
      },
    );
  }

  // ✅ NON-BLOCKING SEND MESSAGE WITH RAPID SENDING SUPPORT
  Future<bool> sendMessage(String groupChatRoomId) async {
    final messageText = messageController.text.trim();
    if (messageText.isEmpty) return false;

    _error = null;

    // Create unique temp ID for this message
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${messageText.hashCode}';
    
    try {
      // Get user data (cached or fetch)
      final userData = await _getCachedUserData(_currentUserId);
      
      // ✅ CREATE TEMPORARY MESSAGE FOR IMMEDIATE UI UPDATE
      final tempMessage = Message(
        id: tempId,
        senderId: _currentUserId,
        senderName: userData['fullName'] ?? _currentUserName,
        senderProfileImage: userData['profileImageUrl'] ?? _currentUserImage,
        text: messageText,
        sentOn: DateTime.now(),
        messageType: 'text',
        isRead: false,
      );

      // ✅ ADD TEMP MESSAGE TO UI AND CLEAR TEXT FIELD IMMEDIATELY
      _messages.add(tempMessage);
      _pendingMessages.add(tempId);
      messageController.clear();
      notifyListeners();

      // Send message in background (non-blocking)
      _sendMessageInBackground(groupChatRoomId, messageText, tempId, userData);
      
      return true;
    } catch (e) {
      // Remove temp message on immediate error
      _messages.removeWhere((msg) => msg.id == tempId);
      _pendingMessages.remove(tempId);
      _error = 'Failed to prepare message: $e';
      print('❌ Error preparing message: $e');
      notifyListeners();
      return false;
    }
  }

  // Get cached user data to avoid repeated fetches
  Future<Map<String, dynamic>> _getCachedUserData(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }
    
    try {
      final userDetails = await GroupChatService.getUserDetails(userId);
      if (userDetails != null) {
        _userCache[userId] = userDetails;
        return userDetails;
      }
      return {'fullName': 'Unknown User', 'profileImageUrl': ''};
    } catch (e) {
      return {'fullName': 'Unknown User', 'profileImageUrl': ''};
    }
  }

  // Send message in background without blocking UI
  void _sendMessageInBackground(
    String groupChatRoomId, 
    String messageText, 
    String tempId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final success = await GroupChatService.sendGroupMessage(
        groupChatRoomId: groupChatRoomId,
        message: messageText,
        senderId: _currentUserId,
      );

      if (success) {
        // ✅ SEND NOTIFICATIONS TO ALL GROUP MEMBERS
        _sendNotificationsToGroupMembers(messageText, groupChatRoomId);
        
        // Remove from pending messages
        _pendingMessages.remove(tempId);
        
        // Update temp message to show as sent
        final tempMessageIndex = _messages.indexWhere((msg) => msg.id == tempId);
        if (tempMessageIndex != -1) {
          // Keep temp message until real one arrives through stream
          notifyListeners();
        }
      } else {
        // ✅ REMOVE TEMP MESSAGE ON FAILURE
        _messages.removeWhere((msg) => msg.id == tempId);
        _pendingMessages.remove(tempId);
        _error = 'Failed to send message';
        notifyListeners();
      }
      // ✅ SUCCESS: Real message will come through stream and replace temp message
    } catch (e) {
      // ✅ REMOVE TEMP MESSAGE ON ERROR
      _messages.removeWhere((msg) => msg.id == tempId);
      _pendingMessages.remove(tempId);
      _error = 'Error sending message: $e';
      print('❌ Send message error: $e');
      notifyListeners();
    }
  }

  /// Send notifications to all group members except the sender
  Future<void> _sendNotificationsToGroupMembers(String messageText, String groupChatRoomId) async {
    try {
      // Get all group member IDs
      final List<String> memberIds = await GroupChatService.getGroupMembers(groupChatRoomId);
      
      // Filter out the current user (sender)
      final List<String> recipientIds = memberIds.where((id) => id != _currentUserId).toList();
      
      print('Sending group notifications to ${recipientIds.length} members');

      // Send notifications to all recipients
      for (String recipientId in recipientIds) {
        try {
          // Get recipient's FCM token
          final recipientToken = await _notificationService.getUserFCMToken(recipientId);
          
          if (recipientToken != null && recipientToken.isNotEmpty) {
            // Send notification
            await _notificationService.sendNotificationToUser(
              receiverToken: recipientToken,
              title: _currentGroupName ?? 'Group Chat',
              body: '${_currentGroupName ?? 'Group Chat'}: ${_currentUserName}: $messageText',
              data: {
                'type': 'group_chat_message',
                'groupChatRoomId': groupChatRoomId,
                'groupName': _currentGroupName,
                'senderId': _currentUserId,
                'message': messageText,
              },
            );
            
            print('✅ Group notification sent to $recipientId');
          } else {
            print('❌ No FCM token found for user $recipientId');
          }
        } catch (e) {
          print('❌ Error sending notification to $recipientId: $e');
          // Continue with other recipients even if one fails
        }
      }
    } catch (e) {
      print('❌ Error sending group notifications: $e');
      // Don't throw error here as message was sent successfully
    }
  }

  Future<bool> removeUserFromGroup({
    required String groupChatRoomId,
    required String userId,
    required String userName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool success = await GroupChatService.removeMemberFromGroup(
        groupChatRoomId: groupChatRoomId,
        userId: userId,
        userName: userName,
      );

      if (success) {
        _groupMembers.removeWhere((member) => member.uid == userId);
        print('✅ User $userName removed successfully');
      }

      return success;
    } catch (e) {
      print('❌ Error removing user: $e');
      _error = 'Failed to remove user: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load group events from groupChatRooms collection
  Future<void> _loadGroupEvents(String groupChatRoomId) async {
    try {
      _eventsSubscription?.cancel();
      
      _eventsSubscription = FirebaseFirestore.instance
          .collection('groupChatRooms')
          .doc(groupChatRoomId)
          .collection('localEvent')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .listen((snapshot) {
        try {
          _currentEvents = snapshot.docs
              .map((doc) => LocalEventModel.fromDocument(doc))
              .toList();
          notifyListeners();
        } catch (e) {
          print('❌ Error parsing group events: $e');
        }
      });
    } catch (e) {
      print('❌ Error loading group events: $e');
    }
  }

  // Build combined timeline of messages and events
  List<dynamic> _buildCombinedTimeline() {
    final List<Map<String, dynamic>> messageItems = _messages
        .map((m) => {
              'itemType': 'message',
              'data': m,
              'createdAt': m.sentOn,
            })
        .toList();

    final List<Map<String, dynamic>> eventItems = _currentEvents
        .map((e) => {
              'itemType': 'event',
              'data': e,
              'createdAt': e.createdAt,
            })
        .toList();

    final List<Map<String, dynamic>> combined = [...messageItems, ...eventItems];
    combined.sort((a, b) {
      final DateTime at = (a['createdAt'] as DateTime);
      final DateTime bt = (b['createdAt'] as DateTime);
      return at.compareTo(bt);
    });
    return combined;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _isLoading = true;
    _error = null;
    _messages.clear();
    _userCache.clear();
    _groupMembers.clear();
    _pendingMessages.clear();
    _currentEvents.clear();
    _currentGroupName = null;
    _currentGroupId = null;
    _hasMoreMessages = true;
    _lastDocument = null;
    _isLoadingMore = false;
    messageController.clear();
    _messagesSubscription?.cancel();
    _eventsSubscription?.cancel();
    notifyListeners();
  }

  // Image/Video functionality
  Future<File?> pickImageOrVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'jpeg', 'mp4', 'mov', 'avi'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final extension = file.path.split('.').last.toLowerCase();

        // Determine file type
        if (['jpg', 'png', 'jpeg'].contains(extension)) {
          _selectedFileType = 'image';
        } else if (['mp4', 'mov', 'avi'].contains(extension)) {
          _selectedFileType = 'video';
        }

        _selectedFile = file;
        notifyListeners();
        return file;
      }
    } catch (e) {
      print('❌ Error picking file: $e');
    }
    return null;
  }

  void clearSelectedFile() {
    _selectedFile = null;
    _selectedFileType = null;
    notifyListeners();
  }

  Future<void> sendMediaMessage({
    required String groupChatRoomId,
    String? caption,
  }) async {
    final selectedFile = _selectedFile;
    final selectedFileType = _selectedFileType;

    if (selectedFile == null || selectedFileType == null) {
      return;
    }

    try {
      final messageText = caption?.isNotEmpty == true ? caption! : (selectedFileType == 'image' ? '📷 Image' : '🎥 Video');

      // Create unique message ID
      final messageId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${_currentUserId}';

      // Get user data
      final userData = await _getCachedUserData(_currentUserId);

      // Show message immediately (optimistic) with uploading state
      final optimisticMessage = Message(
        id: messageId,
        senderId: _currentUserId,
        senderName: userData['fullName'] ?? _currentUserName,
        senderProfileImage: userData['profileImageUrl'] ?? _currentUserImage,
        text: selectedFile.path, // Use local file path for immediate preview
        sentOn: DateTime.now(),
        messageType: selectedFileType,
        isRead: false,
      );

      // Add to chat immediately with upload state
      _messages.add(optimisticMessage);
      _messageUploadProgress[messageId] = 0.0;
      _optimisticToDocIdMapping[messageId] = selectedFile.path; // Store local file path
      _pendingMessages.add(messageId);
      notifyListeners();

      // Clear selected file
      clearSelectedFile();

      // Start upload in background
      await _uploadAndSendMedia(messageId, selectedFile, selectedFileType, messageText, userData, groupChatRoomId);

    } catch (e) {
      print('❌ Error sending media message: $e');
    }
  }

  Future<void> _uploadAndSendMedia(
    String messageId,
    File file,
    String fileType,
    String messageText,
    Map<String, dynamic> userData,
    String groupChatRoomId,
  ) async {
    try {
      // Mark as uploading
      _messageUploadProgress[messageId] = 0.1;
      notifyListeners();

      // Upload file with progress tracking
      final fileUrl = await _uploadFileWithProgress(file, fileType, messageId);

      if (fileUrl != null && fileUrl.isNotEmpty) {
        // Get current user name for formatted lastMessage
        final currentUserName = await _getCurrentUserName();
        final formattedLastMessage = fileType == 'image' 
            ? '$currentUserName sent an image'
            : '$currentUserName sent a video';

        // Send the actual message with image URL and formatted lastMessage
        final success = await GroupChatService.sendGroupMessage(
          groupChatRoomId: groupChatRoomId,
          message: fileUrl,
          senderId: _currentUserId,
          messageType: fileType,
          customLastMessage: formattedLastMessage,
        );

        if (success) {
          // Remove optimistic message (real message will come through stream)
          _messages.removeWhere((msg) => msg.id == messageId);
          _pendingMessages.remove(messageId);
          _messageUploadProgress.remove(messageId);
          _optimisticToDocIdMapping.remove(messageId);
          
          // Send notifications to group members
          _sendNotificationsToGroupMembers(messageText, groupChatRoomId);
          
          notifyListeners();
        } else {
          throw Exception('Failed to send message to group');
        }
      } else {
        throw Exception('Failed to upload file');
      }

    } catch (e) {
      // Mark message as failed
      _messageRetryStatus[messageId] = true;
      _messageUploadProgress.remove(messageId);
      notifyListeners();
      print('❌ Error uploading media: $e');
    }
  }

  Future<String?> _uploadFileWithProgress(File file, String fileType, String messageId) async {
    try {
      // Validate file exists
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last.toLowerCase();
      final fileName = '${timestamp}_${_currentUserId}.$extension';

      // Create storage reference - using GroupChatImageVideo folder as requested
      final storageRef = _storage.ref().child('GroupChatImageVideo/$fileName');

      // Create upload task with progress tracking
      final uploadTask = storageRef.putFile(file);
      
      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        _messageUploadProgress[messageId] = progress;
        notifyListeners();
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (downloadUrl.isEmpty) {
        throw Exception('Empty download URL received');
      }

      return downloadUrl;
    } catch (e) {
      throw Exception('Upload failed: ${e.toString()}');
    }
  }

  // Delete message with media cleanup
  Future<void> deleteMessage(String messageId, String groupChatRoomId) async {
    try {
      // Find the message
      final message = _messages.firstWhere(
        (msg) => msg.id == messageId,
        orElse: () => throw Exception('Message not found'),
      );

      // If it's a media message, delete from storage first
      if (message.text.startsWith('http') && message.text.contains('firebase')) {
        await _deleteFileFromStorage(message.text);
      }

      // Delete from Firestore
      await GroupChatService.deleteGroupMessage(groupChatRoomId, messageId);

      // Remove from local list
      _messages.removeWhere((msg) => msg.id == messageId);
      
      notifyListeners();
      print('✅ Message deleted successfully');
    } catch (e) {
      print('❌ Error deleting message: $e');
    }
  }

  Future<void> _deleteFileFromStorage(String fileUrl) async {
    try {
      // Use Firebase Storage's refFromURL (most reliable with download URL)
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      print('✅ File deleted from storage: ${ref.fullPath}');
    } catch (e) {
      print('❌ Error deleting file from storage: $e');
      // Continue even if storage deletion fails
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _eventsSubscription?.cancel();
    messageController.dispose();
    super.dispose();
  }
}