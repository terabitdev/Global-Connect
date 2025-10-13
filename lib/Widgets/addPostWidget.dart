import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../Provider/AddPostProvider.dart';
import '../core/const/app_color.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:global_connect/core/const/app_images.dart';
import 'package:global_connect/core/theme/app_text_style.dart';
import '../../Widgets/CustomTextField.dart';


Widget buildImageSelector(AddPostProvider provider, [BuildContext? context]) {
  final totalImages = provider.existingImages.length + provider.selectedImages.length;
  final hasImages = totalImages > 0;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (!hasImages)
        GestureDetector(
          onTap: () => provider.pickImagesFromGallery(context),
          child: DottedBorder(
            borderType: BorderType.RRect,
            radius: const Radius.circular(10),
            color: AppColors.primary,
            strokeWidth: 2,
            dashPattern: const [8, 4],
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(AppImages.addIcon2, height: 48, width: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Upload Images',
                    style: pjsStyleBlack14700.copyWith(
                      color: AppColors.garyModern400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      else
        Column(
          children: [
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: totalImages,
                itemBuilder: (context, index) {
                  final isExistingImage = index < provider.existingImages.length;
                  
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: isExistingImage
                              ? Image.network(
                            provider.existingImages[index],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error),
                            ),
                          )
                              : Image.file(
                            provider.selectedImages[index - provider.existingImages.length],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              if (isExistingImage) {
                                provider.removeExistingImage(index);
                              } else {
                                provider.removeImage(index - provider.existingImages.length);
                              }
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        if (isExistingImage)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Current',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => provider.pickImagesFromGallery(context),
                  icon: const Icon(Icons.add_photo_alternate),
                  label: Text(hasImages ? 'Add More Images' : 'Upload Images'),
                ),
                const Spacer(),
                Text(
                  '$totalImages image(s) total',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            if (provider.existingImages.isNotEmpty && provider.selectedImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${provider.existingImages.length} existing, ${provider.selectedImages.length} new',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
          ],
        ),
      if (provider.imageError != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            provider.imageError!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
    ],
  );
}

Widget buildLocationField(AddPostProvider provider) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            label: 'Location',
            hintText: 'Type location',
            controller: provider.locationController,
            focusNode: provider.locationFocusNode,
            keyboardType: TextInputType.text,
            minLines: 1,
            maxLines: 2,
            onChanged: (value) {
              provider.searchLocation(value);
            },
            suffixIcon: provider.locationController.text.isNotEmpty
                ? IconButton(
              onPressed: () {
                provider.locationController.clear();
                provider.hideSuggestions();
              },
              icon: const Icon(Icons.clear),
              tooltip: 'Clear',
            )
                : const Icon(Icons.search),
          ),
          if (provider.locationError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                provider.locationError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),

      // Location suggestions dropdown
      if (provider.showSuggestions && provider.locationSuggestions.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.locationSuggestions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final suggestion = provider.locationSuggestions[index];
              return ListTile(
                dense: true,
                leading: const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 18,
                ),
                title: Text(
                  suggestion,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                onTap: () {
                  provider.selectLocation(suggestion);
                },
              );
            },
          ),
        ),

    ],
  );
}