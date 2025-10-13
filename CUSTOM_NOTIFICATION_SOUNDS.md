# Custom Notification Sounds Guide

## Current Status
✅ **Notifications are working with default sounds**  
❌ **Custom sounds were causing errors**  
✅ **Fixed by removing custom sound references**

## How to Add Custom Notification Sounds (Optional)

### For Android:

1. **Add Sound Files:**
   ```
   android/app/src/main/res/raw/
   ├── notification_sound.mp3
   ├── chat_message.wav
   └── alert.mp3
   ```

2. **Update NotificationService:**
   ```dart
   // In NotificationService.dart
   AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
     channel.id,
     channel.name,
     channelDescription: channel.description,
     importance: Importance.high,
     priority: Priority.high,
     ticker: 'ticker',
     icon: '@mipmap/ic_launcher',
     sound: const RawResourceAndroidNotificationSound('notification_sound'),
     enableVibration: true,
     vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
   );
   ```

3. **Update FCM Payload:**
   ```dart
   'android': {
     'notification': {
       'channel_id': 'chat_channel',
       'sound': 'notification_sound',
       'icon': '@mipmap/ic_launcher',
       'color': '#FF6B6B',
     },
     'priority': 'high',
   },
   ```

### For iOS:

1. **Add Sound Files:**
   ```
   ios/Runner/
   ├── notification_sound.aiff
   ├── chat_message.aiff
   └── alert.aiff
   ```

2. **Update NotificationService:**
   ```dart
   const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
     presentAlert: true,
     presentBadge: true,
     presentSound: true,
     sound: 'notification_sound.aiff',
   );
   ```

3. **Update FCM Payload:**
   ```dart
   'apns': {
     'payload': {
       'aps': {
         'alert': {
           'title': title,
           'body': body,
         },
         'sound': 'notification_sound.aiff',
         'badge': 1,
         'category': 'chat_message',
       }
     },
     'headers': {
       'apns-priority': '10',
     }
   }
   ```

## Sound File Requirements

### Android:
- **Format**: MP3, WAV, OGG
- **Duration**: 5 seconds or less
- **Size**: Under 1MB
- **Location**: `android/app/src/main/res/raw/`

### iOS:
- **Format**: AIFF, WAV, CAF
- **Duration**: 30 seconds or less
- **Size**: Under 5MB
- **Location**: `ios/Runner/`

## Testing Custom Sounds

1. **Add sound files to the correct directories**
2. **Update NotificationService code**
3. **Clean and rebuild the app**
4. **Test local notifications first**
5. **Test FCM notifications**

## Troubleshooting Custom Sounds

### Common Issues:
- **File not found**: Check file path and name
- **Format not supported**: Use recommended formats
- **File too large**: Compress or shorten the sound
- **Permission denied**: Check file permissions

### Debug Steps:
```dart
// Test with default sound first
await NotificationService.instance.testLocalNotification();

// Then test with custom sound
// (after adding sound files and updating code)
```

## Current Working Configuration

The notification system is currently working with:
- ✅ Default system sounds
- ✅ Vibration enabled
- ✅ High priority notifications
- ✅ Proper channel configuration
- ✅ Cross-platform compatibility

## Recommendation

For now, stick with default sounds as they:
- ✅ Work reliably across all devices
- ✅ Don't require additional files
- ✅ Follow platform conventions
- ✅ Reduce app size
- ✅ Avoid compatibility issues

You can add custom sounds later when the basic notification system is fully tested and working. 