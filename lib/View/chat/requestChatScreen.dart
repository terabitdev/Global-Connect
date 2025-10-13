import 'package:flutter/material.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:provider/provider.dart';
import '../../Provider/PrivateChatProvider.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/buildUserList.dart';
import '../../core/const/app_color.dart';
import '../../core/theme/app_text_style.dart';

class RequestChatScreen extends StatefulWidget {
  const RequestChatScreen({super.key});
  @override
  State<RequestChatScreen> createState() => _RequestChatScreenState();
}

class _RequestChatScreenState extends State<RequestChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar2(
        title: Text(
          'Request Chat',
          style: pjsStyleBlack18600.copyWith(color: AppColors.black),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.screenWidth * 0.05,
          vertical: context.screenHeight * 0.02,
        ),
        child: Consumer<PrivateChatProvider>(
          builder: (context, privateChatProvider, child) {
            return ListView(
              children: [
                /// Users list
                if (privateChatProvider.allUsers.isEmpty)
                  const Center(child: Text("No users found"))
                else
                  ...privateChatProvider.allUsers.map(
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
