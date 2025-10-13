import 'package:flutter/material.dart';
import '../core/const/app_color.dart';
import '../core/theme/app_text_style.dart';

class InfoRowCardSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;

  const InfoRowCardSwitch({
    super.key,
    required this.title,
    required this.subtitle,
    this.value = false,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      children: [
        Row(
          spacing: 10,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                spacing: 5,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: pjsStyleBlack14500.copyWith(
                      color: AppColors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: pjsStyleBlack12500.copyWith(
                      color: AppColors.garyModern400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Switch(
                value: value,
                onChanged: onChanged ?? (value) {},
                activeColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const Divider(
          color: AppColors.garyModern200,
          thickness: 2,
        ),
      ],
    );
  }
}