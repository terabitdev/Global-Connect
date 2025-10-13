import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:global_connect/core/const/app_color.dart';
import 'package:global_connect/core/theme/app_text_style.dart';

class StepItem extends StatelessWidget {
  final String assetPath;
  final String title;
  final bool isActive;
  final bool isCompleted;

  const StepItem({
    super.key,
    required this.assetPath,
    required this.title,
    this.isActive = false,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(
              color: (isActive || isCompleted) ? AppColors.primary : AppColors.darkGrey,
              width: 2,
            ),
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Center(
            child: SvgPicture.asset(
              assetPath,
              height: 20,
              width: 20,
              color: (isActive || isCompleted) ? AppColors.primary : AppColors.darkGrey,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: pjsStyleBlack14400.copyWith(
            color: (isActive || isCompleted) ? AppColors.primary : AppColors.darkGrey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

Widget buildDivider({bool isCompleted = false}) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 5, right: 5),
      child: Divider(
        color: isCompleted ? AppColors.primary : AppColors.darkGrey,
        thickness: 2,
      ),
    ),
  );
}
Widget dividerLine() {
  return Divider(
    color: AppColors.primary,
    thickness: 2,
  );
}