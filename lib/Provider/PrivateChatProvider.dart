import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../Model/chatRoomModel.dart';
import '../Model/userModel.dart';
import '../core/const/app_images.dart';
import '../core/services/GroupChatService.dart';
import '../core/services/chat_Services.dart';
import '../core/services/firebase_services.dart';
import 'SignupProvider.dart';
import 'ChatProvider.dart';

class PrivateChatProvider with ChangeNotifier {
  static PrivateChatProvider? _instance;
  static PrivateChatProvider get instance {
    _instance ??= PrivateChatProvider._internal();
    return _instance!;
  }

  final ChatServices _chatServices = ChatServices();
  final FirebaseServices _firebaseServices = FirebaseServices.instance;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController groupDescriptionController = TextEditingController();

  int _selectedTabIndex = 0;
  bool isCreatingGroup = false;
  bool _showSearchBar = false;
  
  List<ChatModel> _privateChatsCache = [];
  List<ChatModel> _groupChatsCache = [];
  List<UserModel> _allUsersCache = [];
  List<UserModel> _connectedUsersCache = [];
  List<UserModel> _filteredUsers = [];
  List<UserModel> _selectedMembers = [];
  
  bool _isLoading = false;
  bool _isPrivateChatsLoading = false;
  bool _isGroupChatsLoading = false;
  bool _isInitialLoadComplete = false;
  bool _isPrefetchingData = false;
  
  String _searchQuery = '';
  
  StreamSubscription<QuerySnapshot>? _chatRoomsSubscription;
  StreamSubscription<List<UserModel>>? _usersSubscription;
  StreamSubscription<List<UserModel>>? _connectedUsersSubscription;
  StreamSubscription<QuerySnapshot>? _groupChatsSubscription;
  StreamSubscription<QuerySnapshot>? _userStatusSubscription;
  
  DateTime? _lastPrivateChatsFetch;
  DateTime? _lastGroupChatsFetch;
  DateTime? _lastUsersFetch;
  
  static const Duration _cacheValidityDuration = Duration(minutes: 5);
  static const Duration _backgroundRefreshInterval = Duration(minutes: 2);
  
  Timer? _backgroundRefreshTimer;
  
  final Map<String, List<ChatModel>> _preparedChatTiles = {};

  // Legacy getters for compatibility
  int get selectedTabIndex => _selectedTabIndex;
  List<ChatModel> get privateChats => _privateChatsCache;
  List<ChatModel> get groupChats => _groupChatsCache;
  bool get isLoading => _isLoading;
  bool get isPrivateChatsLoading => _isPrivateChatsLoading;
  bool get isGroupChatsLoading => _isGroupChatsLoading;
  bool get isInitialLoadComplete => _isInitialLoadComplete;
  bool get isPrefetchingData => _isPrefetchingData;
  List<UserModel> get allUsers => _searchQuery.isEmpty ? _allUsersCache : _filteredUsers;
  List<UserModel> get connectedUsers => _searchQuery.isEmpty ? _connectedUsersCache : _filteredUsers;
  String get currentUserId => _chatServices.currentUserId;
  List<UserModel> get selectedMembers => _selectedMembers;
  String get searchQuery => _searchQuery;
  bool get showSearchBar => _showSearchBar;

  // Constructor for singleton pattern
  PrivateChatProvider._internal() {
    _startBackgroundRefresh();
  }

  // Factory constructor for backward compatibility
  factory PrivateChatProvider() {
    return instance;
  }

  // Prefetch all data when app starts
  Future<void> prefetchAllData() async {
    if (_isPrefetchingData || _isInitialLoadComplete) return;
    
    _isPrefetchingData = true;
    print('🚀 Starting prefetch of all chat data...');
    
    try {
      await Future.wait([
        _prefetchPrivateChats(),
        _prefetchGroupChats(),
        _prefetchUsers(),
      ]);
      
      _isInitialLoadComplete = true;
      _prepareChatTiles();
      print('✅ Prefetch complete! Data is cached and ready.');
    } catch (e) {
      print('❌ Error during prefetch: $e');
    } finally {
      _isPrefetchingData = false;
      notifyListeners();
    }
  }

  void _prepareChatTiles() {
    _preparedChatTiles['private'] = List.from(_privateChatsCache);
    _preparedChatTiles['group'] = List.from(_groupChatsCache);
    print('📦 Chat tiles prepared for instant rendering');
  }

  Future<void> _prefetchPrivateChats() async {
    if (currentUserId.isEmpty) return;
    
    if (_isCacheValid(_lastPrivateChatsFetch)) {
      print('✨ Using cached private chats');
      return;
    }
    
    try {
      final snapshot = await _chatServices.getPrivateChatRoomsStream().first;
      await _processPrivateChats(snapshot.docs, isBackground: true);
      _lastPrivateChatsFetch = DateTime.now();
      print('✅ Private chats prefetched: ${_privateChatsCache.length} chats');
    } catch (e) {
      print('❌ Error prefetching private chats: $e');
    }
  }

  Future<void> _prefetchGroupChats() async {
    if (currentUserId.isEmpty) return;
    
    if (_isCacheValid(_lastGroupChatsFetch)) {
      print('✨ Using cached group chats');
      return;
    }
    
    try {
      final snapshot = await GroupChatService.getUserGroupChatRoomsStream().first;
      await _processGroupChats(snapshot.docs, isBackground: true);
      _lastGroupChatsFetch = DateTime.now();
      print('✅ Group chats prefetched: ${_groupChatsCache.length} chats');
    } catch (e) {
      print('❌ Error prefetching group chats: $e');
    }
  }

  Future<void> _prefetchUsers() async {
    if (_isCacheValid(_lastUsersFetch)) {
      print('✨ Using cached users');
      return;
    }
    
    try {
      final users = await _firebaseServices.getAllUsersStream().first;
      _allUsersCache = users;
      _filteredUsers = users;
      _lastUsersFetch = DateTime.now();
      print('✅ Users prefetched: ${_allUsersCache.length} users');
    } catch (e) {
      print('❌ Error prefetching users: $e');
    }
  }

  bool _isCacheValid(DateTime? lastFetch) {
    if (lastFetch == null) return false;
    return DateTime.now().difference(lastFetch) < _cacheValidityDuration;
  }

  void _startBackgroundRefresh() {
    _backgroundRefreshTimer?.cancel();
    _backgroundRefreshTimer = Timer.periodic(_backgroundRefreshInterval, (_) {
      _silentRefreshData();
    });
  }

  Future<void> _silentRefreshData() async {
    if (!_isInitialLoadComplete) return;
    
    print('🔄 Silent background refresh started...');
    
    try {
      await Future.wait([
        _silentRefreshPrivateChats(),
        _silentRefreshGroupChats(),
      ]);
      _prepareChatTiles();
    } catch (e) {
      print('❌ Error in background refresh: $e');
    }
  }

  Future<void> _silentRefreshPrivateChats() async {
    if (currentUserId.isEmpty) return;
    
    try {
      final snapshot = await _chatServices.getPrivateChatRoomsStream().first;
      await _processPrivateChats(snapshot.docs, isBackground: true);
      _lastPrivateChatsFetch = DateTime.now();
    } catch (e) {
      print('❌ Silent refresh private chats error: $e');
    }
  }

  Future<void> _silentRefreshGroupChats() async {
    if (currentUserId.isEmpty) return;
    
    try {
      final snapshot = await GroupChatService.getUserGroupChatRoomsStream().first;
      await _processGroupChats(snapshot.docs, isBackground: true);
      _lastGroupChatsFetch = DateTime.now();
    } catch (e) {
      print('❌ Silent refresh group chats error: $e');
    }
  }

  // Initialize streams with caching support
  void initializeStreams() {
    if (currentUserId.isEmpty) return;
    
    _initializePrivateChatsStream();
    _initializeGroupChatsStream();
    _initializeUsersStream();
    _initializeConnectedUsersStream();
    _initializeUserStatusListener();
  }

  void _initializePrivateChatsStream() {
    _chatRoomsSubscription?.cancel();
    
    if (_privateChatsCache.isNotEmpty) {
      print('✨ Using cached private chats for instant display');
      notifyListeners();
    } else {
      _isPrivateChatsLoading = true;
      notifyListeners();
    }
    
    _chatRoomsSubscription = _chatServices
        .getPrivateChatRoomsStream()
        .listen((snapshot) {
      _processPrivateChats(snapshot.docs);
      print('🔄 Private chats stream update: ${snapshot.docs.length} documents');
    });
  }

  void _initializeGroupChatsStream() {
    _groupChatsSubscription?.cancel();
    
    if (_groupChatsCache.isNotEmpty) {
      print('✨ Using cached group chats for instant display');
      notifyListeners();
    } else {
      _isGroupChatsLoading = true;
      notifyListeners();
    }
    
    _groupChatsSubscription = GroupChatService
        .getUserGroupChatRoomsStream()
        .listen((snapshot) {
      _processGroupChats(snapshot.docs);
      print('🔄 Group chats stream update: ${snapshot.docs.length} documents');
    }, onError: (error) {
      print('❌ Error loading group chats: $error');
      _isGroupChatsLoading = false;
      notifyListeners();
    });
  }

  void _initializeUsersStream() {
    if (_allUsersCache.isNotEmpty) {
      print('✨ Using cached users');
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    _usersSubscription = _firebaseServices.getAllUsersStream().listen(
      (users) {
        _allUsersCache = users;
        _filteredUsers = users;
        _isLoading = false;
        _lastUsersFetch = DateTime.now();
        notifyListeners();
        print('✅ Users loaded: ${users.length}');
      },
      onError: (error) {
        print('❌ Error loading users: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _initializeConnectedUsersStream() {
    _connectedUsersSubscription?.cancel();
    
    if (currentUserId.isEmpty) return;
    
    if (_connectedUsersCache.isNotEmpty) {
      print('✨ Using cached connected users');
      notifyListeners();
    }
    
    _connectedUsersSubscription = _firebaseServices.getConnectedUsersStream(currentUserId).listen(
      (connectedUsers) {
        _connectedUsersCache = connectedUsers;
        // Update filtered users if there's a search query
        if (_searchQuery.isNotEmpty) {
          _filteredUsers = connectedUsers.where((user) => 
            user.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }
        notifyListeners();
        print('✅ Connected users loaded: ${connectedUsers.length}');
      },
      onError: (error) {
        print('❌ Error loading connected users: $error');
        notifyListeners();
      },
    );
  }

  void _initializeUserStatusListener() {
    _userStatusSubscription?.cancel();
    
    // Get list of user IDs from current chat list
    final chatUserIds = _privateChatsCache
        .where((chat) => chat.otherUserId != null)
        .map((chat) => chat.otherUserId!)
        .toSet()
        .toList();
    
    if (chatUserIds.isEmpty) {
      print('📱 No chat users to listen for status updates');
      return;
    }
    
    // Listen to specific users' status changes in real-time
    // Firebase whereIn has a limit of 10, so we batch if needed
    final batches = <List<String>>[];
    for (int i = 0; i < chatUserIds.length; i += 10) {
      batches.add(chatUserIds.sublist(i, (i + 10).clamp(0, chatUserIds.length)));
    }
    
    // For now, use the first batch (most common scenario)
    final userIdsToListen = batches.isNotEmpty ? batches[0] : <String>[];
    
    if (userIdsToListen.isNotEmpty) {
      _userStatusSubscription = FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIdsToListen)
          .snapshots()
          .listen((snapshot) {
        _updateChatStatusFromUserChanges(snapshot.docChanges);
      }, onError: (error) {
        print('❌ Error listening to user status changes: $error');
      });
      
      print('📱 Listening to status changes for ${userIdsToListen.length} chat users');
    }
  }

  void _updateChatStatusFromUserChanges(List<DocumentChange> changes) {
    bool hasUpdates = false;
    
    for (var change in changes) {
      if (change.type == DocumentChangeType.modified) {
        final userData = change.doc.data() as Map<String, dynamic>;
        final userId = change.doc.id;
        final newStatus = userData['status'] ?? 'offline';
        final newActivityStatus = userData['appSettings'] != null 
            ? (userData['appSettings']['activityStatus'] ?? true)
            : true;
        
        // Update private chats with this user
        for (int i = 0; i < _privateChatsCache.length; i++) {
          if (_privateChatsCache[i].otherUserId == userId) {
            _privateChatsCache[i] = _privateChatsCache[i].copyWith(
              status: newStatus,
              activityStatus: newActivityStatus,
            );
            hasUpdates = true;
          }
        }
      }
    }
    
    if (hasUpdates) {
      print('📱 Real-time status updated for chat list');
      notifyListeners();
    }
  }

  // Legacy initialization methods for backward compatibility
  void _initializePrivateChats() {
    _initializePrivateChatsStream();
  }

  void _initializeGroupChats() {
    _initializeGroupChatsStream();
  }

  Future<void> _processPrivateChats(List<QueryDocumentSnapshot> docs, {bool isBackground = false}) async {
    List<ChatModel> newChats = [];
    final chatController = ChatController.instance;
    
    for (var doc in docs) {
      final chatData = await _chatServices.processChatRoomDocument(doc);
      
      if (chatData != null && chatData['lastMessage'] != null && chatData['lastMessage'].toString().isNotEmpty) {
        // Only add chatrooms that have at least one message
        ChatModel chatModel = ChatModel(
          status: chatData['status'],
          id: chatData['id'],
          name: chatData['name'],
          lastMessage: chatData['lastMessage'],
          profileImage: chatData['profileImage'].isNotEmpty
              ? chatData['profileImage']
              : AppImages.profileImage,
          time: chatData['time'],
          isOnline: chatData['isOnline'],
          activityStatus: chatData['activityStatus'] ?? true,
          otherUserId: chatData['otherUserId'],
          lastMessageTime: chatData['sentOn'] is Timestamp
              ? (chatData['sentOn'] as Timestamp).toDate()
              : chatData['sentOn'] as DateTime?,
        );
        
        newChats.add(chatModel);
        
        // Prefetch chat messages and user profile for faster ChatScreen loading
        if (chatModel.id?.isNotEmpty == true && chatModel.otherUserId?.isNotEmpty == true) {
          _prefetchChatData(chatModel.id!, chatModel.otherUserId!, isBackground: isBackground);
        }
      }
    }
    
    newChats.sort((a, b) =>
        b.lastMessageTime?.compareTo(a.lastMessageTime ?? DateTime.now()) ?? 0);
    
    _privateChatsCache = newChats;
    _isPrivateChatsLoading = false;
    _isLoading = false;
    _lastPrivateChatsFetch = DateTime.now();
    
    // Reinitialize status listener for new chat users
    _initializeUserStatusListener();
    
    if (!isBackground) {
      notifyListeners();
    }
  }

  Future<void> _processGroupChats(List<QueryDocumentSnapshot> docs, {bool isBackground = false}) async {
    List<ChatModel> newGroupChats = [];
    
    for (var doc in docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        
        ChatModel groupChatModel = ChatModel(
          status: 'group', // Groups don't have online/offline status
          id: data['id'] ?? doc.id,
          name: data['groupName'] ?? 'Unnamed Group',
          lastMessage: data['lastMessage'] ?? 'No messages yet',
          profileImage: data['groupImageUrl']?.isNotEmpty == true
              ? data['groupImageUrl']
              : AppImages.profileImage,
          time: _formatTime(data['sentOn']),
          isOnline: true,
          otherUserId: '',
          lastMessageTime: data['sentOn'] is Timestamp
              ? (data['sentOn'] as Timestamp).toDate()
              : data['sentOn'] as DateTime?,
        );
        
        newGroupChats.add(groupChatModel);
        print('✅ Processed group: ${groupChatModel.name}');
      } catch (e) {
        print('❌ Error processing group doc ${doc.id}: $e');
      }
    }
    
    newGroupChats.sort((a, b) =>
        b.lastMessageTime?.compareTo(a.lastMessageTime ?? DateTime.now()) ?? 0);
    
    _groupChatsCache = newGroupChats;
    _isGroupChatsLoading = false;
    _isLoading = false;
    _lastGroupChatsFetch = DateTime.now();
    
    if (!isBackground) {
      notifyListeners();
    }
    
    print('✅ Total groups loaded: ${_groupChatsCache.length}');
  }

  String _formatTime(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return '';
      }
      
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      print('❌ Error formatting time: $e');
      return '';
    }
  }

  void setSelectedTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  List<ChatModel> getCurrentChatList() {
    switch (_selectedTabIndex) {
      case 0:
        return _privateChatsCache;
      case 1:
        return _groupChatsCache;
      default:
        return _privateChatsCache;
    }
  }

  List<ChatModel> getCachedChatList(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return _preparedChatTiles['private'] ?? _privateChatsCache;
      case 1:
        return _preparedChatTiles['group'] ?? _groupChatsCache;
      default:
        return [];
    }
  }

  bool isCurrentTabLoading() {
    if (_isInitialLoadComplete) {
      return false;
    }
    
    switch (_selectedTabIndex) {
      case 0:
        return _privateChatsCache.isEmpty && _isPrivateChatsLoading;
      case 1:
        return _groupChatsCache.isEmpty && _isGroupChatsLoading;
      case 2:
        return false;
      default:
        return false;
    }
  }

  Future<void> refreshPrivateChats() async {
    if (currentUserId.isEmpty) return;
    
    if (_privateChatsCache.isEmpty) {
      _isPrivateChatsLoading = true;
      _isLoading = true;
      notifyListeners();
    }
    
    _chatRoomsSubscription?.cancel();
    await _silentRefreshPrivateChats();
    _initializePrivateChatsStream();
    _prepareChatTiles();
    notifyListeners();
  }

  Future<void> refreshGroupChats() async {
    if (currentUserId.isEmpty) return;
    
    if (_groupChatsCache.isEmpty) {
      _isGroupChatsLoading = true;
      _isLoading = true;
      notifyListeners();
    }
    
    _groupChatsSubscription?.cancel();
    await _silentRefreshGroupChats();
    _initializeGroupChatsStream();
    _prepareChatTiles();
    notifyListeners();
  }

  void searchUsers(String query) {
    _searchQuery = query.toLowerCase();
    
    if (_searchQuery.isEmpty) {
      _filteredUsers = _allUsersCache;
    } else {
      _filteredUsers = _allUsersCache.where((user) {
        final name = user.fullName?.toLowerCase() ?? '';
        final email = user.email?.toLowerCase() ?? '';
        final nationality = user.nationality?.toLowerCase() ?? '';
        
        return name.contains(_searchQuery) ||
            email.contains(_searchQuery) ||
            nationality.contains(_searchQuery);
      }).toList();
    }
    
    notifyListeners();
    print('🔍 Search results: ${_filteredUsers.length} users found for "$query"');
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredUsers = _allUsersCache;
    notifyListeners();
  }

  void toggleSearchBar() {
    _showSearchBar = !_showSearchBar;
    if (!_showSearchBar) {
      searchController.clear();
      clearSearch();
    }
    notifyListeners();
  }

  void toggleMemberSelection(UserModel user) {
    if (_selectedMembers.any((member) => member.uid == user.uid)) {
      _selectedMembers.removeWhere((member) => member.uid == user.uid);
      print('🔴 Removed ${user.fullName} from selected members');
    } else {
      _selectedMembers.add(user);
      print('🟢 Added ${user.fullName} to selected members');
    }
    notifyListeners();
  }

  bool isMemberSelected(UserModel user) {
    return _selectedMembers.any((member) => member.uid == user.uid);
  }

  void clearSelectedMembers() {
    _selectedMembers.clear();
    notifyListeners();
  }

  void removeMemberFromSelection(UserModel user) {
    _selectedMembers.removeWhere((member) => member.uid == user.uid);
    notifyListeners();
  }

  Future<Map<String, dynamic>> addMembersToGroup(String groupChatroomId) async {
    if (selectedMembers.isEmpty) {
      return {
        'success': false,
        'message': 'Please select at least one member to add'
      };
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      List<String> newMemberIds = selectedMembers
          .map((member) => member.uid)
          .toList();
      
      List<String> newMemberNames = selectedMembers
          .map((member) => member.fullName ?? 'Unknown User')
          .toList();
      
      List<String> existingMembers = await GroupChatService.getGroupMembers(groupChatroomId);
      List<String> membersToAdd = [];
      List<String> namesToAdd = [];
      
      for (int i = 0; i < newMemberIds.length; i++) {
        if (!existingMembers.contains(newMemberIds[i])) {
          membersToAdd.add(newMemberIds[i]);
          namesToAdd.add(newMemberNames[i]);
        }
      }
      
      if (membersToAdd.isEmpty) {
        return {
          'success': false,
          'message': 'All selected members are already in the group'
        };
      }
      
      bool success = await GroupChatService.addMembersToGroup(
        groupChatRoomId: groupChatroomId,
        userIds: membersToAdd,
        userNames: namesToAdd,
      );
      
      if (success) {
        clearSelectedMembers();
        clearSearch();
        
        return {
          'success': true,
          'message': '${membersToAdd.length} member(s) added successfully!'
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to add members. Please try again.'
        };
      }
    } catch (e) {
      print('❌ Error adding members to group: $e');
      return {
        'success': false,
        'message': 'Error adding members: ${e.toString()}'
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> createGroupChat(SignupProvider signupProvider) async {
    if (groupNameController.text.trim().isEmpty) {
      return {
        'success': false,
        'message': 'Please enter a group name'
      };
    }
    
    if (selectedMembers.isEmpty) {
      return {
        'success': false,
        'message': 'Please select at least one member'
      };
    }
    
    isCreatingGroup = true;
    notifyListeners();
    
    try {
      List<String> participantIds = selectedMembers
          .map((member) => member.uid)
          .toList();
      
      String groupType = selectedTabIndex == 0 ? 'public' : 'private';
      
      String? groupChatRoomId = await GroupChatService.createGroupChatRoom(
        groupName: groupNameController.text.trim(),
        groupDescription: groupDescriptionController.text.trim(),
        groupType: groupType,
        participantsList: participantIds,
        groupImage: signupProvider.profileImage,
      );
      
      if (groupChatRoomId != null) {
        _clearFormData(signupProvider);
        
        await refreshGroupChats();
        
        return {
          'success': true,
          'message': 'Group "${groupNameController.text.trim()}" created successfully!',
          'groupId': groupChatRoomId
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create group. Please try again.'
        };
      }
    } catch (e) {
      print('❌ Group creation error: $e');
      return {
        'success': false,
        'message': 'Error creating group: ${e.toString()}'
      };
    } finally {
      isCreatingGroup = false;
      notifyListeners();
    }
  }

  void _clearFormData(SignupProvider signupProvider) {
    groupNameController.clear();
    groupDescriptionController.clear();
    searchController.clear();
    signupProvider.notifyListeners();
    clearSelectedMembers();
    clearSearch();
    setSelectedTab(0);
  }

  void clearForm(SignupProvider signupProvider) {
    _clearFormData(signupProvider);
  }

  /// Prefetch chat messages and user profile for faster ChatScreen loading
  Future<void> _prefetchChatData(String chatroomId, String otherUserId, {bool isBackground = false}) async {
    try {
      final chatController = ChatController.instance;
      
      // Prefetch user profile data
      await chatController.prefetchUserProfile(otherUserId);
      
      // Prefetch chat messages
      await chatController.prefetchChatMessages(chatroomId);
      
      if (!isBackground) {
        print('✅ Prefetched chat data for chatroom: $chatroomId, user: $otherUserId');
      }
    } catch (e) {
      print('❌ Error prefetching chat data: $e');
    }
  }

  /// Prefetch chat data for all visible chats
  Future<void> prefetchAllChatData() async {
    print('🚀 Starting prefetch of all chat data...');
    
    try {
      final chatController = ChatController.instance;
      
      // Prefetch for private chats
      for (final chat in _privateChatsCache) {
        if (chat.id?.isNotEmpty == true && chat.otherUserId?.isNotEmpty == true) {
          await _prefetchChatData(chat.id!, chat.otherUserId!, isBackground: true);
        }
      }
      
      print('✅ Completed prefetching chat data for ${_privateChatsCache.length} chats');
    } catch (e) {
      print('❌ Error in bulk chat data prefetch: $e');
    }
  }

  void invalidateCache() {
    _lastPrivateChatsFetch = null;
    _lastGroupChatsFetch = null;
    _lastUsersFetch = null;
    print('🗑️ Cache invalidated');
  }

  /// Override dispose to prevent singleton disposal
  @override
  void dispose() {
    // Don't dispose the singleton - it should persist
    // Only clean up resources when the app is completely terminated
    print('⚠️ PrivateChatProvider dispose() called - ignoring for singleton');
    // Don't call super.dispose() to prevent actual disposal
  }

  /// Manual cleanup for app termination only
  void forceDispose() {
    searchController.dispose();
    groupNameController.dispose();
    groupDescriptionController.dispose();
    _chatRoomsSubscription?.cancel();
    _usersSubscription?.cancel();
    _connectedUsersSubscription?.cancel();
    _groupChatsSubscription?.cancel();
    _userStatusSubscription?.cancel();
    _backgroundRefreshTimer?.cancel();
    super.dispose();
  }
}