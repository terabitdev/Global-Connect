import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:global_connect/core/utils/components/CustomButton.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../Model/userModel.dart';
import '../../Provider/PrivateChatProvider.dart';
import '../../Provider/SignupProvider.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/CustomTextField.dart';
import '../../Widgets/buildTabButton.dart';
import '../../core/const/app_color.dart';
import '../../core/const/app_images.dart';
import '../../core/theme/app_text_style.dart';
import 'ProfileCard.dart';

Widget buildUserList(
  BuildContext context,
  UserModel user,
  PrivateChatProvider provider,
) {
  final isSelected = provider.isMemberSelected(user);

  return GestureDetector(
    onTap: () {
      // Create a ProfileCard instance and show the dialog
      final profileCard = ProfileCard(
        status: user.status,
        user: user,
        name: user.fullName ?? 'Unknown User',
        distance: '', // You can calculate distance if needed
        countryFlag: '', // Add flag based on nationality if needed
        countryName: user.nationality ?? '',
        profileImagePath: user.profileImageUrl?.isNotEmpty == true 
            ? user.profileImageUrl! 
            : AppImages.profileImage,
        bio: user.bio ?? '',
        onChatTap: () {
          print('Chat with ${user.fullName}');
        },
      );
      profileCard.showProfileDialog(context);
    },
    child: Container(
      margin: EdgeInsets.only(bottom: context.screenHeight * 0.01),
      padding: EdgeInsets.all(context.screenWidth * 0.04),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          bottom: BorderSide(
            color: isSelected
                ? AppColors.primary
                : AppColors.borderColor.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Profile Image with Status Indicator
          Stack(
            children: [
              CircleAvatar(
                radius: context.screenWidth * 0.06,
                backgroundImage:
                    user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                    ? NetworkImage(user.profileImageUrl!)
                    : AssetImage(AppImages.profileImage) as ImageProvider,
              ),
              // Status indicator - only show if user has activity status enabled
              if (user.status == 'online' && user.appSettings.activityStatus)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.yellow,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
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
                  user.bio ?? 'No email',
                  style: pjsStyleBlack12400.copyWith(color: AppColors.darkGrey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: context.screenWidth * 0.04),

          GestureDetector(
            onTap: () {},
            child: SvgPicture.asset(AppImages.forward),
          ),
        ],
      ),
    ),
  );
}
Widget buildShimmerUserCard(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Shimmer.fromColors(
      baseColor: AppColors.garyModern200,
      highlightColor: AppColors.lightGrey,
      child: Container(
        margin: EdgeInsets.only(bottom: context.screenHeight * 0.01),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: context.screenWidth * 0.12,
              height: context.screenWidth * 0.12,
              decoration: BoxDecoration(
                color: AppColors.garyModern200,
                shape: BoxShape.circle,
              ),
            ),

            SizedBox(width: context.screenWidth * 0.04),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.garyModern200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: context.screenHeight * 0.008),

                  Container(
                    width: context.screenWidth * 0.5,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.garyModern200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: context.screenWidth * 0.04),

            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.garyModern200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}