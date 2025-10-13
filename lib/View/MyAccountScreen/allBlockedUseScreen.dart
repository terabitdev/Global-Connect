import 'package:flutter/material.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:provider/provider.dart';
import '../../Model/userModel.dart';
import '../../Provider/privateChatSettingProvider.dart';
import '../../Provider/user_profile_provider.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../core/const/app_color.dart';

import '../../core/const/app_images.dart';
import '../../core/services/firebase_services.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/utils/components/CustomButton.dart';

class AllBlockedUseScreen extends StatefulWidget {
  const AllBlockedUseScreen({super.key});

  @override
  State<AllBlockedUseScreen> createState() => _AllBlockedUseScreenState();
}

class _AllBlockedUseScreenState extends State<AllBlockedUseScreen> {
  final firebaseServices = FirebaseServices.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar2(
        title: Text(
          'Blocked Users',
          style: pjsStyleBlack18600.copyWith(color: AppColors.black),
        ),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firebaseServices.getBlockedUsersDetailsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final blockedUsers = snapshot.data ?? [];

          if (blockedUsers.isEmpty) {
            return Center(
              child: Text('No blocked users', style: pjsStyleBlack18600),
            );
          }
          return ListView.builder(
            itemCount: blockedUsers.length,
            padding: EdgeInsets.all(context.screenWidth * 0.04),
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              return buildBlockedUserTile(context, user);
            },
          );
        },
      ),
    );
  }

  Widget buildBlockedUserTile(BuildContext context, UserModel user) {
    return Container(
      margin: EdgeInsets.only(bottom: context.screenHeight * 0.015),
      padding: EdgeInsets.all(context.screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Profile Image
          CircleAvatar(
            radius: context.screenWidth * 0.06,
            backgroundImage:
                user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
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
                if (user.nationality != null &&
                    user.nationality!.isNotEmpty) ...[
                  SizedBox(height: context.screenHeight * 0.002),
                  Row(
                    spacing: 5,
                    children: [
                      Text(
                        getFlagByNationality(user.nationality),
                        style: pjsStyleBlack10400.copyWith(
                          color: AppColors.darkGrey,
                        ),
                      ),
                      Text(
                        '${user.nationality}',
                        style: pjsStyleBlack10400.copyWith(
                          color: AppColors.darkGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          Consumer<PrivateChatSettingProvider>(
            builder: (context, provider, _) {
              return GestureDetector(
                onTap: () async {
                  await provider.unblockUser(user.uid);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.block, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Unblock',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
