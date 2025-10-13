import 'package:flutter/material.dart';
import 'package:global_connect/core/theme/app_text_style.dart';

import '../core/const/app_color.dart';
import '../core/const/app_images.dart';

class PlaceCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String location;
  final VoidCallback onTap;
  final bool isNetworkImage;

  const PlaceCard({
    Key? key,
    required this.imageUrl,
    required this.name,
    required this.location,
    required this.onTap,
    this.isNetworkImage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        color: AppColors.white,
        elevation: 1,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),

          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Container(
                height: 110,
                width: 164,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    topLeft: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    topLeft: Radius.circular(16),
                  ),
                  child: isNetworkImage
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
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
                              color: AppColors.garyModern200,
                              child: Icon(
                                Icons.image_not_supported,
                                color: AppColors.garyModern400,
                                size: 40,
                              ),
                            );
                          },
                        )
                      : Image.asset(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.garyModern200,
                              child: Icon(
                                Icons.image_not_supported,
                                color: AppColors.garyModern400,
                                size: 40,
                              ),
                            );
                          },
                        ),
                ),
              ),

              // Text section
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: pjsStyleBlack14600, maxLines: 1,overflow: TextOverflow.ellipsis,),
                      const SizedBox(height: 4),
                      Text(
                        location,
                        style: pjsStyleBlack12400.copyWith(
                          color: AppColors.garyModern400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
