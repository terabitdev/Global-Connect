import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'NetworkProvider.dart';

class UserStatusProvider extends ChangeNotifier with WidgetsBindingObserver {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NetworkProvider _networkProvider = NetworkProvider();
  
  String? _currentUserId;
  bool _isInitialized = false;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription? _networkSubscription;

  UserStatusProvider() {
    _setupListeners();
    if (_auth.currentUser != null) {
      _initialize();
    }
  }

  void _setupListeners() {
    // Auth state listener
    _authSubscription = _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        _currentUserId = user.uid;
        if (!_isInitialized) {
          await _initialize();
        } else {
          await _updateUserStatus();
        }
      } else {
        if (_currentUserId != null) {
          await setUserOffline();
        }
        await cleanup();
      }
    });

    // Network status listener
    _networkProvider.addListener(_onNetworkStatusChanged);
  }

  void _onNetworkStatusChanged() {
    if (_currentUserId != null && _isInitialized) {
      _updateUserStatus();
    }
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    _currentUserId = _auth.currentUser?.uid;
    
    if (_currentUserId != null) {
      WidgetsBinding.instance.addObserver(this);
      await _networkProvider.initialize();
      await _updateUserStatus();
      _isInitialized = true;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (_currentUserId == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _updateUserStatus();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        setUserOffline();
        break;
      case AppLifecycleState.inactive:
        // Don't change status for temporary states
        break;
    }
  }

  Future<void> _updateUserStatus() async {
    if (_networkProvider.isConnected) {
      await setUserOnline();
    } else {
      await setUserOffline();
    }
  }

  Future<void> setUserOnline() async {
    if (_currentUserId == null) return;
    
    try {
      final docSnapshot = await _firestore.collection('users').doc(_currentUserId).get();
      
      if (!docSnapshot.exists) return;
      
      await _firestore.collection('users').doc(_currentUserId).update({
        'status': 'online',
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error setting user online: $e');
    }
  }

  Future<void> setUserOffline() async {
    if (_currentUserId == null) return;
    
    try {
      final docSnapshot = await _firestore.collection('users').doc(_currentUserId).get();
      
      if (!docSnapshot.exists) return;
      
      await _firestore.collection('users').doc(_currentUserId).update({
        'status': 'offline',
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error setting user offline: $e');
    }
  }

  Future<void> refreshUserId() async {
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (_currentUserId != null && !_isInitialized) {
      await _initialize();
    }
  }

  Future<void> cleanup() async {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
    }
    
    _currentUserId = null;
    _isInitialized = false;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _networkProvider.removeListener(_onNetworkStatusChanged);
    
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      if (_currentUserId != null) {
        setUserOffline();
      }
    }
    
    super.dispose();
  }
}