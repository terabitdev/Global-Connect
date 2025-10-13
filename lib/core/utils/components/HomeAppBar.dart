import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:global_connect/core/const/responsive_layout.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

import '../../../Provider/user_profile_provider.dart';
import '../../../Widgets/shimmer_widgets.dart';
import '../../const/app_color.dart';
import '../../const/app_images.dart';
import '../../theme/app_text_style.dart';
import '../routes/routes.dart';

class HomeAppBar extends StatefulWidget {
  const HomeAppBar({super.key});

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProfileProvider>().listenToCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
        builder: (context, userProfileProvider, child) {
          final user = userProfileProvider.currentUser;
          final isLoading = user == null;
          return Container(
            child: Column(
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: Image.asset(
                          AppImages.homeAppBar, fit: BoxFit.cover),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.screenWidth * 0.05,
                        vertical: context.screenHeight * 0.05,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                        context, RoutesName.profileScreen);
                                  },
                                  child: CircleAvatar(
                                    backgroundColor: AppColors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: isLoading
                                        ? const CircleImageShimmerWidget(size: 60)
                                        : CircleAvatar(
                                            backgroundImage: NetworkImage(
                                              user!.profileImageUrl.toString(),
                                            ),
                                            backgroundColor: AppColors.white,
                                            radius: 30,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  AppImages.appLogo,
                                  fit: BoxFit.cover,
                                  color: AppColors.white,
                                  height: 80,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                          context, RoutesName.notificationScreen);

                                    },
                                    child: CircleAvatar(
                                      backgroundColor: AppColors.white,
                                      radius: 20,
                                      child: SvgPicture.asset(
                                        AppImages.notification,
                                        height: 20,
                                        width: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(context, RoutesName.privateChatScreen);
                                    },
                                    child: CircleAvatar(
                                      backgroundColor: AppColors.white,
                                      radius: 20,
                                      child: SvgPicture.asset(
                                        AppImages.message,
                                        height: 20,
                                        width: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bottom Text Positioned
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'Global Connect, Where Every\n Journey Begins',
                          style: pjsStyleBlack18900.copyWith(
                              color: AppColors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
    );
  }
}
