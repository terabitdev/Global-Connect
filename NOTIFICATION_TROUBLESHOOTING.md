# Notification Troubleshooting Guide

## Common Issues and Solutions

### 1. Notifications Not Showing on Other Devices

#### **Check FCM Token**
```dart
// Test if FCM token is being saved correctly
final token = await NotificationService.instance.getDeviceToken();
print('Current device token: $token');
```

#### **Group Chat Notifications**
```dart
// Test group chat notifications
await NotificationTest.testGroupChatNotification(
  receiverToken: 'user_fcm_token',
  groupName: 'Test Group',
  senderName: 'John Doe',
  message: 'Hello everyone!',
  groupChatRoomId: 'group_chatroom_id',
  senderId: 'sender_user_id',
);
```

#### **Check User FCM Token in Firestore**
- Go to Firebase Console → Firestore
- Check the `users` collection
- Verify that the target user has a valid `fcmToken` field
- Token should look like: `fMEP0vJqS0:APA91bHqX...`

#### **Test Local Notifications First**
```dart
// Test if local notifications work
await NotificationService.instance.testLocalNotification();
```

### 2. FCM API Errors

#### **400 Error - Invalid JSON Payload**
- Check the notification payload structure
- Ensure all fields are valid for FCM v1 API
- Remove invalid fields like `click_action` from Android notification

#### **401 Error - Unauthorized**
- Check Firebase service account credentials
- Verify project ID matches
- Ensure service account has FCM permissions

#### **404 Error - Token Not Found**
- User's FCM token is invalid or expired
- User needs to reinstall app or clear data
- Check if token is being refreshed properly

### 3. Android-Specific Issues

#### **Notification Channel Not Created**
```dart
// Ensure notification channel is created
await NotificationService.instance._createNotificationChannel();
```

#### **Permission Issues**
- Check if notification permissions are granted
- Go to Settings → Apps → Your App → Notifications
- Ensure notifications are enabled

#### **Do Not Disturb Mode**
- Check if device is in Do Not Disturb mode
- Ensure app is allowed in DND exceptions

### 4. iOS-Specific Issues

#### **APNs Configuration**
- Verify APNs certificate is valid
- Check bundle ID matches
- Ensure push notifications capability is enabled

#### **Background App Refresh**
- Enable Background App Refresh for your app
- Settings → General → Background App Refresh

### 5. Debugging Steps

#### **Step 1: Check FCM Token**
```dart
// In your app, add this debug code
final token = await NotificationService.instance.getDeviceToken();
print('FCM Token: $token');

// Save to Firestore
await FirebaseFirestore.instance
    .collection('users')
    .doc(FirebaseAuth.instance.currentUser?.uid)
    .update({'fcmToken': token});
```

#### **Step 2: Test Local Notifications**
```dart
// Test if local notifications work
await NotificationService.instance.testLocalNotification();
```

#### **Step 3: Test FCM Sending**
```dart
// Test sending to yourself first
final myToken = await NotificationService.instance.getDeviceToken();
await NotificationService.instance.sendNotificationToUser(
  receiverToken: myToken,
  title: 'Test',
  body: 'Test message',
  data: {'type': 'test'},
);
```

#### **Step 4: Check Firebase Console**
- Go to Firebase Console → Cloud Messaging
- Check delivery reports
- Look for failed deliveries

### 6. Common Solutions

#### **Solution 1: Reinstall App**
- Uninstall and reinstall the app
- This generates a new FCM token
- Ensures clean notification setup

#### **Solution 2: Clear App Data**
- Clear app data and cache
- Restart the app
- Check if new FCM token is generated

#### **Solution 3: Check Network**
- Ensure device has internet connection
- Check if firewall is blocking FCM
- Try on different network (WiFi vs Mobile)

#### **Solution 4: Update Dependencies**
```yaml
# Ensure you have the latest compatible versions
dependencies:
  firebase_messaging: ^15.2.9
  flutter_local_notifications: ^17.2.0
  firebase_core: ^3.15.1
```

### 7. Testing Checklist

- [ ] FCM token is generated and saved
- [ ] Local notifications work
- [ ] Firebase service account is configured
- [ ] Notification permissions are granted
- [ ] Notification channel is created (Android)
- [ ] APNs is configured (iOS)
- [ ] Network connectivity is available
- [ ] App is not in battery optimization mode
- [ ] Do Not Disturb is not blocking notifications

### 8. Log Analysis

#### **Successful Notification**
```
✅ Notification sent successfully
✅ User FCM token: [token]
```

#### **Failed Notification**
```
❌ Failed to send notification: 400
❌ Error sending notification: [error]
❌ No FCM token found for user [user_id]
```

### 9. Production Checklist

- [ ] Use production Firebase project
- [ ] Configure production APNs certificate
- [ ] Test on multiple devices
- [ ] Test on different Android/iOS versions
- [ ] Test with different network conditions
- [ ] Monitor Firebase Console for delivery reports
- [ ] Set up error monitoring (Crashlytics)

### 10. Emergency Fixes

#### **If Nothing Works**
1. Clear all app data
2. Uninstall and reinstall app
3. Check device notification settings
4. Test on different device
5. Verify Firebase project configuration
6. Check service account permissions

#### **Quick Test**
```dart
// Add this to your main.dart for quick testing
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.initialize();
  
  // Quick test
  await NotificationService.instance.testLocalNotification();
  
  runApp(MyApp());
}
``` 