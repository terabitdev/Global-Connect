import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:provider/provider.dart';

import '../Provider/GroupChatProvider.dart';
import '../Provider/PrivateChatProvider.dart';
import '../core/const/app_color.dart';
import '../core/theme/app_text_style.dart';

Widget buildChatTile(
    BuildContext context,
    chat, {
      String? actionTitle,
      VoidCallback? action,
      String? userId,
      bool isGroupAdmin = false,
      bool isCurrentUserAdmin = false,
      Function(String)? onMemberTap,
    }) {
  return GestureDetector(
    onTap: () {

      if (isCurrentUserAdmin && !isGroupAdmin && onMemberTap != null && userId != null) {
        onMemberTap(userId);
      }
    },
    child: Container(
      margin: EdgeInsets.only(bottom: context.screenHeight * 0.01),
      padding: EdgeInsets.all(context.screenWidth * 0.04),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: AppColors.borderColor.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          // Profile Image
          CircleAvatar(
            radius: context.screenWidth * 0.06,
            backgroundImage: NetworkImage(
              chat.profileImage,
            ),
          ),
          SizedBox(width: context.screenWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      chat.name,
                      style: pjsStyleBlack16600.copyWith(color: AppColors.black),
                    ),
                    if (isGroupAdmin) ...[
                      SizedBox(width: 8),
                      Icon(
                        Icons.admin_panel_settings,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: context.screenHeight * 0.005),
                Text(
                  chat.lastMessage,
                  style: pjsStyleBlack12400.copyWith(color: AppColors.darkGrey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          if (action != null) ...[
            GestureDetector(
              onTap: action,
              child: Container(
                decoration: BoxDecoration(
                  color: chat.isOnline ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  child: Text(
                    actionTitle!,
                    style: psjStyleBlack10400.copyWith(color: AppColors.white),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Show remove option only for admin
            if (isCurrentUserAdmin && !isGroupAdmin) ...[
              Icon(
                Icons.more_vert,
                size: 16,
                color: AppColors.darkGrey,
              ),
            ] else ...[
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.darkGrey,
              ),
            ],
          ],
        ],
      ),
    ),
  );
}

// Alert Dialog Function
void showRemoveUserDialog(
    BuildContext context,
    String userName,
    String profileImagePath,
    String userId,
    String groupChatRoomId,
    GroupChatProvider provider,
    ) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return ListenableBuilder(
        listenable: provider,
        builder: (context, child) {
          return WillPopScope(
            onWillPop: () async => !provider.isLoading,
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              elevation: 10,
              backgroundColor: Colors.white,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: Column(
                  spacing: 15,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(profileImagePath),
                          backgroundColor: AppColors.white,
                          radius: 35,
                        ),

                        SizedBox(width: 16),

                        // Name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName, style: pStyleBlack14500),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: provider.isLoading ? null : () => Navigator.of(dialogContext).pop(),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.close,
                              color: provider.isLoading ? AppColors.darkGrey : AppColors.primary,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        // Remove button
                        Expanded(
                          child: Container(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: provider.isLoading ? null : () async {
                                bool success = await provider.removeUserFromGroup(
                                  groupChatRoomId: groupChatRoomId,
                                  userId: userId,
                                  userName: userName,
                                );

                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('$userName has been removed from the group'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  Navigator.of(dialogContext).pop();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(provider.error ?? 'Failed to remove $userName from the group'),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: provider.isLoading ? AppColors.darkGrey : AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: provider.isLoading
                                  ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Removing...',
                                    style: pStyleBlack12600.copyWith(
                                      color: AppColors.white,
                                    ),
                                  ),
                                ],
                              )
                                  : Text(
                                'Remove From Group',
                                style: pStyleBlack12600.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

