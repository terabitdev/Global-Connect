// import 'package:device_preview/device_preview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'Provider/EventsProvider.dart';
import 'Provider/LocationProvider.dart';
import 'Provider/PostProvider.dart';
import 'Provider/SelectionProvider.dart';
import 'Provider/UserTipsProvider.dart';
import 'Provider/user_profile_provider.dart';
import 'Provider/UserPostsProvider.dart';
import 'Provider/localChatProvider.dart';
import 'Provider/ChatProvider.dart';
import 'Provider/PrivateChatProvider.dart';
import 'Provider/AddMemoryProvider.dart';
import 'Provider/CountryProvider.dart';
import 'Provider/SharedPostProvider.dart';
// import 'Provider/MemoryProvider.dart';
import 'Provider/PostCardProvider.dart';
import 'Provider/PostInteractionProvider.dart';
import 'Provider/NetworkProvider.dart';
import 'Provider/UserStatusProvider.dart';
import 'core/services/NotificationService/NotificationService.dart';
import 'Widgets/LocalChatAutoInitializer.dart';
import 'Widgets/ChatDataInitializer.dart';
import 'Widgets/NetworkStatusWidget.dart';
import 'Widgets/UserStatusInitializer.dart';
import 'core/utils/routes/routes.dart';
import 'core/utils/routes/routes_names.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.initialize();
  // Initialize network monitoring
  await NetworkProvider().initialize();

  runApp(MyApp());
  // runApp(
  //   DevicePreview(
  //     enabled: !kReleaseMode,
  //     builder: (context) => const MyApp(),
  //   ),
  // );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late String _initialRoute;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    final User? currentUser = FirebaseAuth.instance.currentUser;
    _initialRoute = currentUser != null
        ? RoutesName.homeMainScreen
        : RoutesName.splashScreen;
    NotificationService.setNavigatorKey(_navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserStatusProvider()),
        ChangeNotifierProvider(create: (_) => PostInteractionProvider()),
        ChangeNotifierProvider(create: (context) => PostCardProvider(context.read<PostInteractionProvider>()),
        ),
        ChangeNotifierProvider(create: (_) => EventsProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => SelectionProvider()),
        ChangeNotifierProvider(create: (context) => LocationProvider()),
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
        ChangeNotifierProvider(create: (context) => UserProfileProvider()),
        ChangeNotifierProvider(create: (context) => UserPostsProvider()),
        ChangeNotifierProvider(create: (context) => UserTipsProvider()),
        ChangeNotifierProvider(create: (context) => LocalChatProvider()),
        ChangeNotifierProvider.value(value: ChatController.instance),
        ChangeNotifierProvider.value(value: PrivateChatProvider.instance),
        ChangeNotifierProvider(create: (context) => AddMemoryProvider()),
        ChangeNotifierProvider(create: (context) => CountryProvider()),
        ChangeNotifierProvider(create: (context) => SharedPostProvider()),
        ChangeNotifierProvider.value(value: NetworkProvider()),

      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Global Connect',
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        initialRoute: _initialRoute,
        onGenerateRoute: Routes.generateRoute,
        builder: (context, child) {
          return UserStatusInitializer(
            child: NetworkStatusWidget(
              child: ChatDataInitializer(
                child: LocalChatAutoInitializer(child: child!),
              ),
            ),
          );
        },
      ),
    );
  }
}