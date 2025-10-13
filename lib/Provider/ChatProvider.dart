import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import '../Model/chatRoomModel.dart';
import 'package:flutter/material.dart';
import '../core/services/chat_Services.dart';
import '../core/services/NotificationService/NotificationService.dart';

enum ChatState { loading, loaded, error, sending }

class ChatController extends ChangeNotifier {
  static ChatController? _instance;
  static ChatController get instance {
    _instance ??= ChatController._internal();
    return _instance!;
  }

  final ChatServices _chatServices = ChatServices();
  final NotificationService _notificationService = NotificationService.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Cache storage for chat data
  final Map<String, List<Message>> _messagesCache = {};
  final Map<String, String> _userProfileImagesCache = {};
  final Map<String, String> _userNamesCache = {};
  final Map<String, DateTime> _lastMessageFetch = {};
  final Map<String, StreamSubscription> _messageStreams = {};

  // State management
  ChatState _state = ChatState.loading;
  String? _error;
  String? _currentChatroomId;
  List<Message> _messages = [];
  Map<String, String> _userProfileImages = {};
  bool _isLoadingMessages = false;
  String? _currentReceiverName;
  String? _currentReceiverId;
  bool get hasMessageText => _hasMessageText;
  bool _hasMessageText = false;
  bool _isInitialLoadComplete = false;

  // File upload state
  File? _selectedFile;
  String? _selectedFileType;
  bool _isUploadingFile = false;
  double _uploadProgress = 0.0;
  Map<String, bool> _messageRetryStatus = {};
  Map<String, double> _messageUploadProgress = {};
  Map<String, String> _optimisticToDocIdMapping = {}; // Maps custom messageId to real docId

  // Cache settings
  static const Duration _cacheValidityDuration = Duration(minutes: 10);
  static const Duration _backgroundRefreshInterval = Duration(minutes: 3);
  
  Timer? _backgroundRefreshTimer;

  // Getters
  ChatState get state => _state;
  String? get error => _error;
  String? get currentChatroomId => _currentChatroomId;
  List<Message> get messages => _messages;
  String? get currentUserId => _chatServices.currentUserId;
  Map<String, String> get userProfileImages => _userProfileImages;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get currentReceiverName => _currentReceiverName;
  String? get currentReceiverId => _currentReceiverId;
  bool get isInitialLoadComplete => _isInitialLoadComplete;
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
    if (currentUserId == null) return 'Someone';
    
    if (_userNamesCache.containsKey(currentUserId)) {
      return _userNamesCache[currentUserId!]!;
    } else {
      try {
        final currentUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();
        final currentUserName = currentUserDoc.data()?['fullName'] ?? 'Someone';
        _userNamesCache[currentUserId!] = currentUserName; // Cache it
        return currentUserName;
      } catch (e) {
        print('Error getting current user name: $e');
        return 'Someone';
      }
    }
  }

  // Text controller for input
  final TextEditingController messageController = TextEditingController();

  // Singleton constructor
  ChatController._internal() {
    _setupMessageControllerListener();
    _startBackgroundRefresh();
  }

  // Factory constructor for backward compatibility
  factory ChatController() {
    return instance;
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
  void _startBackgroundRefresh() {
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = Timer.periodic(_backgroundRefreshInterval, (_) {
      _silentRefreshCurrentChat();
    });
  }

  Future<void> _silentRefreshCurrentChat() async {
    if (_currentChatroomId == null || !_isInitialLoadComplete) return;
    
    try {
      print('🔄 Silent refresh of chat messages...');
      // Silently refresh current chat messages without showing loading
      final snapshot = await _chatServices.getMessagesStream(_currentChatroomId!).first;
      if (snapshot.isNotEmpty) {
        await _updateMessagesCache(_currentChatroomId!, snapshot, isBackground: true);
      }
    } catch (e) {
      print('❌ Error in silent refresh: $e');
    }
  }

  /// Prefetch messages for a specific chatroom
  Future<void> prefetchChatMessages(String chatroomId) async {
    if (_isCacheValid(chatroomId)) {
      print('✨ Using cached messages for chatroom: $chatroomId');
      return;
    }

    try {
      print('🚀 Prefetching messages for chatroom: $chatroomId');
      final snapshot = await _chatServices.getMessagesStream(chatroomId).first;
      await _updateMessagesCache(chatroomId, snapshot, isBackground: true);
      print('✅ Messages prefetched for chatroom: $chatroomId');
    } catch (e) {
      print('❌ Error prefetching messages: $e');
    }
  }

  /// Prefetch user profile data for faster chat initialization
  Future<void> prefetchUserProfile(String userId) async {
    if (_userProfileImagesCache.containsKey(userId) && _userNamesCache.containsKey(userId)) {
      print('✨ Using cached profile for user: $userId');
      return;
    }

    try {
      print('🚀 Prefetching profile for user: $userId');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        _userNamesCache[userId] = data?['fullName'] ?? 'Unknown User';
        _userProfileImagesCache[userId] = data?['profileImageUrl'] ?? '';
        print('✅ Profile prefetched for user: $userId');
      }
    } catch (e) {
      print('❌ Error prefetching user profile: $e');
    }
  }

  bool _isCacheValid(String chatroomId) {
    final lastFetch = _lastMessageFetch[chatroomId];
    if (lastFetch == null) return false;
    return DateTime.now().difference(lastFetch) < _cacheValidityDuration;
  }

  Future<void> _updateMessagesCache(String chatroomId, List<Message> messages, {bool isBackground = false}) async {
    _messagesCache[chatroomId] = messages;
    _lastMessageFetch[chatroomId] = DateTime.now();
    
    // Update profile images for message senders
    await _loadProfileImagesForMessages(messages, isBackground: isBackground);
    
    // If this is the current chatroom, update the UI
    if (chatroomId == _currentChatroomId && !isBackground) {
      _messages = messages;
      notifyListeners();
    }
  }

  /// Initialize chatroom with enhanced caching
  Future<void> initializeChatroom({
    required String otherUserId,
    required String chatType,
    String? existingChatroomId,
  }) async {
    try {
      _currentReceiverId = otherUserId;

      // Check if we have cached user data
      if (_userNamesCache.containsKey(otherUserId)) {
        _currentReceiverName = _userNamesCache[otherUserId];
        _userProfileImages[otherUserId] = _userProfileImagesCache[otherUserId] ?? '';
        print('✨ Using cached user data for: $otherUserId');
      } else {
        await _loadReceiverDetails(otherUserId);
      }

      String? chatroomId = existingChatroomId;
      if (chatroomId == null) {
        // Only check if chatroom exists, don't create it yet
        _setState(ChatState.loading);
        chatroomId = await _chatServices.checkChatroomExists(otherUserId);
      }

      if (chatroomId != null) {
        _currentChatroomId = chatroomId;
        
        // Immediately load cached messages if available
        if (_messagesCache.containsKey(chatroomId) && _messagesCache[chatroomId]!.isNotEmpty) {
          _messages = List.from(_messagesCache[chatroomId]!);
          print('✨ Loaded ${_messages.length} cached messages instantly');
          _setState(ChatState.loaded);
          notifyListeners();
        } else {
          _setState(ChatState.loading);
        }

        // Always start listening to real-time updates
        _listenToMessages(otherUserId, chatroomId);
        _isInitialLoadComplete = true;
      } else {
        // Chatroom doesn't exist yet - will be created on first message
        _currentChatroomId = null;
        _messages = [];
        _setState(ChatState.loaded);
        _isInitialLoadComplete = true;
        print('💬 Chat ready - chatroom will be created on first message');
      }

    } catch (e) {
      _setError('Failed to initialize chat: ${e.toString()}');
    }
  }

  /// Load receiver's details with caching
  Future<void> _loadReceiverDetails(String receiverId) async {
    try {
      // Check cache first
      if (_userNamesCache.containsKey(receiverId)) {
        _currentReceiverName = _userNamesCache[receiverId];
        _userProfileImages[receiverId] = _userProfileImagesCache[receiverId] ?? '';
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        _currentReceiverName = data?['fullName'] ?? 'Unknown User';
        final profileImage = data?['profileImageUrl'] ?? '';
        _userProfileImages[receiverId] = profileImage;
        
        // Cache the data
        _userNamesCache[receiverId] = _currentReceiverName!;
        _userProfileImagesCache[receiverId] = profileImage;
      } else {
        _currentReceiverName = 'Unknown User';
        _userProfileImages[receiverId] = '';
        _userNamesCache[receiverId] = 'Unknown User';
        _userProfileImagesCache[receiverId] = '';
      }
    } catch (e) {
      print('Error loading receiver details: $e');
      _currentReceiverName = 'Unknown User';
      _userProfileImages[receiverId] = '';
    }
  }

  /// Enhanced message listening with caching
  void _listenToMessages(String otherUserId, String chatroomId) {
    // Cancel existing stream for this chatroom
    _messageStreams[chatroomId]?.cancel();
    
    _messageStreams[chatroomId] = _chatServices.getMessagesStream(chatroomId).listen(
      (newMessages) async {
        await _updateMessagesCache(chatroomId, newMessages);
        
        // Only update UI if this is the current chatroom
        if (chatroomId == _currentChatroomId) {
          _messages = newMessages;
          
          // Mark unread messages from the other user as read
          final hasUnreadFromOther = newMessages.any((msg) =>
              msg.sender == otherUserId && msg.isRead == false
          );
          if (hasUnreadFromOther) {
            await markMessagesAsRead(otherUserId);
          }

          if (_state == ChatState.loading) {
            _setState(ChatState.loaded);
          }
          
          notifyListeners();
        }
      },
      onError: (error) {
        _setError('Error listening to messages: ${error.toString()}');
      },
    );
  }

  /// Load profile images with enhanced caching
  Future<void> _loadProfileImagesForMessages(List<Message> messages, {bool isBackground = false}) async {
    try {
      final Set<String> userIds = {};
      for (var message in messages) {
        userIds.add(message.sender);
        if (message.receiver.isNotEmpty) {
          userIds.add(message.receiver);
        }
      }

      // Load profile images for users we don't have cached yet
      for (String userId in userIds) {
        if (!_userProfileImagesCache.containsKey(userId)) {
          await loadUserProfileImage(userId);
        } else {
          // Use cached data
          _userProfileImages[userId] = _userProfileImagesCache[userId]!;
        }
      }
    } catch (e) {
      print('Error loading profile images: $e');
    }
  }

  /// Load profile image with caching
  Future<void> loadUserProfileImage(String userId) async {
    try {
      // Check cache first
      if (_userProfileImagesCache.containsKey(userId)) {
        _userProfileImages[userId] = _userProfileImagesCache[userId]!;
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final profileImage = data?['profileImageUrl'] ?? '';
        _userProfileImages[userId] = profileImage;
        _userProfileImagesCache[userId] = profileImage; // Cache it
      } else {
        _userProfileImages[userId] = '';
        _userProfileImagesCache[userId] = ''; // Cache empty result
      }
    } catch (e) {
      print('Error loading profile image for user $userId: $e');
      _userProfileImages[userId] = '';
      _userProfileImagesCache[userId] = '';
    }
  }

  /// Enhanced send message with optimistic updates
  Future<void> sendMessage(String receiverId) async {
    final messageText = messageController.text.trim();
    if (messageText.isEmpty || currentUserId == null) return;

    if (_currentChatroomId == null) {
      try {
        _setState(ChatState.loading);
        _currentChatroomId = await _chatServices.getOrCreateChatroom(
          receiverId,
          'Private',
        );
        _listenToMessages(receiverId, _currentChatroomId!);
        _setState(ChatState.loaded);
      } catch (e) {
        _setError('Failed to create chatroom: ${e.toString()}');
        return;
      }
    }

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = Message(
      id: tempId,
      text: messageText,
      sender: currentUserId!,
      receiver: receiverId,
      sentOn: DateTime.now(),
      isRead: false,
    );

    // Optimistic update
    _messages.add(tempMessage);
    if (_currentChatroomId != null) {
      _messagesCache[_currentChatroomId!] = List.from(_messages);
    }
    messageController.clear();
    notifyListeners();

    try {
      // Send the actual message
      await _chatServices.sendMessage(
        chatroomId: _currentChatroomId!,
        text: messageText,
        receiverId: receiverId,
      );

      // Remove temp message (real message will come through stream)
      _messages.removeWhere((msg) => msg.id == tempId);
      if (_currentChatroomId != null) {
        _messagesCache[_currentChatroomId!] = List.from(_messages);
      }
      notifyListeners();

      // Send notification
      final receiverSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .get();

      if (receiverSnapshot.exists) {
        final data = receiverSnapshot.data();
        final isPushEnabled = data?['isPushNotificationEnabled'] ?? false;

        if (isPushEnabled == true) {
          await _sendNotificationToReceiver(receiverId, messageText);
        }
      }

    } catch (e) {
      // Remove temp message on error
      _messages.removeWhere((msg) => msg.id == tempId);
      if (_currentChatroomId != null) {
        _messagesCache[_currentChatroomId!] = List.from(_messages);
      }
      _setError('Failed to send message: ${e.toString()}');
    }
  }

  /// Send notification to message receiver
  Future<void> _sendNotificationToReceiver(String receiverId, String messageText) async {
    try {
      // Check if receiver is currently in this chatroom (optional optimization)
      if (_chatServices.isUserInChatroom(_currentChatroomId ?? '')) {
        print('Receiver is in chatroom, skipping notification');
        return;
      }

      // Get receiver's FCM token
      final receiverToken = await _notificationService.getUserFCMToken(receiverId);

      if (receiverToken != null && receiverToken.isNotEmpty) {
        // Get current user's name for notification
        String currentUserName = 'Someone';
        if (_userNamesCache.containsKey(currentUserId)) {
          currentUserName = _userNamesCache[currentUserId!]!;
        } else {
          final currentUserDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .get();
          currentUserName = currentUserDoc.data()?['fullName'] ?? 'Someone';
          _userNamesCache[currentUserId!] = currentUserName; // Cache it
        }

        // Send notification
        await _notificationService.sendNotificationToUser(
          receiverToken: receiverToken,
          title: currentUserName,
          body: messageText,
          data: {
            'type': 'Private',
            'chatroomId': _currentChatroomId,
            'senderId': currentUserId,
            'receiverId': receiverId,
            'message': messageText,
          },
        );

        print('Notification sent successfully to $receiverId');
      } else {
        print('No FCM token found for user $receiverId');
      }
    } catch (e) {
      print('Error sending notification: $e');
      // Don't throw error here as message was sent successfully
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String senderId) async {
    if (_currentChatroomId == null) return;

    try {
      await _chatServices.markMessagesAsRead(
        chatroomId: _currentChatroomId!,
        senderId: senderId,
      );
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  /// Get user chatrooms stream
  Stream<List<ChatRoom>> getUserChatrooms() {
    return _chatServices.getUserChatrooms();
  }

  /// Check if message is from current user
  bool isMessageFromCurrentUser(Message message) {
    return message.sender == currentUserId;
  }

  /// Get profile image for a user with caching
  String getUserProfileImage(String userId) {
    return _userProfileImagesCache[userId] ?? _userProfileImages[userId] ?? '';
  }

  /// Get cached messages for a chatroom
  List<Message> getCachedMessages(String chatroomId) {
    return _messagesCache[chatroomId] ?? [];
  }

  /// Check if chatroom has cached messages
  bool hasCachedMessages(String chatroomId) {
    return _messagesCache.containsKey(chatroomId) && _messagesCache[chatroomId]!.isNotEmpty;
  }

  /// Check if chatroom has valid cached messages (considering cache expiry)
  bool hasValidCachedMessages(String chatroomId) {
    return _messagesCache.containsKey(chatroomId) && 
           _messagesCache[chatroomId]!.isNotEmpty && 
           _isCacheValid(chatroomId);
  }

  /// Preload messages to ensure instant display
  Future<void> preloadMessagesForDisplay(String chatroomId) async {
    if (!_messagesCache.containsKey(chatroomId) || _messagesCache[chatroomId]!.isEmpty) {
      try {
        print('🚀 Preloading messages for instant display: $chatroomId');
        final snapshot = await _chatServices.getMessagesStream(chatroomId).first;
        await _updateMessagesCache(chatroomId, snapshot, isBackground: true);
        print('✅ Messages preloaded for instant display: ${snapshot.length} messages');
      } catch (e) {
        print('❌ Error preloading messages: $e');
      }
    }
  }

  /// Clear cache for a specific chatroom
  void clearChatroomCache(String chatroomId) {
    _messagesCache.remove(chatroomId);
    _lastMessageFetch.remove(chatroomId);
    _messageStreams[chatroomId]?.cancel();
    _messageStreams.remove(chatroomId);
  }

  /// Clear all cache
  void clearAllCache() {
    _messagesCache.clear();
    _userProfileImagesCache.clear();
    _userNamesCache.clear();
    _lastMessageFetch.clear();
    for (var stream in _messageStreams.values) {
      stream.cancel();
    }
    _messageStreams.clear();
    print('🗑️ All chat cache cleared');
  }

  /// Clear error and reset state
  void clearError() {
    _error = null;
    if (_state == ChatState.error) {
      _state = ChatState.loaded;
    }
    notifyListeners();
  }

  /// Set loading state
  void _setState(ChatState newState) {
    _state = newState;
    _error = null;
    notifyListeners();
  }

  /// Set error state
  void _setError(String errorMessage) {
    _state = ChatState.error;
    _error = errorMessage;
    notifyListeners();
  }

  /// Reset current chat state but maintain cache
  void resetCurrentChat() {
    // Don't cancel streams - let them continue for background updates
    _state = ChatState.loading;
    _error = null;
    _currentChatroomId = null;
    _messages.clear();
    _isLoadingMessages = false;
    _currentReceiverName = null;
    _currentReceiverId = null;
    _isInitialLoadComplete = false;
    messageController.clear();
    // Don't call notifyListeners if the widget tree is locked (during dispose)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  /// Full reset - only for complete cleanup (rarely used)
  void reset() {
    // Cancel current message stream only
    if (_currentChatroomId != null) {
      _messageStreams[_currentChatroomId]?.cancel();
      _messageStreams.remove(_currentChatroomId);
    }
    
    _state = ChatState.loading;
    _error = null;
    _currentChatroomId = null;
    _messages.clear();
    _userProfileImages.clear();
    _isLoadingMessages = false;
    _currentReceiverName = null;
    _currentReceiverId = null;
    _isInitialLoadComplete = false;
    messageController.clear();
    notifyListeners();
  }

  /// Override dispose to prevent singleton disposal
  @override
  void dispose() {
    // Don't dispose the singleton - it should persist
    // Only clean up resources when the app is completely terminated
    print('⚠️ ChatController dispose() called - ignoring for singleton');
    // Don't call super.dispose() to prevent actual disposal
  }

  /// Manual cleanup for app termination only
  void forceDispose() {
    messageController.dispose();
    _backgroundRefreshTimer?.cancel();
    for (var stream in _messageStreams.values) {
      stream.cancel();
    }
    _messageStreams.clear();
    super.dispose();
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
    required String receiverId,
    String? caption,
  }) async {
    final selectedFile = _selectedFile;
    final selectedFileType = _selectedFileType;
    
    if (selectedFile == null || selectedFileType == null) {
      return;
    }

    // Create chatroom if it doesn't exist yet
    if (_currentChatroomId == null) {
      try {
        _setState(ChatState.loading);
        _currentChatroomId = await _chatServices.getOrCreateChatroom(
          receiverId,
          'Private',
        );
        _listenToMessages(receiverId, _currentChatroomId!);
        _setState(ChatState.loaded);
      } catch (e) {
        _setError('Failed to create chatroom: ${e.toString()}');
        return;
      }
    }
    
    final chatroomId = _currentChatroomId;

    try {
      final messageText = caption?.isNotEmpty == true ? caption! : (selectedFileType == 'image' ? '📷 Image' : '🎥 Video');

      // Create unique message ID
      final messageId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${currentUserId}';

      // Show message immediately (optimistic) with uploading state
      final optimisticMessage = Message(
        id: messageId,
        text: selectedFile.path, // Use local file path for immediate preview
        sender: currentUserId!,
        receiver: receiverId,
        sentOn: DateTime.now(),
        isRead: false,
        messageType: selectedFileType,
      );

      // Add to chat immediately with upload state
      _messages.add(optimisticMessage);
      _messageUploadProgress[messageId] = 0.0;
      _optimisticToDocIdMapping[messageId] = selectedFile.path; // Store local file path
      if (chatroomId != null) {
        _messagesCache[chatroomId] = List.from(_messages);
      }
      notifyListeners();

      // Clear selected file
      clearSelectedFile();

      // Start upload in background
      await _uploadAndSendMedia(messageId, selectedFile, selectedFileType, messageText, receiverId);

    } catch (e) {
      print('❌ Error sending media message: $e');
    }
  }

  Future<void> _uploadAndSendMedia(
    String messageId,
    File file,
    String fileType,
    String messageText,
    String receiverId,
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
        await _chatServices.sendMessage(
          chatroomId: _currentChatroomId!,
          text: fileUrl,
          receiverId: receiverId,
          messageType: fileType,
          customLastMessage: formattedLastMessage,
        );

        // Remove optimistic message (real message will come through stream)
        _messages.removeWhere((msg) => msg.id == messageId);
        _messageUploadProgress.remove(messageId);
        _optimisticToDocIdMapping.remove(messageId);
        if (_currentChatroomId != null) {
          _messagesCache[_currentChatroomId!] = List.from(_messages);
        }
        notifyListeners();

        // Send notification
        await _sendNotificationToReceiver(receiverId, messageText);

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
      final fileName = '${timestamp}_${currentUserId}.$extension';

      // Create storage reference - using PrivateChatVideoImage folder as requested
      final storageRef = _storage.ref().child('PrivateChatVideoImage/$fileName');

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

  // Send a post to chat
  Future<void> sendPostToChat({
    required String receiverId,
    required String postId,
    required String postOwnerId,
  }) async {
    try {
      // Ensure chatroom exists or create one
      if (_currentChatroomId == null) {
        _setState(ChatState.loading);
        _currentChatroomId = await _chatServices.getOrCreateChatroom(
          receiverId,
          'Private',
        );
        _listenToMessages(receiverId, _currentChatroomId!);
        _setState(ChatState.loaded);
      }

      // Get current user name for formatted lastMessage
      final currentUserName = await _getCurrentUserName();
      final customLastMessage = '$currentUserName shared a post';

      // Send the post message
      await _chatServices.sendPostMessage(
        chatroomId: _currentChatroomId!,
        postId: postId,
        postOwnerId: postOwnerId,
        receiverId: receiverId,
        customLastMessage: customLastMessage,
      );

      // Send notification to receiver
      final receiverSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .get();

      if (receiverSnapshot.exists) {
        final data = receiverSnapshot.data();
        final isPushEnabled = data?['isPushNotificationEnabled'] ?? false;

        if (isPushEnabled == true) {
          await _sendNotificationToReceiver(receiverId, 'Shared a post with you');
        }
      }

      print('✅ Post shared successfully in chat');
    } catch (e) {
      _setError('Failed to share post: ${e.toString()}');
      print('❌ Error sharing post: $e');
    }
  }

  // Delete message with media cleanup
  Future<void> deleteMessage(String messageId) async {
    if (_currentChatroomId == null) return;

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
      await _chatServices.deleteMessage(_currentChatroomId!, messageId);

      // Remove from local list
      _messages.removeWhere((msg) => msg.id == messageId);
      if (_currentChatroomId != null) {
        _messagesCache[_currentChatroomId!] = List.from(_messages);
      }
      
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
}