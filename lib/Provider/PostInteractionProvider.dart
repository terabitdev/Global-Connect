import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/firebase_services.dart';

class PostInteractionProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for local state
  final Map<String, bool> _likedPosts = {};
  final Map<String, int> _likeCounts = {};
  final Map<String, List<Map<String, dynamic>>> _postComments = {};
  final Map<String, int> _commentCounts = {};
  
  // Cache for user details to avoid repeated fetches
  final Map<String, Map<String, dynamic>> _userDetailsCache = {};

  // Getter
  bool isPostLiked(String postId) => _likedPosts[postId] ?? false;
  int getLikeCount(String postId) => _likeCounts[postId] ?? 0;
  List<Map<String, dynamic>> getComments(String postId) => _postComments[postId] ?? [];
  int getCommentCount(String postId) => _commentCounts[postId] ?? 0;

  // Initialize post data - fetch from Firestore
  Future<void> initializePost(String postId, String postOwnerId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get post reference
      final postRef = _firestore
          .collection('addpost')
          .doc(postOwnerId)
          .collection('posts')
          .doc(postId);

      // Check if current user has liked this post
      final likeDoc = await postRef
          .collection('likes')
          .doc(currentUser.uid)
          .get();
      
      _likedPosts[postId] = likeDoc.exists;

      // Get like count
      final likesSnapshot = await postRef.collection('likes').get();
      _likeCounts[postId] = likesSnapshot.docs.length;

      // Get comments
      final commentsSnapshot = await postRef
          .collection('comments')
          .orderBy('createdAt', descending: false)
          .get();
      
      _postComments[postId] = commentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'userId': data['userId'] ?? '',
          'comment': data['comment'] ?? '',
          'createdAt': data['createdAt'],
        };
      }).toList();

      _commentCounts[postId] = _postComments[postId]!.length;

      // Preload user details for all comment authors
      final userIds = _postComments[postId]!.map((comment) => comment['userId'] as String).toSet().toList();
      if (userIds.isNotEmpty) {
        // Use Future.microtask to avoid calling setState during build
        Future.microtask(() => preloadUserDetails(userIds));
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error initializing post: $e');
    }
  }

  // Toggle like functionality
  Future<void> toggleLike(String postId, String postOwnerId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final postRef = _firestore
          .collection('addpost')
          .doc(postOwnerId)
          .collection('posts')
          .doc(postId);

      final likeRef = postRef.collection('likes').doc(currentUser.uid);

      // Optimistic UI update
      final wasLiked = _likedPosts[postId] ?? false;
      _likedPosts[postId] = !wasLiked;
      _likeCounts[postId] = (_likeCounts[postId] ?? 0) + (wasLiked ? -1 : 1);
      notifyListeners();

      bool isLiking = false;
      await _firestore.runTransaction((transaction) async {
        final likeSnapshot = await transaction.get(likeRef);

        if (likeSnapshot.exists) {
          // Unlike: delete like doc and decrement likes field atomically
          transaction.delete(likeRef);
          transaction.update(postRef, {
            'likes': FieldValue.increment(-1),
          });
          _likedPosts[postId] = false;
          isLiking = false;
        } else {
          // Like: create like doc and increment likes field atomically
          transaction.set(likeRef, {
            'userId': currentUser.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.update(postRef, {
            'likes': FieldValue.increment(1),
          });
          _likedPosts[postId] = true;
          isLiking = true;
        }
      });

      // Create like notification if user is liking the post and it's not their own post
      if (isLiking && currentUser.uid != postOwnerId) {
        try {
          print('🔍 DEBUGGING: About to create like notification');
          print('🔍 DEBUGGING: From User: ${currentUser.uid}');
          print('🔍 DEBUGGING: To User: $postOwnerId');
          print('🔍 DEBUGGING: Post ID: $postId');
          
          // Get post data to include image URL in notification
          final postDoc = await postRef.get();
          String? postImageUrl;
          if (postDoc.exists) {
            final postData = postDoc.data() as Map<String, dynamic>?;
            final images = postData?['images'] as List<dynamic>?;
            if (images != null && images.isNotEmpty) {
              postImageUrl = images.first as String?;
            }
          }

          await FirebaseServices.instance.createLikeNotification(
            currentUser.uid,
            postOwnerId,
            postId,
            postImageUrl,
          );
          print('✅ Like notification created successfully');
          print('🔍 DEBUGGING: Notification should now trigger Cloud Function');
        } catch (e) {
          print('❌ Error creating like notification: $e');
          // Don't fail the like operation if notification creation fails
        }
      } else {
        if (!isLiking) {
          print('🔍 DEBUGGING: User is unliking, no notification needed');
        } else if (currentUser.uid == postOwnerId) {
          print('🔍 DEBUGGING: User liked their own post, no notification needed');
        }
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error toggling like: $e');
      // Rollback optimistic update on error
      _likedPosts[postId] = !(_likedPosts[postId] ?? false);
      _likeCounts[postId] = (_likeCounts[postId] ?? 0) + ((_likedPosts[postId] ?? false) ? 1 : -1);
      notifyListeners();
    }
  }

  // Add comment functionality
  Future<void> addComment(String postId, String postOwnerId, String comment) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final postRef = _firestore
          .collection('addpost')
          .doc(postOwnerId)
          .collection('posts')
          .doc(postId);

      final commentData = {
        'userId': currentUser.uid,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add comment to subcollection
      await postRef.collection('comments').add(commentData);

      // Don't update local cache here - let the real-time listener handle it
      // This prevents duplicate comments

      // Get current comment count from Firestore for accuracy
      final commentsSnapshot = await postRef.collection('comments').get();
      final actualCount = commentsSnapshot.docs.length;

      // Update the main post document with comment count
      await postRef.update({
        'commentCount': actualCount,
      });

      // Create comment notification if it's not the post owner commenting on their own post
      if (currentUser.uid != postOwnerId) {
        try {
          print('🔍 DEBUGGING: About to create comment notification');
          print('🔍 DEBUGGING: From User: ${currentUser.uid}');
          print('🔍 DEBUGGING: To User: $postOwnerId');
          print('🔍 DEBUGGING: Post ID: $postId');
          print('🔍 DEBUGGING: Comment: $comment');
          
          // Get post data to include image URL in notification
          final postDoc = await postRef.get();
          String? postImageUrl;
          if (postDoc.exists) {
            final postData = postDoc.data() as Map<String, dynamic>?;
            final images = postData?['images'] as List<dynamic>?;
            if (images != null && images.isNotEmpty) {
              postImageUrl = images.first as String?;
            }
          }

          await FirebaseServices.instance.createCommentNotification(
            currentUser.uid,
            postOwnerId,
            postId,
            postImageUrl,
            comment, // Pass the comment text
          );
          print('✅ Comment notification created successfully');
          print('🔍 DEBUGGING: Notification should now trigger Cloud Function');
        } catch (e) {
          print('❌ Error creating comment notification: $e');
          // Don't fail the comment operation if notification creation fails
        }
      } else {
        print('🔍 DEBUGGING: User commented on their own post, no notification needed');
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error adding comment: $e');
    }
  }

  // Share post functionality
  Future<void> sharePost(String postId, String postOwnerId, List<String> sharedWithUserIds) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final postRef = _firestore
          .collection('addpost')
          .doc(postOwnerId)
          .collection('posts')
          .doc(postId);

      // Create share record
      final shareData = {
        'sharedBy': currentUser.uid,
        'sharedWith': sharedWithUserIds,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add share to subcollection
      await postRef.collection('shares').add(shareData);

      // Get current share count and increment
      final sharesSnapshot = await postRef.collection('shares').get();
      final shareCount = sharesSnapshot.docs.length;

      // Update the main post document with share count
      await postRef.update({
        'shares': shareCount,
      });

      notifyListeners();
    } catch (e) {
      print('❌ Error sharing post: $e');
    }
  }

  // Get share count for a post
  Future<int> getShareCount(String postId, String postOwnerId) async {
    try {
      final postRef = _firestore
          .collection('addpost')
          .doc(postOwnerId)
          .collection('posts')
          .doc(postId);

      final sharesSnapshot = await postRef.collection('shares').get();
      return sharesSnapshot.docs.length;
    } catch (e) {
      print('❌ Error getting share count: $e');
      return 0;
    }
  }

  // Listen to real-time updates for a post's likes
  Stream<int> listenToLikeCount(String postId, String postOwnerId) {
    return _firestore
        .collection('addpost')
        .doc(postOwnerId)
        .collection('posts')
        .doc(postId)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      final count = (data != null ? (data['likes'] ?? 0) : 0) as int;
      _likeCounts[postId] = count;
      return count;
    });
  }

  // Listen to real-time updates for a post's comments
  Stream<List<Map<String, dynamic>>> listenToComments(String postId, String postOwnerId) {
    return _firestore
        .collection('addpost')
        .doc(postOwnerId)
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      final comments = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'userId': data['userId'] ?? '',
          'comment': data['comment'] ?? '',
          'createdAt': data['createdAt'],
        };
      }).toList();
      
      _postComments[postId] = comments;
      _commentCounts[postId] = comments.length;
      
      // Preload user details for comment authors
      final userIds = comments.map((comment) => comment['userId'] as String).toSet().toList();
      if (userIds.isNotEmpty) {
        // Use Future.microtask to avoid calling setState during build
        Future.microtask(() => preloadUserDetails(userIds));
      }
      
      return comments;
    });
  }

  // Listen to whether current user has liked a post
  Stream<bool> listenToUserLike(String postId, String postOwnerId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection('addpost')
        .doc(postOwnerId)
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(currentUser.uid)
        .snapshots()
        .map((doc) {
      final isLiked = doc.exists;
      _likedPosts[postId] = isLiked;
      return isLiked;
    });
  }

  // Listen to real-time updates for a post's share count
  Stream<int> listenToShareCount(String postId, String postOwnerId) {
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

  // Delete comment functionality - only post owner can delete comments
  Future<bool> deleteComment(String postId, String postOwnerId, String commentId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        return false;
      }

      // Check if current user is the post owner
      if (currentUser.uid != postOwnerId) {
        print('❌ Only post owner can delete comments');
        return false;
      }

      final postRef = _firestore
          .collection('addpost')
          .doc(postOwnerId)
          .collection('posts')
          .doc(postId);

      // Delete comment from subcollection
      await postRef.collection('comments').doc(commentId).delete();

      // Get updated comment count from Firestore
      final commentsSnapshot = await postRef.collection('comments').get();
      final actualCount = commentsSnapshot.docs.length;

      // Update the main post document with new comment count
      await postRef.update({
        'commentCount': actualCount,
      });

      // Update local cache
      final updatedComments = _postComments[postId]?.where((comment) => comment['id'] != commentId).toList() ?? [];
      _postComments[postId] = updatedComments;
      _commentCounts[postId] = updatedComments.length;

      notifyListeners();
      print('✅ Comment deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting comment: $e');
      return false;
    }
  }

  // Check if current user is the post owner
  bool isPostOwner(String postOwnerId) {
    final currentUser = _auth.currentUser;
    return currentUser != null && currentUser.uid == postOwnerId;
  }

  // Clear cache for a specific post
  void clearPostCache(String postId) {
    _likedPosts.remove(postId);
    _likeCounts.remove(postId);
    _postComments.remove(postId);
    _commentCounts.remove(postId);
    // Don't clear user details cache as it can be reused across posts
  }

  // Clear all cache
  void clearAllCache() {
    _likedPosts.clear();
    _likeCounts.clear();
    _postComments.clear();
    _commentCounts.clear();
    _userDetailsCache.clear();
  }

  // Get user details by userId with caching
  Map<String, dynamic>? getUserDetails(String userId) {
    return _userDetailsCache[userId];
  }

  // Get user details stream for real-time updates
  Stream<Map<String, dynamic>?> getUserDetailsStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        final userDetails = {
          'fullName': userData['fullName'] ?? 'Unknown User',
          'profileImageUrl': userData['profileImageUrl'] ?? '',
        };
        // Cache the user details
        _userDetailsCache[userId] = userDetails;
        return userDetails;
      }
      return null;
    });
  }

  // Preload user details for a list of userIds
  Future<void> preloadUserDetails(List<String> userIds) async {
    try {
      for (String userId in userIds) {
        if (!_userDetailsCache.containsKey(userId)) {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            _userDetailsCache[userId] = {
              'fullName': userData['fullName'] ?? 'Unknown User',
              'profileImageUrl': userData['profileImageUrl'] ?? '',
            };
          }
        }
      }
      notifyListeners();
    } catch (e) {
      print('❌ Error preloading user details: $e');
    }
  }
}