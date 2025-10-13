import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/services/firebase_services.dart';

class PrivateChatSettingProvider extends ChangeNotifier {
  final FirebaseServices _firebaseServices = FirebaseServices.instance;
  bool isPrivate = false;
  bool isMuted = false;
  bool isBlocked = false;
  bool isLoading = false;
  String? errorMessage;
  bool isBlocking = false;
  bool isBlockedByOther = false;
  String? blockStatusMessage;

  /// Set loading state
  void setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  /// Set blocking state (for block/unblock operations)
  void setBlocking(bool blocking) {
    isBlocking = blocking;
    notifyListeners();
  }

  /// Set error message
  void setError(String? error) {
    errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  /// Toggle private setting
  void togglePrivate() {
    isPrivate = !isPrivate;
    notifyListeners();
  }

  /// Toggle muted setting
  void toggleMuted() {
    isMuted = !isMuted;
    notifyListeners();
  }

  /// Check if user is blocked by another user
  Future<bool> _checkIfUserBlockedBy(String userToCheck, String blockedByUserId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userToCheck)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final blockedUsers = List<String>.from(userData['blocked_users'] ?? []);
        return blockedUsers.contains(blockedByUserId);
      }
      return false;
    } catch (e) {
      print('Error checking if user is blocked by: $e');
      return false;
    }
  }

  /// Check mutual block status
  Future<void> checkBlockStatus(String userId) async {
    setLoading(true);
    clearError();

    try {
      // Check if current user has blocked the other user
      isBlocked = await _firebaseServices.isUserBlocked(userId);
      
      // Check if current user is blocked by the other user
      isBlockedByOther = await _checkIfUserBlockedBy(userId, _firebaseServices.getCurrentUserId() ?? '');
      
      // Set status message
      if (isBlocked && isBlockedByOther) {
        blockStatusMessage = 'You have blocked each other';
      } else if (isBlocked) {
        blockStatusMessage = 'You have blocked this user';
      } else if (isBlockedByOther) {
        blockStatusMessage = 'This user has blocked you';
      } else {
        blockStatusMessage = null;
      }
      
      notifyListeners();
    } catch (e) {
      setError('Failed to check block status: ${e.toString()}');
    } finally {
      setLoading(false);
    }
  }

  /// Block user
  Future<bool> blockUser(String userId) async {
    setBlocking(true);
    clearError();

    try {
      final success = await _firebaseServices.addUserToBlockList(userId);

      if (success) {
        isBlocked = true;
        notifyListeners();
        return true;
      } else {
        setError('Failed to block user');
        return false;
      }
    } catch (e) {
      setError('Error blocking user: ${e.toString()}');
      return false;
    } finally {
      setBlocking(false);
    }
  }

  /// Unblock user
  Future<bool> unblockUser(String userId) async {
    setBlocking(true);
    clearError();

    try {
      final success = await _firebaseServices.removeUserFromBlockList(userId);

      if (success) {
        isBlocked = false;
        notifyListeners();
        return true;
      } else {
        setError('Failed to unblock user');
        return false;
      }
    } catch (e) {
      setError('Error unblocking user: ${e.toString()}');
      return false;
    } finally {
      setBlocking(false);
    }
  }

  /// Handle block/unblock toggle
  Future<void> toggleBlockUser(String userId) async {
    if (isBlocked) {
      await unblockUser(userId);
    } else {
      await blockUser(userId);
    }
  }

  /// Reset provider state
  void reset() {
    isPrivate = false;
    isMuted = false;
    isBlocked = false;
    isLoading = false;
    isBlocking = false;
    isBlockedByOther = false;
    blockStatusMessage = null;
    errorMessage = null;
    notifyListeners();
  }

  /// Initialize provider with user data
  Future<void> initialize(String userId) async {
    reset();
    await checkBlockStatus(userId);
  }
}