import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:global_connect/core/const/responsive_layout.dart';

import '../../Widgets/CustomAppBar.dart';
import '../../Widgets/buildPolicySection.dart';
import '../../core/const/app_color.dart';
import '../../core/theme/app_text_style.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar2(
        title: Text(
          'Privacy Policy',
          style: pjsStyleBlack18600.copyWith(color: AppColors.black),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.screenWidth * 0.05,
          vertical: context.screenHeight * 0.02,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Effective Date: June 17, 2025', style: pjsStyleBlack18600),
              SizedBox(height: context.screenHeight * 0.03),

              buildPolicySection(
                context,
                'Processing of Personal Data by Global Connect',
                'Global Connect recognizes the importance of processing data about you as an individual, such as your name, address or e-mail address (“Personal Data”). This Privacy Notice sets out how Global Connect AS with registration number 935687519, may use, process and store Personal Data. The controller for the personal data we process is Global Connect AS by CEO Leander Harestad.',
              ),

              buildPolicySection(
                context,
                'Scope',
                'If you visit our webpage and/or communicate with us by receiving newsletters or in relation to recruitment, Global Connect may collect and store Personal Data. As Global Connect is committed to protecting and respecting your privacy, this Privacy Notice sets out what Personal Data we collect and store, why this is done, and your rights regarding Personal Data that we hold. In general, you can visit www.global-connect.ai without revealing any Personal Data. We track the Internet address of visitors who visit www.global-connect.ai and analyze this data for trends and statistics. If you do not provide the information we request, you can still visit most of our website, but you may be unable to access certain options.',
              ),

              buildPolicySection(
                context,
                'Why we collect Personal Data, and what information we collect',
                '',
                bulletPoints: [
                  'For recruiting purposes, we may collect and store your CV, application, certificates and references. Use of this personal information is based on your consent.',
                  'To obtain information regarding your use of our website, we use cookies. Our processing of Personal Data is based on a balancing of interests, and we have concluded that collection and use of cookies is necessary to improve our website and to provide you with more tailored information when you return to the website. You may set your browser to tell you when you receive a cookie, and to refuse to receive it.',
                  'We collect your name, email address, and password when you create an account and interact with our service. This data is essential for setting up and managing your user account, as well as for secure login and communication regarding your account.',
                  'We collect your username, profile picture, bio, and interests as provided by you. This information helps to personalize your experience within the app, allows other users to identify you, and enables us to tailor content and recommendations.',
                  'We collect your precise location information (geolocation data) directly from your device. This data is gathered when the app is open and, if you grant permission, potentially when it\'s running in the background. We use this to show you nearby travelers, local tips, and events. We also analyze app usage patterns based on location to improve our services and to enable us and our trusted partners to provide you with more relevant offers and experiences. You can control location access through your device settings, though disabling it may affect certain app features.',
                  'We collect data on how you use the app. This includes information such as which features you interact with, how long you use the app, what you search for, and which events or tips you click on or like. This helps us understand user behavior, improve app functionality, and enhance your overall experience.',
                  'We collect the content of your communications within our chat features, specifically in local chats. This is done to facilitate your interactions with other users and to maintain a safe and compliant community environment within the app.',
                  'We collect information about the device you use to access our service, including your device type, operating system, and IP address. This data helps us ensure the app functions correctly on various devices, troubleshoot technical issues, and enhance the security of our service.',
                  'We collect data on who you follow, who you are friends with, and how you interact with other users within the app. This information is used to facilitate social connections, personalize your feed, and improve the social networking aspects of our service.',
                  'We collect and store information about the countries you add to your "Countries Visited" feature. This data is used to personalize your profile, track your travel history within the app, and allow other users to see your travel experiences.',
                ],
              ),

              buildPolicySection(
                context,
                'Sharing personal data with third parties',
                'Global Connect does not share Personal Data with third parties unless you have consented to allow us to do so, or for legal reasons. Global Connect does not transfer Personal Data to countries outside the EU/EEA unless there is legal basis and only when sufficient mechanisms for cross-border transfers are in place. To operate our Service effectively, we engage various third-party service providers who assist us with functions such as hosting, communication, analytics, and infrastructure. These providers act as data processors on our behalf or may process data for their own purposes as independent controllers. We ensure that all our service providers are compliant with GDPR and have appropriate data processing agreements (DPAs) in place where required.',
                bulletPoints: [
                  'Google Analytics (Analytics & Usage Tracking): We use Google Analytics to understand how users interact with our website and app. This service collects data such as your IP address (often anonymized), device information, and usage patterns within the Service to help us analyze traffic, improve user experience, and optimize our offerings.',
                  'Google Cloud Platform / Firebase (Backend Hosting & Services): We may utilize Google Cloud Platform (GCP) and/or Firebase to host our application\'s backend, databases, and various cloud services. This means your data, including identification data, profile data, usage data, is processed and stored on Google\'s secure cloud infrastructure.',
                  'Google Workspace (Internal Operations & Communication): We use Google Workspace (including Gmail, Google Drive, and Google Docs) for our internal communication, document management, and collaboration. This may involve processing certain personal data related to your interactions with us or for our operational purposes.',
                  'Google Maps API (Mapping Services): Our app integrates Google Maps API to provide location-based functionalities, such as displaying nearby travelers, events, and tips on a map. When you use map features, certain data like your IP address and location (if enabled) may be sent to Google. Please refer to Google\'s own privacy policy for more details on their data practices related to Google Maps.',
                  'Google Ads (Advertising & Marketing): If and when we run advertising campaigns, we may use Google Ads to measure the effectiveness of our advertisements and to reach potential users. This involves collecting data related to ad impressions and clicks, which may be linked to your anonymous user ID.',
                ],
              ),

              buildPolicySection(
                context,
                'Storing of personal data',
                'If you do not request us to stop using Personal Data, we retain Personal Data for as long as required by law. Personal Data that we have collected based on your consent is deleted if you withdraw your consent. Personal Data used to perform an agreement with you is deleted as soon as all obligations of the agreement is carried out.',
              ),

              buildPolicySection(
                context,
                'Your rights',
                'In connection with our collection, storage and use of Personal Data, you have the right to request access, rectification or erasure. Further, you have the right to restrict our processing, to object to our processing and to port Personal Data elsewhere. To exercise your rights, please contact us at email: hello@global-connect.ai . We will respond to your inquiry as soon as possible, and at the latest within 30 days. If you wish to exercise your rights, we will require that you confirm your identity by providing additional information. We do this to ensure that third parties are not given access to Personal Data.',
              ),

              buildPolicySection(
                context,
                'Complaints',
                'If you believe that our collection, storage and use of Personal Data does not comply with our privacy notice or does not comply with privacy law, you may complain to the local data protection authority here: https://www.datatilsynet.no/',
              ),

              buildPolicySection(
                context,
                'Changes to our Privacy Notice',
                'Global Connect may change this notice from time to time in the future. Any such changes will be posted here and, where appropriate, notified to you in writing. We advise you to check back frequently to see any updates or changes.',
              ),

              SizedBox(height: context.screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
