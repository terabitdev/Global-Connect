# User Online/Offline Status Implementation

## Overview
This implementation automatically tracks user online/offline status using Flutter's `AppLifecycleState` and updates Firebase in real-time.

## Files Modified/Created

### 1. **UserModel** (`lib/Model/userModel.dart`)
Added new fields:
- `status`: String ('online' or 'offline')
- `lastSeen`: DateTime? (timestamp of last activity)

### 2. **UserStatusProvider** (`lib/Provider/UserStatusProvider.dart`)
New provider that handles:
- App lifecycle state monitoring
- Firebase status updates
- Auth state changes
- Automatic cleanup on logout

### 3. **main.dart** (`lib/main.dart`)
Registered `UserStatusProvider` in the app's MultiProvider

## How It Works

### App Lifecycle States

| State | Action | Status |
|-------|--------|--------|
| **resumed** | App comes to foreground | 🟢 Set `online` |
| **paused** | App goes to background | 🔴 Set `offline` + update `lastSeen` |
| **detached** | App is being terminated | 🔴 Set `offline` + update `lastSeen` |
| **inactive** | App is inactive (call, notification) | ⚪ No change (temporary state) |
| **hidden** | App is hidden | 🔴 Set `offline` + update `lastSeen` |

### Auth State Changes

| Event | Action |
|-------|--------|
| **User logs in** | Set status to `online` |
| **User logs out** | Set status to `offline` and cleanup |

## Firebase Structure

```json
{
  "users": {
    "userId": {
      "status": "online",  // or "offline"
      "lastSeen": "Timestamp",
      // ... other user fields
    }
  }
}
```

## Usage in UI

### Display Online Status

```dart
// In any widget
import 'package:provider/provider.dart';

// Show online indicator
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return SizedBox();
    
    final userData = snapshot.data!.data() as Map<String, dynamic>?;
    final status = userData?['status'] ?? 'offline';
    
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: status == 'online' ? Colors.green : Colors.grey,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  },
)
```

### Display Last Seen

```dart
// Using UserModel helpers
Text(
  userModel.formattedLastSeen,
  // Shows: "Online", "Last seen 5m ago", etc.
  style: TextStyle(fontSize: 12, color: Colors.grey),
)

// Or check if online
if (userModel.isOnline) {
  Text('Online', style: TextStyle(color: Colors.green));
} else {
  Text(userModel.formattedLastSeen);
}
```

## UserModel Helper Methods

```dart
// Set user online
final updatedUser = user.setOnlineStatus();
await FirebaseServices.updateUser(updatedUser);

// Set user offline
final offlineUser = user.setOfflineStatus();
await FirebaseServices.updateUser(offlineUser);

// Check online status
if (user.isOnline) {
  print('User is online');
}

// Get formatted last seen
print(user.formattedLastSeen);
// Outputs: "Online" or "Last seen 5m ago"
```

## Automatic Status Updates

The `UserStatusProvider` handles everything automatically:

1. ✅ **App Opens** → User set to online
2. ✅ **App Minimized** → User set to offline with lastSeen
3. ✅ **App Killed** → User set to offline with lastSeen
4. ✅ **User Logs In** → User set to online
5. ✅ **User Logs Out** → User set to offline
6. ✅ **App Resumed** → User set to online again

## Security Rules (Recommended)

Add these Firebase Security Rules to protect user status:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Users can only update their own status
      allow update: if request.auth != null 
                    && request.auth.uid == userId
                    && request.resource.data.diff(resource.data).affectedKeys()
                       .hasOnly(['status', 'lastSeen']);
    }
  }
}
```

## Performance Considerations

- Status updates use `FieldValue.serverTimestamp()` for accurate timestamps
- Lifecycle state changes are debounced (inactive state doesn't trigger updates)
- Provider is a singleton (shared across app)
- Cleanup happens automatically on logout

## Testing

To test the implementation:

1. **Open app** → Check Firebase, status should be 'online'
2. **Minimize app** → Status should change to 'offline', lastSeen updated
3. **Return to app** → Status should change back to 'online'
4. **Force kill app** → Status should be 'offline'
5. **Logout** → Status should be 'offline'

## Troubleshooting

### Status not updating?
- Check if user is authenticated
- Verify Firebase permissions
- Check console logs for errors

### Multiple status updates?
- This is normal during app state transitions
- Firebase batches updates efficiently

### Status shows offline when online?
- Check device internet connection
- Verify Firebase rules allow status updates
- Check console for error messages

## Future Enhancements

Possible improvements:
- [ ] Add typing indicator
- [ ] Add "Away" status after certain inactive time
- [ ] Add custom status messages
- [ ] Add push notifications for friend's online status
- [ ] Add presence in chat rooms

