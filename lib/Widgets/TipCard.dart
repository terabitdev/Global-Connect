import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../core/const/app_color.dart';
import '../../core/const/app_images.dart';
import '../../core/theme/app_text_style.dart';
class TipCard extends StatelessWidget {
  final String title;
  final String subTitle;
  final String location;
  final String? category;

  const TipCard({
    Key? key,
    required this.title,
    required this.subTitle,
    required this.location,
    this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.blue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 18,
        ),
        child: Column(
          spacing: 5,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: pjsStyleBlack14800.copyWith(color: AppColors.black),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Center(
                      child: Text(
                      category!,
                        style: pjsStyleBlack8600.copyWith(color: AppColors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              subTitle,
              style: pjsStyleBlack12600.copyWith(color: AppColors.darkGrey),
            ),
            Row(
              children: [
                SvgPicture.asset(AppImages.pin),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: pjsStyleBlack12400.copyWith(color: AppColors.darkGrey),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}