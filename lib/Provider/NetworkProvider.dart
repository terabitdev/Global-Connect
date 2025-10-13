import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkProvider extends ChangeNotifier {
  static final NetworkProvider _instance = NetworkProvider._internal();
  factory NetworkProvider() => _instance;
  NetworkProvider._internal();

  // Network state variables
  bool _isConnected = true;
  ConnectivityResult _connectionType = ConnectivityResult.none;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);

  // Getters
  bool get isConnected => _isConnected;
  bool get isOnline => _isConnected;
  ConnectivityResult get connectionType => _connectionType;
  int get retryCount => _retryCount;

  // Initialize network monitoring
  Future<void> initialize() async {
    print('🌐 Initializing NetworkProvider...');
    
    // Check initial connectivity
    await _checkInitialConnectivity();
    
    // Start monitoring connectivity changes
    _startConnectivityMonitoring();
    
    print('✅ NetworkProvider initialized - Online: $isOnline');
  }

  // Check initial connectivity state
  Future<void> _checkInitialConnectivity() async {
    try {
      final List<ConnectivityResult> results = await Connectivity().checkConnectivity();
      _connectionType = results.isNotEmpty ? results.first : ConnectivityResult.none;
      _isConnected = _connectionType != ConnectivityResult.none;
      
      print('🔍 Initial connectivity check: Connected=$_isConnected, Type=$_connectionType');
      notifyListeners();
    } catch (e) {
      print('❌ Error checking initial connectivity: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  // Start monitoring connectivity changes
  void _startConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _connectionType = results.isNotEmpty ? results.first : ConnectivityResult.none;
        final bool wasConnected = _isConnected;
        _isConnected = _connectionType != ConnectivityResult.none;
        
        print('📡 Connectivity changed: $_connectionType, Connected: $_isConnected');
        
        if (_isConnected && !wasConnected) {
          _stopRetryTimer();
          _retryCount = 0;
          print('✅ Network connection restored');
        } else if (!_isConnected) {
          _startRetryTimer();
          print('⚠️ Network connection lost');
        }
        
        notifyListeners();
      },
      onError: (error) {
        print('❌ Connectivity monitoring error: $error');
      },
    );
  }

  // Start retry timer for failed operations
  void _startRetryTimer() {
    _stopRetryTimer();
    _retryTimer = Timer.periodic(_retryDelay, (timer) {
      if (_retryCount < _maxRetries) {
        _retryCount++;
        print('🔄 Retrying connectivity check (attempt $_retryCount/$_maxRetries)');
        _checkInitialConnectivity();
      } else {
        print('❌ Max retry attempts reached');
        _stopRetryTimer();
      }
    });
  }

  // Stop retry timer
  void _stopRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  // Reset retry count
  void resetRetryCount() {
    _retryCount = 0;
    _stopRetryTimer();
  }

  // Manual connectivity check
  Future<bool> checkConnectivity() async {
    try {
      await _checkInitialConnectivity();
      return isOnline;
    } catch (e) {
      print('❌ Error in manual connectivity check: $e');
      return false;
    }
  }

  // Get connection type description
  String get connectionTypeDescription {
    switch (_connectionType) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'No Connection';
    }
  }

  // Get network status message
  String get networkStatusMessage {
    if (!_isConnected) {
      return 'No network connection available';
    } else {
      return 'Connected via $connectionTypeDescription';
    }
  }

  // Dispose resources
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _stopRetryTimer();
    super.dispose();
  }
}