import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:provider/provider.dart';

import '../../Provider/PrivateChatProvider.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/CustomTextField.dart';
import '../../Widgets/buildChatTile.dart';
import '../../core/const/app_color.dart';
import '../../core/const/app_images.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/utils/components/CustomButton.dart';
import '../PrivateChat/createGroupChatScreen.dart';

class InviteMemberScreen extends StatefulWidget {
  final String groupChatroomId;
  const InviteMemberScreen({super.key,required this.groupChatroomId});

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {


  @override
  Widget build(BuildContext context) {
    final groupChatroomId = widget.groupChatroomId;
    return Scaffold(
      appBar: CustomAppBar2(
        title: Text(
          'Invite Members',
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
              Text('Search Members', style: pjsStyleBlack14500),

              Consumer< PrivateChatProvider>(
                builder: (context, privateChatProvider, child) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.gray20),
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: SvgPicture.asset(AppImages.searchMember),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: privateChatProvider.searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search members...',
                                    border: InputBorder.none,
                                    hintStyle: pjsStyleBlack14400.copyWith(
                                      color: AppColors.garyModern400,
                                    ),
                                  ),
                                  style: pStyleBlack12400,
                                  onChanged: (value) {
                                    privateChatProvider.searchUsers(value);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),
                        if (privateChatProvider.selectedMembers.isNotEmpty) ...[
                          Text(
                            'Selected Members (${privateChatProvider.selectedMembers.length})',
                            style: pjsStyleBlack14500.copyWith(
                              color: AppColors.black,
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: privateChatProvider.selectedMembers.length,
                              itemBuilder: (context, index) {
                                final member = privateChatProvider.selectedMembers[index];
                                return Container(
                                  margin: EdgeInsets.only(right: 8),
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundImage: member.profileImageUrl != null && member.profileImageUrl!.isNotEmpty
                                            ? NetworkImage(member.profileImageUrl!)
                                            : AssetImage(AppImages.profileImage) as ImageProvider,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        member.fullName.split(' ').first ?? 'User',
                                        style: TextStyle(fontSize: 10),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 16),
                        ],

                        Text(
                          'Suggested',
                          style: pjsStyleBlack14500.copyWith(
                            color: AppColors.black,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Loading state for users
                        if (privateChatProvider.isLoading)
                          Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                        else if (privateChatProvider.allUsers.isEmpty)
                          Center(
                            child: Text(
                              'No users found',
                              style: pjsStyleBlack14500.copyWith(
                                color: AppColors.darkGrey,
                              ),
                            ),
                          )
                        else
                        // Display all users
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: privateChatProvider.allUsers.length,
                            itemBuilder: (context, index) {
                              final user = privateChatProvider.allUsers[index];
                              return buildUserTile(context, user, privateChatProvider);
                            },
                          ),

                        const SizedBox(height: 16),
                        CustomButton(
                            text: privateChatProvider.isCreatingGroup ? 'Saving' : 'Save',
                            onTap:  privateChatProvider.isCreatingGroup ? null : () {
                              privateChatProvider.addMembersToGroup(groupChatroomId);
                            }
                        ),

                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
