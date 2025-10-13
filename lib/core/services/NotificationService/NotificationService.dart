import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Model/userModel.dart';
import '../../../Provider/ChatProvider.dart';
import '../../../Provider/GroupChatProvider.dart';
import '../../../View/chat/GroupChat_Screen.dart';
import '../../../View/chat/chat-Screen.dart';
import '../../../View/chat/localGroupChatScreen.dart';

class NotificationService {
  NotificationService._privateConstructor();
  static NotificationService? _instance;

  static NotificationService get instance {
    _instance ??= NotificationService._privateConstructor();
    return _instance!;
  }

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Global navigation key for handling notifications
  static GlobalKey<NavigatorState>? navigatorKey;

  static String firebaseMessagingScope =
      "https://www.googleapis.com/auth/firebase.messaging";

  // Your Firebase service account credentials
  static Map<String, dynamic> serviceAccountKey = {
    "type": "service_account",
    "project_id": "global-connect-7c86b",
    "private_key_id": "f39d5365be9806b78028dffc96c3d50ca312b86e",
    "private_key":
        "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCuEGaza5kyr+gf\nDNS2/8Rsa/m6eJO+3OM2ZdqAm45K3CvdtbiLb4SixyTBrV8noM263qeKSYVWd9eu\nquepfqW29zCoretFfU9b/fYXXCYw/oFdyF7pmmHHwmAQm9jllu54DUTUJd7vsnt7\nIxkTuB38fkR0w/gsnvds+UeiLLsaO1KV7iGeLBUtwvISmIY6CssbH6SY0wjg2/s+\nIdPADtKPzInBnP0y2rmDjtqO2cEG0QBwiSx2dv9GGc3/EFGkX2ioH7jyC2zPfq67\n3Jxp6j9Q4Os0l1MtXhLwnOIthSgpnuvejkFMeSn6Oqb2pUQHR9UeWhzbfnPZnS77\nUTijMYIPAgMBAAECggEAS25HG0yvHISXelE0o0Mua2/VTmYvXKBbhHjaGi6PGMjV\n56P239IJcAMN3jKUEFfCn88aWrampkST/pkIgG6mQKZZe1e3I6t8pxhku1XPJR89\nj5cj7mbdJdSJjdkDwubH29WgNLFerZAyq7eXh/Cbag6L+u/rzeZrwdk7Hj/1KxXA\nIJlQ4zD8aIOKz5y7t76nsdK6H+T82rtQ859QCx7KC77IAWwksEIupK26m6oZeAat\nHfF2vYQfd0q7RtK82JD9BA+/hxDFktOkABkyfrOkpGZEiDcXEQ1Jtag6C39aI55o\nz6idFnS/5WKnP7pS2uvB/zoXTozuRZHTk4iYcIctdQKBgQDX7QA4lQihmvAjjMlX\n3CippZ4Z2Bx2GDBXI5F4lYNrKyAYWNpstzlbl0J64K9zDv15E+hFfqLAlevIMiZE\n3sGW06aZs3XLwb2s6iUz5hW6Eb5ukK3tggGZJJ4JqnLngho3+VDG4NmzlhH2+JDd\n8+ZmtikG9Vfi7sFX32ffxEPo1QKBgQDOXnq1O4ulpDGZR9H0VdSdZ7qcEUPecd1l\ncIOIRcEsyfXLy2XnnMe8TNM6f7SitPSF35rKA/oBHo2zSn3b1ST7k9hs7HS2qMKN\n9y9//PZqDRzc4KtB0dj10ejBW5K9hkiZNrDPJWteKRzedwFenU5gZ2y9SU5i/vfK\niAcKDUtxUwKBgAbunOs0HarShpMdmfkwID4SCxlZTtCbxjGF+s2cPzPZlpYxhBGp\ncDX4jTHUtM1E1e5lLTfN8Put1HwA4Cml3SEyek7E7Cs2dRhwC/G2mUv39d0m1+6g\nFd0Mx+YXisjT7HOPlYBNB7A0SS9cm4oEooj5oCeRCNlIQPzJN1R/wI5hAoGBAKTJ\ntNp7DevazPBE9VZSI1D9v3lYIAXEjrGtwppSeQq2yltNs7Xa73NhNVqFF0zFimxM\nPWILAttZ9nSwiwe7j6iESlHQDvK8l36dX4SoDmxoxB9sF9SbKNBCKcYcxXQpglc1\n4MHIc4/g7HiINsPCgQ9iBuavXrSWPG+xZ02TiCaZAoGAf1yoSdmUiJuYZXfOWJ3T\nYgq4U9EZkDrPuBDUU4pDe4b6nr5fh7plGgfebJ6dTwoXo9pG0YI1Sts6f9IaudiK\nxTKkIBQy6HhrSSEl1Qil55pFzWVBu+1ADz35qsExshhUgTkwfYsaZHyM7Kp2isNh\ndWafGD+eosJJBBL15FYqd3A=\n-----END PRIVATE KEY-----\n",
    "client_email":
        "firebase-adminsdk-fbsvc@global-connect-7c86b.iam.gserviceaccount.com",
    "client_id": "107800591528779259476",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url":
        "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40global-connect-7c86b.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com",
  };

  // Initialize notification service
  Future<void> initialize() async {
    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging();
  }

  // Set navigation key for handling notifications
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  // Get device FCM token
  Future<String> getDeviceToken() async {
    String? token;
    try {
      token = await _firebaseMessaging.getToken();
    } catch (e) {
      print("Error getting device token: $e");
    }
    return token ?? "";
  }

  // Request notification permissions
  Future<void> requestNotificationPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('Notification permission granted');

      // Get and save FCM token
      String? token = await getDeviceToken();
      if (token.isNotEmpty) {
        await _saveFCMToken(token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);
    } else {
      print('Notification permission denied');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  // Create notification channels for Android
  Future<void> _createNotificationChannel() async {
    final androidNotifications = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    
    if (androidNotifications == null) return;

    // Chat notifications channel
    const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
      'chat_channel',
      'Chat Messages',
      description: 'Notifications for chat messages',
      importance: Importance.high,
    );

    // Follow notifications channel
    const AndroidNotificationChannel followChannel = AndroidNotificationChannel(
      'follow_notifications',
      'Follow Notifications',
      description: 'Notifications when someone follows you',
      importance: Importance.high,
    );

    // Connection notifications channel
    const AndroidNotificationChannel connectionChannel = AndroidNotificationChannel(
      'connection_requests',
      'Connection Requests',
      description: 'Notifications for connection requests and updates',
      importance: Importance.high,
    );

    // Create all channels
    await androidNotifications.createNotificationChannel(chatChannel);
    await androidNotifications.createNotificationChannel(followChannel);
    await androidNotifications.createNotificationChannel(connectionChannel);

    print('Notification channels created: chat, follow, and connection');
  }

  // Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Request permissions
    await requestNotificationPermissions();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle notification opened app
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpenedApp);

    // Handle initial message when app is opened from terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpenedApp(initialMessage);
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'fcmToken': token,
              'lastTokenUpdate': FieldValue.serverTimestamp(),
            });
        print('FCM token saved successfully');
      } catch (e) {
        print('Error saving FCM token: $e');
      }
    }
  }

  // Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');
    if (message.data['type'] == 'Private') {
      final currentChatroomId = message.data['chatroomId'];
    }

    if (Platform.isAndroid) {
      await showNotification(message);
    } else {
      await showNotification(message);
    }
  }

  // Handle notification tapped
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _handleNotificationNavigation(data);
    }
  }

  // Handle notification opened app
  void _handleNotificationOpenedApp(RemoteMessage message) {
    print('Notification opened app: ${message.data}');
    _handleNotificationNavigation(message.data);
  }

  // Handle notification navigation
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    print('Handle notification navigation with data: $data');

    if (navigatorKey?.currentState == null) {
      print('Navigator key is null, cannot navigate');
      return;
    }

    try {
      // Handle Follow and Connection Notifications - Navigate to notification screen
      if (data['type'] == 'follow' || 
          data['type'] == 'connection_request' || 
          data['type'] == 'connection_accepted' ||
          data['screen'] == 'notification') {
        print('Navigating to notification screen for ${data['type']} notification');
        
        // Navigate to notification screen
        navigatorKey!.currentState!.pushNamedAndRemoveUntil(
          'notification_screen',
          (route) => route.isFirst,
        );
        return;
      }
      
      // Handle Private Chat Notification
      else if (data['type'] == 'Private') {
        final senderId = data['senderId'];
        final chatroomId = data['chatroomId'];

        FirebaseFirestore.instance
            .collection('users')
            .doc(senderId)
            .get()
            .then((userDoc) {
              if (userDoc.exists) {
                final userData = userDoc.data()!;

                // Helper function to convert Firestore Timestamp to DateTime
                DateTime? convertToDateTime(dynamic value) {
                  if (value == null) return null;
                  if (value is Timestamp) return value.toDate();
                  if (value is String) {
                    try {
                      return DateTime.parse(value);
                    } catch (e) {
                      return null;
                    }
                  }
                  return null;
                }

                // Create UserModel object for navigation
                final userModel = UserModel(
                  uid: senderId,
                  email: userData['email'] ?? '',
                  fullName: userData['fullName'] ?? 'Unknown User',
                  dateOfBirth: convertToDateTime(userData['dateOfBirth']),
                  nationality: userData['nationality'] ?? '',
                  homeCity: userData['homeCity'] ?? '',
                  createdAt:
                      convertToDateTime(userData['createdAt']) ??
                      DateTime.now(),
                );

                navigatorKey!.currentState!.push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider(
                      create: (context) => ChatController(),
                      child: ChatScreen(
                        user: userModel,
                        type: 'Private',
                        chatroomId: chatroomId,
                      ),
                    ),
                  ),
                );
              }
            })
            .catchError((error) {
              print('Error getting user details: $error');
            });
      }
      // Handle Group Chat Notification
      else if (data['type'] == 'group_chat_message') {
        final groupChatRoomId = data['groupChatRoomId'];
        final groupName = data['groupName'] ?? 'Group Chat';

        print('Navigating to group chat: $groupName with ID: $groupChatRoomId');

        // Navigate to GroupChatScreen using MaterialPageRoute
        navigatorKey!.currentState!.push(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => GroupChatProvider(),
              child: GroupChatScreen(
                groupName: groupName,
                groupChatRoomId: groupChatRoomId,
              ),
            ),
          ),
        );
      }
      // Handle Local Group Chat Notification
      else if (data['type'] == 'local_group_chat_message') {
        final cityName =
            data['groupName'] ??
            'Local Group'; // groupName is actually cityName

        print('Navigating to local group chat: $cityName');

        // Navigate to LocalGroupChatScreen using MaterialPageRoute
        navigatorKey!.currentState!.push(
          MaterialPageRoute(
            builder: (_) => LocalGroupChatScreen(cityName: cityName),
          ),
        );
      }
    } catch (e) {
      print('Error navigating to chat: $e');
    }
  }

  // Show local notification
  Future<void> showNotification(RemoteMessage message) async {
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chat_channel',
      'Chat Messages',
      description: 'Notifications for chat messages',
      importance: Importance.high,
    );

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      Random().nextInt(100000),
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? 'You have a new message',
      details,
      payload: jsonEncode(message.data),
    );
  }

  // Test notification method
  Future<void> testLocalNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'chat_channel',
          'Chat Messages',
          channelDescription: 'Notifications for chat messages',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      Random().nextInt(100000),
      'Test Notification',
      'This is a test notification',
      details,
    );

    print('Test local notification sent');
  }

  // Get access token using service account
  Future<String> getAccessToken() async {
    try {
      final client = await clientViaServiceAccount(
        ServiceAccountCredentials.fromJson(serviceAccountKey),
        [firebaseMessagingScope],
      );
      final accessToken = client.credentials.accessToken.data;
      client.close();
      return accessToken;
    } catch (e) {
      print('Error getting access token: $e');
      return '';
    }
  }

  // Send notification to specific user
  Future<bool> sendNotificationToUser({
    required String receiverToken,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    if (receiverToken.isEmpty) {
      print('Receiver token is empty');
      return false;
    }

    print(
      'Sending notification to token: ${receiverToken.substring(0, 20)}...',
    );
    print('Title: $title');
    print('Body: $body');
    print('Data: $data');

    try {
      String accessToken = await getAccessToken();
      if (accessToken.isEmpty) {
        print('Failed to get access token');
        return false;
      }

      String projectId = serviceAccountKey['project_id'];

      var requestData = {
        'message': {
          'token': receiverToken,
          'notification': {'title': title, 'body': body},
          'data': data.map((key, value) => MapEntry(key, value.toString())),
          'android': {
            'notification': {
              'channel_id': 'chat_channel',
              'icon': '@mipmap/ic_launcher',
              'color': '#FF6B6B',
            },
            'priority': 'high',
          },
          'apns': {
            'payload': {
              'aps': {
                'alert': {'title': title, 'body': body},
                'sound': 'default',
                'badge': 1,
                'category': 'Private',
              },
            },
            'headers': {'apns-priority': '10'},
          },
        },
      };

      var request = http.Request(
        'POST',
        Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
        ),
      );

      request.body = json.encode(requestData);
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      });

      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print('Notification sent successfully');
        return true;
      } else {
        print('Failed to send notification: ${response.statusCode}');
        print('Response: $responseBody');
        return false;
      }
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  // Get user's FCM token from Firestore
  Future<String?> getUserFCMToken(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc.data()?['fcmToken'];
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
    return null;
  }

  Future<void> sendBulkNotification({
    required List<String> tokens,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    for (String token in tokens) {
      await sendNotificationToUser(
        receiverToken: token,
        title: title,
        body: body,
        data: data,
      );
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> markNotificationAsRead(String chatroomId) async {
    print('Marking notification as read for chatroom: $chatroomId');
  }
}

Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  if (message.data['type'] == 'Private') {
    print('Background chat message received: ${message.data}');
  }
}
