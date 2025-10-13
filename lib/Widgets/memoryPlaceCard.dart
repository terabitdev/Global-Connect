import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:global_connect/core/const/app_images.dart';
import 'package:global_connect/core/theme/app_text_style.dart';
import 'package:global_connect/core/utils/components/CustomButton.dart';

import '../core/const/app_color.dart';

class MemoryPlaceCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String location;
  final String dateRange;
  final String status;
  final int likes;
  final int views;
  final bool isNetworkImage;

  const MemoryPlaceCard({
    Key? key,
    required this.imageUrl,
    required this.name,
    required this.location,
    this.dateRange = "",
    this.status = "Published",
    this.likes = 0,
    this.views = 0,
    this.isNetworkImage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.garyModern200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      SvgPicture.asset(AppImages.calender),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: psjStyleBlack14600,maxLines: 1,overflow: TextOverflow.ellipsis,),
                            if (dateRange.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                dateRange,
                                style: psjStyleBlack10400.copyWith(
                                  color: AppColors.darkGrey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Globe icon and status
                Expanded(
                  child: Row(
                    spacing: 10,
                    children: [
                      SvgPicture.asset(AppImages.word, color: AppColors.black),

                      Expanded(
                        child: CustomButton(
                          text: status,
                          onTap: () {},
                          height: 24,
                          padding: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: isNetworkImage
                  ? Image.network(
                imageUrl,
                height: 315,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 315,
                    width: double.infinity,
                    color: AppColors.garyModern200,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 315,
                    width: double.infinity,
                    color: AppColors.garyModern200,
                    child: Icon(
                      Icons.image_not_supported,
                      color: AppColors.garyModern400,
                      size: 60,
                    ),
                  );
                },
              )
                  : Image.asset(
                imageUrl,
                height: 315,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 315,
                    width: double.infinity,
                    color: AppColors.garyModern200,
                    child: Icon(
                      Icons.image_not_supported,
                      color: AppColors.garyModern400,
                      size: 60,
                    ),
                  );
                },
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Location
                Expanded(
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        AppImages.locationIcon,
                        color: AppColors.darkGrey,
                        width: 17,
                        height: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              location,
                              style: psjStyleBlack12400.copyWith(
                                color: AppColors.darkGrey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "$likes Likes",
                              style: psjStyleBlack10400.copyWith(
                                color: AppColors.darkGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Likes and Views
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$views Views",
                      style: psjStyleBlack10400.copyWith(
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}