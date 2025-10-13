import 'package:flutter/material.dart';

import '../core/const/app_color.dart';
import '../core/theme/app_text_style.dart';
import '../core/utils/components/CustomButton.dart';

class InfoRowCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;
  final String? svgAsset;

  const InfoRowCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
    this.svgAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 5,
      children: [
        Row(
          spacing: 5,
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
              child: CustomButton(
                textStyle: pjsStyleBlack10400,
                text: buttonText,
                height: 28,
                backgroundColor: AppColors.white,
                borderColor: AppColors.garyModern400,
                textColor: AppColors.black,
                svgAsset: svgAsset,
                onTap: onTap,
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
