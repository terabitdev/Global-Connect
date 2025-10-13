import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserPostsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user posts stream for real-time updates
  Stream<QuerySnapshot>? getUserPostsStream() {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _firestore
        .collection('addpost')
        .doc(user.uid)
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get posts stream for a specific user by userId
  Stream<QuerySnapshot>? getSpecificUserPostsStream(String userId) {
    if (userId.isEmpty) return null;

    return _firestore
        .collection('addpost')
        .doc(userId)
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}