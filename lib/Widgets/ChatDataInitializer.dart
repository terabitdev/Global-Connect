import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Provider/PrivateChatProvider.dart';

class ChatDataInitializer extends StatefulWidget {
  final Widget child;
  
  const ChatDataInitializer({super.key, required this.child});
  
  @override
  State<ChatDataInitializer> createState() => _ChatDataInitializerState();
}

class _ChatDataInitializerState extends State<ChatDataInitializer> {
  bool _hasInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeChatData();
  }
  
  void _initializeChatData() async {
    if (_hasInitialized) return;
    
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        print('🚀 Initializing chat data prefetch...');
        
        // First prefetch the chat list data
        await PrivateChatProvider.instance.prefetchAllData();
        
        // Then prefetch individual chat messages for faster ChatScreen loading
        await PrivateChatProvider.instance.prefetchAllChatData();
        
        _hasInitialized = true;
        print('✅ Complete chat data prefetch completed');
      } catch (e) {
        print('❌ Error during chat data initialization: $e');
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}