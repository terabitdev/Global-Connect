import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../Provider/PostProvider.dart';
import '../Provider/UserTipsProvider.dart';
import '../Provider/user_profile_provider.dart';
import '../Widgets/CustomSearchBar.dart';
import '../Widgets/shimmer_widgets.dart';
import '../core/const/app_color.dart';
import '../core/const/app_images.dart';
import '../core/utils/routes/routes.dart';

class HeaderWithSearchAndActions extends StatelessWidget {
  final String searchHintText;
  final bool useUserTipsProvider;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  
  const HeaderWithSearchAndActions({
    super.key,
    this.searchHintText = 'Search posts...',
    this.useUserTipsProvider = false,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (controller != null || onChanged != null) {
      // Custom controller/handler provided by caller (e.g., FestivalsEvents)
      return Row(
        children: [
          Expanded(
            child: CustomSearchBar(
              controller: controller ?? TextEditingController(),
              hintText: searchHintText,
              onChanged: onChanged,
            ),
          ),
          _buildActionButtons(context),
        ],
      );
    } else if (useUserTipsProvider) {
      return Consumer<UserTipsProvider>(
        builder: (context, tipsProvider, child) {
          return Row(
            children: [
              Expanded(
                child: CustomSearchBar(
                  controller: tipsProvider.searchController,
                  hintText: searchHintText,
                  onChanged: tipsProvider.onSearchChanged,
                ),
              ),
              _buildActionButtons(context),
            ],
          );
        },
      );
    } else {
      return Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          return Row(
            children: [
              Expanded(
                child: CustomSearchBar(
                  controller: postProvider.searchController,
                  hintText: searchHintText,
                  onChanged: postProvider.onSearchChanged,
                ),
              ),
              _buildActionButtons(context),
            ],
          );
        },
      );
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              RoutesName.notificationScreen,
            );
          },
          child: SvgPicture.asset(
            AppImages.notification,
            color: AppColors.primary,
            height: 20,
            width: 20,
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              RoutesName.privateChatScreen,
            );
          },
          child: SvgPicture.asset(
            AppImages.message,
            height: 20,
            width: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Consumer<UserProfileProvider>(
          builder: (context, userProfileProvider, child) {
            final user = userProfileProvider.currentUser;
            final isLoading = user == null;
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          RoutesName.profileScreen,
                        );
                      },
                      child: CircleAvatar(
                        backgroundColor: AppColors.white,
                        child: isLoading
                            ? const CircleImageShimmerWidget(
                                size: 60,
                              )
                            : CircleAvatar(
                                backgroundImage: NetworkImage(
                                  user.profileImageUrl.toString(),
                                ),
                                backgroundColor: AppColors.white,
                                radius: 30,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}