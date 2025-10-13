import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:global_connect/core/theme/app_text_style.dart';
import 'dart:io';

import '../Provider/GroupChatProvider.dart' show Message;
import '../core/const/app_color.dart';
import '../View/chat/FullScreenImageViewer.dart';
import '../View/chat/VideoPlayerWidget.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final Map<String, dynamic>? additionalProps;
  final Function(String)? onDeleteMessage;
  final Function(String)? onRetryMessage;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.additionalProps,
    this.onDeleteMessage,
    this.onRetryMessage,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOptimistic = additionalProps?['isOptimistic'] ?? false;
    final bool isUploading = additionalProps?['isUploading'] ?? false;
    final double uploadProgress = additionalProps?['uploadProgress'] ?? 0.0;
    final bool isFailed = additionalProps?['isFailed'] ?? false;

    return StreamBuilder<DocumentSnapshot?>(
      stream: !isCurrentUser 
          ? FirebaseFirestore.instance
              .collection('users')
              .doc(message.senderId)
              .snapshots()
          : null,
      builder: (context, snapshot) {
        String senderName = 'Unknown User';
        String? senderProfileImage;
        
        if (!isCurrentUser && snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          senderName = userData?['fullName'] ?? 'Unknown User';
          senderProfileImage = userData?['profileImageUrl'];
        }

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: isCurrentUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isCurrentUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundImage: senderProfileImage != null && senderProfileImage.isNotEmpty
                      ? NetworkImage(senderProfileImage)
                      : null,
                  child: senderProfileImage == null || senderProfileImage.isEmpty
                      ? Icon(Icons.person, size: 16, color: Colors.grey)
                      : null,
                ),
                SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isCurrentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Show sender name for other users
                    if (!isCurrentUser && message.messageType != 'system') ...[
                      Padding(
                        padding: EdgeInsets.only(left: 12, bottom: 2),
                        child: Text(
                          senderName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.darkGrey,
                          ),
                        ),
                      ),
                    ],

                    Stack(
                      children: [
                        GestureDetector(
                          onLongPress: (message.messageType == 'text' || message.messageType == 'image' || message.messageType == 'video') && !isOptimistic
                              ? () =>  _showDeleteConfirmation(context)
                              : null,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            padding: message.messageType == 'image' || message.messageType == 'video'
                                ? EdgeInsets.all(4)
                                : EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: message.messageType == 'system'
                                  ? AppColors.gray20
                                  : isCurrentUser
                                  ? AppColors.primary
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: isCurrentUser || message.messageType == 'system'
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
                                else
                                  Text(
                                    message.text,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: message.messageType == 'system'
                                          ? AppColors.darkGrey
                                          : isCurrentUser
                                          ? AppColors.white
                                          : AppColors.black,
                                    ),
                                  ),
                                if (message.messageType != 'system') ...[
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
                                        _buildCompactUploadIndicator(uploadProgress, isCurrentUser),
                                      ] else ...[
                                        Text(
                                          _formatTime(message.sentOn),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w400,
                                            color: isCurrentUser
                                                ? AppColors.white.withOpacity(0.7)
                                                : AppColors.darkGrey,
                                          ),
                                        ),
                                      ],
                                      if (isCurrentUser && !isFailed && !isUploading) ...[
                                        SizedBox(width: 4),
                                        Icon(
                                          isOptimistic 
                                              ? Icons.schedule
                                              : message.isRead 
                                                  ? Icons.done_all 
                                                  : Icons.done,
                                          size: 12,
                                          color: isOptimistic
                                              ? AppColors.white.withOpacity(0.5)
                                              : message.isRead
                                                  ? Colors.blue
                                                  : AppColors.white.withOpacity(0.7),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        
                        // 3-dot menu button (only for current user's messages)
                        // if (isCurrentUser && !isOptimistic && (message.messageType == 'text' || message.messageType == 'image' || message.messageType == 'video'))
                        //   Positioned(
                        //     top: 4,
                        //     right: 4,
                        //     child: Material(
                        //       color: Colors.transparent,
                        //       child: InkWell(
                        //         borderRadius: BorderRadius.circular(20),
                        //         onTap: () => _showDeleteConfirmation(context),
                        //         child: Container(
                        //           padding: EdgeInsets.all(6),
                        //           decoration: BoxDecoration(
                        //             color: Colors.black.withOpacity(0.6),
                        //             borderRadius: BorderRadius.circular(20),
                        //           ),
                        //           child: Icon(
                        //             Icons.more_vert,
                        //             color: Colors.white,
                        //             size: 14,
                        //           ),
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isCurrentUser) ...[
                SizedBox(width: 8),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(message.senderId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String? profileImage;
                    if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                      final userData = snapshot.data!.data() as Map<String, dynamic>?;
                      profileImage = userData?['profileImageUrl'];
                    }
                    
                    return CircleAvatar(
                      radius: 16,
                      backgroundImage: profileImage != null && profileImage.isNotEmpty
                          ? NetworkImage(profileImage)
                          : null,
                      child: profileImage == null || profileImage.isEmpty
                          ? Icon(Icons.person, size: 16, color: Colors.grey)
                          : null,
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageContent(BuildContext context) {
    final bool isOptimistic = additionalProps?['isOptimistic'] ?? false;
    final bool isUploading = additionalProps?['isUploading'] ?? false;
    final double uploadProgress = additionalProps?['uploadProgress'] ?? 0.0;
    final bool isFailed = additionalProps?['isFailed'] ?? false;
    final File? localFile = additionalProps?['localFile'];
    final String? localFileUrl = additionalProps?['localFileUrl'];

    Widget imageWidget;
    
    if (isOptimistic && localFile != null) {
      imageWidget = Image.file(
        localFile,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder('Failed to load image');
        },
      );
    } else if (isOptimistic && localFileUrl != null) {
      imageWidget = Image.file(
        File(localFileUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorPlaceholder('Failed to load image');
        },
      );
    } else if (message.text.startsWith('http')) {
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

    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            onTap: !isFailed && !isUploading
                ? () {
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
                : null,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 250,
                maxWidth: MediaQuery.of(context).size.width * 0.6,
              ),
              child: imageWidget,
            ),
          ),
        ),
        // if (isUploading)
        //   _buildUploadingOverlay(uploadProgress),
        if (isFailed)
          GestureDetector(
            onTap: onRetryMessage != null 
                ? () => onRetryMessage!(message.messageId ?? message.id)
                : null,
            child: _buildFailedOverlay(),
          ),
      ],
    );
  }

  Widget _buildVideoContent(BuildContext context) {
    final bool isOptimistic = additionalProps?['isOptimistic'] ?? false;
    final bool isUploading = additionalProps?['isUploading'] ?? false;
    final double uploadProgress = additionalProps?['uploadProgress'] ?? 0.0;
    final bool isFailed = additionalProps?['isFailed'] ?? false;
    final File? localFile = additionalProps?['localFile'];
    final String? localFileUrl = additionalProps?['localFileUrl'];

    String videoPath;
    if (isOptimistic && localFile != null) {
      videoPath = localFile.path;
    } else if (isOptimistic && localFileUrl != null) {
      videoPath = localFileUrl;
    } else {
      videoPath = message.text;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            onTap: !isFailed && !isUploading
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenVideoPlayer(
                          videoUrl: videoPath,
                          isLocalFile: !videoPath.startsWith('http'),
                        ),
                      ),
                    );
                  }
                : null,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: 250,
                maxWidth: MediaQuery.of(context).size.width * 0.6,
              ),
              child: VideoPlayerWidget(
                videoUrl: videoPath,
                isLocalFile: !videoPath.startsWith('http'),
              ),
            ),
          ),
        ),
        // if (isUploading)
        //   _buildUploadingOverlay(uploadProgress),
        if (isFailed)
          GestureDetector(
            onTap: onRetryMessage != null 
                ? () => onRetryMessage!(message.messageId ?? message.id)
                : null,
            child: _buildFailedOverlay(),
          ),
      ],
    );
  }

  // Widget _buildUploadingOverlay(double progress) {
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: Colors.black.withOpacity(0.75),
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Center(
  //       child: Container(
  //         padding: EdgeInsets.all(20),
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.circular(12),
  //           boxShadow: [
  //             BoxShadow(
  //               color: Colors.black.withOpacity(0.1),
  //               blurRadius: 10,
  //               offset: Offset(0, 4),
  //             ),
  //           ],
  //         ),
  //         // child: Column(
  //         //   mainAxisSize: MainAxisSize.min,
  //         //   children: [
  //         //     Stack(
  //         //       alignment: Alignment.center,
  //         //       children: [
  //         //         SizedBox(
  //         //           width: 50,
  //         //           height: 50,
  //         //           child: CircularProgressIndicator(
  //         //             strokeWidth: 3,
  //         //             backgroundColor: Colors.grey[300],
  //         //             valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
  //         //             value: progress > 0 ? progress : null,
  //         //           ),
  //         //         ),
  //         //         if (progress > 0)
  //         //           Text(
  //         //             '${(progress * 100).toInt()}%',
  //         //             style: TextStyle(
  //         //               fontSize: 12,
  //         //               fontWeight: FontWeight.w600,
  //         //               color: AppColors.primary,
  //         //             ),
  //         //           ),
  //         //       ],
  //         //     ),
  //         //     SizedBox(height: 12),
  //         //     Text(
  //         //       'Uploading...',
  //         //       style: TextStyle(
  //         //         fontSize: 14,
  //         //         fontWeight: FontWeight.w500,
  //         //         color: Colors.grey[700],
  //         //       ),
  //         //     ),
  //         //   ],
  //         // ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildFailedOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Upload Failed',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Tap to retry',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactUploadIndicator(double progress, bool isCurrentUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
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
            value: progress > 0 ? progress : null,
          ),
        ),
        SizedBox(width: 6),
        Text(
          progress > 0 
              ? '${(progress * 100).toInt()}%'
              : 'Uploading...',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isCurrentUser
                ? Colors.white.withOpacity(0.8)
                : AppColors.darkGrey,
          ),
        ),
      ],
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
          title: Text('Delete Message',style: pjsStyleBlack19700,),
          content: Text('Are you sure you want to delete this message? This action cannot be undone.',style: pjsStyleBlack14700.copyWith(color: AppColors.darkGrey),),
          actions: [
          Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Message button
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

            // View Profile button
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onDeleteMessage!(message.messageId ?? message.id);
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