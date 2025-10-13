import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:global_connect/core/const/app_color.dart';
import 'package:global_connect/core/theme/app_text_style.dart';

class InfoCard extends StatelessWidget {
  final String svgAsset;
  final String number;
  final String title;
  final String subtitle;

  const InfoCard({
    super.key,
    required this.svgAsset,
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:AppColors.primary2.withOpacity(0.16),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              svgAsset,
              width: 40,
              height: 40,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              number,
              style: pjsStyleBlack25700.copyWith(
                color: AppColors.primary
              )
            ),
            const SizedBox(height: 8),
            Text(
              title,
                style: pjsStyleBlack12700.copyWith(
                    color: AppColors.darkBlue.withOpacity(0.34)
                )
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
                style: pjsStyleBlack10700.copyWith(
                    color: AppColors.darkBlue.withOpacity(0.34)
                )
            ),
          ],
        ),
      ),
    );
  }
}


