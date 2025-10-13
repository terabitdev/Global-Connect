import 'package:flutter/material.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:provider/provider.dart';

import '../../Provider/localChatProvider.dart';
import '../../core/const/app_color.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/utils/routes/routes.dart';

class LocalGroupScreen extends StatefulWidget {
  const LocalGroupScreen({super.key});

  @override
  State<LocalGroupScreen> createState() => _LocalGroupScreenState();
}

class _LocalGroupScreenState extends State<LocalGroupScreen> {
  @override
  void initState() {
    super.initState();
  }

  String getCityInitials(String cityName) {
    if (cityName.isEmpty || cityName == 'Unknown City') {
      return 'UC';
    }

    List<String> words = cityName.trim().split(' ');

    if (words.length >= 2) {
      return (words[0][0] + words[1][0]).toUpperCase();
    } else if (words[0].length >= 2) {
      return words[0].substring(0, 2).toUpperCase();
    } else {
      return (words[0][0] + words[0][0]).toUpperCase();
    }
  }

  @override
  void dispose() {
    // Clean up when screen is disposed
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider is already initialized in PrivateChatScreen
    // No need to call loadLocalGroupChats again
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<LocalChatProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.localGroupChats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_city, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No local groups available'),
                  const SizedBox(height: 8),
                  if (provider.currentUserCity != null)
                    Text('Current city: ${provider.currentUserCity}'),
                  if (provider.isManagingGroups)
                    const Text('Setting up groups...'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.localGroupChats.length,
            itemBuilder: (context, index) {
              final chat = provider.localGroupChats[index];
              final cityName = chat['id'] ?? 'Unknown City';
              final lastMessage = chat['lastMessage'] ?? '';
              final participantCount =
                  (chat['participantsList'] as List?)?.length ?? 0;
              final cityInitials = getCityInitials(cityName);

              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 1,
                      color: AppColors.borderColor.withOpacity(0.05),
                    ),
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: context.screenWidth * 0.06,
                    backgroundColor: AppColors.lightGrey,
                    child: Text(
                      cityInitials,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  title: Text(
                    cityName,
                    style: pjsStyleBlack16600.copyWith(color: AppColors.black),
                  ),
                  subtitle: Text(
                    lastMessage,
                    style: pjsStyleBlack12400.copyWith(
                      color: AppColors.darkGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text('$participantCount members'),
                  onTap: () async {
                    try {
                      await Navigator.pushNamed(
                        context, 
                        RoutesName.localGroupChatScreen,
                        arguments: cityName,
                      );
                      print('Open chat for $cityName');
                    } catch (e) {
                      print('Navigation error: $e');
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
