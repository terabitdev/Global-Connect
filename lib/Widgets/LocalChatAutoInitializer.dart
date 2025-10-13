import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Provider/localChatProvider.dart';

class LocalChatAutoInitializer extends StatefulWidget {
  final Widget child;

  const LocalChatAutoInitializer({Key? key, required this.child}) : super(key: key);

  @override
  State<LocalChatAutoInitializer> createState() => _LocalChatAutoInitializerState();
}

class _LocalChatAutoInitializerState extends State<LocalChatAutoInitializer>
    with WidgetsBindingObserver {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocalChatProvider();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _initialized) {
      _reinitializeIfNeeded();
    }
  }

  Future<void> _initializeLocalChatProvider() async {
    try {
      // Check if user is logged in
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('⚠️ No user logged in, skipping LocalChatProvider initialization');
        return;
      }

      // Get the LocalChatProvider instance
      final localChatProvider = Provider.of<LocalChatProvider>(context, listen: false);

      // Initialize automatic group management
      await localChatProvider.initializeGroupManagement();

      _initialized = true;
      print('✅ LocalChatProvider initialized successfully in main app');

    } catch (e) {
      print('❌ Error initializing LocalChatProvider in main app: $e');
    }
  }

  Future<void> _reinitializeIfNeeded() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final localChatProvider = Provider.of<LocalChatProvider>(context, listen: false);

        // Check if provider needs reinitialization
        if (localChatProvider.currentUserCity == null) {
          await localChatProvider.initializeGroupManagement();
        }
      }
    } catch (e) {
      print('❌ Error reinitializing LocalChatProvider: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}