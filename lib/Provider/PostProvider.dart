import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../Model/AddPostModel.dart';

class PostProvider extends ChangeNotifier {
  String _selectedFilter = 'Global';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingFeed = false;
  bool _isLoadingPosts = false;
  bool _hasInitiallyLoaded = false;
  List<AddPost> _allPosts = [];
  List<AddPost> _filteredPosts = [];
  String? _postsError;
  Map<String, Map<String, dynamic>> _userDataCache = {};
  Timer? _searchDebounceTimer;
  
  // Stream subscriptions for real-time updates
  StreamSubscription<QuerySnapshot>? _followingSubscription;
  StreamSubscription<QuerySnapshot>? _connectionsSubscription;
  StreamSubscription<QuerySnapshot>? _postsCollectionSubscription;
  Set<String> _followingUserIds = {};
  Set<String> _connectedUserIds = {};
  
  // Track which user post streams we're listening to
  Map<String, StreamSubscription<QuerySnapshot>> _userPostsSubscriptions = {};

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;
  TextEditingController get searchController => _searchController;
  bool get isLoadingFeed => _isLoadingFeed;
  bool get isLoadingPosts => _isLoadingPosts;
  bool get hasInitiallyLoaded => _hasInitiallyLoaded;
  List<AddPost> get allPosts => _allPosts;
  List<AddPost> get filteredPosts => _filteredPosts;
  String? get postsError => _postsError;
  FirebaseFirestore get firestore => _firestore;
  Map<String, Map<String, dynamic>> get userDataCache => _userDataCache;

  Future<void> loadUserFeedPreference() async {
    try {
      _isLoadingFeed = true;
      notifyListeners();

      final User? user = _auth.currentUser;
      if (user == null) {
        _selectedFilter = 'Global';
        _isLoadingFeed = false;
        notifyListeners();
        return;
      }

      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        final String feedValue = userData?['feed'] ?? 'Global';
        
        // Validate the feed value is one of the allowed options
        if (['Following', 'Connections', 'Global'].contains(feedValue)) {
          _selectedFilter = feedValue;
        } else {
          _selectedFilter = 'Global'; // Fallback to Global for invalid values
        }
      } else {
        _selectedFilter = 'Global'; // Default for new users
      }

      // Start listening to real-time updates for Following and Connections
      _startListeningToRelationships(user.uid);

      _isLoadingFeed = false;
      if (mounted) notifyListeners();
    } catch (e) {
      print('❌ Error loading user feed preference: $e');
      _selectedFilter = 'Global'; // Fallback on error
      _isLoadingFeed = false;
      if (mounted) notifyListeners();
    }
  }

  // Update user's feed preference in Firebase
  Future<void> updateUserFeedPreference(String newFeed) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        return;
      }

      // Update locally first for immediate UI response
      _selectedFilter = newFeed;
      if (mounted) notifyListeners();

      // Update in Firebase
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'feed': newFeed});

      print('✅ Feed preference updated to: $newFeed');
    } catch (e) {
      print('❌ Error updating feed preference: $e');
      // Revert to previous value on error
      await loadUserFeedPreference();
    }
  }

  // Start listening to real-time updates for Following and Connections
  void _startListeningToRelationships(String userId) {
    // Cancel existing subscriptions
    _followingSubscription?.cancel();
    _connectionsSubscription?.cancel();

    // Listen to Following collection changes
    _followingSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('Following')
        .snapshots()
        .listen((snapshot) {
      _followingUserIds = snapshot.docs.map((doc) => doc.id).toSet();
      print('✅ Following list updated: ${_followingUserIds.length} users');
      
      // Re-apply filter if currently showing Following posts
      if (_selectedFilter == 'Following') {
        _applyFilterSync();
      }
    }, onError: (error) {
      print('❌ Error listening to Following changes: $error');
    });

    // Listen to Connections collection changes
    _connectionsSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('Connections')
        .snapshots()
        .listen((snapshot) {
      _connectedUserIds = snapshot.docs.map((doc) => doc.id).toSet();
      print('✅ Connections list updated: ${_connectedUserIds.length} users');
      
      // Re-apply filter if currently showing Connections posts
      if (_selectedFilter == 'Connections') {
        _applyFilterSync();
      }
    }, onError: (error) {
      print('❌ Error listening to Connections changes: $error');
    });
  }

  void setFilter(String filter) {
    // Update both local state and Firebase
    updateUserFeedPreference(filter);
    // Apply filter to existing posts
    _applyFilter();
  }

  // Start listening to real-time posts updates
  void startListeningToPosts() {
    try {
      _isLoadingPosts = true;
      _postsError = null;
      notifyListeners();

      print('🔍 Starting real-time posts listener...');

      // First, listen to the addpost collection to know which users have posts
      _postsCollectionSubscription = _firestore
          .collection('addpost')
          .snapshots()
          .listen((usersSnapshot) async {
        print('📁 Users collection updated: ${usersSnapshot.docs.length} users with posts');
        // If there are no users with posts, finalize loading and show empty state
        if (usersSnapshot.docs.isEmpty) {
          _cancelUserPostsSubscriptions();
          _allPosts.clear();
          _filteredPosts.clear();
          _applyFilterSync();
          _isLoadingPosts = false;
          _hasInitiallyLoaded = true;
          if (mounted) notifyListeners();
          return;
        }
        
        // Cancel existing user post subscriptions
        _cancelUserPostsSubscriptions();
        
        // Preload user data for all users who have posts
        List<Future<void>> userDataFutures = [];
        for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
          final String userId = userDoc.id;
          if (!_userDataCache.containsKey(userId)) {
            userDataFutures.add(_fetchUserDataAsync(userId));
          }
        }
        
        // Wait for some user data to load (but don't block everything)
        if (userDataFutures.isNotEmpty) {
          // Load first 10 users immediately for better initial experience
          try {
            await Future.wait(userDataFutures.take(10)).timeout(
              const Duration(seconds: 3), // Don't wait too long
              onTimeout: () {
                print('⏰ User data loading timeout, continuing anyway');
                return [];
              },
            );
            print('✅ Preloaded user data for initial users');
          } catch (e) {
            print('❌ Error preloading user data: $e');
          }
          
          // Continue loading remaining users in background
          if (userDataFutures.length > 10) {
            Future.wait(userDataFutures.skip(10)).then((_) {
              print('✅ Background user data loading completed');
            }).catchError((e) {
              print('❌ Error in background user data loading: $e');
            });
          }
        }
        
        // Start listening to each user's posts subcollection
        for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
          final String userId = userDoc.id;
          _startListeningToUserPosts(userId);
        }
      }, onError: (error) {
        print('❌ Error listening to posts collection: $error');
        _postsError = 'Failed to load posts: ${error.toString()}';
        _isLoadingPosts = false;
        if (mounted) notifyListeners();
      });

    } catch (e) {
      print('❌ Error starting posts listener: $e');
      _postsError = 'Failed to load posts: ${e.toString()}';
      _isLoadingPosts = false;
      if (mounted) notifyListeners();
    }
  }

  // Start listening to a specific user's posts
  void _startListeningToUserPosts(String userId) {
    _userPostsSubscriptions[userId] = _firestore
        .collection('addpost')
        .doc(userId)
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((postsSnapshot) {
      print('📝 Posts updated for user $userId: ${postsSnapshot.docs.length} posts');
      
      // Update posts for this user and refresh the complete list
      _updatePostsFromSnapshot(userId, postsSnapshot);
      // If all user streams yield zero posts and no posts exist, finalize loading
      if (_allPosts.isEmpty) {
        _isLoadingPosts = false;
        _hasInitiallyLoaded = true;
        if (mounted) notifyListeners();
      }
    }, onError: (error) {
      print('❌ Error listening to posts for user $userId: $error');
    });
  }

  // Update posts from a snapshot and refresh the complete list
  void _updatePostsFromSnapshot(String userId, QuerySnapshot postsSnapshot) async {
    try {
      // Remove existing posts from this user
      _allPosts.removeWhere((post) => post.userId == userId);

      // Add new posts from this user
      for (QueryDocumentSnapshot postDoc in postsSnapshot.docs) {
        try {
          final Map<String, dynamic> postData = postDoc.data() as Map<String, dynamic>;
          final AddPost post = AddPost.fromJson(postData, postDoc.id);
          _allPosts.add(post);
        } catch (e) {
          print('❌ Error parsing post ${postDoc.id}: $e');
          // Continue with other posts even if one fails
        }
      }

      // Sort all posts by creation time (newest first)
      _allPosts.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      print('✅ Updated posts list: ${_allPosts.length} total posts');

      // Immediately cache user data for this user if not already cached
      if (!_userDataCache.containsKey(userId)) {
        await _fetchUserDataAsync(userId);
      }

      // Cache user data for any other new users in posts
      _cacheUserDataSync();

      // Initialize relationship sets if not already done
      _initializeRelationshipSetsSync();

      // Apply current filter
      _applyFilterSync();

      _isLoadingPosts = false;
      _hasInitiallyLoaded = true;
      if (mounted) notifyListeners();
    } catch (e) {
      print('❌ Error updating posts from snapshot: $e');
    }
  }

  // Cancel all user posts subscriptions
  void _cancelUserPostsSubscriptions() {
    for (var subscription in _userPostsSubscriptions.values) {
      subscription.cancel();
    }
    _userPostsSubscriptions.clear();
  }

  // Stop all posts listeners
  void stopListeningToPosts() {
    _postsCollectionSubscription?.cancel();
    _cancelUserPostsSubscriptions();
    print('✅ Stopped all posts listeners');
  }

  // Restart posts listeners (useful for refresh)
  void refreshPosts() {
    stopListeningToPosts();
    _allPosts.clear();
    _filteredPosts.clear();
    _hasInitiallyLoaded = false;
    startListeningToPosts();
  }

  // Cache user data for all post owners for efficient search
  // Deprecated: prefer _cacheUserDataSync() for real-time flow

  // Synchronous version of cache user data for real-time updates
  void _cacheUserDataSync() {
    try {
      // Get unique user IDs from all posts
      Set<String> userIds = _allPosts.map((post) => post.userId).toSet();
      
      for (String userId in userIds) {
        if (!_userDataCache.containsKey(userId)) {
          // For real-time updates, we'll fetch user data asynchronously without blocking
          _fetchUserDataAsync(userId);
        }
      }
    } catch (e) {
      print('❌ Error caching user data sync: $e');
    }
  }

  // Track which users we're currently loading to avoid duplicate requests
  final Set<String> _loadingUserData = {};

  // Asynchronously fetch user data for cache
  Future<void> _fetchUserDataAsync(String userId) async {
    // Avoid duplicate requests
    if (_loadingUserData.contains(userId) || _userDataCache.containsKey(userId)) {
      return;
    }
    
    _loadingUserData.add(userId);
    
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        _userDataCache[userId] = userDoc.data() as Map<String, dynamic>;
        // Trigger UI update when user data is cached (but throttle notifications)
        print('✅ Cached user data for: ${_userDataCache[userId]?['fullName'] ?? userId}');
        
        // Use post frame callback to avoid excessive notifications
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            notifyListeners();
          }
        });
      }
    } catch (e) {
      print('❌ Error fetching user data for $userId: $e');
    } finally {
      _loadingUserData.remove(userId);
    }
  }

  // Add mounted check for provider
  bool _mounted = true;
  bool get mounted => _mounted;

  // Synchronous version of initialize relationship sets
  void _initializeRelationshipSetsSync() {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // If sets are empty, initialize them asynchronously
    if (_followingUserIds.isEmpty || _connectedUserIds.isEmpty) {
      _initializeRelationshipSets();
    }
  }

  // Initialize relationship sets if they're empty (for first load)
  Future<void> _initializeRelationshipSets() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Initialize Following set if empty
      if (_followingUserIds.isEmpty) {
        final followingSnapshot = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('Following')
            .get();
        _followingUserIds = followingSnapshot.docs.map((doc) => doc.id).toSet();
        print('✅ Initialized Following set: ${_followingUserIds.length} users');
      }

      // Initialize Connections set if empty
      if (_connectedUserIds.isEmpty) {
        final connectionsSnapshot = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('Connections')
            .get();
        _connectedUserIds = connectionsSnapshot.docs.map((doc) => doc.id).toSet();
        print('✅ Initialized Connections set: ${_connectedUserIds.length} users');
      }
    } catch (e) {
      print('❌ Error initializing relationship sets: $e');
    }
  }

  // Apply current filter to posts
  Future<void> _applyFilter() async {
    if (!mounted) return;
    
    final User? currentUser = _auth.currentUser;
    final String? currentUserId = currentUser?.uid;
    
    // First filter out current user's posts from all posts
    List<AddPost> postsToFilter = _allPosts.where((post) {
      return currentUserId == null || post.userId != currentUserId;
    }).toList();
    
    if (_searchQuery.isNotEmpty) {
      // Apply comprehensive search filter
      _filteredPosts = postsToFilter.where((post) {
        final searchLower = _searchQuery.toLowerCase();
        
        // Search in post caption/description
        bool matchesCaption = post.caption.toLowerCase().contains(searchLower);
        
        // Search in tags (including hashtags without #)
        bool matchesTags = post.tags.any((tag) {
          final tagLower = tag.toLowerCase();
          return tagLower.contains(searchLower) || 
                 tagLower.replaceAll('#', '').contains(searchLower);
        });
        
        // Search in location address (city, country, etc.)
        bool matchesLocation = post.location.address.toLowerCase().contains(searchLower);
        
        // Search in user data (name, username, etc.)
        final userData = _userDataCache[post.userId];
        bool matchesUser = false;
        if (userData != null) {
          final fullName = (userData['fullName'] ?? '').toLowerCase();
          final userName = (userData['userName'] ?? '').toLowerCase();
          final email = (userData['email'] ?? '').toLowerCase();
          
          matchesUser = fullName.contains(searchLower) ||
                       userName.contains(searchLower) ||
                       email.contains(searchLower);
        }
        
        // Search in comments text
        bool matchesComments = post.comments.any((comment) => 
          comment.text.toLowerCase().contains(searchLower)
        );
        
        return matchesCaption || matchesTags || matchesLocation || matchesUser || matchesComments;
      }).toList();
    } else {
      // Apply feed filter (excluding current user's posts)
      switch (_selectedFilter) {
        case 'Following':
          _filteredPosts = _filterFollowingPostsSync(postsToFilter);
          break;
        case 'Connections':
          _filteredPosts = _filterConnectionsPostsSync(postsToFilter);
          break;
        case 'Global':
        default:
          _filteredPosts = postsToFilter;
          break;
      }
    }
    
    // Ensure posts are sorted by creation time (newest first)
    _filteredPosts.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    
    if (mounted) {
      notifyListeners();
    }
  }

  // Synchronous version of _applyFilter for real-time updates
  void _applyFilterSync() {
    if (!mounted) return;
    
    final User? currentUser = _auth.currentUser;
    final String? currentUserId = currentUser?.uid;
    
    // First filter out current user's posts from all posts
    List<AddPost> postsToFilter = _allPosts.where((post) {
      return currentUserId == null || post.userId != currentUserId;
    }).toList();
    
    if (_searchQuery.isNotEmpty) {
      // Apply comprehensive search filter
      _filteredPosts = postsToFilter.where((post) {
        final searchLower = _searchQuery.toLowerCase();
        
        // Search in post caption/description
        bool matchesCaption = post.caption.toLowerCase().contains(searchLower);
        
        // Search in tags (including hashtags without #)
        bool matchesTags = post.tags.any((tag) {
          final tagLower = tag.toLowerCase();
          return tagLower.contains(searchLower) || 
                 tagLower.replaceAll('#', '').contains(searchLower);
        });
        
        // Search in location address (city, country, etc.)
        bool matchesLocation = post.location.address.toLowerCase().contains(searchLower);
        
        // Search in user data (name, username, etc.)
        final userData = _userDataCache[post.userId];
        bool matchesUser = false;
        if (userData != null) {
          final fullName = (userData['fullName'] ?? '').toLowerCase();
          final userName = (userData['userName'] ?? '').toLowerCase();
          final email = (userData['email'] ?? '').toLowerCase();
          
          matchesUser = fullName.contains(searchLower) ||
                       userName.contains(searchLower) ||
                       email.contains(searchLower);
        }
        
        // Search in comments text
        bool matchesComments = post.comments.any((comment) => 
          comment.text.toLowerCase().contains(searchLower)
        );
        
        return matchesCaption || matchesTags || matchesLocation || matchesUser || matchesComments;
      }).toList();
    } else {
      // Apply feed filter (excluding current user's posts)
      switch (_selectedFilter) {
        case 'Following':
          _filteredPosts = _filterFollowingPostsSync(postsToFilter);
          break;
        case 'Connections':
          _filteredPosts = _filterConnectionsPostsSync(postsToFilter);
          break;
        case 'Global':
        default:
          _filteredPosts = postsToFilter;
          break;
      }
    }
    
    // Ensure posts are sorted by creation time (newest first)
    _filteredPosts.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    
    if (mounted) {
      notifyListeners();
    }
  }

  // Synchronous filter for Following posts using cached user IDs
  List<AddPost> _filterFollowingPostsSync(List<AddPost> posts) {
    List<AddPost> filteredPosts = posts.where((post) {
      return _followingUserIds.contains(post.userId);
    }).toList();
    
    print('✅ Filtered to ${filteredPosts.length} posts from ${_followingUserIds.length} following users');
    return filteredPosts;
  }

  // Synchronous filter for Connections posts using cached user IDs
  List<AddPost> _filterConnectionsPostsSync(List<AddPost> posts) {
    List<AddPost> filteredPosts = posts.where((post) {
      return _connectedUserIds.contains(post.userId);
    }).toList();
    
    print('✅ Filtered to ${filteredPosts.length} posts from ${_connectedUserIds.length} connected users');
    return filteredPosts;
  }


  Future<void> setSearchQuery(String query) async {
    if (!mounted) return;
    _searchQuery = query;
    await _applyFilter();
  }

  void onSearchChanged(String value) {
    if (!mounted) return;
    
    // Cancel previous debounce timer
    _searchDebounceTimer?.cancel();
    
    // Set up new debounce timer
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setSearchQuery(value);
      }
    });
  }

  void clearSearch() {
    if (!mounted) return;
    _searchController.clear();
    setSearchQuery('');
  }

  // Get cached user data for a specific user
  Map<String, dynamic>? getCachedUserData(String userId) {
    // If user data is not cached, fetch it asynchronously
    if (!_userDataCache.containsKey(userId)) {
      _fetchUserDataAsync(userId);
    }
    return _userDataCache[userId];
  }

  // Check if current user has liked a specific post
  Future<bool> isPostLiked(String postId, String postOwnerId) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return false;

      final likeDoc = await _firestore
          .collection('addpost')
          .doc(postOwnerId)
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(user.uid)
          .get();

      return likeDoc.exists;
    } catch (e) {
      print('❌ Error checking if post is liked: $e');
      return false;
    }
  }

  // Get share count for a post with real-time updates
  Stream<int> getShareCountStream(String postId, String postOwnerId) {
    return _firestore
        .collection('addpost')
        .doc(postOwnerId)
        .collection('posts')
        .doc(postId)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      return (data != null ? (data['shares'] ?? 0) : 0) as int;
    });
  }

  @override
  void dispose() {
    _mounted = false;
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _userDataCache.clear();
    _loadingUserData.clear();
    _followingSubscription?.cancel();
    _connectionsSubscription?.cancel();
    _postsCollectionSubscription?.cancel();
    _cancelUserPostsSubscriptions();
    super.dispose();
  }
}