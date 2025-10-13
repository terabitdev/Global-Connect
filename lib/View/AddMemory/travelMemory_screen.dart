import 'package:flutter/material.dart';
import 'package:global_connect/core/const/app_images.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/memoryPlaceCard.dart';
import '../../Model/createMemoryModel.dart';
import '../../Provider/AddMemoryProvider.dart';
import '../../core/const/app_color.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/const/custamSnackBar.dart';
import '../../core/utils/components/CustomButton.dart';

class TravelMemoryScreen extends StatefulWidget {
  const TravelMemoryScreen({super.key});

  @override
  State<TravelMemoryScreen> createState() => _TravelMemoryScreenState();
}

class _TravelMemoryScreenState extends State<TravelMemoryScreen> {
  CreateMemoryModel? memory;
  bool _viewTracked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (memory == null) {
      memory = ModalRoute.of(context)?.settings.arguments as CreateMemoryModel?;
      _trackMemoryView();
    }
  }

  // Track memory view when screen loads
  void _trackMemoryView() async {
    if (memory != null && !_viewTracked) {
      _viewTracked = true;
      final memoryProvider = Provider.of<AddMemoryProvider>(context, listen: false);
      final updatedMemory = await memoryProvider.addViewToMemory(memory!);
      
      if (updatedMemory != null && mounted) {
        setState(() {
          memory = updatedMemory;
        });
      }
    }
  }

  String formatDateRange(DateTime startDate, DateTime endDate) {
    final dateFormat = DateFormat('MMM dd');
    final yearFormat = DateFormat('yyyy');
    return '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}, ${yearFormat.format(endDate)}';
  }

  void _showDeleteConfirmation(
    BuildContext context,
    AddMemoryProvider memoryProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<AddMemoryProvider>(
          builder: (context, provider, child) {
            return AlertDialog(
              backgroundColor: AppColors.white,
              title: Text(
                'Delete Memory',
                style: pjsStyleBlack14500.copyWith(color: AppColors.black),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to delete "${memory!.memoryName}"?',
                    style: pjsStyleBlack12400.copyWith(color: AppColors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This will permanently delete all images and data associated with this memory. This action cannot be undone.',
                    style: pjsStyleBlack12400.copyWith(
                      color: AppColors.garyModern400,
                    ),
                  ),
                  if (provider.isLoading) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      provider.uploadProgress,
                      style: pjsStyleBlack12400.copyWith(
                        color: AppColors.garyModern400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
              actions: [
                Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Cancel',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Expanded(
                      child: CustomButton(
                        backgroundColor: AppColors.red,
                        textColor: AppColors.white,
                        text: provider.isLoading ? 'Deleting...' : 'Delete',
                        onTap: provider.isLoading
                            ? null
                            : () => _deleteMemory(context, provider),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteMemory(
    BuildContext context,
    AddMemoryProvider memoryProvider,
  ) async {
    try {
      final success = await memoryProvider.deleteMemory(memory!);

      if (success && context.mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        CustomSnackBar.showSuccess(context, 'Memory deleted successfully!');
      } else if (context.mounted) {
        CustomSnackBar.showFailure(
          context,
          memoryProvider.uploadProgress.isNotEmpty
              ? memoryProvider.uploadProgress
              : 'Failed to delete memory',
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showFailure(
          context,
          'Error deleting memory: ${e.toString()}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (memory == null) {
      return Scaffold(
        appBar: CustomAppBar2(
          title: Text(
            'Memory Not Found',
            style: pjsStyleBlack18600.copyWith(color: AppColors.black),
          ),
        ),
        body: const Center(child: Text('No memory data found')),
      );
    }

    return Consumer<AddMemoryProvider>(
      builder: (context, memoryProvider, child) {
        final isOwner = memoryProvider.isMemoryOwner(memory!);

        // Define the delete callback
        final deleteCallback = isOwner
            ? () {
                _showDeleteConfirmation(context, memoryProvider);
              }
            : null;

        return Scaffold(
          appBar: CustomAppBar2(
            title: Text(
              memory!.memoryName,
              style: pjsStyleBlack18600.copyWith(color: AppColors.black),
            ),
            deleteIconOnTap: deleteCallback,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                spacing: 20,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    spacing: 5,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Travel Memories', style: pjsStyleBlack18700),
                      Text(
                        memory!.caption.isNotEmpty
                            ? memory!.caption
                            : 'Create beautiful albums from your trips',
                        style: pjsStyleBlack12500.copyWith(
                          color: AppColors.garyModern400,
                        ),
                      ),
                    ],
                  ),
                  MemoryPlaceCard(
                    imageUrl:
                        memory!.coverImageUrl ??
                        (memory!.mediaImageUrls.isNotEmpty
                            ? memory!.mediaImageUrls.first
                            : AppImages.onBoarding),
                    isNetworkImage:
                        memory!.coverImageUrl != null ||
                        memory!.mediaImageUrls.isNotEmpty,
                    name: memory!.memoryName,
                    location: memory!.country,
                    dateRange: formatDateRange(
                      memory!.startDate,
                      memory!.endDate,
                    ),
                    status: memory!.privacy == PrivacySetting.public
                        ? "Published"
                        : "Private",
                    likes: 0,
                    views: memory!.viewedBy.length,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
