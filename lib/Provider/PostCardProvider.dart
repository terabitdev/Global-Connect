import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'user_profile_provider.dart';
import '../Model/CommentModel.dart';
import 'PostInteractionProvider.dart';

class PostCardProvider extends ChangeNotifier {
  final Map<String, int> _currentImageIndex = {};
  final PostInteractionProvider _interactionProvider;

  PostCardProvider(this._interactionProvider);

  // Getters - delegate to PostInteractionProvider
  bool isLiked(String postId) => _interactionProvider.isPostLiked(postId);
  int likeCount(String postId) => _interactionProvider.getLikeCount(postId);
  List<Map<String, dynamic>> comments(String postId) => _interactionProvider.getComments(postId);
  int commentCount(String postId) => _interactionProvider.getCommentCount(postId);
  int currentImageIndex(String postId) => _currentImageIndex[postId] ?? 0;

  // Initialize post data
  Future<void> initializePost(String postId, String postOwnerId, {
    int initialLikeCount = 0,
    List<CommentModel> comments = const [],
  }) async {
    _currentImageIndex[postId] = 0;
    await _interactionProvider.initializePost(postId, postOwnerId);
    notifyListeners();
  }

  // Toggle like - delegate to PostInteractionProvider
  Future<void> toggleLike(String postId, String postOwnerId) async {
    await _interactionProvider.toggleLike(postId, postOwnerId);
    notifyListeners();
  }

  // Add comment - delegate to PostInteractionProvider
  Future<void> addComment(String postId, String postOwnerId, String comment) async {
    await _interactionProvider.addComment(postId, postOwnerId, comment);
    notifyListeners();
  }

  // Share post - delegate to PostInteractionProvider
  Future<void> sharePost(String postId, String postOwnerId, List<String> sharedWithUserIds) async {
    await _interactionProvider.sharePost(postId, postOwnerId, sharedWithUserIds);
    notifyListeners();
  }

  // Update current image index
  void updateCurrentImageIndex(String postId, int index) {
    _currentImageIndex[postId] = index;
    notifyListeners();
  }

  // Get real-time streams
  Stream<int> getLikeCountStream(String postId, String postOwnerId) {
    return _interactionProvider.listenToLikeCount(postId, postOwnerId);
  }

  Stream<List<Map<String, dynamic>>> getCommentsStream(String postId, String postOwnerId) {
    return _interactionProvider.listenToComments(postId, postOwnerId);
  }

  Stream<bool> getUserLikeStream(String postId, String postOwnerId) {
    return _interactionProvider.listenToUserLike(postId, postOwnerId);
  }

  Stream<int> getShareCountStream(String postId, String postOwnerId) {
    return _interactionProvider.listenToShareCount(postId, postOwnerId);
  }

  // Delete comment - delegate to PostInteractionProvider
  Future<bool> deleteComment(String postId, String postOwnerId, String commentId) async {
    final result = await _interactionProvider.deleteComment(postId, postOwnerId, commentId);
    if (result) {
      notifyListeners();
    }
    return result;
  }

  // Check if current user is post owner
  bool isPostOwner(String postOwnerId) {
    return _interactionProvider.isPostOwner(postOwnerId);
  }

  // Get user details - delegate to PostInteractionProvider
  Map<String, dynamic>? getUserDetails(String userId) {
    return _interactionProvider.getUserDetails(userId);
  }

  // Preload user details for comments
  Future<void> preloadUserDetailsForComments(String postId) async {
    final comments = _interactionProvider.getComments(postId);
    final userIds = comments.map((comment) => comment['userId'] as String).toList();
    await _interactionProvider.preloadUserDetails(userIds);
  }

  Stream<Map<String, dynamic>?> getUserDetailsStream(String userId) {
    return _interactionProvider.getUserDetailsStream(userId);
  }

  // Clean up resources for a specific post
  void disposePost(String postId) {
    _currentImageIndex.remove(postId);
    _interactionProvider.clearPostCache(postId);
  }

  // Location / Flag helpers moved from UI to provider
  Future<String?> getCountry(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        return placemarks.first.country;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String getFlagByNationalityProxy(String? nationality) {
    return getFlagByNationality(nationality);
  }
}