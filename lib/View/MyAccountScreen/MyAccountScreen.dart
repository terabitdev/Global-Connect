import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:global_connect/Widgets/InfoRowCardSwitch.dart';
import 'package:provider/provider.dart';
import '../../Provider/MyAccountScreenProvider.dart';
import '../../Provider/user_profile_provider.dart';
import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/InfoRowCard.dart';
import '../../core/const/app_color.dart';
import '../../core/const/app_images.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/utils/components/CustomButton.dart';

class MyAccountScreen extends StatelessWidget {
  const MyAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyAccountScreenProvider(),
      child: SafeArea(
        bottom: true,
        top: false,
        child: Scaffold(
          appBar: CustomAppBar2(
            title: Text(
              'Settings',
              style: pjsStyleBlack18600.copyWith(color: AppColors.black),
            ),
          ),
          body: Consumer<MyAccountScreenProvider>(
            builder: (context, provider, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Consumer<UserProfileProvider>(
                      builder: (context, userProfileProvider, child) {
                        final user = userProfileProvider.currentUser;
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: AppColors.garyModern200,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  spacing: 6,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Account',
                                      style: pjsStyleBlack18700.copyWith(
                                        color: AppColors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: AppColors.garyModern200,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 15,
                                        ),
                                        child: Text(
                                          user!.email,
                                          style: pjsStyleBlack14400.copyWith(
                                            color: AppColors.darkGrey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    Divider(
                                      color: AppColors.garyModern200,
                                      thickness: 2,
                                    ),
                                    CustomButton(
                                      height: 34,
                                      text: 'Sign out',
                                      onTap: () {
                                        provider.logout(context);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.garyModern200,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            spacing: 10,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location & Travel',
                                style: pjsStyleBlack16600.copyWith(
                                  color: AppColors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Consumer<UserProfileProvider>(
                              //   builder: (context, userProfileProvider, child) {
                              //     final user = userProfileProvider.currentUser;
                              //     return _switchTile(
                              //       title: 'Pause My Visibility',
                              //       value: user?.pauseMyVisibility ?? false,
                              //       onChanged: (bool newValue) async {
                              //         await userProfileProvider.updatePauseMyVisibility(
                              //           newValue,
                              //         );
                              //       },
                              //     );
                              //   },
                              // ),
                              Consumer<UserProfileProvider>(
                                builder: (context, userProfileProvider, child) {
                                  final user = userProfileProvider.currentUser;
                                  return InfoRowCardSwitch(
                                    title: "Location Sharing",
                                    subtitle:
                                        "Share your current location with friends",
                                    value: user?.pauseMyVisibility ?? false,
                                    onChanged: (bool newValue) async {
                                      await userProfileProvider
                                          .updatePauseMyVisibility(newValue);
                                    },
                                  );
                                },
                              ),
                              Consumer<UserProfileProvider>(
                                builder: (context, userProfileProvider, child) {
                                  final user = userProfileProvider.currentUser;
                                  return InfoRowCardSwitch(
                                    title: "Auto Detect Cities",
                                    subtitle:
                                        "Automatically detect when you visit new cities",
                                    value:
                                        user?.appSettings.autoDetectCities ??
                                        true,
                                    onChanged: (bool newValue) async {
                                      await userProfileProvider
                                          .updateAppSetting(
                                            'autoDetectCities',
                                            newValue,
                                          );
                                    },
                                  );
                                },
                              ),
                              // Consumer<UserProfileProvider>(
                              //   builder: (context, userProfileProvider, child) {
                              //     final user = userProfileProvider.currentUser;
                              //     return InfoRowCardSwitch(
                              //       title: "Travel Notifications",
                              //       subtitle:
                              //           "Get notifications about nearby events and tips",
                              //       value:
                              //           user?.appSettings.travelNotification ??
                              //           true,
                              //       onChanged: (bool newValue) async {
                              //         await userProfileProvider
                              //             .updateAppSetting(
                              //               'travelNotification',
                              //               newValue,
                              //             );
                              //       },
                              //     );
                              //   },
                              // ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.garyModern200,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            spacing: 10,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profile Visibility',
                                style: pjsStyleBlack16600.copyWith(
                                  color: AppColors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Consumer<UserProfileProvider>(
                                builder: (context, userProfileProvider, child) {
                                  final user = userProfileProvider.currentUser;
                                  return InfoRowCardSwitch(
                                    title: "Private Account",
                                    subtitle:
                                        "Only approved followers can see your posts and profile",
                                    value:
                                        user?.appSettings.privateAccount ??
                                        true,
                                    onChanged: (bool newValue) async {
                                      await userProfileProvider
                                          .updateAppSetting(
                                            'privateAccount',
                                            newValue,
                                          );
                                    },
                                  );
                                },
                              ),
                              // Consumer<UserProfileProvider>(
                              //   builder: (context, userProfileProvider, child) {
                              //     final user = userProfileProvider.currentUser;
                              //     return InfoRowCardSwitch(
                              //       title: "Public Profile",
                              //       subtitle:
                              //           "Allow others to find and view your profile",
                              //       value:
                              //           user?.appSettings.publicProfile ?? true,
                              //       onChanged: (bool newValue) async {
                              //         await userProfileProvider
                              //             .updateAppSetting(
                              //               'publicProfile',
                              //               newValue,
                              //             );
                              //       },
                              //     );
                              //   },
                              // ),
                              Consumer<UserProfileProvider>(
                                builder: (context, userProfileProvider, child) {
                                  final user = userProfileProvider.currentUser;
                                  return InfoRowCardSwitch(
                                    title: "Show Travel Map",
                                    subtitle:
                                        "Display your countries visited map to others",
                                    value:
                                        user?.appSettings.showTravelMap ?? true,
                                    onChanged: (bool newValue) async {
                                      await userProfileProvider
                                          .updateAppSetting(
                                            'showTravelMap',
                                            newValue,
                                          );
                                    },
                                  );
                                },
                              ),
                              Consumer<UserProfileProvider>(
                                builder: (context, userProfileProvider, child) {
                                  final user = userProfileProvider.currentUser;
                                  return InfoRowCardSwitch(
                                    title: "Show Travel Stats",
                                    subtitle:
                                        "Display your travel statistics publicly",
                                    value:
                                        user?.appSettings.showTravelStats ??
                                        true,
                                    onChanged: (bool newValue) async {
                                      await userProfileProvider
                                          .updateAppSetting(
                                            'showTravelStats',
                                            newValue,
                                          );
                                    },
                                  );
                                },
                              ),
                              Consumer<UserProfileProvider>(
                                builder: (context, userProfileProvider, child) {
                                  final user = userProfileProvider.currentUser;
                                  return InfoRowCardSwitch(
                                    title: "Activity Status",
                                    subtitle:
                                        "Show when you're online or recently active",
                                    value:
                                        user?.appSettings.activityStatus ??
                                        true,
                                    onChanged: (bool newValue) async {
                                      await userProfileProvider
                                          .updateAppSetting(
                                            'activityStatus',
                                            newValue,
                                          );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.garyModern200,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            spacing: 10,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notifications',
                                style: pjsStyleBlack16600.copyWith(
                                  color: AppColors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Consumer<UserProfileProvider>(
                                builder: (context, userProfileProvider, child) {
                                  final user = userProfileProvider.currentUser;
                                  return InfoRowCardSwitch(
                                    title: "Push Notifications",
                                    subtitle:
                                        "Receive notifications about activities and messages",
                                    value:
                                        user?.isPushNotificationEnabled ??
                                        false,
                                    onChanged: (bool newValue) async {
                                      await userProfileProvider
                                          .updatePushNotificationEnabled(
                                            newValue,
                                          );
                                    },
                                  );
                                },
                              ),
                              Consumer<UserProfileProvider>(
                                builder: (context, userProfileProvider, child) {
                                  final user = userProfileProvider.currentUser;
                                  return InfoRowCardSwitch(
                                    title: "Friend Requests",
                                    subtitle:
                                        "Get notified when someone wants to connect",
                                    value:
                                        user?.appSettings.friendRequests ??
                                        true,
                                    onChanged: (bool newValue) async {
                                      await userProfileProvider
                                          .updateAppSetting(
                                            'friendRequests',
                                            newValue,
                                          );
                                    },
                                  );
                                },
                              ),
                              Consumer<UserProfileProvider>(
                                builder: (context, userProfileProvider, child) {
                                  final user = userProfileProvider.currentUser;
                                  return InfoRowCardSwitch(
                                    title: "New Tips & Events",
                                    subtitle:
                                        "Get updates about new tips and events in your area",
                                    value:
                                        user?.appSettings.newTipsAndEvents ??
                                        true,
                                    onChanged: (bool newValue) async {
                                      await userProfileProvider
                                          .updateAppSetting(
                                            'newTipsAndEvents',
                                            newValue,
                                          );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.garyModern200,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            spacing: 10,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connect With Us',
                                style: pjsStyleBlack16600.copyWith(
                                  color: AppColors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              InfoRowCard(
                                title: "Our Website",
                                subtitle:
                                    "Visit our main website for more information",
                                buttonText: "Visit",
                                svgAsset: AppImages.word,
                                onTap: () async {
                                  await provider.launchWebsite();
                                },
                              ),
                              InfoRowCard(
                                title: "Follow us on Instagram",
                                subtitle: "Get travel inspiration and updates",
                                buttonText: "Follow",
                                svgAsset: AppImages.instagramIcon,
                                onTap: () async {
                                  await provider.launchInstagram();
                                },
                              ),
                              InfoRowCard(
                                title: "Follow us on TikTok",
                                subtitle:
                                    "Watch travel tips and community highlights",
                                buttonText: "Follow",
                                svgAsset: AppImages.music,
                                onTap: () async {
                                  await provider.launchTikTok();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.garyModern200,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            spacing: 10,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Legal',
                                style: pjsStyleBlack16600.copyWith(
                                  color: AppColors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              InfoRowCard(
                                title: "Terms and Conditions",
                                subtitle:
                                    "Read our terms of service and usage policies",
                                buttonText: "View",
                                svgAsset: AppImages.view,
                                onTap: () {
                                  provider.viewTermsOfUse(context);
                                },
                              ),
                              InfoRowCard(
                                title: "Privacy Policy",
                                subtitle:
                                    "Understand how we collect and use your data",
                                buttonText: "View",
                                svgAsset: AppImages.view2,
                                onTap: () {
                                  provider.viewPrivacyPolicy(context);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Account & Profile Section
                    _sectionHeader('Account & Profile'),

                    _settingsCard([
                      _settingsTile(
                        title: 'Personal Data',
                        onTap: () => provider.setPersonalData(context),
                      ),
                      _settingsCard([
                        _settingsTile(
                          title: "Countries I've Visited",
                          onTap: () => provider.setCountryIVisited(context),
                        ),
                      ]),
                      // _settingsTile(
                      //   svgIcon: AppImages.emailIcon,
                      //   title: 'Change Email',
                      //   onTap: provider.changeEmail,
                      // ),
                      // _settingsTile(
                      //   svgIcon: AppImages.lock,
                      //   title: 'Change Password',
                      //   onTap: provider.changePassword,
                      // ),
                    ]),

                    // Location & Visibility Section
                    _sectionHeader('Location & Visibility'),
                    _settingsCard([
                      // Consumer<UserProfileProvider>(
                      //   builder: (context, userProfileProvider, child) {
                      //     final user = userProfileProvider.currentUser;
                      //     return _switchTile(
                      //       title: 'Pause My Visibility',
                      //       value: user?.pauseMyVisibility ?? false,
                      //       onChanged: (bool newValue) async {
                      //         await userProfileProvider.updatePauseMyVisibility(
                      //           newValue,
                      //         );
                      //       },
                      //     );
                      //   },
                      // ),
                      _settingsTile(
                        title: 'Discovery Radius',
                        onTap: () => provider.setDiscoveryRadius(context),
                      ),
                      // _settingsTile(
                      //   title: 'Default Mode',
                      //   onTap: provider.setDefaultMode,
                      // ),
                    ]),

                    // // Notifications Section
                    // _sectionHeader('Notifications'),
                    // _settingsCard([
                    //   // Consumer<UserProfileProvider>(
                    //   //   builder: (context, userProfileProvider, child) {
                    //   //     final user = userProfileProvider.currentUser;
                    //   //     return _switchTile(
                    //   //       title: 'Push Notifications',
                    //   //       value: user?.isPushNotificationEnabled ?? false,
                    //   //       onChanged: (bool newValue) async {
                    //   //         await userProfileProvider
                    //   //             .updatePushNotificationEnabled(newValue);
                    //   //       },
                    //   //     );
                    //   //   },
                    //   // ),
                    //
                    //   // _switchTile(
                    //   //   title: 'New Travelers',
                    //   //   value: provider.newTravelers,
                    //   //   onChanged: provider.toggleNewTravelers,
                    //   // ),
                    //   // _switchTile(
                    //   //   title: 'New Messages',
                    //   //   value: provider.newMessages,
                    //   //   onChanged: provider.toggleNewMessages,
                    //   // ),
                    //   // _switchTile(
                    //   //   title: 'New Events or Tips',
                    //   //   value: provider.newEventsOrTips,
                    //   //   onChanged: provider.toggleNewEventsOrTips,
                    //   // ),
                    //   // _switchTile(
                    //   //   title: 'Chat Activity',
                    //   //   value: provider.chatActivity,
                    //   //   onChanged: provider.toggleChatActivity,
                    //   // ),
                    //   // _switchTile(
                    //   //   title: 'Admin Updates',
                    //   //   value: provider.adminUpdates,
                    //   //   onChanged: provider.toggleAdminUpdates,
                    //   // ),
                    // ]),

                    // Privacy & Safety Section
                    _sectionHeader('Privacy & Safety'),
                    _settingsCard([
                      // _settingsTile(
                      //   title: 'Who can message me',
                      //   onTap: provider.setWhoCanMessageMe,
                      // ),
                      _settingsTile(
                        title: 'Blocked Users',
                        onTap: () => provider.viewBlockedUsers(context),
                      ),
                      // _settingsTile(
                      //   title: 'Report an Issue',
                      //   onTap: provider.reportIssue,
                      // ),
                      // _settingsTile(
                      //   title: 'Data Consent Settings',
                      //   onTap: provider.dataConsentSettings,
                      // ),
                      _settingsTile(
                        title: 'Delete Account',
                        onTap: () {
                          provider.deleteAccount(context);
                        },
                        textColor: Colors.red,
                      ),
                    ]),

                    _sectionHeader('Tips & Contributions'),
                    _settingsCard([
                      _settingsTile(
                        title: 'My Tips ',
                        onTap: () => provider.viewMyTipsAndReviews(context),
                      ),
                      // _settingsTile(
                      //   title: 'My Event Submissions',
                      //   onTap: provider.viewMyEventSubmissions,
                      // ),
                      // _settingsTile(
                      //   title: 'Promote a Tip or Event',
                      //   onTap: provider.promoteEvent,
                      // ),
                    ]),

                    // Help & Support Section
                    _sectionHeader('Help & Support'),
                    _settingsCard([
                      _settingsTile(
                        title: 'FAQs',
                        onTap: () => provider.viewFAQs(context),
                      ),
                      _settingsTile(
                        title: 'Contact Support',
                        onTap: () => provider.contactSupport(context),
                      ),
                      // _settingsTile(
                      //   title: 'Give Feedback',
                      //   onTap: () => provider.giveFeedback(context),
                      // ),
                      // _settingsTile(
                      //   title: 'Terms of Use',
                      //   onTap: () => provider.viewTermsOfUse(context),
                      // ),
                      // _settingsTile(
                      //   title: 'Privacy Policy',
                      //   onTap: () => provider.viewPrivacyPolicy(context),
                      // ),
                    ]),

                    // const SizedBox(height: 24),
                    // // Log Out Button
                    // CustomButton(
                    //   text: 'Log Out',
                    //   onTap: () {
                    //     provider.logout(context);
                    //   },
                    // ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16, left: 4),
      child: Text(
        title,
        style: pjsStyleBlack18600.copyWith(color: AppColors.black),
      ),
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsTile({
    String? svgIcon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.garyModern200, width: 1.0),
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.white,
        ),
        child: Row(
          children: [
            if (svgIcon != null) ...[
              SvgPicture.asset(svgIcon),
              const SizedBox(width: 12),
            ],

            Expanded(
              child: Text(
                title,
                style: pjsStyleBlack14500.copyWith(
                  color: textColor ?? AppColors.black,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.darkGrey),
          ],
        ),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGrey, width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: pjsStyleBlack14500.copyWith(color: AppColors.black),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
