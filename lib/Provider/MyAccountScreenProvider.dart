
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/const/firebase_Collection_Names.dart';
import '../core/services/firebase_services.dart';
import '../core/utils/components/LogoutDialog.dart';
import '../core/utils/routes/routes.dart';
import 'package:url_launcher/url_launcher.dart';

class MyAccountScreenProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserAccountService _userAccountService = UserAccountService();
  String userName = 'Jenny Wilson';
  String userEmail = 'wilson@gmail.com';
  String? profileImagePath;

  // Notification Settings
  bool pushNotifications = true;
  bool pauseLocationUpdates = false;
  bool newTravelers = true;
  bool newMessages = true;
  bool newEventsOrTips = true;
  bool chatActivity = true;
  bool adminUpdates = true;
  bool _isDeleting = false;

  bool get isDeleting => _isDeleting;

  // Location & Visibility Settings
  String? hometown;
  String? visibility;
  String? discoveryRadius;
  String? defaultMode;

  // Privacy & Safety Settings
  String? whoCanMessageMe;
  List<String> blockedUsers = [];

  // Methods for Account & Profile
  void updateUserName(String name) {
    userName = name;
    notifyListeners();
  }

  void updateUserEmail(String email) {
    userEmail = email;
    notifyListeners();
  }

  void updateProfileImage(String? imagePath) {
    profileImagePath = imagePath;
    notifyListeners();
  }

  void changeEmail() {
    // Handle change email logic
    print('Change Email tapped');
  }

  void changePassword() {
    // Handle change password logic
    print('Change Password tapped');
  }

  void setPersonalData(BuildContext context) {
    Navigator.pushNamed(context, RoutesName.personalDataScreen);
  }
  void setCountryIVisited(BuildContext context) {
    Navigator.pushNamed(context, RoutesName.countriesIVisitedScreen);
  }
  // Methods for Location & Visibility
  void pauseVisibility() {
    print('Pause My Visibility tapped');
  }

  void setDiscoveryRadius(BuildContext context) {
    Navigator.pushNamed(context, RoutesName.discoveryRadiusScreen);
  }

  void setDefaultMode() {
    print('Default Mode tapped');
  }


  void togglePauseLocationUpdates(bool value) {
    pauseLocationUpdates = value;
    notifyListeners();
  }
  void togglePushNotifications(bool value) {
    pushNotifications = value;
    notifyListeners();
  }

  void toggleNewTravelers(bool value) {
    newTravelers = value;
    notifyListeners();
  }

  void toggleNewMessages(bool value) {
    newMessages = value;
    notifyListeners();
  }

  void toggleNewEventsOrTips(bool value) {
    newEventsOrTips = value;
    notifyListeners();
  }

  void toggleChatActivity(bool value) {
    chatActivity = value;
    notifyListeners();
  }

  void toggleAdminUpdates(bool value) {
    adminUpdates = value;
    notifyListeners();
  }

  // Methods for Privacy & Safety
  void setWhoCanMessageMe() {
    print('Who can message me tapped');
  }

  void viewBlockedUsers(BuildContext context) {
    Navigator.pushNamed(context, RoutesName.allBlockedUseScreen);
    print('Blocked Users tapped');
  }

  void reportIssue() {
    print('Report an Issue tapped');
  }

  void dataConsentSettings() {
    print('Data Consent Settings tapped');
  }

  Future<void> deleteAccount(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteAccountDialog(
        onConfirm: () async {
          await _userAccountService.deleteUserAccount();

        },
      ),
    );
  }



  // Methods for Tips & Contributions
  void viewMyTipsAndReviews(BuildContext context) {
    Navigator.pushNamed(context, RoutesName.myTipsScreen);

    print('My Tips & Reviews tapped');
  }

  void viewMyEventSubmissions() {
    print('My Event Submissions tapped');
  }

  void promoteEvent() {
    print('Promote a Tip or Event tapped');
  }

  // Methods for Help & Support
  void viewFAQs(BuildContext context) {
    Navigator.pushNamed(context, RoutesName.faqScreen);

    print('FAQs tapped');
  }

  void contactSupport(BuildContext context) {
    Navigator.pushNamed(context, RoutesName.contactSupport);
  }

  void giveFeedback(BuildContext context) {
    Navigator.pushNamed(context, RoutesName.feedBackScreen);

    print('Give Feedback tapped');
  }

  void viewTermsOfUse(BuildContext context) {
    Navigator.pushNamed(context, RoutesName.termsOfUseScreen);
  }

  void viewPrivacyPolicy(BuildContext context) {
    Navigator.pushNamed(context, RoutesName.privacyPolicyScreen);
  }

  void logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return LogoutDialog(
          onLogout: () async {
            try {
              final uid = _auth.currentUser?.uid;

              // ✅ Sign out + token delete
              if (uid != null) {
                await usersCollection.doc(uid).update({
                  'fcmToken': FieldValue.delete(),
                });
              }
              await _auth.signOut();
              Navigator.of(dialogContext).pop();
              Navigator.of(context, rootNavigator: true)
                  .pushReplacementNamed(RoutesName.loginScreen);

            } catch (e) {
              print("❌ Logout failed: $e");
            }
          },
        );
      },
    );
  }

  // Social Media URLs
  final String websiteUrl = 'https://www.global-connect.ai/';
  final String instagramUrl = 'https://www.instagram.com/globalconnectai/';
  final String tiktokUrl = 'https://www.tiktok.com/@globalconnectai';

  Future<void> launchWebsite() async {
    final Uri url = Uri.parse(websiteUrl);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> launchInstagram() async {
    final Uri url = Uri.parse(instagramUrl);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> launchTikTok() async {
    final Uri url = Uri.parse(tiktokUrl);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}


