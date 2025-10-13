import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import '../../Model/chatRoomModel.dart';
import '../../Model/userModel.dart';
import '../../core/const/app_color.dart';
import '../../core/const/app_images.dart';
import '../../core/theme/app_text_style.dart';
import '../../Provider/PrivateChatProvider.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../core/utils/components/CustomButton.dart';
import '../../core/utils/routes/routes.dart';

class PrivateChatScreen extends StatefulWidget {
  const PrivateChatScreen({super.key});

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  late PrivateChatProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = PrivateChatProvider.instance;
    _provider.initializeStreams();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<PrivateChatProvider>(
        builder: (context, provider, child) {
          return _buildContent(context, provider);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PrivateChatProvider provider) {
    if (!provider.isInitialLoadComplete && provider.isPrefetchingData) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              SizedBox(height: 16),
              Text(
                'Loading your chats...',
                style: pjsStyleBlack16600.copyWith(color: AppColors.darkGrey),
              ),
            ],
          ),
        ),
      );
    }

    return _buildMainContent(context, provider);
  }

  Widget _buildMainContent(BuildContext context, PrivateChatProvider provider) {
    return Scaffold(
            backgroundColor: AppColors.white,
            appBar: CustomAppBar2(
              title: Text(
                'Chat',
                style: pjsStyleBlack18600.copyWith(color: AppColors.black),
              ),
              onBack: () => Navigator.pop(context),
              onAdd: provider.selectedTabIndex == 1 ? () {} : null,
            ),
            body: Column(
              children: [
                // Tab Bar
                Container(
                  margin: EdgeInsets.all(context.screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey.withOpacity(0.70),
                    borderRadius: BorderRadius.circular(
                    12
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7,horizontal: 12),
                    child: Row(
                      spacing: 8,
                      children: [
                        _buildTabButton(
                          context,
                          AppImages.message,
                          'Private',
                          0,
                          provider.selectedTabIndex == 0,
                          () => provider.setSelectedTab(0),
                        ),
                        _buildTabButton(
                          context,
                          AppImages.group,
                          'Groups',
                          1,
                          provider.selectedTabIndex == 1,
                          () => provider.setSelectedTab(1),
                        ),
                        _buildTabButton(
                          context,
                          AppImages.location,
                          'Local',
                          2,
                          provider.selectedTabIndex == 2,
                          () => _handleLocalTabTap(context, provider),
                        ),
                      ],
                    ),
                  ),
                ),


                // New Chat and Requests buttons for Private tab
                if (provider.selectedTabIndex == 0)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.screenWidth * 0.05,
                      vertical: context.screenHeight * 0.01,
                    ),
                    child: Row(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomButton(
                          backgroundColor: AppColors.white,
                          textColor: AppColors.black,
                          height: 35,
                          width: 110,
                          iconSize: 12,
                          borderColor: AppColors.garyModern200,
                          text: 'New Chat',
                          svgAsset: AppImages.add,
                          onTap: () {
                            Navigator.pushNamed(context, RoutesName.newChatScreen);
                          },
                        ),
                        CustomButton(
                          height: 35,
                          width: 80,
                          iconSize: 12,
                          backgroundColor: AppColors.white,
                          textColor: AppColors.black,
                          borderColor: AppColors.garyModern200,
                          text: 'Requests',
                          onTap: () {
                            Navigator.pushNamed(context, RoutesName.requestChatScreen);
                          },
                        ),
                      ],
                    ),
                  ),

                // Chat List
                Expanded(child: _buildChatListContent(context, provider)),
              ],
            ),
    );
  }

  Widget _buildChatListContent(
    BuildContext context,
    PrivateChatProvider provider,
  ) {

    if (provider.selectedTabIndex == 2) {
      return Container();
    }
    if (provider.isCurrentTabLoading()) {
      return _buildShimmerList(context);
    }

    final chatList = provider.getCurrentChatList();
    if (chatList.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          if (provider.selectedTabIndex == 0) {
            await provider.refreshPrivateChats();
          } else if (provider.selectedTabIndex == 1) {
            await provider.refreshGroupChats();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.3,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Text(
                    provider.selectedTabIndex == 0
                        ? 'No conversations yet'
                        : 'No ${getTabType(provider.selectedTabIndex).toLowerCase()} chats yet',
                    style: pjsStyleBlack16600.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                  SizedBox(height: context.screenHeight * 0.01),
                  Text(
                    'Tap "New chat +" above to begin\n messaging someone',
                    style: pjsStyleBlack14400.copyWith(
                      color: AppColors.darkGrey
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (provider.selectedTabIndex == 0) {
          await provider.refreshPrivateChats();
        } else if (provider.selectedTabIndex == 1) {
        await provider.refreshGroupChats();
        }
      },
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: context.screenWidth * 0.05),
        itemCount: chatList.length,
        itemBuilder: (context, index) {
          final chat = chatList[index];

          return _buildChatTile(
            context,
            chat,
            onTap: () {
              print('Chat ID: ${chat.id}');
              print('Status: ${chat.status}');

              if (provider.selectedTabIndex == 0) {

                UserModel chatUser = UserModel(
                  status: chat.status ?? 'offline',
                  uid: chat.otherUserId.toString(),
                  fullName: chat.name,
                  profileImageUrl: chat.profileImage,
                  email: '',
                  nationality: '',
                  homeCity: '',
                  createdAt: DateTime.now(),
                );

                Navigator.pushNamed(
                  context,
                  RoutesName.chatScreen,
                  arguments: {
                    'type': getTabType(provider.selectedTabIndex),
                    'user': chatUser,
                    'chatroomId': chat.id,
                  },
                );
              } else if (provider.selectedTabIndex == 1) {
                // Group Chat
                Navigator.pushNamed(
                  context,
                  RoutesName.groupChatScreen,
                  arguments: {
                    'groupName': chat.name,
                    'groupChatRoomId': chat.id,
                  },
                );
              } else {
                // Local Chat
                Navigator.pushNamed(
                  context,
                  RoutesName.chatScreen,
                  arguments: {'type': getTabType(provider.selectedTabIndex)},
                );
              }
            },
          );
        },
      ),
    );
  }

  void _handleLocalTabTap(BuildContext context, PrivateChatProvider provider) async {
    // Set the tab to Local first
    provider.setSelectedTab(2);

    if (context.mounted) {
      await Navigator.pushNamed(
        context,
        RoutesName.localGroupChatScreen,
      );
      provider.setSelectedTab(0);
    }
  }

  Widget _buildTabButton(
    BuildContext context,
    String icon,
    String title,
    int index,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: context.screenHeight * 0.010,
            horizontal: context.screenWidth * 0.04,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(context.screenWidth * 0.02),
          ),
          child: Row(
            children: [
              SvgPicture.asset(icon, color: isSelected ? AppColors.white : AppColors.darkGrey),
              SizedBox(width: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: (isSelected ? pjsStyleBlack12700 : pjsStyleBlack12400).copyWith(
                  color: isSelected ? AppColors.white : AppColors.darkGrey,

                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: context.screenWidth * 0.05),
      itemCount: 8,
      itemBuilder: (context, index) {
        return _buildShimmerChatTile(context);
      },
    );
  }

  Widget _buildShimmerChatTile(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: context.screenHeight * 0.01),
      padding: EdgeInsets.all(context.screenWidth * 0.04),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: AppColors.borderColor.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          // Profile image shimmer
          Shimmer(
            duration: const Duration(seconds: 2),
            child: Container(
              width: context.screenWidth * 0.12,
              height: context.screenWidth * 0.12,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(context.screenWidth * 0.06),
              ),
            ),
          ),

          SizedBox(width: context.screenWidth * 0.04),

          // Chat Content shimmer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name shimmer
                    Shimmer(
                      duration: const Duration(seconds: 2),
                      child: Container(
                        width: context.screenWidth * 0.4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    // Time shimmer
                    Shimmer(
                      duration: const Duration(seconds: 2),
                      child: Container(
                        width: context.screenWidth * 0.15,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.screenHeight * 0.005),
                // Last message shimmer
                Shimmer(
                  duration: const Duration(seconds: 2),
                  child: Container(
                    width: context.screenWidth * 0.6,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: context.screenWidth * 0.02),
          // Chevron shimmer
          Shimmer(
            duration: const Duration(seconds: 2),
            child: Container(
              width: context.screenWidth * 0.06,
              height: context.screenWidth * 0.06,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String getTabType(int index) {
    switch (index) {
      case 0:
        return 'Private';
      case 1:
        return 'Groups';
      case 2:
        return 'Local';
      default:
        return 'Private';
    }
  }

  /// Check if we should show online status indicator for this chat
  bool _shouldShowOnlineStatus(ChatModel chat) {
    // Only show status for private chats (not groups), when user is online, 
    // and when user has enabled activity status sharing
    return chat.status != null && 
           chat.status == 'online' && 
           chat.status != 'group' &&
           chat.activityStatus == true;
  }

  Widget _buildChatTile(
    BuildContext context,
    ChatModel chat, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
            margin: EdgeInsets.only(bottom: context.screenHeight * 0.01),
            padding: EdgeInsets.all(context.screenWidth * 0.04),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 1,
                  color: AppColors.borderColor.withOpacity(0.05),
                ),
              ),
            ),
            child: Row(
              children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: context.screenWidth * 0.06,
                          backgroundColor: AppColors.lightGrey,
                          child: chat.profileImage.startsWith('http')
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              context.screenWidth * 0.06,
                            ),
                            child: Image.network(
                              chat.profileImage,
                              width: context.screenWidth * 0.12,
                              height: context.screenWidth * 0.12,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: context.screenWidth * 0.08,
                                  color: AppColors.darkGrey,
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                );
                              },
                            ),
                          )
                              : Image.asset(
                            chat.profileImage,
                            width: context.screenWidth * 0.12,
                            height: context.screenWidth * 0.12,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: context.screenWidth * 0.08,
                                color: AppColors.darkGrey,
                              );
                            },
                          ),
                        ),
                        if (_shouldShowOnlineStatus(chat))...[
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: CircleAvatar(
                              backgroundColor: AppColors.yellow,
                              radius: 6,
                            ),
                          ),
                        ]
                      ],

                    ),


                SizedBox(width: context.screenWidth * 0.04),

                // Chat Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chat.name,
                              style: pjsStyleBlack16600.copyWith(
                                color: AppColors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            chat.time,
                            style: pjsStyleBlack12400.copyWith(
                              color: AppColors.darkGrey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.screenHeight * 0.005),
                      Text(
                        chat.lastMessage,
                        style: pjsStyleBlack12400.copyWith(
                          color: AppColors.darkGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                SizedBox(width: context.screenWidth * 0.02),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.brown,
                  size: context.screenWidth * 0.06,
                ),
              ],
            ),
          ),
    );
  }
}