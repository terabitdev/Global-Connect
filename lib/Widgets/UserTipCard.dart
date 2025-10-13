import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../Provider/UserTipsProvider.dart';
import '../Provider/user_profile_provider.dart';
import '../Provider/ReportProvider.dart';
import '../Model/ReportModel.dart';
import '../core/const/app_color.dart';
import '../core/const/app_images.dart';
import '../core/const/responsive_layout.dart';
import '../core/services/firebase_services.dart';
import '../core/theme/app_text_style.dart';
import 'ReportDialog.dart';

class UserTipCard extends StatelessWidget {
  final String userImage;
  final String userName;
  final String userNationality;
  final String countryFlag;
  final String timeAgo;
  final String tipsCategories;
  final String title;
  final String description;
  final String location;
  final int likesCount;
  final int dislikesCount;
  final String tipId;
  final String tipOwnerId;
  final List<String> userLikeMembers;
  final List<String> userDislikeMembers;
  final VoidCallback? onActivityTap;

  const UserTipCard({
    super.key,
    required this.userImage,
    required this.userName,
    required this.countryFlag,
    required this.timeAgo,
    required this.title,
    required this.description,
    required this.location,
    required this.likesCount,
    required this.dislikesCount,
    required this.userNationality,
    required this.tipsCategories,
    required this.tipId,
    required this.tipOwnerId,
    required this.userLikeMembers,
    required this.userDislikeMembers,
    this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserTipsProvider, UserProfileProvider>(
      builder: (context, tipsProvider, userProvider, child) {
        final currentUserId = userProvider.currentUser?.uid;
        final bool isLiked =
            currentUserId != null && userLikeMembers.contains(currentUserId);
        final bool isDisliked =
            currentUserId != null && userDislikeMembers.contains(currentUserId);

        return Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: context.sizes.cardPaddings,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.garyModern200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Row(
                  children: [
                    // User Avatar
                    CircleAvatar(
                      radius: context.sizes.avatarSize / 2,
                      backgroundImage: NetworkImage(userImage),
                      backgroundColor: AppColors.garyModern200,
                      onBackgroundImageError: (exception, stackTrace) {
                        // Error handled by child widget
                      },
                      child: userImage.isEmpty
                          ? Icon(
                              Icons.person,
                              color: Colors.grey[600],
                              size: context.sizes.avatarSize * 0.5,
                            )
                          : null,
                    ),
                    SizedBox(width: context.responsive.isMobile ? 8 : 12),

                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  userName,
                                  style: context.responsive.responsiveTextStyle(
                                    base: pjsStyleBlack16700,
                                    mobileFontSize: 14,
                                    tabletFontSize: 18,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: context.responsive.isMobile ? 4 : 8,
                              ),

                              // SizedBox(width: context.responsive.isMobile ? 3 : 5),
                              // Text(
                              //   userNationality,
                              //   style: context.responsive.responsiveTextStyle(
                              //     base: pjsStyleBlack12400,
                              //     mobileFontSize: 10,
                              //     tabletFontSize: 14,
                              //   ),
                              // ),
                            ],
                          ),
                          SizedBox(height: context.responsive.isMobile ? 2 : 4),
                          Row(
                            spacing: 5,
                            children: [
                              Text(
                                timeAgo,
                                style: psjStyleBlack10500.copyWith(
                                  color: AppColors.garyModern400,
                                ),
                              ),
                              CircleAvatar(
                                backgroundColor: AppColors.garyModern400,
                                radius: 2,
                              ),
                              Text(
                                userNationality,
                                style: context.responsive
                                    .responsiveTextStyle(
                                      base: pjsStyleBlack12400,
                                      mobileFontSize: 10,
                                      tabletFontSize: 14,
                                    )
                                    .copyWith(color: AppColors.garyModern400),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.responsive.isMobile ? 8 : 12),
                    // Activity Button
                    GestureDetector(
                      onTap: onActivityTap,
                      child: Container(
                        padding: context.sizes.buttonPadding,
                        decoration: BoxDecoration(
                          color: AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(
                            context.sizes.smallBorderRadius,
                          ),
                        ),
                        child: Text(
                          tipsCategories,
                          style: pjsStyleBlack8600.copyWith(
                            color: AppColors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    SizedBox(width: context.responsive.isMobile ? 8 : 12),
                    PopupMenuButton<String>(
                      onSelected: (String value) {
                        if (value == 'report') {
                          showDialog(
                            context: context,
                            builder: (context) => ChangeNotifierProvider(
                              create: (context) => ReportProvider(),
                              child: ReportDialog(
                                contentId: tipId,
                                contentOwnerId: tipOwnerId,
                                contentType: ReportContentType.tip,
                              ),
                            ),
                          );
                        }
                      },
                      offset: const Offset(-10, 35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                      surfaceTintColor: Colors.white,
                      color: Colors.white,
                      padding: const EdgeInsets.all(10),
                      child: SvgPicture.asset(
                        AppImages.dot,
                        width: 20,
                        height: 20,
                      ),
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'report',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flag_outlined,
                                  size: 18,
                                  color: Colors.red[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Report Tip',
                                  style: pjsStyleBlack14400.copyWith(
                                    color: Colors.red[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: context.responsive.isMobile ? 12 : 16),

                // Title
                Text(
                  title,
                  style: psjStyleBlack14600.copyWith(color: AppColors.black),
                  maxLines: context.responsive.isMobile ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                ),

                SizedBox(height: context.responsive.isMobile ? 6 : 8),

                // Description with Read More functionality
                _buildExpandableDescription(context, tipsProvider),

                SizedBox(height: context.responsive.isMobile ? 8 : 12),

                // Location
                Row(
                  children: [
                    SvgPicture.asset(
                      AppImages.locationIcon,
                      width: context.sizes.iconSize,
                      height: context.sizes.iconSize,
                      color: AppColors.garyModern400,
                    ),
                    SizedBox(width: context.responsive.isMobile ? 3 : 4),
                    Expanded(
                      child: Text(
                        location,
                        style: psjStyleBlack14400.copyWith(
                          color: AppColors.garyModern400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.responsive.isMobile ? 12 : 16),
                Divider(color: AppColors.garyModern200),
                SizedBox(height: context.responsive.isMobile ? 12 : 16),

                // Engagement Section
                Row(
                  spacing: 15,
                  children: [
                    // Likes
                    Flexible(
                      child: GestureDetector(
                        onTap: currentUserId != null
                            ? () => _handleLike(
                                context,
                                tipsProvider,
                                currentUserId!,
                              )
                            : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              AppImages.like,
                              width: 40,
                              height: 20,
                              color: isLiked
                                  ? AppColors.primary
                                  : AppColors.darkGrey,
                            ),
                            SizedBox(
                              width: context.responsive.isMobile ? 4 : 6,
                            ),
                            Text(
                              '$likesCount',
                              style: context.responsive
                                  .responsiveTextStyle(
                                    base: psjStyleBlack12400,
                                    mobileFontSize: 9,
                                    tabletFontSize: 12,
                                  )
                                  .copyWith(
                                    color: isLiked
                                        ? AppColors.primary
                                        : AppColors.darkGrey,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: context.responsive.isMobile ? 8 : 12),

                    // Dislikes
                    Flexible(
                      child: GestureDetector(
                        onTap: currentUserId != null
                            ? () => _handleDislike(
                                context,
                                tipsProvider,
                                currentUserId!,
                              )
                            : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              AppImages.dislike,
                              width: 40,
                              height: 20,
                              color: isDisliked
                                  ? AppColors.primary
                                  : AppColors.darkGrey,
                            ),
                            SizedBox(
                              width: context.responsive.isMobile ? 4 : 6,
                            ),
                            Text(
                              '$dislikesCount',
                              style: context.responsive
                                  .responsiveTextStyle(
                                    base: psjStyleBlack12400,
                                    mobileFontSize: 9,
                                    tabletFontSize: 12,
                                  )
                                  .copyWith(
                                    color: isDisliked
                                        ? AppColors.darkGrey
                                        : AppColors.darkGrey,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandableDescription(
    BuildContext context,
    UserTipsProvider tipsProvider,
  ) {
    final maxLines = context.responsive.isMobile ? 3 : 4;
    final isExpanded = tipsProvider.isExpanded(tipId);

    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(
          text: description,
          style: psjStyleBlack12400.copyWith(color: AppColors.black),
        );

        final textPainter = TextPainter(
          text: textSpan,
          maxLines: maxLines,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout(maxWidth: constraints.maxWidth);

        final isTextOverflowing = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: psjStyleBlack12400.copyWith(color: AppColors.black),
              maxLines: isExpanded ? null : maxLines,
              overflow: isExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
            ),
            if (isTextOverflowing)
              GestureDetector(
                onTap: () {
                  tipsProvider.toggleExpansion(tipId);
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    isExpanded ? 'Read Less' : 'Read More',
                    style: pjsStyleBlack12600.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _handleLike(
    BuildContext context,
    UserTipsProvider tipsProvider,
    String currentUserId,
  ) async {
    try {
      final success = await FirebaseServices.likeTip(
        tipOwnerId: tipOwnerId,
        tipId: tipId,
        currentUserId: currentUserId,
      );

      if (success) {
        // Refresh tips to get updated data
        //  await tipsProvider.refresh();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to like tip'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleDislike(
    BuildContext context,
    UserTipsProvider tipsProvider,
    String currentUserId,
  ) async {
    try {
      final success = await FirebaseServices.dislikeTip(
        tipOwnerId: tipOwnerId,
        tipId: tipId,
        currentUserId: currentUserId,
      );

      if (success) {
        // Refresh tips to get updated data
        // await tipsProvider.refresh();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to dislike tip'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
