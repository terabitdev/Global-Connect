import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:global_connect/core/utils/components/CustomButton.dart';
import 'package:provider/provider.dart';
import '../../Model/userModel.dart';
import '../../Provider/PrivateChatProvider.dart';
import '../../Provider/SignupProvider.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/CustomTextField.dart';
import '../../Widgets/buildTabButton.dart';
import '../../core/const/app_color.dart';
import '../../core/const/app_images.dart';
import '../../core/theme/app_text_style.dart';

class CreateGroupChatScreen extends StatefulWidget {
  const CreateGroupChatScreen({super.key});

  @override
  State<CreateGroupChatScreen> createState() => _CreateGroupChatScreenState();
}

class _CreateGroupChatScreenState extends State<CreateGroupChatScreen> {

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SignupProvider()),
        ChangeNotifierProvider(create: (context) => PrivateChatProvider()),
      ],
      child: Scaffold(
        appBar: CustomAppBar2(
          title: Text(
            'Create Group Chat',
            style: pjsStyleBlack18600.copyWith(color: AppColors.black),
          ),
          onBack: () => Navigator.pop(context),
        ),
        body: SafeArea(
          child: Consumer2<SignupProvider, PrivateChatProvider>(
            builder: (context, signupProvider, privateChatProvider, child) {
              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.screenWidth * 0.05,
                    vertical: context.screenHeight * 0.02,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  signupProvider.pickImageFromGallery(),
                              child: DottedBorder(
                                borderType: BorderType.Circle,
                                dashPattern: const [8, 6],
                                color: AppColors.primary,
                                strokeWidth: 2,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.transparent,
                                  ),
                                  child: signupProvider.profileImage != null
                                      ? ClipOval(
                                    child: Image.file(
                                      signupProvider.profileImage!,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                    ),
                                  )
                                      : Icon(
                                    Icons.camera_alt,
                                    size: 40,
                                    color: AppColors.garyModern400,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Add Profile Picture',
                              style: pjsStyleBlack14500.copyWith(
                                color: AppColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Group Name',
                        hintText: 'Enter your Group Name..',
                        controller: privateChatProvider.groupNameController,
                      ),
                      SizedBox(height: 16),
                      CustomTextField(
                        label: 'Group Description (Optional)...',
                        hintText: 'Enter your group description...',
                        controller: privateChatProvider.groupDescriptionController,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Group Privacy',
                        style: pjsStyleBlack14500.copyWith(
                          color: AppColors.black,
                        ),
                      ),
                      SizedBox(height: 16),

                      Container(
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(
                            context.screenWidth * 0.03,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(7.0),
                          child: Row(
                            spacing: 10,
                            children: [
                              buildTabButton(
                                context,
                                '🔓 Public',
                                0,
                                privateChatProvider.selectedTabIndex == 0,
                                    () => privateChatProvider.setSelectedTab(0),
                              ),
                              buildTabButton(
                                context,
                                '🔒 Private',
                                1,
                                privateChatProvider.selectedTabIndex == 1,
                                    () => privateChatProvider.setSelectedTab(1),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      CustomTextField(
                        label: 'Add Members',
                        hintText: 'Search travelers by name or nationality..',
                        controller: privateChatProvider.searchController,
                        onChanged: (value) {
                          privateChatProvider.searchUsers(value);
                        },
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
                                      member.fullName?.split(' ').first ?? 'User',
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
                          text: privateChatProvider.isCreatingGroup ? 'Creating Group...' : 'Create Group Chat',
                          onTap:  privateChatProvider.isCreatingGroup ? null : () {
                            privateChatProvider.createGroupChat(signupProvider);
                          }
                      ),

                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }



}
Widget buildUserTile(BuildContext context, UserModel user, PrivateChatProvider provider) {
  final isSelected = provider.isMemberSelected(user);

  return Container(
    margin: EdgeInsets.only(bottom: context.screenHeight * 0.01),
    padding: EdgeInsets.all(context.screenWidth * 0.04),
    decoration: BoxDecoration(
      color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isSelected ? AppColors.primary : AppColors.borderColor.withOpacity(0.05),
        width: 1,
      ),
    ),
    child: Row(
      children: [
        // Profile Image
        CircleAvatar(
          radius: context.screenWidth * 0.06,
          backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
              ? NetworkImage(user.profileImageUrl!)
              : AssetImage(AppImages.profileImage) as ImageProvider,
        ),
        SizedBox(width: context.screenWidth * 0.04),

        // User Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.fullName ?? 'Unknown User',
                style: pjsStyleBlack16600.copyWith(color: AppColors.black),
              ),
              SizedBox(height: context.screenHeight * 0.005),
              Text(
                user.email ?? 'No email',
                style: pjsStyleBlack12400.copyWith(color: AppColors.darkGrey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (user.nationality != null && user.nationality!.isNotEmpty) ...[
                SizedBox(height: context.screenHeight * 0.002),
                Text(
                  '🌍 ${user.nationality}',
                  style: pjsStyleBlack10400.copyWith(color: AppColors.darkGrey),
                ),
              ],
            ],
          ),
        ),

        GestureDetector(
          onTap: () {
            provider.toggleMemberSelection(user);
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green : AppColors.primary,
              borderRadius: BorderRadius.circular(5),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ] : [],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                  ],
                  Text(
                    isSelected ? 'Added' : 'Add',
                    style: psjStyleBlack10400.copyWith(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}