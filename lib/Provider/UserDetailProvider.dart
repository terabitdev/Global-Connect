import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../Model/followModel.dart';
import '../Model/connectionModel.dart';
import '../core/services/firebase_services.dart';
import '../Model/userModel.dart';

class UserDetailProvider extends ChangeNotifier {
  bool _isFollowing = false;
  bool _isFollowedByTarget = false;
  bool _isLoading = false;
  bool _hasCheckedStatus = false;
  String? _currentUserId;
  String? _lastCheckedUserId;
  
  // Connection related properties
  ConnectionStatus _connectionStatus = ConnectionStatus.none;
  bool _isConnectionLoading = false;
  bool _hasCheckedConnectionStatus = false;
  StreamSubscription<DocumentSnapshot>? _connectionListener;
  StreamSubscription<DocumentSnapshot>? _requestListener;
  
  // Cache for follow status
  static final Map<String, bool> _followStatusCache = {};
  static final Map<String, bool> _followedByTargetCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static final Map<String, ConnectionStatus> _connectionStatusCache = {};
  static final Map<String, DateTime> _connectionCacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  bool get isFollowing => _isFollowing;
  bool get isFollowedByTarget => _isFollowedByTarget;
  bool get isLoading => _isLoading;
  bool get hasCheckedStatus => _hasCheckedStatus;
  String? get currentUserId => _currentUserId;
  
  // Connection getters
  ConnectionStatus get connectionStatus => _connectionStatus;
  bool get isConnectionLoading => _isConnectionLoading;
  bool get hasCheckedConnectionStatus => _hasCheckedConnectionStatus;

  UserDetailProvider() {
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  void resetForNewUser() {
    _isFollowing = false;
    _isFollowedByTarget = false;
    _isLoading = false;
    _hasCheckedStatus = false;
    _lastCheckedUserId = null;
    
    // Reset connection state
    _connectionStatus = ConnectionStatus.none;
    _isConnectionLoading = false;
    _hasCheckedConnectionStatus = false;
    
    // Cancel any existing listeners
    _connectionListener?.cancel();
    _connectionListener = null;
    _requestListener?.cancel();
    _requestListener = null;
  }
  
  @override
  void dispose() {
    _connectionListener?.cancel();
    _requestListener?.cancel();
    super.dispose();
  }

  Future<void> checkFollowingStatus(String targetUserId) async {
    if (_currentUserId == null) return;
    
    // If checking same user and already have status, return early
    if (_lastCheckedUserId == targetUserId && _hasCheckedStatus) {
      return;
    }

    final cacheKey = '${_currentUserId}_$targetUserId';
    
    // Check cache first
    if (_followStatusCache.containsKey(cacheKey) && 
        _followedByTargetCache.containsKey(cacheKey)) {
      final cacheTime = _cacheTimestamps[cacheKey];
      if (cacheTime != null && 
          DateTime.now().difference(cacheTime) < _cacheExpiry) {
        _isFollowing = _followStatusCache[cacheKey]!;
        _isFollowedByTarget = _followedByTargetCache[cacheKey]!;
        _hasCheckedStatus = true;
        _lastCheckedUserId = targetUserId;
        notifyListeners();
        return;
      }
    }
    
    try {
      // Only show loading for initial check or if cache is empty
      if (!_hasCheckedStatus || _lastCheckedUserId != targetUserId) {
        _isLoading = true;
        notifyListeners();
      }

      // Check if current user follows target user
      _isFollowing = await FirebaseServices.instance
          .isFollowing(_currentUserId!, targetUserId);
      
      // Check if target user follows current user (for "Follow Back" feature)
      _isFollowedByTarget = await FirebaseServices.instance
          .isFollowing(targetUserId, _currentUserId!);
      
      // Cache the results
      _followStatusCache[cacheKey] = _isFollowing;
      _followedByTargetCache[cacheKey] = _isFollowedByTarget;
      _cacheTimestamps[cacheKey] = DateTime.now();
      _hasCheckedStatus = true;
      _lastCheckedUserId = targetUserId;
          
    } catch (e) {
      print('❌ Error checking following status: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFollow(UserModel targetUser) async {
    if (_currentUserId == null || _isLoading) return;
    
    // Optimistic UI update - immediately change the UI
    final originalStatus = _isFollowing;
    _isFollowing = !_isFollowing;
    _isLoading = true;
    notifyListeners();
    
    try {
      // Update cache optimistically
      final cacheKey = '${_currentUserId}_${targetUser.uid}';
      _followStatusCache[cacheKey] = _isFollowing;
      // Keep _isFollowedByTarget as is - it won't change when we toggle our follow
      _cacheTimestamps[cacheKey] = DateTime.now();

      // Perform the actual operation
      if (originalStatus) {
        await _unfollowUser(targetUser);
      } else {
        await _followUser(targetUser);
      }
      
    } catch (e) {
      print('❌ Error toggling follow: $e');
      
      // Revert optimistic update on error
      _isFollowing = originalStatus;
      final cacheKey = '${_currentUserId}_${targetUser.uid}';
      _followStatusCache[cacheKey] = originalStatus;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      // Show error or refresh from server
      await _refreshFromServer(targetUser.uid);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshFromServer(String targetUserId) async {
    try {
      final actualStatus = await FirebaseServices.instance
          .isFollowing(_currentUserId!, targetUserId);
      
      final actualFollowedByTarget = await FirebaseServices.instance
          .isFollowing(targetUserId, _currentUserId!);
      
      _isFollowing = actualStatus;
      _isFollowedByTarget = actualFollowedByTarget;
      final cacheKey = '${_currentUserId}_$targetUserId';
      _followStatusCache[cacheKey] = actualStatus;
      _followedByTargetCache[cacheKey] = actualFollowedByTarget;
      _cacheTimestamps[cacheKey] = DateTime.now();
    } catch (e) {
      print('❌ Error refreshing from server: $e');
    }
  }

  Future<void> _followUser(UserModel targetUser) async {
    if (_currentUserId == null) return;

    // Double-check that we're not already following before proceeding
    final isAlreadyFollowing = await FirebaseServices.instance
        .isFollowing(_currentUserId!, targetUser.uid);
        
    if (isAlreadyFollowing) {
      print('✅ Already following this user, skipping follow operation');
      return;
    }

    final followModel = FollowModel(
      userId: targetUser.uid,
      followedAt: DateTime.now(),
    );

    // Add to current user's Following subcollection
    await FirebaseServices.instance
        .addFollowing(_currentUserId!, followModel);

    // Add to target user's Followers subcollection
    final followerModel = FollowModel(
      userId: _currentUserId!,
      followedAt: DateTime.now(),
    );

    await FirebaseServices.instance
        .addFollower(targetUser.uid, followerModel);

    // Increment following count for current user
    await FirebaseServices.instance
        .updateFollowingCount(_currentUserId!, 1);

    // Increment followers count for target user
    await FirebaseServices.instance
        .updateFollowersCount(targetUser.uid, 1);

    // Create follow notification for target user
    await FirebaseServices.instance
        .createFollowNotification(_currentUserId!, targetUser.uid);
  }

  Future<void> _unfollowUser(UserModel targetUser) async {
    if (_currentUserId == null) return;

    // Double-check that we're actually following before proceeding
    final isCurrentlyFollowing = await FirebaseServices.instance
        .isFollowing(_currentUserId!, targetUser.uid);
        
    if (!isCurrentlyFollowing) {
      print('✅ Not following this user, skipping unfollow operation');
      return;
    }

    // Remove from current user's Following subcollection
    await FirebaseServices.instance
        .removeFollowing(_currentUserId!, targetUser.uid);

    // Remove from target user's Followers subcollection
    await FirebaseServices.instance
        .removeFollower(targetUser.uid, _currentUserId!);

    // Decrement following count for current user
    await FirebaseServices.instance
        .updateFollowingCount(_currentUserId!, -1);

    // Decrement followers count for target user
    await FirebaseServices.instance
        .updateFollowersCount(targetUser.uid, -1);
  }

  // Connection related methods
  Future<void> checkConnectionStatus(String targetUserId) async {
    if (_currentUserId == null) return;
    
    // If checking same user and already have status, check if cache is still valid
    if (_lastCheckedUserId == targetUserId && _hasCheckedConnectionStatus) {
      final cacheKey = '${_currentUserId}_$targetUserId';
      final cacheTime = _connectionCacheTimestamps[cacheKey];
      // If cache is older than 30 seconds, refresh it
      if (cacheTime != null && 
          DateTime.now().difference(cacheTime) > const Duration(seconds: 30)) {
        await _refreshConnectionStatusFromServer(targetUserId);
        notifyListeners();
      }
      return;
    }

    final cacheKey = '${_currentUserId}_$targetUserId';
    
    // Check cache first (use shorter cache time for connection status)
    if (_connectionStatusCache.containsKey(cacheKey)) {
      final cacheTime = _connectionCacheTimestamps[cacheKey];
      if (cacheTime != null && 
          DateTime.now().difference(cacheTime) < const Duration(minutes: 1)) {
        _connectionStatus = _connectionStatusCache[cacheKey]!;
        _hasCheckedConnectionStatus = true;
        notifyListeners();
        // Start listening for real-time updates
        _startConnectionListener(targetUserId);
        return;
      }
    }
    
    try {
      // Check connection status without showing loading
      _connectionStatus = await FirebaseServices.instance
          .getConnectionStatus(_currentUserId!, targetUserId);
      
      // Cache the result
      _connectionStatusCache[cacheKey] = _connectionStatus;
      _connectionCacheTimestamps[cacheKey] = DateTime.now();
      _hasCheckedConnectionStatus = true;
      
      // Start listening for real-time updates
      _startConnectionListener(targetUserId);
      
      notifyListeners(); // Update UI with actual status
          
    } catch (e) {
      print('❌ Error checking connection status: $e');
    }
  }
  
  void _startConnectionListener(String targetUserId) {
    if (_currentUserId == null) return;
    
    // Cancel existing listeners
    _connectionListener?.cancel();
    _requestListener?.cancel();
    
    // Helper function to update connection status
    void updateConnectionStatus() async {
      try {
        final newStatus = await FirebaseServices.instance
            .getConnectionStatus(_currentUserId!, targetUserId);
            
        if (_connectionStatus != newStatus) {
          _connectionStatus = newStatus;
          
          // Update cache
          final cacheKey = '${_currentUserId}_$targetUserId';
          _connectionStatusCache[cacheKey] = _connectionStatus;
          _connectionCacheTimestamps[cacheKey] = DateTime.now();
          
          print('🔄 Connection status updated via listener: $_connectionStatus');
          notifyListeners();
        }
      } catch (e) {
        print('❌ Error updating connection status: $e');
      }
    }
    
    // Listen to Connections collection for accepted connections
    _connectionListener = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('Connections')
        .doc(targetUserId)
        .snapshots()
        .listen((snapshot) {
      print('🔄 Connection document changed: exists=${snapshot.exists}');
      updateConnectionStatus();
    });
    
    // Listen to SentConnectionRequests for pending/cancelled requests
    _requestListener = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('SentConnectionRequests')
        .doc(targetUserId)
        .snapshots()
        .listen((snapshot) {
      print('🔄 Request document changed: exists=${snapshot.exists}');
      updateConnectionStatus();
    });
  }

  Future<void> toggleConnection(UserModel targetUser) async {
    if (_currentUserId == null) return;
    
    // Store original status for rollback
    final originalStatus = _connectionStatus;
    final cacheKey = '${_currentUserId}_${targetUser.uid}';
    
    // Optimistic UI update - change state immediately without loading
    switch (_connectionStatus) {
      case ConnectionStatus.none:
        _connectionStatus = ConnectionStatus.pending;
        break;
      case ConnectionStatus.pending:
      case ConnectionStatus.accepted:
        _connectionStatus = ConnectionStatus.none;
        break;
    }
    
    // Update cache optimistically
    _connectionStatusCache[cacheKey] = _connectionStatus;
    _connectionCacheTimestamps[cacheKey] = DateTime.now();
    notifyListeners(); // Update UI immediately
    
    try {
      switch (originalStatus) {
        case ConnectionStatus.none:
          // Send connection request
          final connectionModel = ConnectionModel(
            userId: targetUser.uid,
            status: 'pending',
            requestedAt: DateTime.now(),
          );
          
          await FirebaseServices.instance
              .sendConnectionRequest(_currentUserId!, connectionModel);
          break;
          
        case ConnectionStatus.pending:
        case ConnectionStatus.accepted:
          // Remove connection or cancel request
          await FirebaseServices.instance
              .removeConnection(_currentUserId!, targetUser.uid);
          break;
      }
      
      print('✅ Connection operation completed successfully');
      
    } catch (e) {
      print('❌ Error toggling connection: $e');
      
      // Revert optimistic update on error
      _connectionStatus = originalStatus;
      _connectionStatusCache[cacheKey] = originalStatus;
      _connectionCacheTimestamps[cacheKey] = DateTime.now();
      notifyListeners(); // Revert UI on error
      
      // Re-throw error for UI to handle
      rethrow;
    }
  }
  
  // Add method to refresh connection status from server
  Future<void> _refreshConnectionStatusFromServer(String targetUserId) async {
    if (_currentUserId == null) return;
    
    try {
      final actualStatus = await FirebaseServices.instance
          .getConnectionStatus(_currentUserId!, targetUserId);
      
      _connectionStatus = actualStatus;
      final cacheKey = '${_currentUserId}_$targetUserId';
      _connectionStatusCache[cacheKey] = actualStatus;
      _connectionCacheTimestamps[cacheKey] = DateTime.now();
      
      print('✅ Connection status refreshed: $actualStatus');
    } catch (e) {
      print('❌ Error refreshing connection status: $e');
    }
  }
  
  // Public method to manually refresh status (useful when receiving notifications)
  Future<void> refreshConnectionStatus(String targetUserId) async {
    await _refreshConnectionStatusFromServer(targetUserId);
    notifyListeners();
  }

  String getConnectionButtonText() {
    switch (_connectionStatus) {
      case ConnectionStatus.none:
        return 'Connect';
      case ConnectionStatus.pending:
        return 'Cancel Request';
      case ConnectionStatus.accepted:
        return 'Remove Connection';
    }
  }

  /// Get the appropriate text for the follow button
  String getFollowButtonText() {
    if (_isFollowing) {
      return 'Unfollow';
    } else if (_isFollowedByTarget) {
      return 'Follow Back';
    } else {
      return 'Follow';
    }
  }

  /// Check if both users follow each other (mutual follow)
  Future<bool> checkMutualFollow(String targetUserId) async {
    if (_currentUserId == null) return false;
    
    try {
      // Check if current user follows target user
      final currentFollowsTarget = await FirebaseServices.instance
          .isFollowing(_currentUserId!, targetUserId);
      
      // Check if target user follows current user
      final targetFollowsCurrent = await FirebaseServices.instance
          .isFollowing(targetUserId, _currentUserId!);
      
      // Return true only if both follow each other
      return currentFollowsTarget && targetFollowsCurrent;
    } catch (e) {
      print('❌ Error checking mutual follow: $e');
      return false;
    }
  }
}