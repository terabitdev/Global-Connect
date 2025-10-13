import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/const/app_color.dart';
import '../core/const/app_images.dart';
import '../core/theme/app_text_style.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 0),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, AppImages.home, 'Home'),
          _buildNavItem(1, AppImages.map, 'Map'),
          _buildNavItem(2, AppImages.post, 'Post'),
          _buildNavItem(3, AppImages.tips, 'Tips'),
          _buildNavItem(4, AppImages.events, 'Events'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String iconPath, String label) {
    final bool isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 80,
        child: Column(
         mainAxisSize: MainAxisSize.min,
         mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              color: isSelected ? AppColors.primary : AppColors.darkGrey,
              height: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: pjsStyleBlack10500.copyWith(
                color: isSelected ? AppColors.primary : AppColors.darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
