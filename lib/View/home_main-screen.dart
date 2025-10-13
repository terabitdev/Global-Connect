import 'package:flutter/material.dart';
import 'package:global_connect/View/post/addPostScreen.dart';
import 'package:global_connect/View/post/allPostScreen.dart';
import 'package:provider/provider.dart';
import '../Provider/SelectionProvider.dart';
import '../Provider/localChatProvider.dart';
import '../Widgets/CustomBottomNavBar.dart' show CustomBottomNavBar;
import 'FestivalsEvents.dart';
import 'tips/UserTips_Screen.dart';
import 'home_screen.dart';

class HomeMainScreen extends StatefulWidget {
  const HomeMainScreen({super.key});
  @override
  State<HomeMainScreen> createState() => _HomeMainScreenState();
}

class _HomeMainScreenState extends State<HomeMainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocalChatProvider();
    });
  }

  Future<void> _initializeLocalChatProvider() async {
    try {
      final localChatProvider = Provider.of<LocalChatProvider>(
        context,
        listen: false,
      );
      await localChatProvider.initializeGroupManagement();
    } catch (e) {
      print('❌ Error initializing LocalChatProvider: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navigationProvider, child) {
        return SafeArea(
          top: false,
          bottom: true,
          child: Scaffold(
            body: IndexedStack(
              index: navigationProvider.currentIndex,
              children: const [
                AllPostScreen(),
                HomeScreen(),
                AddPostScreen(),
                UserTipsScreen(),
                FestivalsEvents(),
              ],
            ),
            bottomNavigationBar: CustomBottomNavBar(
              currentIndex: navigationProvider.currentIndex,
              onTap: (index) {
                navigationProvider.setCurrentIndex(index);
              },
            ),
          ),
        );
      },
    );
  }
}
