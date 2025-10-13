import 'package:flutter/material.dart';
import 'package:global_connect/core/const/gap.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:provider/provider.dart';

import '../../Provider/PrivateChatProvider.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/CustomSearchBar.dart';
import '../../Widgets/buildUserList.dart';
import '../../core/const/app_color.dart';
import '../../core/const/app_images.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/utils/components/CustomButton.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar2(
        title: Text(
          'New Chat',
          style: pjsStyleBlack18600.copyWith(color: AppColors.black),
        ),
      ),
      body: Padding(
        padding: gapSymmetric(horizontal: 10,vertical: 20),
        child: Consumer<PrivateChatProvider>(
          builder: (context, privateChatProvider, child) {
            return ListView(
              children: [
                /// Top buttons row
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Connections',
                        svgAsset: AppImages.group,
                        onTap: () {
                          // Handle navigation
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomButton(
                        backgroundColor: AppColors.white,
                        borderColor: AppColors.darkGrey.withOpacity(0.50),
                        textColor: AppColors.darkGrey,
                        svgAsset: AppImages.search,
                        text: 'Search',
                        onTap: () {
                          privateChatProvider.toggleSearchBar();
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// Search bar - conditionally shown
                if (privateChatProvider.showSearchBar) ...[
                  CustomSearchBar(
                    controller: privateChatProvider.searchController,
                    onChanged: (value) {
                      privateChatProvider.searchUsers(value);
                    },
                    hintText: 'Search',
                  ),
                  const SizedBox(height: 40),
                ],

                /// Users list
                if (privateChatProvider.connectedUsers.isEmpty)
                  Center(
                    child: Text(
                      "No connections yet. Connect with users to\n start chatting!",
                      style: pjsStyleBlack16600.copyWith(
                        color: AppColors.darkGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...privateChatProvider.connectedUsers.map(
                    (user) => buildUserList(context, user, privateChatProvider),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
