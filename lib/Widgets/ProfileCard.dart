import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import '../Model/userModel.dart';
import '../core/const/app_color.dart';
import '../core/const/app_images.dart';
import '../core/theme/app_text_style.dart';
import '../core/utils/routes/routes.dart';

class ProfileCard extends StatelessWidget {
  final UserModel user;
  final String name;
  final String status;
  final String distance;
  final String countryFlag;
  final String countryName;
  final String profileImagePath;
  final String bio;
  final VoidCallback? onChatTap;

  const ProfileCard({
    Key? key,
    required this.user,
    required this.name,
    required this.status,
    required this.distance,
    required this.countryFlag,
    required this.countryName,
    required this.profileImagePath,
    required this.bio,
    this.onChatTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showProfileDialog(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderShad),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(profileImagePath),
                    backgroundColor: AppColors.white,
                    radius: 30,
                  ),
                  if (status == 'online' && user.appSettings.activityStatus)...[
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: CircleAvatar(
                        backgroundColor: AppColors.yellow,
                        radius: 6,
                      ),
                    ),
                  ]

                ],
              ),
              SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: pjsStyleBlack13600.copyWith(
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(countryFlag, style: TextStyle(fontSize: 16)),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            countryName,
                            style: pjsStyleBlack13600.copyWith(
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      distance,
                      style: pjsStyleBlack10500.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10),
              SvgPicture.asset(AppImages.chatBubble, height: 30, width: 30),
            ],
          ),
        ),
      ),
    );
  }

  void showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
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
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(profileImagePath),
                      backgroundColor: AppColors.white,
                      radius: 35,
                    ),

                    SizedBox(width: 16),

                    // Name and location
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(name, style: pStyleBlack14500),
                          SizedBox(height: 4),
                          Text(
                            countryName,
                            style: pjsStyleBlack10400.copyWith(
                              color: AppColors.darkGrey,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            distance + ' Away',
                            style: pjsStyleBlack10400.copyWith(
                              color: AppColors.darkGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.close,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(bio, style: pStyleBlack12400, maxLines: 3,overflow: TextOverflow.ellipsis,)),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Message button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          _handleMessageTap(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          height: 50,
                          child: Center(
                            child: Text(
                              'Message',
                              style: pStyleBlack12600.copyWith(
                                color: AppColors.white,
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
                          Navigator.of(context).pop();
                          _handleViewProfileTap(context, user);
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
                              'View Profile',
                              style: pStyleBlack12600.copyWith(
                                color: AppColors.primary,
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
            ),
          ),
        );
      },
    );
  }

  void _handleMessageTap(BuildContext context) {
    Navigator.pushNamed(
      context,
      RoutesName.chatScreen,
      arguments: {'user': user, 'type': 'Private'},
    );
    print('Message button tapped');
  }

  void _handleViewProfileTap(BuildContext context, user) {
    Navigator.pushNamed(
      context,
      RoutesName.userDetailScreen,
      arguments: {'user': user},
    );
    print('View Profile button tapped');
  }
}
