import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/AddPostModel.dart';
import '../Model/userModel.dart';

enum SharedPostState { loading, loaded, error, notFound }

class SharedPostData {
  final AddPost post;
  final UserModel user;

  SharedPostData({required this.post, required this.user});
}

class SharedPostProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache for shared posts to avoid refetching
  final Map<String, SharedPostData> _postCache = {};
  final Map<String, SharedPostState> _postStates = {};
  final Map<String, String?> _postErrors = {};

  // Getters
  SharedPostState getPostState(String postKey) => _postStates[postKey] ?? SharedPostState.loading;
  SharedPostData? getPostData(String postKey) => _postCache[postKey];
  String? getPostError(String postKey) => _postErrors[postKey];

  // Generate unique key for caching
  String _generatePostKey(String postId, String postOwnerId) {
    return '${postOwnerId}_$postId';
  }

  // Load shared post data
  Future<void> loadSharedPost(String postId, String postOwnerId) async {
    final postKey = _generatePostKey(postId, postOwnerId);
    
    // Return if already loaded successfully
    if (_postStates[postKey] == SharedPostState.loaded) {
      return;
    }

    // Set loading state
    _postStates[postKey] = SharedPostState.loading;
    _postErrors[postKey] = null;
    notifyListeners();

    try {
      // Fetch both post and user data simultaneously
      final List<Future<DocumentSnapshot>> futures = [
        _firestore
            .collection('addpost')
            .doc(postOwnerId)
            .collection('posts')
            .doc(postId)
            .get(),
        _firestore
            .collection('users')
            .doc(postOwnerId)
            .get(),
      ];

      final results = await Future.wait(futures);
      final postDoc = results[0];
      final userDoc = results[1];

      // Check if both documents exist
      if (!postDoc.exists || !userDoc.exists) {
        _postStates[postKey] = SharedPostState.notFound;
        _postErrors[postKey] = postDoc.exists ? 'User not found' : 'Post not found';
        notifyListeners();
        return;
      }

      // Parse the data
      final postData = postDoc.data() as Map<String, dynamic>;
      final userData = userDoc.data() as Map<String, dynamic>;

      // Create models
      final post = AddPost.fromJson(postData, postDoc.id);
      final user = UserModel.fromMap(userData);

      // Cache the data
      _postCache[postKey] = SharedPostData(post: post, user: user);
      _postStates[postKey] = SharedPostState.loaded;
      
      notifyListeners();
    } catch (e) {
      _postStates[postKey] = SharedPostState.error;
      _postErrors[postKey] = e.toString();
      notifyListeners();
      print('❌ Error loading shared post: $e');
    }
  }

  // Get real-time updates for a post (optional feature)
  Stream<SharedPostData?> getSharedPostStream(String postId, String postOwnerId) {
    final postKey = _generatePostKey(postId, postOwnerId);
    
    return Stream.periodic(const Duration(minutes: 5))
        .asyncMap<SharedPostData?>((index) async {
      await loadSharedPost(postId, postOwnerId);
      return _postCache[postKey];
    });
  }

  // Clear cache for memory management
  void clearCache() {
    _postCache.clear();
    _postStates.clear();
    _postErrors.clear();
    notifyListeners();
  }

  // Remove specific post from cache
  void removeFromCache(String postId, String postOwnerId) {
    final postKey = _generatePostKey(postId, postOwnerId);
    _postCache.remove(postKey);
    _postStates.remove(postKey);
    _postErrors.remove(postKey);
    notifyListeners();
  }

  // Preload post (useful for performance)
  void preloadPost(String postId, String postOwnerId) {
    final postKey = _generatePostKey(postId, postOwnerId);
    if (_postStates[postKey] == null) {
      loadSharedPost(postId, postOwnerId);
    }
  }

  @override
  void dispose() {
    _postCache.clear();
    _postStates.clear();
    _postErrors.clear();
    super.dispose();
  }
}