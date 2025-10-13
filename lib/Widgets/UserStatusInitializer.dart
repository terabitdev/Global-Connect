import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Provider/UserStatusProvider.dart';

/// Widget to initialize UserStatusProvider when app starts
/// This ensures the provider is created and lifecycle monitoring begins
class UserStatusInitializer extends StatefulWidget {
  final Widget child;
  
  const UserStatusInitializer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<UserStatusInitializer> createState() => _UserStatusInitializerState();
}

class _UserStatusInitializerState extends State<UserStatusInitializer> {
  @override
  void initState() {
    super.initState();
    // Access the provider to ensure it's created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // This will trigger the provider's creation
        context.read<UserStatusProvider>();
        print('🎯 UserStatusInitializer: Provider accessed and initialized');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // This Consumer ensures provider stays alive
    return Consumer<UserStatusProvider>(
      builder: (context, statusProvider, child) {
        return widget.child;
      },
    );
  }
}

