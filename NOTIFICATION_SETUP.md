# Notification System Setup Guide

This document explains how to set up and use the notification system in the Global Connect Mobile app.

## Overview

The notification system provides:
- Real-time push notifications for chat messages
- Local notifications for foreground messages
- Background message handling
- Navigation to chat screens when notifications are tapped
- FCM token management

## Features

### ✅ Implemented Features

1. **Push Notifications**: Send notifications to specific users via FCM
2. **Local Notifications**: Show notifications when app is in foreground
3. **Background Handling**: Handle notifications when app is closed
4. **Chat Navigation**: Navigate to chat screen when notification is tapped
5. **Token Management**: Automatic FCM token generation and storage
6. **Message Read Status**: Mark notifications as read when entering chat
7. **Sound & Vibration**: Custom notification sounds and vibration patterns

## Setup Instructions

### 1. Firebase Configuration

Make sure you have the following Firebase services configured:

- **Firebase Cloud Messaging (FCM)**
- **Firebase Authentication**
- **Cloud Firestore**

### 2. Dependencies

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^16.3.0
  googleapis_auth: ^1.4.1
  http: ^1.1.0
```

### 3. Android Configuration

#### Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <application>
        <!-- Add this inside the application tag -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="chat_channel" />
    </application>
    
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
</manifest>
```

#### Add notification sound files to `android/app/src/main/res/raw/`:
- `notification_sound.mp3` (or .wav)

### 4. iOS Configuration

#### Add to `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

#### Add notification sound files to `ios/Runner/`:
- `notification_sound.aiff`

## Usage

### 1. Initialize Notification Service

The notification service is automatically initialized in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize NotificationService
  await NotificationService.instance.initialize();
  
  runApp(MyApp());
}
```

### 2. Send Notifications from Chat

Notifications are automatically sent when messages are sent through the `ChatProvider`:

```dart
// This happens automatically in ChatProvider.sendMessage()
await _sendNotificationToReceiver(receiverId, messageText);
```

### 3. Manual Notification Sending

You can also send notifications manually:

```dart
final notificationService = NotificationService.instance;

await notificationService.sendNotificationToUser(
  receiverToken: 'user_fcm_token',
  title: 'John Doe',
  body: 'Hello! How are you?',
  data: {
    'type': 'chat_message',
    'chatroomId': 'chatroom_id',
    'senderId': 'sender_id',
    'receiverId': 'receiver_id',
    'message': 'Hello! How are you?',
  },
);
```

### 4. Get User FCM Token

```dart
final token = await notificationService.getUserFCMToken('user_id');
```

### 5. Get Device Token

```dart
final deviceToken = await notificationService.getDeviceToken();
```

## Notification Flow

### 1. Message Sent
1. User sends a message in chat
2. Message is saved to Firestore
3. Notification is sent to receiver's FCM token
4. Receiver's device receives notification

### 2. Notification Received
1. **Foreground**: Local notification is shown
2. **Background**: System notification is shown
3. **Tapped**: App opens and navigates to chat screen

### 3. Chat Navigation
1. Notification data contains chatroom and user info
2. App fetches user details from Firestore
3. Navigates to chat screen with user data
4. Marks notifications as read

## Testing

Use the `NotificationTest` class to test notifications:

```dart
// Test sending a notification
await NotificationTest.testSendNotification(
  receiverToken: 'test_token',
  senderName: 'Test User',
  message: 'Test message',
  chatroomId: 'test_chatroom',
  senderId: 'sender_id',
  receiverId: 'receiver_id',
);

// Test getting device token
await NotificationTest.testGetDeviceToken();

// Test getting user token
await NotificationTest.testGetUserToken('user_id');
```

## Troubleshooting

### Common Issues

1. **Notifications not showing**
   - Check FCM token is saved in Firestore
   - Verify notification permissions are granted
   - Check device is connected to internet

2. **Navigation not working**
   - Ensure navigator key is set in main.dart
   - Check route names match in routes file
   - Verify user data is properly formatted

3. **Sound not playing**
   - Check sound files are in correct locations
   - Verify file names match in code
   - Test on physical device (emulator may not play sounds)

### Debug Logs

Enable debug logging by checking console output:

```
✅ Notification sent successfully
✅ User FCM token: [token]
❌ Error sending notification: [error]
```

## Security Considerations

1. **Service Account Key**: Keep the Firebase service account key secure
2. **Token Validation**: Validate FCM tokens before sending notifications
3. **Rate Limiting**: Implement rate limiting for notification sending
4. **User Consent**: Ensure users have granted notification permissions

## Future Enhancements

- [ ] Notification grouping for multiple messages
- [ ] Custom notification sounds per user
- [ ] Notification preferences (sound, vibration, etc.)
- [ ] Read receipts for notifications
- [ ] Notification history
- [ ] Mute specific users/chats

## Support

For issues or questions about the notification system, check:
1. Firebase Console logs
2. Device notification settings
3. App notification permissions
4. Network connectivity 