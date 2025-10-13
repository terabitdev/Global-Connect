import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../Model/userModel.dart';
import '../../Provider/PrivateChatProvider.dart';
import '../../Provider/privateChatSettingProvider.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/SettingTile.dart';
import '../../Widgets/buildChatTile.dart';
import '../../core/const/app_color.dart';
import '../../core/const/app_images.dart';
import '../../core/theme/app_text_style.dart';
import 'package:dotted_border/dotted_border.dart';

import 'package:global_connect/core/const/responsive_layout.dart';

import '../../Widgets/CustomTextField.dart';

import '../../core/utils/components/CustomButton.dart';
import '../../Provider/GroupSettingsProvider.dart';
import '../../core/utils/routes/routes.dart';
import 'groupChatSetting-Screen.dart';

class PrivateChatSettingScreen extends StatefulWidget {
  final UserModel user;

  const PrivateChatSettingScreen({
    super.key,
    required this.user,
  });

  @override
  State<PrivateChatSettingScreen> createState() =>
      _PrivateChatSettingScreenState();
}

class _PrivateChatSettingScreenState extends State<PrivateChatSettingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrivateChatSettingProvider>().initialize(widget.user.uid);
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar2(
        title: Text(
          'Private Chat Settings',
          style: pjsStyleBlack18600.copyWith(color: AppColors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.screenWidth * 0.05,
            vertical: context.screenHeight * 0.02,
          ),
          child: Column(
            spacing: 20,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(widget.user.profileImageUrl.toString()),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.user.fullName,
                      style: pjsStyleBlack14500.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),


              Text('Settings', style: pjsStyleBlack14500),

              // Consumer<GroupSettingsProvider>(
              //   builder: (context, settings, _) => Column(
              //     spacing: 20,
              //     mainAxisAlignment: MainAxisAlignment.start,
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       SettingTile(
              //         title: '🔕 Mute Notifications',
              //         value: settings.muteNotifications,
              //         onChanged: settings.toggleMuteNotifications,
              //       ),
              //       SettingTile(
              //         title: '📍 Share Location',
              //         value: settings.shareLocation,
              //         onChanged: settings.toggleShareLocation,
              //       ),
              //
              //     ],
              //   ),
              // ),
              Consumer<PrivateChatSettingProvider>(
                builder: (context, provider, _) {
                  return Column(
                    children: [
                      // Show block status message if any
                      // if (provider.blockStatusMessage != null)
                      //   Container(
                      //     width: double.infinity,
                      //     padding: const EdgeInsets.all(12),
                      //     margin: const EdgeInsets.only(bottom: 16),
                      //     decoration: BoxDecoration(
                      //       color: Colors.orange.withOpacity(0.1),
                      //       borderRadius: BorderRadius.circular(8),
                      //       border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      //     ),
                      //     child: Text(
                      //       provider.blockStatusMessage!,
                      //       style: pStyleBlack12400.copyWith(
                      //         color: Colors.orange[700],
                      //       ),
                      //       textAlign: TextAlign.center,
                      //     ),
                      //   ),
                      
                      // Block/Unblock button
                      CustomButton(
                        text: provider.isBlocking
                            ? '🔄 Loading...'
                            : provider.isBlocked
                            ? 'Unblock User'
                            : 'Block User',
                        onTap: provider.isBlocking || provider.isBlockedByOther
                            ? null
                            : () async {
                          await provider.toggleBlockUser(widget.user.uid);
                        },
                      ),
                      
                      // Show message if blocked by other user
                      // if (provider.isBlockedByOther && !provider.isBlocked)
                      //   Container(
                      //     width: double.infinity,
                      //     padding: const EdgeInsets.all(12),
                      //     margin: const EdgeInsets.only(top: 16),
                      //     decoration: BoxDecoration(
                      //       color: Colors.red.withOpacity(0.1),
                      //       borderRadius: BorderRadius.circular(8),
                      //       border: Border.all(color: Colors.red.withOpacity(0.3)),
                      //     ),
                      //     child: Text(
                      //       'You cannot block this user because they have blocked you.',
                      //       style: pStyleBlack12400.copyWith(
                      //         color: Colors.red[700],
                      //       ),
                      //       textAlign: TextAlign.center,
                      //     ),
                      //   ),
                    ],
                  );
                },
              ),

            ],
          ),
        ),
      ),
    );
  }
}
