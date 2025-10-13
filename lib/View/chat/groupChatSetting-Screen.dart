import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Model/chatRoomModel.dart';
import '../../Provider/GroupChatProvider.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/SettingTile.dart';
import '../../Widgets/buildChatTile.dart';
import '../../core/const/app_color.dart';
import '../../core/const/app_images.dart';
import '../../core/theme/app_text_style.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import '../../core/utils/components/CustomButton.dart';
import '../../Provider/GroupSettingsProvider.dart';
import '../../core/utils/routes/routes.dart';
import 'package:shimmer/shimmer.dart';
class GroupChatSettingScreen extends StatefulWidget {
  final String groupName;
  final String groupChatRoomId;
  const GroupChatSettingScreen({
    super.key,
    required this.groupName,
    required this.groupChatRoomId,
  });

  @override
  State<GroupChatSettingScreen> createState() => _GroupChatSettingScreenState();
}

class _GroupChatSettingScreenState extends State<GroupChatSettingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String groupChatRoomId = widget.groupChatRoomId;
      final provider = context.read<GroupChatProvider>();
      provider.fetchGroupMembers(groupChatRoomId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final String groupName = widget.groupName;
   final String groupChatRoomId = widget.groupChatRoomId;
    print('group name ${widget.groupName}');
    return Scaffold(
      appBar: CustomAppBar2(
        title: Text(
          groupName,
          style: pjsStyleBlack18600.copyWith(color: AppColors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.screenWidth * 0.05,
            vertical: context.screenHeight * 0.02,
          ),
          child: Column(
            spacing: 20,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<GroupChatProvider>(
                builder: (context, provider, _) {
                  final members = provider.groupMembers;
                  final String? groupImageUrl = provider.groupImageUrl;
                  final bool isLoading = provider.isLoading;

                  return Center(
                    child: Column(
                      children: [
                        isLoading
                            ? Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        )
                            : Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: groupImageUrl != null
                                  ? NetworkImage(groupImageUrl)
                                  : const AssetImage(AppImages.profileImage)
                              as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Shimmer for group name
                        isLoading
                            ? Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 100,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        )
                            : Text(
                          groupName,
                          style: pjsStyleBlack14500.copyWith(
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Shimmer for member count
                        isLoading
                            ? Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 80,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        )
                            : Text(
                          '${members.length} members',
                          style: pjsStyleBlack14500.copyWith(
                            color: AppColors.darkGrey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Consumer<GroupChatProvider>(
                builder: (context, provider, _) {
                  final members = provider.groupMembers;
                  final String? createdById = provider.createdById;
                  final bool isLoading = provider.isLoading;
                  final String? currentUserId = provider.currentUserId;

                  if (isLoading) {
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return _buildShimmerChatTile();
                      },
                    );
                  }

                  final sortedMembers = createdById != null
                      ? [
                    ...members.where((user) => user.uid == createdById),
                    ...members.where((user) => user.uid != createdById),
                  ]
                      : members;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedMembers.length,
                    itemBuilder: (context, index) {
                      final user = sortedMembers[index];
                      final bool isGroupAdmin = createdById != null && user.uid == createdById;
                      final bool isCurrentUserAdmin = currentUserId == createdById;

                      return buildChatTile(
                        context,
                        ChatModel(
                          status: user.status,
                          name: user.fullName,
                          profileImage: user.profileImageUrl ?? AppImages.profileImage,
                          lastMessage: isGroupAdmin ? 'Group Admin' : 'Group Member',
                          isOnline: user.isLocationSharingEnabled,
                          time: '',
                        ),
                        userId: user.uid,
                        isGroupAdmin: isGroupAdmin,
                        isCurrentUserAdmin: isCurrentUserAdmin,
                        onMemberTap: (String memberId) {

                          if (isCurrentUserAdmin && !isGroupAdmin) {
                            final provider = context.read<GroupChatProvider>();
                            showRemoveUserDialog(context, user.fullName,user.profileImageUrl.toString(), memberId, groupChatRoomId,provider);
                          }
                        },
                      );
                    },
                  );
                },
              ),
              CustomButton(
                text: '+ Add More Members',
                onTap: () {
                  Navigator.pushNamed(context, RoutesName.inviteMemberScreen, arguments: {'groupChatroomId': groupChatRoomId},);
                },
              ),


              // Setting Tile
              Text('Settings', style: pjsStyleBlack14500),

              Consumer2<GroupSettingsProvider,GroupChatProvider>(
                builder: (context, settings, groupChatProvider, _) => Column(
                  spacing: 20,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingTile(
                      title: '🔕 Mute Notifications',
                      value: settings.muteNotifications,
                      onChanged: settings.toggleMuteNotifications,
                    ),
                    SettingTile(
                      title: '📍 Share Location',
                      value: settings.shareLocation,
                      onChanged: settings.toggleShareLocation,
                    ),
                    Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gray20),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              '🚪 Leave Group',
                              style: pStyleBlack14500,
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            onTap: () {
                              final String currentUserId = groupChatProvider.currentUserId;
                              final String? createdById = groupChatProvider.createdById;
                              if (currentUserId != createdById) {
                                final currentUser = groupChatProvider.groupMembers.firstWhere(
                                      (member) => member.uid == currentUserId,
                                  orElse: () => groupChatProvider.groupMembers.first,
                                );
                                showRemoveUserDialog(
                                  context,
                                  currentUser.fullName,
                                  currentUser.profileImageUrl.toString(),
                                  currentUserId,
                                  groupChatRoomId,
                                  groupChatProvider,
                                );
                              } else if (currentUserId == createdById) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('As an admin, you cannot leave the group.'),
                                    backgroundColor: Colors.orange,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Unable to identify current user'),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Shimmer widget for chat tile
  Widget _buildShimmerChatTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Row(
          children: [
            // Profile image shimmer
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name shimmer
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Role shimmer
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}