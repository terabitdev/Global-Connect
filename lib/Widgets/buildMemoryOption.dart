import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:global_connect/core/const/app_color.dart';
import 'package:global_connect/core/const/app_images.dart';
import 'package:global_connect/core/theme/app_text_style.dart';
import '../Provider/AddMemoryProvider.dart';

Widget buildMemoryOption({
  required BuildContext context,
  required AddMemoryProvider provider,
  required int value,
  required String title,
  required String subtitle,
  required bool isSelected,
}) {
  return GestureDetector(
    onTap: () => provider.setSelectedTab(value),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SvgPicture.asset(
            isSelected ? AppImages.radioOn : AppImages.radioOff,
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:pjsStyleBlack14500
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: pjsStyleBlack14500.copyWith(color: AppColors.garyModern400)
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}