import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/createMemoryModel.dart';

class MemoryProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get stream of user memories
  Stream<QuerySnapshot>? getUserMemoriesStream() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('userMemory')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get stream of memories for a specific user by userId
  Stream<QuerySnapshot>? getSpecificUserMemoriesStream(String userId) {
    if (userId.isEmpty) return null;

    // Check if viewing own profile or another user's profile
    final currentUser = _auth.currentUser;
    final isOwnProfile = currentUser != null && currentUser.uid == userId;

    if (isOwnProfile) {
      // If viewing own profile, show all memories (both private and public)
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('userMemory')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      // If viewing another user's profile, show only public memories
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('userMemory')
          .where('privacy', isEqualTo: 'public')
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  // Convert QuerySnapshot to List<CreateMemoryModel>
  List<CreateMemoryModel> convertSnapshotToMemories(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      return CreateMemoryModel.fromJson(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    }).toList();
  }

  // Get single memory by ID
  Future<CreateMemoryModel?> getMemoryById(String memoryId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('userMemory')
          .doc(memoryId)
          .get();

      if (doc.exists) {
        return CreateMemoryModel.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching memory: $e');
      return null;
    }
  }

  // Delete memory
  Future<bool> deleteMemory(String memoryId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('userMemory')
          .doc(memoryId)
          .delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting memory: $e');
      return false;
    }
  }

  // Get memories count
  Future<int> getMemoriesCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('userMemory')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting memories count: $e');
      return 0;
    }
  }
}