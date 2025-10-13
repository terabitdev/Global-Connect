
import 'package:flutter/material.dart';
import 'package:global_connect/core/const/responsive_layout.dart';

import '../../core/const/app_color.dart';
import '../../core/theme/app_text_style.dart';
Widget buildTabButton(
    BuildContext context,
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
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: (isSelected ? pjsStyleBlack12700 : pjsStyleBlack12400).copyWith(
            color: isSelected ? AppColors.white : AppColors.darkGrey,

          ),
        ),
      ),
    ),
  );
}