# User Status Testing Guide

## 🧪 How to Test the Status Feature

### Step 1: Check Console Logs

When you run the app, you should see these logs in your console:

```
🔧 UserStatusProvider constructor called
🔧 Setting up auth listener
🔔 Auth state changed: <user_id>
✅ User logged in: <user_id>
🚀 Initializing UserStatusProvider...
👤 Current user ID: <user_id>
👀 Lifecycle observer added
🟢 Setting user online: <user_id>
✅ User successfully set to online
📝 Verified status: online
✅ UserStatusProvider initialized successfully
```

### Step 2: Check Firebase Console

1. Open Firebase Console
2. Go to Firestore Database
3. Navigate to `users` collection
4. Find your user document
5. You should see:
   ```
   status: "online"
   lastSeen: <timestamp>
   ```

### Step 3: Test App Lifecycle

**Test 1: Minimize App**
- Action: Press home button (minimize app)
- Expected Log: `🔴 Setting user offline: <user_id>`
- Expected in Firebase: `status: "offline"`

**Test 2: Return to App**
- Action: Open app again from recent apps
- Expected Log: `🟢 Setting user online: <user_id>`
- Expected in Firebase: `status: "online"`

**Test 3: Kill App**
- Action: Force close the app
- Expected in Firebase: `status: "offline"` (from previous minimize)

**Test 4: Re-open App**
- Action: Launch app fresh
- Expected Log: Full initialization sequence
- Expected in Firebase: `status: "online"`

### Step 4: Test Login/Logout

**Test Logout:**
```
🚪 User logged out
🔴 Setting user offline: <user_id>
✅ User successfully set to offline
🧹 Cleaning up UserStatusProvider...
```

**Test Login:**
```
🔔 Auth state changed: <user_id>
✅ User logged in: <user_id>
🚀 Initializing UserStatusProvider...
🟢 Setting user online: <user_id>
```

## 🐛 Troubleshooting

### Issue 1: No Logs Appearing

**Problem:** You don't see any console logs
**Solution:**
- Make sure you're running in debug mode
- Check if UserStatusProvider is in the MultiProvider list
- Restart the app completely

### Issue 2: Status Not Updating in Firebase

**Problem:** Logs show success but Firebase doesn't update
**Possible Causes:**

1. **Missing Fields in User Document**
   - Solution: Run the migration script below

2. **Firebase Permission Error**
   - Check console for error: `❌ Error setting user online: [firebase_auth/permission-denied]`
   - Solution: Update Firebase Security Rules (see below)

3. **No Internet Connection**
   - Check if device/emulator has internet
   - Check Firebase connection in Firebase Console

### Issue 3: "User document does not exist" Error

**Problem:** `❌ User document does not exist: <user_id>`
**Solution:** 
- Make sure user document is created during signup
- Run migration script to add fields to existing users

## 🔧 Migration Script for Existing Users

If you have existing users without `status` and `lastSeen` fields, run this in Firebase Console:

### Option 1: Using Firebase Console (Manual)

1. Go to Firestore Database
2. Open `users` collection
3. For each user document, add:
   - Field: `status`, Type: string, Value: `offline`
   - Field: `lastSeen`, Type: timestamp, Value: (current time)

### Option 2: Using Cloud Function (Automated)

Create this Cloud Function:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.migrateUserStatus = functions.https.onRequest(async (req, res) => {
  const db = admin.firestore();
  const usersRef = db.collection('users');
  
  try {
    const snapshot = await usersRef.get();
    const batch = db.batch();
    let count = 0;
    
    snapshot.forEach(doc => {
      const data = doc.data();
      
      // Only update if status or lastSeen is missing
      if (!data.status || !data.lastSeen) {
        batch.update(doc.ref, {
          status: 'offline',
          lastSeen: admin.firestore.FieldValue.serverTimestamp()
        });
        count++;
      }
    });
    
    await batch.commit();
    res.send(`✅ Migrated ${count} users`);
  } catch (error) {
    console.error('Migration error:', error);
    res.status(500).send('Migration failed: ' + error.message);
  }
});
```

### Option 3: Using Flutter App (One-time)

Add this to your app (temporary, remove after running once):

```dart
Future<void> migrateExistingUsers() async {
  final firestore = FirebaseFirestore.instance;
  
  try {
    final snapshot = await firestore.collection('users').get();
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      
      if (!data.containsKey('status') || !data.containsKey('lastSeen')) {
        await doc.reference.update({
          'status': 'offline',
          'lastSeen': FieldValue.serverTimestamp(),
        });
        print('✅ Migrated user: ${doc.id}');
      }
    }
    
    print('✅ Migration complete');
  } catch (e) {
    print('❌ Migration error: $e');
  }
}

// Call this once from a button or initState
```

## 🔒 Firebase Security Rules

Make sure your Firestore rules allow status updates:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Allow users to read any user document
      allow read: if request.auth != null;
      
      // Allow users to update only their own status and lastSeen
      allow update: if request.auth != null 
                    && request.auth.uid == userId
                    && request.resource.data.diff(resource.data)
                       .affectedKeys()
                       .hasOnly(['status', 'lastSeen']);
    }
  }
}
```

## 📊 Expected Behavior Summary

| User Action | App State | Expected Status | Console Log |
|-------------|-----------|-----------------|-------------|
| Open App | resumed | `online` | 🟢 Setting user online |
| Minimize App | paused | `offline` | 🔴 Setting user offline |
| Kill App | detached | `offline` | 🔴 Setting user offline |
| Return to App | resumed | `online` | 🟢 Setting user online |
| Login | - | `online` | ✅ User logged in |
| Logout | - | `offline` | 🚪 User logged out |

## 🎯 Quick Test Checklist

- [ ] Console shows initialization logs
- [ ] Firebase shows `status: "online"` when app is open
- [ ] Firebase shows `status: "offline"` when app is minimized
- [ ] Status changes back to `online` when returning to app
- [ ] `lastSeen` timestamp updates with each status change
- [ ] Logout sets status to `offline`
- [ ] Login sets status to `online`

## 💡 Tips

1. **Use Firebase Console in Real-time**: Keep Firebase Console open while testing to see live updates
2. **Check Timestamps**: The `lastSeen` field should update every time status changes
3. **Debug Mode**: Always test in debug mode to see console logs
4. **Clear Cache**: If issues persist, try clearing app data/cache
5. **Hot Restart**: Use hot restart (not hot reload) when testing lifecycle changes

## 📞 Need Help?

If status still not working:
1. Share the console logs
2. Share Firebase security rules
3. Check if user document exists in Firestore
4. Verify internet connection
5. Check Firebase project configuration

