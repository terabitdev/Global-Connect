import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../Model/localEvenModel.dart';
import '../Model/userModel.dart';
import '../core/services/firebase_services.dart';
import '../core/services/NotificationService/NotificationService.dart';

class LocalChatProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _localGroupChats = [];
  List<Map<String, dynamic>> _currentChatMessages = [];
  bool _isLoading = false;
  bool _isManagingGroups = false;
  bool _shouldKeepKeyboardOpen = false;
  bool _hasMoreMessages = true;
  int _messagesLimit = 20;
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  Set<String> _pendingMessages = {};
  final Map<String, Map<String, dynamic>> _userDataCache = {};
  String? _currentChatId;
  String? _currentUserCity;
  String? _previousUserCity;
  String? _errorMessage;
  String? _currentGroupName;
  String? _currentGroupId;
  String _chatFilterMode = 'Global';
  String? _currentUserNationality;
  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  StreamSubscription<QuerySnapshot>? _groupChatsSubscription;
  StreamSubscription<DocumentSnapshot>? _userLocationSubscription;
  StreamSubscription<List<LocalEventModel>>? _eventsSubscription;
  Timer? _locationCheckTimer;
  Map<String, StreamSubscription<DocumentSnapshot>> _nationalityListeners = {};
  bool get hasMessageText => _hasMessageText;

  // UI State Management
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _shouldAutoScroll = true;
  String? _displayCityName;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // File upload state
  File? _selectedFile;
  String? _selectedFileType;
  bool _isUploadingFile = false;
  double _uploadProgress = 0.0;
  Map<String, bool> _messageRetryStatus = {};
  // Map<String, double> _messageUploadProgress = {}; // deprecated, not used
  Map<String, String> _optimisticToDocIdMapping = {};

  // Notification service
  final NotificationService _notificationService = NotificationService.instance;

  // Getters
  List<Map<String, dynamic>> get localGroupChats => _localGroupChats;
  List<Map<String, dynamic>> get currentChatMessages => _currentChatMessages;
  List<LocalEventModel> _currentEvents = [];
  List<dynamic> get currentTimelineItems => _buildCombinedTimeline();
  bool get isLoading => _isLoading;
  bool get isManagingGroups => _isManagingGroups;
  bool get shouldKeepKeyboardOpen => _shouldKeepKeyboardOpen;
  bool get hasMoreMessages => _hasMoreMessages;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasPendingMessages => _pendingMessages.isNotEmpty;
  String? get currentChatId => _currentChatId;
  String? get currentUserCity => _currentUserCity;
  String? get errorMessage => _errorMessage;
  String get currentUserId => _auth.currentUser?.uid ?? '';
  String? get currentGroupName => _currentGroupName;
  String? get currentGroupId => _currentGroupId;
  bool _hasMessageText = false;

  // UI State Getters
  ScrollController get scrollController => _scrollController;
  TextEditingController get messageController => _messageController;
  FocusNode get messageFocusNode => _messageFocusNode;
  String get displayCityName => _displayCityName ?? _currentUserCity ?? 'Local Chat';
  String get chatFilterMode => _chatFilterMode;
  String? get currentUserNationality => _currentUserNationality;
  File? get selectedFile => _selectedFile;
  String? get selectedFileType => _selectedFileType;
  bool get isUploadingFile => _isUploadingFile;
  double get uploadProgress => _uploadProgress;

  // Initialize automatic group management
  Future<void> initializeGroupManagement() async {
    try {
      print('🚀 Initializing automatic group management...');

      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No user logged in');
        return;
      }

      // Setup message controller listener
      setupMessageControllerListener();

      await _loadCurrentUserCity();
      await _loadCurrentUserNationality();
      _listenToUserLocationChanges();
      _startPeriodicLocationCheck();
      loadLocalGroupChats();

      // Pre-load chat messages for user's city if available
      if (_currentUserCity != null && _currentUserCity!.isNotEmpty) {
        await _preloadChatForUserCity();
      }

      print('✅ Group management initialized successfully');
    } catch (e) {
      print('❌ Error initializing group management: $e');
      _errorMessage = 'Failed to initialize: $e';
      notifyListeners();
    }
  }
  void setupMessageControllerListener() {
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (_hasMessageText != hasText) {
        _hasMessageText = hasText;
        notifyListeners();
      }
    });
  }
  // Start periodic location checking
  void _startPeriodicLocationCheck() {
    _locationCheckTimer?.cancel();
    _locationCheckTimer = Timer.periodic(
      const Duration(minutes: 3),
          (timer) => _checkAndUpdateLocationBasedGroups(),
    );
    print('⏰ Started periodic location check');
  }

  // Stop periodic location checking
  void _stopPeriodicLocationCheck() {
    _locationCheckTimer?.cancel();
    _locationCheckTimer = null;
    print('⏹️ Stopped periodic location check');
  }

  // Listen to user's location and nationality changes in Firestore
  void _listenToUserLocationChanges() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _userLocationSubscription?.cancel();
    _userLocationSubscription = _firestore
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .listen(
          (DocumentSnapshot userDoc) {
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          // Handle location changes
          double? latitude = userData['latitude']?.toDouble();
          double? longitude = userData['longitude']?.toDouble();

          if (latitude != null && longitude != null) {
            _checkLocationAndUpdateGroups(latitude, longitude);
          }
          
          // Handle nationality changes
          String? newNationality = userData['nationality'];
          if (newNationality != _currentUserNationality) {
            print('🏳️ Current user nationality changed from $_currentUserNationality to $newNationality');
            _currentUserNationality = newNationality;
            
            // Invalidate user cache for current user
            _userDataCache.remove(currentUser.uid);
            
            // Re-filter messages if in Countrymen mode
            if (_chatFilterMode == 'Countrymen') {
              print('🔄 Re-filtering messages due to nationality change');
              _refilterMessages();
            }
          }
        }
      },
      onError: (error) {
        print('❌ Error listening to user location/nationality changes: $error');
      },
    );
  }

  // Load current user's city from Firestore
  Future<void> _loadCurrentUserCity() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        double? latitude = userData['latitude']?.toDouble();
        double? longitude = userData['longitude']?.toDouble();

        if (latitude != null && longitude != null) {
          String? cityFromCoordinates = await _getCityFromCoordinates(latitude, longitude);
          if (cityFromCoordinates != null) {
            _currentUserCity = cityFromCoordinates;
            print('🏠 Current user city: $_currentUserCity');

            // Ensure user is in the correct group
            await _ensureUserInCorrectGroup();
          }
        }
      }
    } catch (e) {
      print('❌ Error loading current user city: $e');
    }
  }

  // Load current user's nationality for Countrymen filter
  Future<void> _loadCurrentUserNationality() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No current user found for nationality loading');
        return;
      }

      print('🔍 Loading nationality for user: ${currentUser.uid}');
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        _currentUserNationality = userData['nationality'];
        print('✅ Current user nationality loaded: $_currentUserNationality');
        print('📋 Full user data: $userData');
      } else {
        print('❌ User document does not exist for: ${currentUser.uid}');
      }
    } catch (e) {
      print('❌ Error loading user nationality: $e');
    }
  }

  // Pre-load chat messages for user's current city
  Future<void> _preloadChatForUserCity() async {
    try {
      if (_currentUserCity == null || _currentUserCity!.isEmpty) return;

      print('🚀 Pre-loading chat for user city: $_currentUserCity');

      // Set current chat context first
      _currentChatId = _currentUserCity;
      _currentGroupId = _currentUserCity;
      _currentGroupName = _currentUserCity;

      // Load initial messages without blocking UI
      await _loadInitialMessages(_currentUserCity!).catchError((e) {
        print('⚠️ Pre-load messages failed, will retry when screen opens: $e');
        return Future.value();
      });

      // Start listening to new messages
      _listenToLocalEvents(_currentUserCity!);

      print('✅ Pre-loaded ${_currentChatMessages.length} messages for $_currentUserCity');
    } catch (e) {
      print('❌ Error pre-loading chat for user city: $e');
    }
  }

  // Check location and update groups
  Future<void> _checkLocationAndUpdateGroups(double latitude, double longitude) async {
    try {
      String? cityFromCoordinates = await _getCityFromCoordinates(latitude, longitude);

      if (cityFromCoordinates != null &&
          cityFromCoordinates != _currentUserCity &&
          cityFromCoordinates.isNotEmpty &&
          cityFromCoordinates != 'Unknown City') {

        print('🗺️ City change detected: $_currentUserCity → $cityFromCoordinates');
        await _handleCityChange(cityFromCoordinates);
      }
    } catch (e) {
      print('❌ Error checking location and updating groups: $e');
    }
  }

  // Check and update location-based groups
  Future<void> _checkAndUpdateLocationBasedGroups() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get current user data from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) return;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      double? latitude = userData['latitude']?.toDouble();
      double? longitude = userData['longitude']?.toDouble();

      if (latitude == null || longitude == null) return;

      // Check if coordinates have city
      await _checkLocationAndUpdateGroups(latitude, longitude);
    } catch (e) {
      print('❌ Error checking location-based groups: $e');
    }
  }

  // Get city name from coordinates
  Future<String?> _getCityFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String? city = placemark.locality ?? placemark.subAdministrativeArea ?? placemark.administrativeArea;
        return city?.trim();
      }
    } catch (e) {
      print('❌ Error getting city from coordinates: $e');
    }
    return null;
  }

  // Handle city change
  Future<void> _handleCityChange(String newCity) async {
    try {
      _previousUserCity = _currentUserCity;
      _currentUserCity = newCity;

      print('🏙️ Handling city change: $_previousUserCity → $_currentUserCity');

      await _manageGroupMembershipOnCityChange();

      // Pre-load chat for new city
      if (_currentUserCity != null && _currentUserCity!.isNotEmpty) {
        await _preloadChatForUserCity();
      }

      // The stream will automatically update the UI with new data
      notifyListeners();
    } catch (e) {
      print('❌ Error handling city change: $e');
    }
  }

  // Ensure user is in correct group
  Future<void> _ensureUserInCorrectGroup() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null || _currentUserCity == null) return;

      // Check if user is already in the current city group
      DocumentSnapshot cityGroupDoc = await _firestore
          .collection('localgroupchat')
          .doc(_currentUserCity!)
          .get();

      if (cityGroupDoc.exists) {
        Map<String, dynamic> groupData = cityGroupDoc.data() as Map<String, dynamic>;
        List<dynamic> participants = groupData['participantsList'] ?? [];

        if (!participants.contains(currentUser.uid)) {
          // User not in group, add them
          await _addUserToCityGroup(_currentUserCity!, currentUser.uid);
        }
      } else {
        // Group doesn't exist, create it
        await _addUserToCityGroup(_currentUserCity!, currentUser.uid);
      }
    } catch (e) {
      print('❌ Error ensuring user in correct group: $e');
    }
  }

  // Manage group membership when city changes
  Future<void> _manageGroupMembershipOnCityChange() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      _isManagingGroups = true;
      notifyListeners();

      print('🏘️ Managing group membership: $_previousUserCity → $_currentUserCity');

      // Remove from previous city group
      if (_previousUserCity != null &&
          _previousUserCity!.isNotEmpty &&
          _previousUserCity != 'Unknown City' &&
          _previousUserCity != _currentUserCity) {
        await _removeUserFromCityGroup(_previousUserCity!, currentUser.uid);
      }

      // Add to new city group
      if (_currentUserCity != null &&
          _currentUserCity!.isNotEmpty &&
          _currentUserCity != 'Unknown City') {
        await _addUserToCityGroup(_currentUserCity!, currentUser.uid);
      }
    } catch (e) {
      print('❌ Error managing group membership: $e');
      _errorMessage = 'Failed to manage group membership: $e';
    } finally {
      _isManagingGroups = false;
      notifyListeners();
    }
  }

  // Add user to city group
  Future<void> _addUserToCityGroup(String cityName, String userId) async {
    try {
      print('🏘️ Adding user to city group: $cityName');

      // FIRST: Remove user from ALL other city groups
      await _removeUserFromAllOtherCityGroups(cityName, userId);

      // Get user data
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String userName = userData['fullName'] ?? 'Unknown User';

      // Reference to the city group document
      DocumentReference cityGroupRef = _firestore.collection('localgroupchat').doc(cityName);

      // Check if group exists
      DocumentSnapshot cityGroupSnapshot = await cityGroupRef.get();

      if (!cityGroupSnapshot.exists) {
        // Create new city group with exact structure from image
        await cityGroupRef.set({
          'id': cityName,
          'isActive': true,
          'lastMessage': 'Welcome to $cityName group chat!',
          'participantsList': [userId],
          'sentOn': FieldValue.serverTimestamp(),
        });

        print('✅ Created new city group for: $cityName');
        // Removed system message creation to avoid duplicates

      } else {
        // Add user to existing group if not already present
        Map<String, dynamic> groupData = cityGroupSnapshot.data() as Map<String, dynamic>;
        List<dynamic> participants = groupData['participantsList'] ?? [];

        if (!participants.contains(userId)) {
          participants.add(userId);

          await cityGroupRef.update({
            'participantsList': participants,
            'lastMessage': '$userName joined the $cityName group',
            'sentOn': FieldValue.serverTimestamp(),
            'isActive': true,
          });

          // Removed join system message to avoid unnecessary system messages

          print('✅ Added user to existing city group: $cityName');
        } else {
          print('ℹ️ User already in city group: $cityName');
        }
      }
    } catch (e) {
      print('❌ Error adding user to city group: $e');
    }
  }

  // Remove user from all other city groups (except the target city)
  Future<void> _removeUserFromAllOtherCityGroups(String targetCityName, String userId) async {
    try {
      print('🧹 Removing user from all other city groups except: $targetCityName');

      // Get user data for messages
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String userName = userData['fullName'] ?? 'Unknown User';

      // Get all groups where user is a participant
      QuerySnapshot groupsWithUser = await _firestore
          .collection('localgroupchat')
          .where('participantsList', arrayContains: userId)
          .get();

      // Remove user from each group except the target city
      for (QueryDocumentSnapshot groupDoc in groupsWithUser.docs) {
        String groupCityName = groupDoc.id;

        // Skip the target city group
        if (groupCityName == targetCityName) continue;

        Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
        List<dynamic> participants = groupData['participantsList'] ?? [];

        if (participants.contains(userId)) {
          participants.remove(userId);

          if (participants.isEmpty) {
            // If no participants left, mark group as inactive
            await groupDoc.reference.update({
              'participantsList': participants,
              'lastMessage': '$userName left the group. Group is now empty.',
              'sentOn': FieldValue.serverTimestamp(),
              'isActive': false,
            });
            print('🗑️ Marked $groupCityName group as inactive (empty)');
          } else {
            // Update participants list
            await groupDoc.reference.update({
              'participantsList': participants,
              'lastMessage': '$userName left the $groupCityName group',
              'sentOn': FieldValue.serverTimestamp(),
            });

            // Removed leave system message to avoid unnecessary system messages
            print('🚪 Removed user from $groupCityName group');
          }
        }
      }

      print('✅ Cleaned up user from all other city groups');
    } catch (e) {
      print('❌ Error removing user from other city groups: $e');
    }
  }

  // Remove user from city group
  Future<void> _removeUserFromCityGroup(String cityName, String userId) async {
    try {
      print('🚪 Removing user from city group: $cityName');

      // Get user data
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String userName = userData['fullName'] ?? 'Unknown User';

      // Reference to the city group document
      DocumentReference cityGroupRef = _firestore.collection('localgroupchat').doc(cityName);

      // Check if group exists
      DocumentSnapshot cityGroupSnapshot = await cityGroupRef.get();

      if (cityGroupSnapshot.exists) {
        Map<String, dynamic> groupData = cityGroupSnapshot.data() as Map<String, dynamic>;
        List<dynamic> participants = groupData['participantsList'] ?? [];

        if (participants.contains(userId)) {
          participants.remove(userId);

          if (participants.isEmpty) {
            // If no participants left, mark group as inactive
            await cityGroupRef.update({
              'participantsList': participants,
              'lastMessage': '$userName left the group. Group is now empty.',
              'sentOn': FieldValue.serverTimestamp(),
              'isActive': false,
            });
          } else {
            // Update participants list
            await cityGroupRef.update({
              'participantsList': participants,
              'lastMessage': '$userName left the $cityName group',
              'sentOn': FieldValue.serverTimestamp(),
            });

            // Removed leave system message to avoid unnecessary system messages
          }

          print('✅ Removed user from city group: $cityName');
        }
      }
    } catch (e) {
      print('❌ Error removing user from city group: $e');
    }
  }



  // Listen to real-time updates for local group chats (Stream-based)
  void loadLocalGroupChats() {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _errorMessage = 'No user logged in';
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('🔄 Starting real-time local group chats stream...');

      // Cancel existing subscription
      _groupChatsSubscription?.cancel();

      // Start real-time stream
      _groupChatsSubscription = _firestore
          .collection('localgroupchat')
          .where('participantsList', arrayContains: currentUser.uid)
          .where('isActive', isEqualTo: true)
          .orderBy('sentOn', descending: true)
          .snapshots()
          .listen(
            (QuerySnapshot querySnapshot) {
          _localGroupChats = querySnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['docId'] = doc.id; // Add document ID for reference
            return data;
          }).toList();

          _isLoading = false;
          _errorMessage = null;

          print('✅ Real-time update: ${_localGroupChats.length} local group chats');
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = 'Failed to load group chats: $error';
          _isLoading = false;
          print('❌ Error in group chats stream: $error');
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to start group chats stream: $e';
      _isLoading = false;
      print('❌ Error starting local group chats stream: $e');
      notifyListeners();
    }
  }

  // Get specific city group chat
  Future<Map<String, dynamic>?> getCityGroupChat(String cityName) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('localgroupchat')
          .doc(cityName)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('❌ Error getting city group chat: $e');
      return null;
    }
  }

  // Load messages for a specific chat with pagination
  Future<void> loadMessagesForChat(String chatId) async {
    try {
      _currentChatId = chatId;
      _currentGroupId = chatId;
      _currentGroupName = chatId; // For local groups, the city name is the group name
      _isLoading = true;
      _errorMessage = null;
      _hasMoreMessages = true;
      _lastDocument = null;
      _currentChatMessages.clear();
      notifyListeners();

      print('💬 Loading initial messages for chat: $chatId');

      // Add timeout to prevent indefinite loading
      await Future.any([
        _loadInitialMessages(chatId),
        Future.delayed(Duration(seconds: 5)).then((_) {
          throw TimeoutException('Loading messages timed out');
        })
      ]);

      _listenToLocalEvents(chatId);
    } catch (e) {
      if (e is TimeoutException) {
        _errorMessage = 'Loading is taking longer than expected. Please check your connection.';
        print('⏱️ Loading messages timed out');
      } else {
        _errorMessage = 'Failed to load messages: $e';
        print('❌ Error loading messages: $e');
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  void _listenToLocalEvents(String cityName) {
    _eventsSubscription?.cancel();
    _eventsSubscription = FirebaseServices.getLocalEventsStream(cityName: cityName)
        .listen((events) {
      _currentEvents = events;
      notifyListeners();
    }, onError: (error) {
      print('❌ Error listening to local events: $error');
    });
  }

  // Public method to rebind nationality listeners on demand (e.g., after app resumes)
  void refreshNationalityListeners() {
    if (_chatFilterMode == 'Countrymen') {
      _setupSenderNationalityListeners();
    }
  }

  List<dynamic> _buildCombinedTimeline() {
    print('🔍 Building timeline with filter mode: $_chatFilterMode');
    print('🏳️ Current user nationality: $_currentUserNationality');
    print('📝 Total messages before filtering: ${_currentChatMessages.length}');
    
    // Optional filter by nationality when chatFilterMode == 'Countrymen'
    final List<Map<String, dynamic>> messageItems = _currentChatMessages
        .where((m) {
          if (_chatFilterMode != 'Countrymen') return true;
          if (_currentUserNationality == null || _currentUserNationality!.isEmpty) {
            print('⚠️ Current user nationality is null or empty, showing all messages');
            return true;
          }
          
          // Get sender nationality
          final senderNationality = m['senderNationality'];
          final senderId = m['senderId'];
          
          print('🔍 Message from ${m['senderName']} (ID: $senderId)');
          print('   Sender nationality: $senderNationality');
          print('   Current user nationality: $_currentUserNationality');
          print('   Is current user: ${senderId == currentUserId}');
          
          // Show messages from users with the same nationality as current user
          // OR messages sent by the current user themselves
          final shouldShow = senderNationality == _currentUserNationality || 
                 senderId == currentUserId;
          print('   Should show: $shouldShow');
          
          return shouldShow;
        })
        .map((m) => {
          'itemType': 'message',
          'data': m,
          'createdAt': (m['timestamp'] is Timestamp)
              ? (m['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
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

  // Re-filter messages when nationality changes occur
  void _refilterMessages() {
    // Trigger UI update by calling notifyListeners
    // The _buildCombinedTimeline method will be called automatically
    // and will apply the new filtering logic with updated nationality data
    notifyListeners();
    print('✅ Messages re-filtered due to nationality change');
  }

  // Set up nationality listeners for all message senders
  void _setupSenderNationalityListeners() {
    if (_chatFilterMode != 'Countrymen') {
      // Only set up listeners when in Countrymen mode
      return;
    }

    // Get all unique sender IDs from current messages
    Set<String> senderIds = _currentChatMessages
        .map((message) => message['senderId'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toSet();

    // Remove current user from the set (already handled by _listenToUserLocationChanges)
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId != null) {
      senderIds.remove(currentUserId);
    }

    print('🔍 Setting up nationality listeners for ${senderIds.length} senders');

    // Set up listeners for each sender
    for (String senderId in senderIds) {
      if (!_nationalityListeners.containsKey(senderId)) {
        _nationalityListeners[senderId] = _firestore
            .collection('users')
            .doc(senderId)
            .snapshots()
            .listen(
              (DocumentSnapshot userDoc) {
            if (userDoc.exists) {
              Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
              String? newNationality = userData['nationality'];
              
              // Check if nationality changed in cache
              Map<String, dynamic>? cachedData = _userDataCache[senderId];
              String? oldNationality = cachedData?['nationality'];
              
              if (newNationality != oldNationality) {
                print('🏳️ Sender $senderId nationality changed from $oldNationality to $newNationality');
                
                // Update cache
                _userDataCache[senderId] = userData;
                
                // Update sender nationality in current messages
                for (var message in _currentChatMessages) {
                  if (message['senderId'] == senderId) {
                    message['senderNationality'] = newNationality;
                  }
                }
                
                // Re-filter messages
                print('🔄 Re-filtering messages due to sender nationality change');
                _refilterMessages();
              }
            }
          },
          onError: (error) {
            print('❌ Error listening to sender $senderId nationality changes: $error');
          },
        );
      }
    }
  }

  // Load initial messages with pagination
  Future<void> _loadInitialMessages(String chatId) async {
    try {
      // First, check if the group exists
      DocumentSnapshot groupDoc = await _firestore
          .collection('localgroupchat')
          .doc(chatId)
          .get();

      if (!groupDoc.exists) {
        print('📝 Group does not exist yet for: $chatId - will be created when first message is sent');
        _currentChatMessages = [];
        _hasMoreMessages = false;
        _lastDocument = null;

        // Still start listening for new messages
        _listenToNewMessages(chatId);
        _isLoading = false;
        notifyListeners();
        scrollToBottom();
        return;
      }

      Query query = _firestore
          .collection('localgroupchat')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(_messagesLimit);

      QuerySnapshot querySnapshot = await query.get();

      // First, collect all unique sender IDs
      Set<String> senderIds = querySnapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['senderId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet();

      // Pre-fetch all user data for these senders
      print('🔄 Pre-fetching user data for ${senderIds.length} unique senders');
      await Future.wait(senderIds.map((senderId) => _getCachedUserData(senderId)));

      // Now process messages with all user data available
      _currentChatMessages = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['messageId'] = doc.id;
        // Enrich with sender data for UI (now synchronous since data is cached)
        _enrichMessageWithSenderData(data);
        return data;
      }).toList();

      // Set pagination info
      _lastDocument = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
      _hasMoreMessages = querySnapshot.docs.length == _messagesLimit;

      print('✅ Loaded ${_currentChatMessages.length} initial messages with sender data');

      // Set up nationality listeners for message senders
      _setupSenderNationalityListeners();

      // Start listening to new messages only
      _listenToNewMessages(chatId);

    } catch (e) {
      print('❌ Error loading initial messages: $e');
      // Don't throw, just set empty messages and continue
      _currentChatMessages = [];
      _hasMoreMessages = false;
      _lastDocument = null;

      // Still try to listen for new messages
      _listenToNewMessages(chatId);
    } finally {
      _isLoading = false;
      notifyListeners();
      scrollToBottom();
    }
  }

  // Load more messages for pagination
  Future<void> loadMoreMessages() async {
    if (_currentChatId == null || !_hasMoreMessages || _isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      Query query = _firestore
          .collection('localgroupchat')
          .doc(_currentChatId!)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(_messagesLimit)
          .startAfterDocument(_lastDocument!);

      QuerySnapshot querySnapshot = await query.get();

      List<Map<String, dynamic>> olderMessages = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['messageId'] = doc.id;
        // Enrich with sender data for UI
        _enrichMessageWithSenderData(data);
        return data;
      }).toList();

      // Insert older messages at the beginning
      _currentChatMessages.insertAll(0, olderMessages);

      // Update pagination info
      _lastDocument = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
      _hasMoreMessages = querySnapshot.docs.length == _messagesLimit;

      print('✅ Loaded ${olderMessages.length} more messages');

    } catch (e) {
      print('❌ Error loading more messages: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Listen to new messages only (after initial load)
  void _listenToNewMessages(String chatId) {
    _messagesSubscription?.cancel();

    DateTime lastMessageTime = DateTime.now().subtract(Duration(seconds: 1));
    if (_currentChatMessages.isNotEmpty) {
      final lastMessage = _currentChatMessages.last;
      if (lastMessage['timestamp'] != null) {
        lastMessageTime = (lastMessage['timestamp'] as Timestamp).toDate();
      }
    }

    _messagesSubscription = _firestore
        .collection('localgroupchat')
        .doc(chatId)
        .collection('messages')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(lastMessageTime))
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen(
          (QuerySnapshot querySnapshot) {
        for (var change in querySnapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
            data['messageId'] = change.doc.id;

            // Check if message already exists (exact messageId match)
            bool messageExists = _currentChatMessages.any((msg) => msg['messageId'] == data['messageId']);

            if (!messageExists) {
              // Check if this might be updating an optimistic message we already have
              bool hasOptimisticVersion = _currentChatMessages.any((msg) =>
                  msg['messageId'].toString().startsWith('temp_') && 
                  msg['messageType'] == data['messageType'] && 
                  msg['senderId'] == data['senderId'] &&
                  msg['message'] == data['message']
              );

              if (hasOptimisticVersion) {
                print('🔄 Skipping Firebase message - already have optimistic version: ${data['messageId']}');
              } else {
                // Pre-fetch sender data to ensure synchronous enrichment
                final senderId = data['senderId'];
                if (senderId != null) {
                  _getCachedUserData(senderId).then((_) {
                    // Enrich message with sender data (now synchronous since data is cached)
                    _enrichMessageWithSenderData(data);
                    _currentChatMessages.add(data);
                    print('📝 Added new message from Firebase: ${data['messageId']}');
                    
                    // Set up nationality listener for new sender if in Countrymen mode
                    if (_chatFilterMode == 'Countrymen' && 
                        senderId != _auth.currentUser?.uid && 
                        !_nationalityListeners.containsKey(senderId)) {
                      _setupNationalityListenerForSender(senderId);
                    }
                    
                    notifyListeners();
                    scrollToBottom();
                  });
                } else {
                  // If no senderId, add message without enrichment
                  _currentChatMessages.add(data);
                  print('📝 Added new message without sender data: ${data['messageId']}');
                }
              }
            } else {
              print('🚫 Skipped duplicate message: ${data['messageId']}');
            }
          }
        }
        // Note: notifyListeners() and scrollToBottom() are now called inside the async callbacks
      },
      onError: (error) {
        print('❌ Error listening to new messages: $error');
        _errorMessage = 'Failed to sync messages: $error';
        notifyListeners();
      },
    );
  }

  // Listen to real-time messages for current chat (legacy - now handled by _listenToNewMessages)
  void listenToMessages(String chatId) {
    // This is now handled by _listenToNewMessages in loadMessagesForChat
    // Keeping for backward compatibility
    if (_currentChatId != chatId) {
      loadMessagesForChat(chatId);
    }
  }

  // Send a message to a local group chat (non-blocking for rapid sending)
  Future<bool> sendMessage({
    required String chatId,
    required String message,
    String messageType = 'text',
    String? imageUrl,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      _errorMessage = 'No user logged in';
      return false;
    }

    if (message.trim().isEmpty && imageUrl == null) {
      _errorMessage = 'Message cannot be empty';
      return false;
    }

    // Create unique temp ID for this message
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${message.hashCode}';

    try {
      // Get user data (cached or fetch)
      final userData = await _getCachedUserData(currentUser.uid);

      // Create temporary message for immediate UI update
      Map<String, dynamic> tempMessage = {
        'messageId': tempId,
        'senderId': currentUser.uid,
        'senderName': userData['fullName'] ?? 'Unknown User', // Add for UI
        'senderProfileImage': userData['profileImageUrl'], // Add for UI
        'message': message.trim(),
        'messageType': messageType,
        'timestamp': Timestamp.now(),
        'isRead': false,
        'isPending': true,
      };

      if (imageUrl != null) {
        tempMessage['imageUrl'] = imageUrl;
      }

      // Add temp message immediately and track it
      _currentChatMessages.add(tempMessage);
      _pendingMessages.add(tempId);
      notifyListeners();

      // Send message in background (non-blocking)
      _sendMessageInBackground(chatId, message.trim(), messageType, imageUrl, tempId, currentUser.uid, userData);

      return true;
    } catch (e) {
      // Remove temp message on immediate error
      _currentChatMessages.removeWhere((msg) => msg['messageId'] == tempId);
      _pendingMessages.remove(tempId);
      _errorMessage = 'Failed to prepare message: $e';
      print('❌ Error preparing message: $e');
      notifyListeners();
      return false;
    }
  }

  // Get cached user data to avoid repeated fetches
  Future<Map<String, dynamic>> _getCachedUserData(String userId) async {
    if (_userDataCache.containsKey(userId)) {
      print('📋 Using cached data for user: $userId');
      return _userDataCache[userId]!;
    }

    try {
      print('🔄 Fetching user data from Firestore for: $userId');
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        print('📊 User data fetched: $userData');
        print('🌍 User nationality: ${userData['nationality']}');
        _userDataCache[userId] = userData;
        return userData;
      } else {
        print('❌ User document does not exist for: $userId');
        return {'fullName': 'Unknown User', 'profileImageUrl': null, 'nationality': null};
      }
    } catch (e) {
      print('❌ Error fetching user data for $userId: $e');
      return {'fullName': 'Unknown User', 'profileImageUrl': null, 'nationality': null};
    }
  }

  // Enrich message with sender data synchronously using cache
  void _enrichMessageWithSenderData(Map<String, dynamic> messageData) {
    final senderId = messageData['senderId'];
    print('🔍 Enriching message from sender: $senderId');
    
    if (senderId != null && _userDataCache.containsKey(senderId)) {
      final userData = _userDataCache[senderId]!;
      messageData['senderName'] = userData['fullName'] ?? 'Unknown User';
      messageData['senderProfileImage'] = userData['profileImageUrl'];
      messageData['senderNationality'] = userData['nationality'];
      print('✅ Message enriched with cached data - Nationality: ${userData['nationality']}');
    } else if (senderId != null) {
      // If not cached, set default and fetch in background
      messageData['senderName'] = 'Unknown User';
      messageData['senderProfileImage'] = null;
      messageData['senderNationality'] = null;
      print('⚠️ Sender data not cached, fetching in background for: $senderId');

      // Fetch user data in background and update message
      _getCachedUserData(senderId).then((userData) {
        print('📥 Fetched user data for $senderId: $userData');
        // Find and update the message if it still exists
        final messageIndex = _currentChatMessages.indexWhere((msg) => msg['messageId'] == messageData['messageId']);
        if (messageIndex != -1) {
          _currentChatMessages[messageIndex]['senderName'] = userData['fullName'] ?? 'Unknown User';
          _currentChatMessages[messageIndex]['senderProfileImage'] = userData['profileImageUrl'];
          _currentChatMessages[messageIndex]['senderNationality'] = userData['nationality'];
          print('✅ Message updated with nationality: ${userData['nationality']}');
          notifyListeners();
        }
      });
    }
  }

  // Send message in background without blocking UI
  void _sendMessageInBackground(
      String chatId,
      String message,
      String messageType,
      String? imageUrl,
      String tempId,
      String senderId,
      Map<String, dynamic> userData,
      ) async {
    try {
      // Prepare message data - only store essential fields
      Map<String, dynamic> messageData = {
        'senderId': senderId,
        'message': message,
        'messageType': messageType,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      if (imageUrl != null) {
        messageData['imageUrl'] = imageUrl;
      }

      // Add message to subcollection and get document reference
      final docRef = await _firestore
          .collection('localgroupchat')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Update last message in group chat document
      await _firestore.collection('localgroupchat').doc(chatId).update({
        'lastMessage': messageType == 'image' ? '📷 Image' : message,
        'sentOn': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
        'lastMessageSenderName': userData['fullName'] ?? 'Unknown User',
      });

      // Send notifications to group members (in background), exclude sender
      _sendNotificationsToGroupMembers(chatId, message, userData['fullName'] ?? 'Unknown User', senderId, messageType: messageType);

      // Remove from pending messages
      _pendingMessages.remove(tempId);

      // Update temp message with Firebase document ID and mark as sent
      final tempMessageIndex = _currentChatMessages.indexWhere((msg) => msg['messageId'] == tempId);
      if (tempMessageIndex != -1) {
        _currentChatMessages[tempMessageIndex]['messageId'] = docRef.id; // Update with Firebase ID
        _currentChatMessages[tempMessageIndex]['isPending'] = false;
        _currentChatMessages[tempMessageIndex].remove('isOptimistic'); // Remove optimistic flag
        notifyListeners();
        print('✅ Updated text message with Firebase doc ID: ${docRef.id}');
      }

      print('✅ Message sent successfully: $message');
    } catch (e) {
      // Mark message as failed but keep it in UI with retry option
      _pendingMessages.remove(tempId);

      final tempMessageIndex = _currentChatMessages.indexWhere((msg) => msg['messageId'] == tempId);
      if (tempMessageIndex != -1) {
        _currentChatMessages[tempMessageIndex]['isPending'] = false;
        _currentChatMessages[tempMessageIndex]['isFailed'] = true;
        notifyListeners();
      }

      print('❌ Error sending message in background: $e');
    }
  }

  // Get participants details for a chat
  Future<List<Map<String, dynamic>>> getChatParticipants(String chatId) async {
    try {
      DocumentSnapshot chatDoc = await _firestore
          .collection('localgroupchat')
          .doc(chatId)
          .get();

      if (!chatDoc.exists) return [];

      Map<String, dynamic> chatData = chatDoc.data() as Map<String, dynamic>;
      List<dynamic> participantIds = chatData['participantsList'] ?? [];

      List<Map<String, dynamic>> participants = [];

      for (String participantId in participantIds) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(participantId)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          userData['uid'] = participantId;
          participants.add(userData);
        }
      }

      return participants;
    } catch (e) {
      print('❌ Error getting chat participants: $e');
      return [];
    }
  }

  // Stream for current city participants
  Stream<List<UserModel>> getCurrentCityParticipantsStream() {
    if (_displayCityName == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('localgroupchat')
        .doc(_displayCityName!)
        .snapshots()
        .asyncMap((DocumentSnapshot groupDoc) async {
      if (!groupDoc.exists) return <UserModel>[];

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      List<dynamic> participantIds = groupData['participantsList'] ?? [];

      List<UserModel> participants = [];

      for (String participantId in participantIds) {
        try {
          DocumentSnapshot userDoc = await _firestore
              .collection('users')
              .doc(participantId)
              .get();

          if (userDoc.exists) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            userData['uid'] = participantId;
            participants.add(UserModel.fromMap(userData));
          }
        } catch (e) {
          print('❌ Error fetching user $participantId: $e');
        }
      }

      return participants;
    });
  }

  // Get current city participants count
  int getCurrentCityParticipantsCount() {
    if (_displayCityName == null) return 0;
    
    // Find the group in localGroupChats
    for (var group in _localGroupChats) {
      if (group['id'] == _displayCityName || group['docId'] == _displayCityName) {
        List<dynamic> participants = group['participantsList'] ?? [];
        return participants.length;
      }
    }
    return 0;
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      QuerySnapshot unreadMessages = await _firestore
          .collection('localgroupchat')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: currentUser.uid)
          .get();

      WriteBatch batch = _firestore.batch();

      for (QueryDocumentSnapshot doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print('✅ Messages marked as read');
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  // Get nearby city groups (for discovery)
  Future<List<Map<String, dynamic>>> getNearbyLocalGroups({
    String? currentCity,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore
          .collection('localgroupchat')
          .where('isActive', isEqualTo: true)
          .orderBy('sentOn', descending: true)
          .limit(limit);

      QuerySnapshot querySnapshot = await query.get();

      List<Map<String, dynamic>> groups = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;
        return data;
      }).toList();

      // Filter out current user's groups and prioritize nearby cities
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        groups = groups.where((group) {
          List<dynamic> participants = group['participantsList'] ?? [];
          return !participants.contains(currentUser.uid);
        }).toList();

        // If current city is provided, prioritize it
        if (currentCity != null) {
          groups.sort((a, b) {
            String cityA = a['cityName'] ?? '';
            String cityB = b['cityName'] ?? '';

            if (cityA == currentCity && cityB != currentCity) return -1;
            if (cityB == currentCity && cityA != currentCity) return 1;
            return 0;
          });
        }
      }

      return groups;
    } catch (e) {
      print('❌ Error getting nearby local groups: $e');
      return [];
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear current chat
  void clearCurrentChat() {
    _currentChatId = null;
    _currentChatMessages.clear();
    _currentEvents = [];
    _currentGroupName = null;
    _currentGroupId = null;
    _messagesSubscription?.cancel();
    _eventsSubscription?.cancel();
    _optimisticToDocIdMapping.clear(); // Clear mappings when clearing chat
    notifyListeners();
  }

  // Set keyboard state
  void setKeyboardState(bool shouldKeepOpen) {
    _shouldKeepKeyboardOpen = shouldKeepOpen;
    notifyListeners();
  }

  // Reset keyboard state
  void resetKeyboardState() {
    _shouldKeepKeyboardOpen = false;
    notifyListeners();
  }

  // UI Methods
  void initializeForScreen({String? cityName}) {
    // Determine display city name
    _displayCityName = cityName ?? _currentUserCity;
    if (_displayCityName == null || _displayCityName!.isEmpty) {
      if (_localGroupChats.isNotEmpty) {
        _displayCityName = _localGroupChats.first['id'];
      } else {
        _displayCityName = 'Local Chat';
      }
    }

    // Set up chat if not already loaded for this city
    String targetCity = _displayCityName!;
    bool isAlreadyLoaded = _currentChatId == targetCity &&
        _currentChatMessages.isNotEmpty &&
        _messagesSubscription != null;

    if (isAlreadyLoaded) {
      print('✅ Using pre-loaded data for $targetCity');
      // Data is already loaded and subscription is active
      _isLoading = false;
      notifyListeners();
      // Ensure nationality listeners are active when already loaded
      if (_chatFilterMode == 'Countrymen') {
        _setupSenderNationalityListeners();
      }
    } else {
      print('🔄 Loading fresh data for $targetCity');
      // Always load messages when coming to screen after app restart
      loadMessagesForChat(targetCity);
    }

    markMessagesAsRead(targetCity);
    scrollToBottom();
  }

  // Set up nationality listener for a single sender
  void _setupNationalityListenerForSender(String senderId) {
    if (_nationalityListeners.containsKey(senderId)) {
      return; // Already listening
    }

    print('🔍 Setting up nationality listener for sender: $senderId');
    
    _nationalityListeners[senderId] = _firestore
        .collection('users')
        .doc(senderId)
        .snapshots()
        .listen(
          (DocumentSnapshot userDoc) {
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          String? newNationality = userData['nationality'];
          
          // Check if nationality changed in cache
          Map<String, dynamic>? cachedData = _userDataCache[senderId];
          String? oldNationality = cachedData?['nationality'];
          
          if (newNationality != oldNationality) {
            print('🏳️ Sender $senderId nationality changed from $oldNationality to $newNationality');
            
            // Update cache
            _userDataCache[senderId] = userData;
            
            // Update sender nationality in current messages
            for (var message in _currentChatMessages) {
              if (message['senderId'] == senderId) {
                message['senderNationality'] = newNationality;
              }
            }
            
            // Re-filter messages
            print('🔄 Re-filtering messages due to sender nationality change');
            _refilterMessages();
          }
        }
      },
      onError: (error) {
        print('❌ Error listening to sender $senderId nationality changes: $error');
      },
    );
  }

  // Clean up nationality listeners
  void _cleanupNationalityListeners() {
    print('🧹 Cleaning up ${_nationalityListeners.length} nationality listeners');
    for (var subscription in _nationalityListeners.values) {
      subscription.cancel();
    }
    _nationalityListeners.clear();
  }

  // Toggle chat filter mode and rebuild timeline
  void setChatFilterMode(String mode) {
    if (mode != 'Global' && mode != 'Countrymen') return;
    if (_chatFilterMode == mode) return;
    
    String previousMode = _chatFilterMode;
    _chatFilterMode = mode;
    
    // Handle nationality listeners based on mode change
    if (mode == 'Countrymen') {
      print('🏳️ Switching to Countrymen mode - setting up nationality listeners');
      _setupSenderNationalityListeners();
    } else if (previousMode == 'Countrymen') {
      print('🌍 Switching from Countrymen mode - cleaning up nationality listeners');
      _cleanupNationalityListeners();
    }
    
    notifyListeners();
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void onProviderChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isLoading && _currentChatMessages.isNotEmpty && _shouldAutoScroll) {
        scrollToBottom();
      }
    });
  }

  void handleSendMessage({String? caption}) async {
    if (_selectedFile != null && _displayCityName != null) {
      // Handle file message with optional caption
      await _handleFileMessage(caption: caption);
    } else if (_messageController.text.trim().isNotEmpty && _displayCityName != null) {
      // Handle text message
      await sendMessage(
        chatId: _displayCityName!,
        message: _messageController.text.trim(),
      );
      _messageController.clear();
      scrollToBottom();

      // Keep keyboard focus after sending
      Future.delayed(Duration(milliseconds: 50), () {
        if (_messageFocusNode.canRequestFocus) {
          _messageFocusNode.requestFocus();
        }
      });
    }
  }

  Future<void> _handleFileMessage({String? caption}) async {
    final selectedFile = _selectedFile;
    final selectedFileType = _selectedFileType;
    final displayCityName = _displayCityName;
    final currentUser = _auth.currentUser;

    if (selectedFile == null || selectedFileType == null || displayCityName == null || currentUser == null) {
      _errorMessage = 'Missing required data for file upload';
      notifyListeners();
      return;
    }

    try {
      final messageText = caption?.isNotEmpty == true ? caption! : (selectedFileType == 'image' ? '📷 Image' : '🎥 Video');
      final userData = await _getCachedUserData(currentUser.uid);

      if (userData.isEmpty) {
        _errorMessage = 'Failed to get user data';
        notifyListeners();
        return;
      }

      // Create unique message ID
      final messageId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${currentUser.uid}';

      // Show message immediately (like WhatsApp)
      final optimisticMessage = {
        'messageId': messageId,
        'senderId': currentUser.uid,
        'senderName': userData['fullName'] ?? 'Unknown User',
        'senderProfileImage': userData['profileImageUrl'],
        'message': messageText,
        'messageType': selectedFileType,
        'timestamp': Timestamp.now(),
        'isRead': false,
        'isOptimistic': true,
        'isUploading': false,
        'uploadProgress': 0.0,
        'localFile': selectedFile,
        'imageUrl': null,
      };

      // Add to chat immediately
      _currentChatMessages.add(optimisticMessage);
      notifyListeners();
      scrollToBottom();

      // Clear selected file
      clearSelectedFile();

      // Start upload in background
      await _uploadAndReplaceMessage(messageId, selectedFile, selectedFileType, messageText, userData, displayCityName);

    } catch (e) {
      _errorMessage = 'Failed to send message: ${e.toString()}';
      notifyListeners();
    }
  }
  Future<void> _uploadAndReplaceMessage(
    String messageId,
    File file,
    String fileType,
    String messageText,
    Map<String, dynamic> userData,
    String chatId,
  ) async {
    try {
      // Update message to show uploading
      final messageIndex = _currentChatMessages.indexWhere((msg) => msg['messageId'] == messageId);
      if (messageIndex != -1) {
        _currentChatMessages[messageIndex]['isUploading'] = true;
        notifyListeners();
      }

      // Upload file
      final fileUrl = await _uploadFileWithProgress(file, fileType);

      if (fileUrl != null && fileUrl.isNotEmpty) {
        // Save to Firestore
        final messageData = {
          'senderId': userData['senderId'] ?? _auth.currentUser?.uid,
          'message': messageText,
          'messageType': fileType,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'imageUrl': fileUrl,
        };

        final docRef = await _firestore
            .collection('localgroupchat')
            .doc(chatId)
            .collection('messages')
            .add(messageData);

        // Update group chat document
        await _firestore.collection('localgroupchat').doc(chatId).update({
          'lastMessage': fileType == 'image' ? '📷 Image' : '🎥 Video',
          'sentOn': FieldValue.serverTimestamp(),
          'lastMessageSenderId': userData['senderId'] ?? _auth.currentUser?.uid,
          'lastMessageSenderName': userData['fullName'] ?? 'Unknown User',
        });

        // Replace optimistic message with final data
        if (messageIndex != -1) {
          _currentChatMessages[messageIndex] = {
            'messageId': docRef.id, // Use Firebase document ID
            'senderId': userData['senderId'] ?? _auth.currentUser?.uid,
            'senderName': userData['fullName'] ?? 'Unknown User',
            'senderProfileImage': userData['profileImageUrl'],
            'message': messageText,
            'messageType': fileType,
            'timestamp': Timestamp.now(),
            'isRead': false,
            'imageUrl': fileUrl,
          };
          notifyListeners();
        }

        // Send notifications
        _sendNotificationsToGroupMembers(
          chatId,
          messageText,
          userData['fullName'] ?? 'Unknown User',
          userData['senderId'] ?? _auth.currentUser?.uid ?? '',
          messageType: fileType,
        );

      } else {
        throw Exception('Failed to upload file');
      }

    } catch (e) {
      // Mark message as failed
      final messageIndex = _currentChatMessages.indexWhere((msg) => msg['messageId'] == messageId);
      if (messageIndex != -1) {
        _currentChatMessages[messageIndex]['isFailed'] = true;
        _currentChatMessages[messageIndex]['isUploading'] = false;
        notifyListeners();
      }
      print('❌ Error uploading file: $e');
    }
  }

  Future<String?> _uploadFileWithProgress(File file, String fileType) async {
    try {
      // Validate file exists
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last.toLowerCase();
      final fileName = '${timestamp}_${_auth.currentUser?.uid}.$extension';

      // Create storage reference
      final storageRef = _storage.ref().child('localChatGroupImagesOrVideo/$fileName');

      // Create upload task
      final uploadTask = storageRef.putFile(file);

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

  Future<void> _uploadFileInBackground(
      String messageId,
      String messageText,
      String messageType,
      File file,
      Map<String, dynamic> userData,
      ) async {
    try {
      // Update progress to show uploading started
      final messageIndex = _currentChatMessages.indexWhere((msg) => msg['messageId'] == messageId);
      if (messageIndex != -1) {
        _currentChatMessages[messageIndex]['uploadProgress'] = 0.1;
        notifyListeners();
      }

      // Upload file to Firebase Storage with progress tracking
      final fileUrl = await _uploadFileToStorageWithProgress(file, messageId);

      if (fileUrl != null && fileUrl.isNotEmpty) {
        // Prepare message data for Firestore - only store essential fields
        final messageData = {
          'senderId': userData['senderId'] ?? _auth.currentUser?.uid,
          'message': messageText,
          'messageType': messageType,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'imageUrl': fileUrl, // Store the Firebase Storage URL
        };

        // Save to Firestore with auto-generated document ID (like text messages)
        final docRef = await _firestore
            .collection('localgroupchat')
            .doc(_displayCityName!)
            .collection('messages')
            .add(messageData);

        // Store the auto-generated document ID
        final docId = docRef.id;

        // Update last message in group chat document
        final displayName = _displayCityName;
        if (displayName != null) {
          await _firestore.collection('localgroupchat').doc(displayName).update({
            'lastMessage': messageType == 'image' ? '📷 Image' : messageType == 'video' ? '🎥 Video' : messageText,
            'sentOn': FieldValue.serverTimestamp(),
            'lastMessageSenderId': userData['senderId'] ?? _auth.currentUser?.uid,
            'lastMessageSenderName': userData['fullName'] ?? 'Unknown User',
          });

          // Send notifications to group members
          final senderId = userData['senderId'] ?? _auth.currentUser?.uid;
          if (senderId != null) {
            _sendNotificationsToGroupMembers(
                displayName,
                messageText,
                userData['fullName'] ?? 'Unknown User',
                senderId,
                messageType: messageType
            );
          }
        }

        // Store mapping for duplicate prevention
        _optimisticToDocIdMapping[messageId] = docId;

        // Mark optimistic message as ready for replacement and remove upload progress
        final finalMessageIndex = _currentChatMessages.indexWhere((msg) => msg['messageId'] == messageId);
        if (finalMessageIndex != -1) {
          // Mark for replacement and clean up upload UI properties
          _currentChatMessages[finalMessageIndex].addAll({
            'readyForReplacement': true,
            'finalDocId': docId,
          });
          
          // Remove upload progress properties to clean up UI
          _currentChatMessages[finalMessageIndex].remove('isUploading');
          _currentChatMessages[finalMessageIndex].remove('uploadProgress');
          
          print('🔄 Marked optimistic message for replacement: $messageId -> $docId');
          notifyListeners(); // Immediately update UI to remove upload progress
        }

      } else {
        throw Exception('Failed to get download URL from storage');
      }
    } catch (e) {
      // Mark message as failed with retry option
      final messageIndex = _currentChatMessages.indexWhere((msg) => msg['messageId'] == messageId);
      if (messageIndex != -1) {
        _currentChatMessages[messageIndex].removeWhere((key, value) =>
            ['isOptimistic', 'isUploading', 'uploadProgress'].contains(key));
        _currentChatMessages[messageIndex]['isFailed'] = true;
        _currentChatMessages[messageIndex]['failureReason'] = e.toString();
        notifyListeners();
      }
    }
  }

  Future<String?> _uploadFileToStorageWithProgress(File file, String messageId) async {
    try {
      // Validate file exists
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      // Get file extension
      final extension = file.path.split('.').last.toLowerCase();
      final fileName = '$messageId.$extension';

      // Create storage reference
      final storageRef = _storage.ref().child('localChatGroupImagesOrVideo/$fileName');

      // Create upload task
      final uploadTask = storageRef.putFile(file);

      // Monitor upload progress for this specific message
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.totalBytes > 0
            ? snapshot.bytesTransferred / snapshot.totalBytes
            : 0.0;

        // Update progress for this specific message
        final messageIndex = _currentChatMessages.indexWhere((msg) => msg['messageId'] == messageId);
        if (messageIndex != -1) {
          _currentChatMessages[messageIndex]['uploadProgress'] = progress;
          notifyListeners();
        }
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
      _errorMessage = 'Failed to pick file: $e';
      notifyListeners();
    }
    return null;
  }

  void clearSelectedFile() {
    _selectedFile = null;
    _selectedFileType = null;
    notifyListeners();
  }

  Future<void> retryFailedMessage(String messageId) async {
    try {
      _messageRetryStatus[messageId] = true;
      notifyListeners();

      // Find the failed message
      final failedMessageIndex = _currentChatMessages.indexWhere(
            (msg) => msg['messageId'] == messageId && (msg['isFailed'] == true),
      );
      
      if (failedMessageIndex == -1) {
        print('❌ Failed message not found: $messageId');
        return;
      }
      
      final failedMessage = _currentChatMessages[failedMessageIndex];
      final messageType = failedMessage['messageType'] ?? 'text';

      if (_displayCityName == null) {
        _errorMessage = 'Chat context not available for retry';
        notifyListeners();
        return;
      }

      // Reset the message state for retry
      _currentChatMessages[failedMessageIndex].addAll({
        'isFailed': false,
        'isUploading': true,
        'uploadProgress': 0.0,
        'failureReason': null,
      });
      notifyListeners();

      if (messageType == 'image' || messageType == 'video') {
        // For media messages, retry the upload process
        final localFile = failedMessage['localFile'] as File?;
        if (localFile != null && await localFile.exists()) {
          // Get user data
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            final userData = await _getCachedUserData(currentUser.uid);
            if (userData.isNotEmpty) {
              // Retry upload
              await _uploadFileInBackground(
                messageId,
                failedMessage['message'] ?? '',
                messageType,
                localFile,
                userData,
              );
            } else {
              throw Exception('Failed to get user data for retry');
            }
          } else {
            throw Exception('User not authenticated');
          }
        } else {
          throw Exception('Local file no longer exists');
        }
      } else {
        // For text messages, retry sending
        await sendMessage(
          chatId: _displayCityName!,
          message: failedMessage['message'] ?? '',
          messageType: messageType,
        );

        // Remove the failed message after successful retry
        _currentChatMessages.removeWhere((msg) => msg['messageId'] == messageId);
      }
    } catch (e) {
      print('❌ Error retrying message: $e');
      _errorMessage = 'Failed to retry message: ${e.toString()}';
      
      // Mark message as failed again
      final failedMessageIndex = _currentChatMessages.indexWhere(
            (msg) => msg['messageId'] == messageId,
      );
      if (failedMessageIndex != -1) {
        _currentChatMessages[failedMessageIndex].addAll({
          'isFailed': true,
          'isUploading': false,
          'failureReason': e.toString(),
        });
      }
      notifyListeners();
    } finally {
      _messageRetryStatus[messageId] = false;
      notifyListeners();
    }
  }

  void dismissKeyboard() {
    resetKeyboardState();
    _messageFocusNode.unfocus();
  }

  void onTextFieldTap() {
    setKeyboardState(true);
  }

  // Delete message with storage cleanup
  Future<void> deleteMessage(String messageId, String chatId) async {
    try {
      // Find the message
      final message = _currentChatMessages.firstWhere(
            (msg) => msg['messageId'] == messageId,
        orElse: () => {},
      );

      if (message.isEmpty) {
        print('❌ Message not found in local list: $messageId');
        return;
      }

      // Check if this is an optimistic message (temp_) that hasn't been updated yet
      if (messageId.startsWith('temp_') && (message['isPending'] == true || message['isOptimistic'] == true)) {
        print('⚠️ Cannot delete optimistic message that hasn\'t been saved to Firebase yet: $messageId');
        
        // Remove locally only
        _currentChatMessages.removeWhere((msg) => msg['messageId'] == messageId);
        notifyListeners();
        print('✅ Cancelled and removed optimistic message');
        return;
      }

      // For saved messages, delete from Firebase
      print('🗑️ Deleting message from Firebase: $messageId');

      // If it's a media message, delete from storage first
      if (message['messageType'] == 'image' || message['messageType'] == 'video') {
        final customMessageId = message['customMessageId'] ?? messageId;
        await _deleteFileFromStorage(customMessageId, message['imageUrl']);
        print('🗑️ Deleted media file from storage');
      }

      // Delete from Firestore using the document ID
      await _firestore
          .collection('localgroupchat')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();

      print('✅ Message deleted from Firestore: $messageId');

      // Remove from local list
      _currentChatMessages.removeWhere((msg) => msg['messageId'] == messageId);
      
      // Update group chat's lastMessage if needed
      await _updateGroupLastMessageAfterDeletion(chatId);
      
      notifyListeners();

      print('✅ Message deleted successfully from all locations');
    } catch (e) {
      print('❌ Error deleting message: $e');
      _errorMessage = 'Failed to delete message: $e';
      notifyListeners();
    }
  }

  // Update group chat's lastMessage after message deletion
  Future<void> _updateGroupLastMessageAfterDeletion(String chatId) async {
    try {
      // Get the latest message from Firestore
      QuerySnapshot latestMessages = await _firestore
          .collection('localgroupchat')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (latestMessages.docs.isNotEmpty) {
        final latestMessage = latestMessages.docs.first.data() as Map<String, dynamic>;
        
        // Get sender info
        String senderId = latestMessage['senderId'] ?? '';
        String senderName = 'Unknown User';
        
        if (senderId.isNotEmpty) {
          try {
            final senderData = await _getCachedUserData(senderId);
            senderName = senderData['fullName'] ?? 'Unknown User';
          } catch (e) {
            print('⚠️ Could not fetch sender name: $e');
          }
        }

        String messageText = latestMessage['message'] ?? '';
        String messageType = latestMessage['messageType'] ?? 'text';
        
        String displayText = messageType == 'image' ? '📷 Image' 
                           : messageType == 'video' ? '🎥 Video' 
                           : messageText;

        // Update group chat document
        await _firestore.collection('localgroupchat').doc(chatId).update({
          'lastMessage': displayText,
          'sentOn': latestMessage['timestamp'] ?? FieldValue.serverTimestamp(),
          'lastMessageSenderId': senderId,
          'lastMessageSenderName': senderName,
        });

        print('✅ Updated group chat lastMessage after deletion');
      } else {
        // No messages left in group
        await _firestore.collection('localgroupchat').doc(chatId).update({
          'lastMessage': 'No messages',
          'sentOn': FieldValue.serverTimestamp(),
          'lastMessageSenderId': '',
          'lastMessageSenderName': '',
        });
        print('✅ Group chat is now empty after deletion');
      }
    } catch (e) {
      print('❌ Error updating group lastMessage after deletion: $e');
    }
  }

  Future<void> _deleteFileFromStorage(String messageId, String? fileUrl) async {
    if (fileUrl == null || fileUrl.isEmpty) return;

    try {
      print('🗑️ Attempting to delete file from storage...');
      print('📁 Message ID: $messageId');
      print('🔗 File URL: $fileUrl');

      // Approach 1: Use Firebase Storage's refFromURL (most reliable with download URL)
      try {
        final ref = _storage.refFromURL(fileUrl);
        await ref.delete();
        print('✅ File deleted from storage using refFromURL: ${ref.fullPath}');
        return; // Success
      } catch (e) {
        print('❌ Approach 1 (refFromURL) failed: $e');
      }

      // Approach 2: Use messageId to construct the path
      try {
        // Try common extensions
        final extensions = ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'avi', 'webp'];
        for (String ext in extensions) {
          try {
            final fileName = '$messageId.$ext';
            final storageRef = _storage.ref().child('localChatGroupImagesOrVideo/$fileName');
            await storageRef.delete();
            print('✅ File deleted from storage using messageId: $fileName');
            return; // Success, exit early
          } catch (e) {
            // Try next extension
            continue;
          }
        }
        print('❌ Approach 2 (messageId) failed: No matching file found');
      } catch (e) {
        print('❌ Approach 2 (messageId) failed: $e');
      }

      // Approach 3: Extract path from download URL
      try {
        final uri = Uri.parse(fileUrl);
        // Firebase Storage URL pattern: https://firebasestorage.googleapis.com/v0/b/{bucket}/o/{path}?{params}
        String? encodedPath;

        if (uri.pathSegments.isNotEmpty && uri.pathSegments.contains('o')) {
          final oIndex = uri.pathSegments.indexOf('o');
          if (oIndex < uri.pathSegments.length - 1) {
            encodedPath = uri.pathSegments[oIndex + 1];
          }
        }

        if (encodedPath != null) {
          final decodedPath = Uri.decodeComponent(encodedPath);
          final storageRef = _storage.ref().child(decodedPath);
          await storageRef.delete();
          print('✅ File deleted from storage using URL path: $decodedPath');
          return; // Success
        }
        print('❌ Approach 3 (URL parsing) failed: Could not extract path');
      } catch (e) {
        print('❌ Approach 3 (URL parsing) failed: $e');
      }

      print('❌ All approaches failed to delete file from storage');
    } catch (e) {
      print('❌ Error deleting file from storage: $e');
      // Continue even if storage deletion fails - don't block message deletion
    }
  }

  // Send notifications to all group members (except sender)
  Future<void> _sendNotificationsToGroupMembers(
      String groupChatRoomId,
      String messageText,
      String senderName,
      String senderId,
      {String? messageType}
      ) async {
    try {
      print('🔔 Sending local group notifications to members');

      // Get group members from the group document
      DocumentSnapshot groupDoc = await _firestore
          .collection('localgroupchat')
          .doc(groupChatRoomId)
          .get();

      if (!groupDoc.exists) {
        print('❌ Group document not found: $groupChatRoomId');
        return;
      }

      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
      List<dynamic> participantIds = groupData['participantsList'] ?? [];

      print('📱 Found ${participantIds.length} group members');

      for (String participantId in participantIds) {
        if (participantId == senderId) continue;

        try {
          // 🔍 Check if notifications are enabled for this user
          final userDoc = await _firestore.collection('users').doc(participantId).get();
          if (!userDoc.exists) {
            print('❌ User not found: $participantId');
            continue;
          }

          final userData = userDoc.data() as Map<String, dynamic>;
          final isPushEnabled = userData['isPushNotificationEnabled'] ?? false;

          if (isPushEnabled != true) {
            print('🚫 Notifications disabled for user: $participantId');
            continue;
          }

          // ✅ Fetch FCM token
          final recipientToken = await _notificationService.getUserFCMToken(participantId);

          if (recipientToken != null && recipientToken.isNotEmpty) {
            // Prepare notification body based on message type
            String notificationBody;
            if (messageType == 'image') {
              notificationBody = '${_currentGroupName ?? 'Local Group'}: $senderName sent an image 📷';
            } else if (messageType == 'video') {
              notificationBody = '${_currentGroupName ?? 'Local Group'}: $senderName sent a video 🎥';
            } else {
              notificationBody = '${_currentGroupName ?? 'Local Group'}: $senderName: $messageText';
            }

            await _notificationService.sendNotificationToUser(
              receiverToken: recipientToken,
              title: _currentGroupName ?? 'Local Group',
              body: notificationBody,
              data: {
                'type': 'local_group_chat_message',
                'groupChatRoomId': groupChatRoomId,
                'groupName': _currentGroupName,
                'senderId': senderId,
                'senderName': senderName,
                'message': messageText,
                'messageType': messageType ?? 'text',
              },
            );
            print('✅ Notification sent to $participantId');
          } else {
            print('❌ No FCM token found for user: $participantId');
          }
        } catch (e) {
          print('❌ Error sending to $participantId: $e');
        }
      }

      print('✅ Local group notifications processing complete');
    } catch (e) {
      print('❌ Error sending local group notifications: $e');
    }
  }


  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _groupChatsSubscription?.cancel();
    _userLocationSubscription?.cancel();
    _eventsSubscription?.cancel();
    _stopPeriodicLocationCheck();
    _cleanupNationalityListeners();

    // Dispose UI controllers
    _scrollController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();

    super.dispose();
  }
}