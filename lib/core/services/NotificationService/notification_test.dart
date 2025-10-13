import 'package:flutter/material.dart';
import 'NotificationService.dart';

/// Test class to demonstrate notification functionality
class NotificationTest {
  static final NotificationService _notificationService = NotificationService.instance;

  /// Test sending a notification to a specific user
  static Future<void> testSendNotification({
    required String receiverToken,
    required String senderName,
    required String message,
    required String chatroomId,
    required String senderId,
    required String receiverId,
  }) async {
    try {
      final success = await _notificationService.sendNotificationToUser(
        receiverToken: receiverToken,
        title: senderName,
        body: message,
        data: {
          'type': 'chat_message',
          'chatroomId': chatroomId,
          'senderId': senderId,
          'receiverId': receiverId,
          'message': message,
        },
      );

      if (success) {
        print('✅ Test notification sent successfully');
      } else {
        print('❌ Test notification failed to send');
      }
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }

  /// Test sending a group chat notification
  static Future<void> testGroupChatNotification({
    required String receiverToken,
    required String groupName,
    required String senderName,
    required String message,
    required String groupChatRoomId,
    required String senderId,
  }) async {
    try {
      final success = await _notificationService.sendNotificationToUser(
        receiverToken: receiverToken,
        title: groupName,
        body: '$groupName: $senderName: $message',
        data: {
          'type': 'group_chat_message',
          'groupChatRoomId': groupChatRoomId,
          'groupName': groupName,
          'senderId': senderId,
          'senderName': senderName,
          'message': message,
        },
      );

      if (success) {
        print('✅ Test group chat notification sent successfully');
      } else {
        print('❌ Test group chat notification failed to send');
      }
    } catch (e) {
      print('❌ Error sending test group chat notification: $e');
    }
  }

  /// Test getting user's FCM token
  static Future<void> testGetUserToken(String userId) async {
    try {
      final token = await _notificationService.getUserFCMToken(userId);
      if (token != null && token.isNotEmpty) {
        print('✅ User FCM token: $token');
      } else {
        print('❌ No FCM token found for user: $userId');
      }
    } catch (e) {
      print('❌ Error getting user token: $e');
    }
  }

  /// Test getting device token
  static Future<void> testGetDeviceToken() async {
    try {
      final token = await _notificationService.getDeviceToken();
      if (token.isNotEmpty) {
        print('✅ Device FCM token: $token');
      } else {
        print('❌ No device FCM token found');
      }
    } catch (e) {
      print('❌ Error getting device token: $e');
    }
  }

  /// Test local notification
  static Future<void> testLocalNotification() async {
    try {
      await _notificationService.testLocalNotification();
      print('✅ Local notification test sent');
    } catch (e) {
      print('❌ Error sending local notification: $e');
    }
  }

  /// Test bulk notification sending
  static Future<void> testBulkNotification({
    required List<String> tokens,
    required String title,
    required String body,
  }) async {
    try {
      await _notificationService.sendBulkNotification(
        tokens: tokens,
        title: title,
        body: body,
        data: {
          'type': 'bulk_notification',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      print('✅ Bulk notification sent to ${tokens.length} users');
    } catch (e) {
      print('❌ Error sending bulk notification: $e');
    }
  }

  /// Test local group chat notification
  static Future<void> testLocalGroupChatNotification({
    required String receiverToken,
    required String cityName,
    required String senderName,
    required String message,
    required String senderId,
  }) async {
    try {
      print('🧪 Testing local group chat notification...');
      
      final groupChatRoomId = cityName; // For local groups, city name is the group ID

      final success = await _notificationService.sendNotificationToUser(
        receiverToken: receiverToken,
        title: cityName,
        body: '$cityName: $senderName: $message',
        data: {
          'type': 'local_group_chat_message',
          'groupChatRoomId': groupChatRoomId,
          'groupName': cityName,
          'senderId': senderId,
          'senderName': senderName,
          'message': message,
        },
      );

      if (success) {
        print('✅ Local group chat notification test successful');
      } else {
        print('❌ Local group chat notification test failed');
      }
    } catch (e) {
      print('❌ Error testing local group chat notification: $e');
    }
  }
}

/// Widget to test notifications in the UI
class NotificationTestWidget extends StatelessWidget {
  const NotificationTestWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => NotificationTest.testGetDeviceToken(),
              child: const Text('Get Device Token'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => NotificationTest.testLocalNotification(),
              child: const Text('Test Local Notification'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => NotificationTest.testGetUserToken('test_user_id'),
              child: const Text('Get User Token'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => NotificationTest.testSendNotification(
                receiverToken: 'test_token',
                senderName: 'Test User',
                message: 'This is a test message',
                chatroomId: 'test_chatroom',
                senderId: 'sender_id',
                receiverId: 'receiver_id',
              ),
              child: const Text('Send Test Notification'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => NotificationTest.testGroupChatNotification(
                receiverToken: 'test_token',
                groupName: 'Test Group',
                senderName: 'Test User',
                message: 'This is a test group message',
                groupChatRoomId: 'test_group_chatroom',
                senderId: 'sender_id',
              ),
              child: const Text('Send Test Group Notification'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => NotificationTest.testLocalGroupChatNotification(
                receiverToken: 'test_token',
                cityName: 'New York',
                senderName: 'Test User',
                message: 'This is a test local group message',
                senderId: 'sender_id',
              ),
              child: const Text('Send Test Local Group Notification'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => NotificationTest.testBulkNotification(
                tokens: ['token1', 'token2', 'token3'],
                title: 'Bulk Test',
                body: 'This is a bulk test notification',
              ),
              child: const Text('Send Bulk Notification'),
            ),
          ],
        ),
      ),
    );
  }
} 