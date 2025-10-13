import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Provider/AddPostProvider.dart';
import '../../Widgets/CustomTextField.dart';
import '../../Widgets/addPostWidget.dart';
import '../../core/const/app_color.dart';
import '../../core/const/custamSnackBar.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/utils/components/CustomButton.dart';
import '../../core/utils/routes/routes.dart';

class EditPostScreen extends StatefulWidget {
  final String? postId;
  final String? caption;
  final List<String>? images;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? hashtags;

  const EditPostScreen({
    super.key,
    this.postId,
    this.caption,
    this.images,
    this.location,
    this.latitude,
    this.longitude,
    this.hashtags,
  });

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final provider = AddPostProvider();
        // Initialize with existing data if in edit mode
        if (widget.postId != null) {
          provider.initializeForEdit(
            postId: widget.postId!,
            caption: widget.caption ?? '',
            images: widget.images ?? [],
            location: widget.location ?? '',
            latitude: widget.latitude ?? 0.0,
            longitude: widget.longitude ?? 0.0,
            hashtags: widget.hashtags ?? '',
          );
        }
        return provider;
      },
      child: Consumer<AddPostProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,vertical: 10
            ),
            child: Stack(
              children: [
                Column(

                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: CircleAvatar(
                            backgroundColor: AppColors.lightGrey.withOpacity(
                              0.60,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.black,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),

                        Text(
                          'Edit Post',
                          style: pjsStyleBlack18600.copyWith(
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Column(
                            spacing: 15,
                            children: [
                              buildImageSelector(provider),

                              // Caption TextField
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomTextField(
                                    label: 'Add a Caption',
                                    hintText: 'Enter a caption...',
                                    controller: provider.captionController,
                                    focusNode: provider.captionFocusNode,
                                    minLines: 3,
                                    maxLines: 5,
                                    keyboardType: TextInputType.multiline,
                                  ),
                                  if (provider.captionError != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        provider.captionError!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              // Location TextField with map button
                              buildLocationField(provider),

                              // Tags TextField
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomTextField(
                                    label: 'Tags',
                                    hintText: 'Enter tags',
                                    controller: provider.tagsController,
                                    focusNode: provider.tagsFocusNode,
                                    keyboardType: TextInputType.text,
                                  ),
                                  if (provider.tagsError != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        provider.tagsError!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Fixed POST button at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: CustomButton(
                        text: provider.isLoading 
                            ? (provider.isEditMode ? 'Updating...' : 'Posting...')
                            : (provider.isEditMode ? 'Update Post' : 'Post'),
                        onTap: provider.isLoading
                            ? null
                            : () async {
                                final success = await provider.uploadPost();
                                if (success && mounted) {
                                  // Close the modal bottom sheet
                                  Navigator.pop(context);
                                  
                                  // Show success message after closing modal
                                  Future.delayed(Duration(milliseconds: 100), () {
                                    if (mounted) {
                                      CustomSnackBar.showSuccess(
                                        context,
                                        provider.isEditMode
                                            ? 'Post updated successfully!'
                                            : 'Post uploaded successfully!',
                                      );
                                    }
                                  });
                                } else if (!success && mounted) {
                                  CustomSnackBar.showFailure(
                                    context,
                                    provider.uploadProgress.isEmpty
                                        ? (provider.isEditMode
                                            ? 'Failed to update post'
                                            : 'Failed to upload post')
                                        : provider.uploadProgress,
                                  );
                                }
                              },
                      ),
                    ),
                  ),
                ),

                // Loading overlay
                if (provider.isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              provider.uploadProgress,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
