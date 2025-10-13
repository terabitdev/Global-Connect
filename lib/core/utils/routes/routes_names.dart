import 'package:flutter/material.dart';
import 'package:global_connect/core/utils/routes/routes.dart';
import 'package:provider/provider.dart';
import '../../../Model/userModel.dart';
import '../../../Provider/AddCountriesProvider.dart';
import '../../../Provider/AddMemoryProvider.dart';
import '../../../Provider/ChatProvider.dart';
import '../../../Provider/CreateLocalEventProvider.dart' show CreateLocalEventProvider;
import '../../../Provider/FaqProvider.dart';
import '../../../Provider/GroupChatProvider.dart';
import '../../../Provider/GroupSettingsProvider.dart';
import '../../../Provider/LoginProvider.dart';
import '../../../Provider/MemoryProvider.dart';
import '../../../Provider/MyAccountScreenProvider.dart';
import '../../../Provider/OnboardingProvider.dart';
import '../../../Provider/PostProvider.dart';
import '../../../Provider/PrivateChatProvider.dart';
import '../../../Provider/SelectionProvider.dart';
import '../../../Provider/ShareTipsScreenProvider.dart';
import '../../../Provider/SignupProvider.dart';
import '../../../Provider/UserDetailProvider.dart';
import '../../../Provider/UserTipsProvider.dart';
import '../../../Provider/VisitedCountriesProvider.dart';
import '../../../Provider/notificationScreenProvider.dart';
import '../../../Provider/privateChatSettingProvider.dart';
import '../../../Provider/user_profile_provider.dart';
import '../../../Provider/PostInteractionProvider.dart';
import '../../../Provider/PostCardProvider.dart';
import '../../../Provider/UserPostsProvider.dart';
import '../../../View/AddMemory/addMemoryScreen.dart';
import '../../../View/AddMemory/travelMemory_screen.dart';
import '../../../View/FestivalsEvents.dart';
import '../../../View/MyAccountScreen/DiscoveryRadiusScreen.dart';
import '../../../View/MyAccountScreen/MyAccountScreen.dart';
import '../../../View/MyAccountScreen/PersonalData_Screen.dart';
import '../../../View/MyAccountScreen/addCountriesScreen.dart';
import '../../../View/MyAccountScreen/allBlockedUseScreen.dart';
import '../../../View/MyAccountScreen/contactSupport.dart';
import '../../../View/MyAccountScreen/countriesIVisitedScreen.dart';
import '../../../View/MyAccountScreen/faqScreen.dart';
import '../../../View/MyAccountScreen/feedBackScreen.dart';
import '../../../View/MyAccountScreen/myTipsScreen.dart';
import '../../../View/MyAccountScreen/privacyPolicyScreen.dart';
import '../../../View/MyAccountScreen/profile_Screen.dart';
import '../../../View/MyAccountScreen/termsOfUseScreen.dart';
import '../../../View/NotificationScreen/notification_Screen.dart';
import '../../../View/PrivateChat/PrivateChatScreen.dart';
import '../../../View/PrivateChat/createGroupChatScreen.dart';
import '../../../View/RestaurantsDetailScreen.dart';
import '../../../View/chat/localChatMembers.dart';
import '../../../View/chat/new_Chat_Screen.dart';
import '../../../View/chat/requestChatScreen.dart';
import '../../../View/post/editPostScreen.dart';
import '../../../View/tips/UserTips_Screen.dart';
import '../../../View/auth/CompleteYourInformation.dart';
import '../../../View/auth/ForgotPassword_Screen.dart';
import '../../../View/auth/Login_Screen.dart';
import '../../../View/auth/onboarding_Screen.dart';
import '../../../View/auth/signUp_screen.dart';
import '../../../View/auth/splash_screen.dart';
import '../../../View/chat/AddEvent/CreateLocalEvent.dart';
import '../../../View/chat/GroupChat_Screen.dart';
import '../../../View/chat/addEventScreen.dart';
import '../../../View/chat/chat-Screen.dart';
import '../../../View/chat/groupChatSetting-Screen.dart';
import '../../../View/chat/inviteMembersScreen.dart';
import '../../../View/chat/localGroupChatScreen.dart';
import '../../../View/chat/localGroupScreen.dart';
import '../../../View/chat/privateChatSettingScreen.dart';
import '../../../View/home_main-screen.dart';
import '../../../View/home_screen.dart';
import '../../../View/post/addPostScreen.dart';
import '../../../View/post/allPostScreen.dart';
import '../../../View/shareTips_Screen.dart';
import '../../../View/tips/tip_Review_Screen.dart';
import '../../../View/user_Detail_screen.dart';
import '../../../WorldMap/WorldMapScreen.dart';

class Routes {
  static MaterialPageRoute generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutesName.loginScreen:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => LoginProvider(),
            child: const LoginScreen(),
          ),
        );

      case RoutesName.splashScreen:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case RoutesName.onboardingScreen:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => OnboardingProvider(),
            child: const OnboardingScreen(),
          ),
        );
      case RoutesName.signupScreen:
        return MaterialPageRoute(builder: (_) => const SignupScreen());

      case RoutesName.forgotPasswordScreen:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());


      case RoutesName.homeScreen:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case RoutesName.homeMainScreen:
        return MaterialPageRoute(builder: (_) => const HomeMainScreen());

      case RoutesName.userTipsScreen:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => UserTipsProvider(),
            child: const UserTipsScreen(),
          ),
        );

      case RoutesName.festivalsEvents:
        return MaterialPageRoute(builder: (_) => const FestivalsEvents());

      case RoutesName.userDetailScreen:
        final arguments = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (context) => VisitedCountriesProvider(),
              ),
              ChangeNotifierProvider(
                create: (context) => UserDetailProvider(),
              ),
              ChangeNotifierProvider(
                create: (context) => MemoryProvider(),
              ),


            ],
            child: UserDetailScreen(
              user: arguments['user'],
            ),
          ),
        );



      case RoutesName.shareTipsScreen:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (context) => ShareTipsScreenProvider(),
            child: const ShareTipsScreen(),
          ),
        );
      case RoutesName.myAccountScreen:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (context) => MyAccountScreenProvider(),
            child: const MyAccountScreen(),
          ),
        );

      case RoutesName.privateChatScreen:
        return MaterialPageRoute(builder: (_) => const PrivateChatScreen());

      case RoutesName.createGroupChatScreen:
        return MaterialPageRoute(builder: (_) => const CreateGroupChatScreen());

      case RoutesName.contactSupport:
        return MaterialPageRoute(builder: (_) => const ContactSupport());

      case RoutesName.privacyPolicyScreen:
        return MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen());
      case RoutesName.termsOfUseScreen:
        return MaterialPageRoute(builder: (_) => const TermsOfUseScreen());

      case RoutesName.feedBackScreen:
        return MaterialPageRoute(builder: (_) => const FeedBackScreen());
      case RoutesName.faqScreen:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (context) => FaqProvider(),
            child: const FaqScreen(),
          ),
        );

      case RoutesName.personalDataScreen:
        return MaterialPageRoute(
          builder: (_) => MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => SignupProvider()),
              ChangeNotifierProvider(create: (_) => UserProfileProvider()),
            ],
            child: const PersonalDataScreen(),
          ),
        );

      case RoutesName.profileScreen:
        return MaterialPageRoute(
          builder: (_) => MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (context) => UserProfileProvider()),
              ChangeNotifierProvider(create: (context) => VisitedCountriesProvider()),
              ChangeNotifierProvider(create: (context) => SelectionProvider()),
              ChangeNotifierProvider(create: (context) => MemoryProvider()),
              ChangeNotifierProvider(create: (context) => UserPostsProvider()),
              ChangeNotifierProvider(create: (context) => PostInteractionProvider()),
              ChangeNotifierProvider(create: (context) => PostCardProvider(context.read<PostInteractionProvider>())),
            ],
            child: const ProfileScreen(),
          ),
        );


      case RoutesName.chatScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final user = args['user'] as UserModel? ?? args['user'] as Map<String, dynamic>?;
        final type = args['type'] as String;
        final chatroomId = args['chatroomId'] as String?;

        // Handle both UserModel and Map<String, dynamic> for notification navigation
        UserModel userModel;
        if (user is UserModel) {
          userModel = user;
        } else if (user is Map<String, dynamic>) {
          userModel = UserModel(
            uid: user['uid'] ?? '',
            fullName: user['fullName'] ?? 'Unknown User',
            email: user['email'] ?? '',
            nationality: user['nationality'] ?? '',
            homeCity: user['homeCity'] ?? '',
            createdAt: DateTime.now(),
            profileImageUrl: user['profileImageUrl'] ?? '',
          );
        } else {
          // Fallback for invalid user data
          userModel = UserModel(
            uid: '',
            fullName: 'Unknown User',
            email: '',
            nationality: '',
            homeCity: '',
            createdAt: DateTime.now(),
            profileImageUrl: '',
          );
        }

        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (context) => ChatController(),
            child: ChatScreen(
              user: userModel,
              type: type,
              chatroomId: chatroomId,
            ),
          ),
        );

      case RoutesName.groupChatScreen:
        final Map<String, dynamic> args = settings.arguments as Map<String, dynamic>;
        final groupName = args['groupName'] ?? 'Group Chat';
        final groupChatRoomId = args['groupChatRoomId'];

        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => GroupChatProvider(),
            child: GroupChatScreen(
              groupName: groupName,
              groupChatRoomId: groupChatRoomId,
            ),
          ),
        );


      case RoutesName.groupChatSettingScreen:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => GroupSettingsProvider()),
              ChangeNotifierProvider(create: (_) => GroupChatProvider()),

            ],
            child: GroupChatSettingScreen(
              groupChatRoomId: args['groupChatRoomId'],
              groupName: args['groupName'],
            ),
          ),
        );


      case RoutesName.addEventScreen:
        return MaterialPageRoute(builder: (_) => const AddEventScreen());
      case RoutesName.inviteMemberScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final groupChatroomId = args['groupChatroomId'] as String;

        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => PrivateChatProvider(),
            child: InviteMemberScreen(groupChatroomId: groupChatroomId),
          ),
        );

      case RoutesName.countriesIVisitedScreen:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (context) => VisitedCountriesProvider(),
            child: const CountriesIVisitedScreen(),
          ),
        );

      case RoutesName.worldMapScreen:
        return MaterialPageRoute(builder: (_) => WorldMapScreen());

      case RoutesName.restaurantsDetailScreen:
        return MaterialPageRoute(
          builder: (_) => RestaurantsDetailScreen(),
          settings: settings,
        );

      case RoutesName.privateChatSettingScreen:
        final UserModel user = settings.arguments as UserModel;
        return MaterialPageRoute(
          builder: (_) => MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => PrivateChatSettingProvider()),
              ChangeNotifierProvider(create: (_) => GroupSettingsProvider()),
            ],
            child: PrivateChatSettingScreen(user: user),
          ),
        );

      case RoutesName.localGroupScreen:
        return MaterialPageRoute(builder: (_) => const LocalGroupScreen());

      case RoutesName.localGroupChatScreen:
        final cityName = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => LocalGroupChatScreen(cityName: cityName),
        );
      case RoutesName.discoveryRadiusScreen:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (context) => PrivateChatProvider(),
            child: const DiscoveryRadiusScreen(),
          ),
        );

      case RoutesName.allBlockedUseScreen:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (context) => PrivateChatSettingProvider(),
            child: const AllBlockedUseScreen(),
          ),
        );

      case RoutesName.notificationScreen:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => NotificationScreenProvider(),
            child: const NotificationScreen(),
          ),
        );

      case RoutesName.myTipsScreen:
        return MaterialPageRoute(builder: (_) => const MyTipsScreen());

      case RoutesName.createLocalEvent:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => SignupProvider()),
              ChangeNotifierProvider(create: (_) => CreateLocalEventProvider()),
            ],
            child: CreateLocalEvent(
              cityName: args['cityName'],
              eventName: args['eventName'],
            ),
          ),
        );

      case RoutesName.completeYourInformation:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => SignupProvider(),
            child: const CompleteYourInformation(),
          ),
        );

      case RoutesName.allPostScreen:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => PostProvider(),
            child: const AllPostScreen(),
          ),
        );
      case RoutesName.addPostScreen:
        return MaterialPageRoute(builder: (_) => const AddPostScreen());


      case RoutesName.addMemoryScreen:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => AddMemoryProvider(),
            child: const AddMemoryScreen(),
          ),
        );

      case RoutesName.tipReviewScreen:
        return MaterialPageRoute(builder: (_) => const TipReviewScreen());

      case RoutesName.addCountriesScreen:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => AddCountriesProvider(),
            child: const AddCountriesScreen(),
          ),
        );

      case RoutesName.travelMemoryScreen:
        return MaterialPageRoute(
          builder: (_) => const TravelMemoryScreen(),
          settings: settings,
        );
      case RoutesName.editPostScreen:
        return MaterialPageRoute(builder: (_) => const EditPostScreen());

      case RoutesName.newChatScreen:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => PrivateChatProvider(),
            child: const NewChatScreen(),
          ),
        );

      case RoutesName.requestChatScreen:
        return MaterialPageRoute(builder: (_) => const RequestChatScreen());
      case RoutesName.localChatMembers:
        return MaterialPageRoute(builder: (_) => const LocalChatMembers());


      default:
        return MaterialPageRoute(
          builder: (_) {
            return Scaffold(
              body: Center(
                child: Text('No route defined for ${settings.name}'),
              ),
            );
          },
        );
    }
  }
}
