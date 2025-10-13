import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../core/const/app_color.dart';
import '../core/const/app_images.dart';
import '../core/theme/app_text_style.dart';

class EmptyStateWidget extends StatelessWidget {
  final String svgAsset;
  final String title;
  final String subtitle;

  const EmptyStateWidget({
    super.key,
    required this.svgAsset,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          svgAsset,
          color: AppColors.purple2,
          width: 60,
          height: 60,
        ),
        Text(title, style: pjsStyleBlack16700),
        Text(
          subtitle,
          style: pjsStyleBlack12500.copyWith(color: AppColors.garyModern400),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
Widget buildEmptyStateWidget(String selectedFilter) {
  switch (selectedFilter) {
    case 'Following':
      return EmptyStateWidget(
        svgAsset: AppImages.followingIcon,
        title: 'No content from people you follow',
        subtitle: 'Follow more people to see their posts and memories!',
      );
    case 'Connections':
      return EmptyStateWidget(
        svgAsset: AppImages.connectionGroup,
        title: 'No content from connections',
        subtitle: 'Connect with more people to see their posts and\nmemories!',
      );
    case 'Global':
    default:
      return EmptyStateWidget(
        svgAsset: AppImages.word,
        title: 'No Content Yet',
        subtitle: 'Be the first to share.',
      );
  }
}