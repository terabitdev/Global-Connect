import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Model/chatRoomModel.dart';
import '../../const/app_color.dart';
import '../../const/app_images.dart';
import '../../theme/app_text_style.dart';
import '../../../View/chat/FullScreenImageViewer.dart';
import '../../../View/chat/VideoPlayerWidget.dart';
import '../../../Widgets/SharedPostWidget.dart';
import 'dart:io';

class EventCard extends StatelessWidget {
  const EventCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderShad),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: context.screenWidth * 0.3,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Container(
                color: Colors.grey.shade300,
                child: Image.asset(
                  AppImages.festivalsEvents,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Music Festival',
                          style: pjsStyleBlack14600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Event Organizer
                  Text('Lisbon Events', style: pStyleBlack12400),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Distance
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.darkGrey,
                      ),
                      Text(
                        '1.5 km',
                        style: pStyleBlack10400.copyWith(
                          color: AppColors.darkGrey,
                        ),
                      ),
                      // Time
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.darkGrey,
                      ),
                      Text(
                        'May 20, 8:00 PM',
                        style: pStyleBlack10400.copyWith(
                          color: AppColors.darkGrey,
                        ),
                      ),
                      // Attendees
                      Icon(Icons.person, size: 14, color: AppColors.darkGrey),
                      Text(
                        '15 going',
                        style: pStyleBlack10400.copyWith(
                          color: AppColors.darkGrey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Text(
                    'Three days of traditional and contemporary Portuguese music with local food and drinks..',
                    style: pStyleBlack10400.copyWith(color: AppColors.darkBlue),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.justify,
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      SvgPicture.asset(
                        AppImages.pin,
                        width: 14,
                        height: 14,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Praca do Comercio, Lisbon',
                        style: pStyleBlack12400.copyWith(
                          fontSize: 12,
                          color: AppColors.darkGrey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class ChatMessage {
  final String text;
  final bool isSender;
  final DateTime timestamp;
  final bool isEvent;

  ChatMessage({
    required this.text,
    required this.isSender,
    required this.timestamp,
    this.isEvent = false,
  });
}

class ChatBubbleFirebase extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final String profileImage;
  final Function(String)? onDeleteMessage;
  final Map<String, dynamic>? additionalProps;

  const ChatBubbleFirebase({
    super.key,
    required this.message,
    required this.profileImage,
    required this.isCurrentUser,
    this.onDeleteMessage,
    this.additionalProps,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOptimistic = additionalProps?['isOptimistic'] ?? false;
    final bool isUploading = additionalProps?['isUploading'] ?? false;
    final double uploadProgress = additionalProps?['uploadProgress'] ?? 0.0;
    final bool isFailed = additionalProps?['isFailed'] ?? false;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                profileImage
              )
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: (message.messageType == 'text' || message.messageType == 'image' || message.messageType == 'video') && isCurrentUser
                  ? () => _showDeleteConfirmation(context)
                  : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: message.messageType == 'image' || message.messageType == 'video'
                    ? EdgeInsets.all(4)
                    : message.messageType == 'post'
                        ? EdgeInsets.zero
                        : EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: message.messageType == 'post' 
                    ? null 
                    : BoxDecoration(
                        color: isCurrentUser ? AppColors.primary : AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isCurrentUser
                            ? null
                            : Border.all(color: AppColors.garyModern200),
                      ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.messageType == 'image')
                    _buildImageContent(context)
                  else if (message.messageType == 'video')
                    _buildVideoContent(context)
                  else if (message.messageType == 'post')
                    _buildPostContent(context)
                  else
                    Text(
                      message.text,
                      style: psjStyleBlack14400.copyWith(
                        color: isCurrentUser ? AppColors.white : AppColors.black,
                      ),
                    ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isFailed) ...[
                        Icon(
                          Icons.error_outline,
                          size: 12,
                          color: Colors.red,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Failed',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else if (isUploading) ...[
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            backgroundColor: isCurrentUser 
                                ? Colors.white.withOpacity(0.3)
                                : Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCurrentUser ? Colors.white : AppColors.primary,
                            ),
                            value: uploadProgress > 0 ? uploadProgress : null,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          uploadProgress > 0 
                              ? '${(uploadProgress * 100).toInt()}%'
                              : 'Uploading...',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isCurrentUser
                                ? Colors.white.withOpacity(0.8)
                                : AppColors.darkGrey,
                          ),
                        ),
                      ] else ...[
                        Text(
                          _formatTime(message.sentOn),
                          style: pStyleBlack10400.copyWith(
                            color: isCurrentUser ? AppColors.white.withOpacity(0.7) : AppColors.darkGrey,
                          ),
                        ),
                        if (isCurrentUser && !isOptimistic) ...[
                          SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 12,
                            color: message.isRead ? Colors.blue : AppColors.white.withOpacity(0.7),
                          ),
                        ],
                      ],
                    ],
                  ),
                ],
              ),
            ),
            ),
          ),
          if (isCurrentUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
                backgroundImage: NetworkImage(
                    profileImage
                )
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    final bool isOptimistic = additionalProps?['isOptimistic'] ?? false;
    final bool isUploading = additionalProps?['isUploading'] ?? false;
    final bool isFailed = additionalProps?['isFailed'] ?? false;

    // Show failed state with better UI
    if (isFailed) {
      return _buildFailedMediaPlaceholder('image');
    }

    Widget imageWidget;
    
    if (message.text.startsWith('http')) {
      imageWidget = Image.network(
        message.text,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder('Failed to load image');
        },
      );
    } else {
      imageWidget = Image.file(
        File(message.text),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder('Failed to load image');
        },
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () {
          // Don't allow opening full screen during upload
          if (!isUploading) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImageViewer(
                  imageUrl: message.text,
                  isLocalFile: !message.text.startsWith('http'),
                ),
              ),
            );
          }
        },
        child: Container(
          constraints: BoxConstraints(
            maxHeight: 250,
            maxWidth: MediaQuery.of(context).size.width * 0.6,
          ),
          child: Stack(
            children: [
              // Main image
              imageWidget,
              // Upload progress overlay (only when uploading)
              if (isUploading)
                _buildUploadOverlay(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent(BuildContext context) {
    final bool isOptimistic = additionalProps?['isOptimistic'] ?? false;
    final bool isUploading = additionalProps?['isUploading'] ?? false;
    final bool isFailed = additionalProps?['isFailed'] ?? false;

    // Show failed state with better UI
    if (isFailed) {
      return _buildFailedMediaPlaceholder('video');
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () {
          // Don't allow opening full screen during upload
          if (!isUploading) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenVideoPlayer(
                  videoUrl: message.text,
                  isLocalFile: !message.text.startsWith('http'),
                ),
              ),
            );
          }
        },
        child: Container(
          constraints: BoxConstraints(
            maxHeight: 250,
            maxWidth: MediaQuery.of(context).size.width * 0.6,
          ),
          child: Stack(
            children: [
              // Main video
              VideoPlayerWidget(
                videoUrl: message.text,
                isLocalFile: !message.text.startsWith('http'),
              ),
              // Upload progress overlay (only when uploading)
              if (isUploading)
                _buildUploadOverlay(context),
            ],
          ),
        ),
      ),
    );
  }

  // Build post content widget
  Widget _buildPostContent(BuildContext context) {
    // Check if we have postId and postOwnerId
    if (message.postId == null || message.postOwnerId == null) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Post unavailable',
          style: pStyleBlack12400.copyWith(color: AppColors.darkGrey),
        ),
      );
    }

    // Use the new SharedPostWidget
    return SharedPostWidget(
      postId: message.postId!,
      postOwnerId: message.postOwnerId!,
      isCurrentUser: isCurrentUser,
    );
  }

  // Upload overlay for media during upload
  Widget _buildUploadOverlay(BuildContext context) {
    final double uploadProgress = additionalProps?['uploadProgress'] ?? 0.0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  value: uploadProgress > 0 ? uploadProgress : null,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              if (uploadProgress > 0) ...[
                SizedBox(height: 8),
                Text(
                  '${(uploadProgress * 100).toInt()}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Better failed media placeholder
  Widget _buildFailedMediaPlaceholder(String mediaType) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // TODO: Add retry functionality
            onDeleteMessage?.call(message.id);
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  mediaType == 'image' ? Icons.image_not_supported : Icons.video_call_outlined,
                  size: 40,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 12),
                Text(
                  'Failed to upload $mediaType',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap to remove',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFailedPlaceholder(String message) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Tap to retry',
              style: TextStyle(
                color: Colors.red[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(String message) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 48, color: Colors.grey[600]),
            SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text('Delete Message', style: pjsStyleBlack18600),
          content: Text(
            'Are you sure you want to delete this message? This action cannot be undone.',
            style: pjsStyleBlack14400.copyWith(color: AppColors.darkGrey),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Cancel button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary),
                      ),
                      height: 50,
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: pStyleBlack12600.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                // Delete button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onDeleteMessage?.call(message.id);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      height: 50,
                      child: Center(
                        child: Text(
                          'Delete',
                          style: pStyleBlack12600.copyWith(
                            color: AppColors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}