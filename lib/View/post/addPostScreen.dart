import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:global_connect/core/const/app_images.dart';
import 'package:global_connect/core/theme/app_text_style.dart';
import 'package:global_connect/core/utils/components/CustomButton.dart';
import 'package:global_connect/core/utils/components/customAppBar.dart';
import 'package:provider/provider.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../Widgets/CustomTextField.dart';
import '../../Widgets/addPostWidget.dart';
import '../../core/const/app_color.dart';
import '../../core/const/custamSnackBar.dart';
import '../../Provider/AddPostProvider.dart';
import '../../Provider/SelectionProvider.dart';
import '../../core/utils/routes/routes.dart';
import 'package:lottie/lottie.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AddPostProvider(),
      child: Consumer<AddPostProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: const CustomAppBarScreen(title: 'Create Post'),
            body: Stack(
              children: [
                Column(
                  children: [
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
                              buildImageSelector(provider, context),

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
                                    minLines: 1,
                                    maxLines: 5,
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
                        text: provider.isLoading ? 'Posting...' : 'Post',
                        onTap: provider.isLoading
                            ? null
                            : () async {
                                try {
                                  final success = await provider.uploadPost();
                                  
                                  // Sirf tabhi navigate karein aur success dikhayein jab upload complete ho
                                  if (success && mounted) {
                                    final navigationProvider = Provider.of<NavigationProvider>(
                                      context,
                                      listen: false,
                                    );
                                    
                                    // Pehle success message dikhayein
                                    CustomSnackBar.showSuccess(
                                      context,
                                      'Post uploaded successfully!',
                                    );

                                    // Phir navigation karein
                                    await Future.delayed(const Duration(milliseconds: 500));
                                    if (mounted) {
                                      navigationProvider.navigateToHome();
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        RoutesName.homeMainScreen,
                                        (route) => false,
                                      );
                                    }
                                  } else if (!success && mounted) {
                                    CustomSnackBar.showFailure(
                                      context,
                                      'Missing required fields',
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    CustomSnackBar.showFailure(
                                      context,
                                      'Error uploading post',
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                  ),
                ),

                // Loading overlay with Lottie
                if (provider.isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Lottie.asset(
                        'assets/lottiefiles/loading.json',
                        width: 150, // size bara kar diya
                        height: 150,
                        fit: BoxFit.contain,
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
