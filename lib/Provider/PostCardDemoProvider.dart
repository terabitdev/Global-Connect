import 'package:flutter/foundation.dart';
import '../Model/CommentModel.dart';
import '../Model/ShareUserModel.dart';

class PostCardDemoProvider with ChangeNotifier {
  // Sample data for demonstration
  static List<CommentModel> getSampleComments() {
    return [
      CommentModel(
        id: '1',
        userId: 'user1',
        userName: 'Alice Johnson',
        userAvatar: 'assets/images/default_avatar.png',
        comment: 'This looks amazing! What a beautiful place to visit.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        likeCount: 5,
        isLiked: false,
      ),
      CommentModel(
        id: '2',
        userId: 'user2',
        userName: 'Mark Wilson',
        userAvatar: 'assets/images/default_avatar.png',
        comment: 'I was there last year! The sunset views are incredible. Highly recommend staying for the evening.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        likeCount: 12,
        isLiked: true,
      ),
      CommentModel(
        id: '3',
        userId: 'user3',
        userName: 'Sarah Chen',
        userAvatar: 'assets/images/default_avatar.png',
        comment: '❤️',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        likeCount: 3,
        isLiked: false,
      ),
      CommentModel(
        id: '4',
        userId: 'user4',
        userName: 'David Brown',
        userAvatar: 'assets/images/default_avatar.png',
        comment: 'Adding this to my travel bucket list! Thanks for sharing.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        likeCount: 8,
        isLiked: true,
      ),
    ];
  }

  static List<ShareUserModel> getSampleUsers() {
    return [
      ShareUserModel(
        id: 'user1',
        name: 'Alice Johnson',
        avatar: 'assets/images/default_avatar.png',
        username: 'alice_j',
        isOnline: true,
        isMutualFriend: true,
      ),
      ShareUserModel(
        id: 'user2',
        name: 'Mark Wilson',
        avatar: 'assets/images/default_avatar.png',
        username: 'markw_travels',
        isOnline: false,
        lastSeen: '2h ago',
        isMutualFriend: true,
      ),
      ShareUserModel(
        id: 'user3',
        name: 'Sarah Chen',
        avatar: 'assets/images/default_avatar.png',
        username: 'sarah_explorer',
        isOnline: true,
        isMutualFriend: false,
      ),
      ShareUserModel(
        id: 'user4',
        name: 'David Brown',
        avatar: 'assets/images/default_avatar.png',
        username: 'david_adventures',
        isOnline: false,
        lastSeen: '1d ago',
        isMutualFriend: true,
      ),
      ShareUserModel(
        id: 'user5',
        name: 'Emma Thompson',
        avatar: 'assets/images/default_avatar.png',
        username: 'emma_wanderlust',
        isOnline: true,
        isMutualFriend: false,
      ),
      ShareUserModel(
        id: 'user6',
        name: 'James Miller',
        avatar: 'assets/images/default_avatar.png',
        username: 'james_captures',
        isOnline: false,
        lastSeen: '30m ago',
        isMutualFriend: true,
      ),
      ShareUserModel(
        id: 'user7',
        name: 'Olivia Davis',
        avatar: 'assets/images/default_avatar.png',
        username: 'olivia_globe',
        isOnline: false,
        lastSeen: '3h ago',
        isMutualFriend: false,
      ),
      ShareUserModel(
        id: 'user8',
        name: 'Michael Garcia',
        avatar: 'assets/images/default_avatar.png',
        username: 'mike_journey',
        isOnline: true,
        isMutualFriend: true,
      ),
    ];
  }

  // Post data management
  Map<String, bool> _likedPosts = {};
  Map<String, int> _likeCounts = {};
  Map<String, List<CommentModel>> _postComments = {};

  bool isPostLiked(String postId) {
    return _likedPosts[postId] ?? false;
  }

  int getPostLikeCount(String postId) {
    return _likeCounts[postId] ?? 0;
  }

  List<CommentModel> getPostComments(String postId) {
    return _postComments[postId] ?? [];
  }

  void togglePostLike(String postId) {
    _likedPosts[postId] = !(_likedPosts[postId] ?? false);
    if (_likedPosts[postId]!) {
      _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
    } else {
      _likeCounts[postId] = (_likeCounts[postId] ?? 1) - 1;
    }
    notifyListeners();
  }

  void addComment(String postId, String comment) {
    if (_postComments[postId] == null) {
      _postComments[postId] = [];
    }
    
    _postComments[postId]!.add(
      CommentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current_user',
        userName: 'You',
        userAvatar: 'assets/images/default_avatar.png',
        comment: comment,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void sharePost(String postId, List<String> userIds) {
    // Handle sharing logic here
    if (kDebugMode) {
      print('Sharing post $postId with users: $userIds');
    }
  }

  void editPost(String postId) {
    // Handle edit post logic here
    if (kDebugMode) {
      print('Editing post: $postId');
    }
  }

  void deletePost(String postId) {
    // Handle delete post logic here
    _likedPosts.remove(postId);
    _likeCounts.remove(postId);
    _postComments.remove(postId);
    notifyListeners();
    
    if (kDebugMode) {
      print('Deleted post: $postId');
    }
  }

  // Sample post data
  static List<Map<String, dynamic>> getSamplePosts() {
    return [
      {
        'postId': 'post_1',
        'userAvatar': 'assets/images/default_avatar.png',
        'userName': 'John Traveler',
        'userLocation': 'Paris, France',
        'locationFlag': '🇫🇷',
        'timeAgo': '2h ago',
        'postImage': 'assets/images/default_avatar.png',
        'description': 'Exploring the beautiful streets of Paris! The architecture here is absolutely stunning and every corner tells a story.',
        'hashtags': '#Paris #Travel #Architecture #France #Wanderlust',
        'initialLikeCount': 24,
        'isLiked': false,
      },
      {
        'postId': 'post_2',
        'userAvatar': 'assets/images/default_avatar.png',
        'userName': 'Maria Explorer',
        'userLocation': 'Tokyo, Japan',
        'locationFlag': '🇯🇵',
        'timeAgo': '5h ago',
        'postImage': 'assets/images/default_avatar.png',
        'description': 'Amazing sushi experience in Shibuya! The chef was incredibly skilled and the flavors were out of this world.',
        'hashtags': '#Tokyo #Sushi #Japan #FoodLover #Shibuya',
        'initialLikeCount': 156,
        'isLiked': true,
      },
      {
        'postId': 'post_3',
        'userAvatar': 'assets/images/default_avatar.png',
        'userName': 'Alex Adventure',
        'userLocation': 'New York, USA',
        'locationFlag': '🇺🇸',
        'timeAgo': '1d ago',
        'postImage': 'assets/images/default_avatar.png',
        'description': 'Central Park in autumn is magical ✨',
        'hashtags': '#NewYork #CentralPark #Autumn #NYC #Nature',
        'initialLikeCount': 89,
        'isLiked': false,
      },
    ];
  }
}