# FCM Push Notifications Setup Guide

This guide explains how Firebase Cloud Messaging (FCM) push notifications are implemented for incoming calls.

## Overview

FCM push notifications enable the call system to work even when the app is completely terminated. When a call is initiated, the backend sends both:
1. Socket.IO notification (for active/background apps)
2. FCM push notification (for terminated apps)

## Implementation Details

### Backend

1. **FCM Service** (`backend/src/services/fcmService.ts`)
   - Sends push notifications to users
   - Handles invalid tokens automatically
   - Supports incoming call notifications

2. **User Model** (`backend/src/models/User.ts`)
   - Added `fcmToken` field to store FCM tokens

3. **Socket Service** (`backend/src/services/socketService.ts`)
   - Updated to send FCM notifications when calls are initiated
   - Sends notification even if Socket.IO fails

4. **API Endpoint** (`backend/src/routes/userRoutes.ts`)
   - `POST /api/users/fcm-token` - Register/update FCM token

### Flutter Apps

1. **FCM Service** (`lib/services/fcm_service.dart`)
   - Handles FCM token registration
   - Processes incoming notifications
   - Navigates to call screen when notification is tapped
   - Works in foreground, background, and terminated states

2. **Main App** (`lib/main.dart`)
   - Initializes FCM service on app startup
   - Sets up background message handler

## Setup Instructions

### 1. Firebase Configuration

#### User App
The user app already has Firebase configured. Verify:
- `firebase_options.dart` exists
- Firebase project is set up in Firebase Console

#### Driver App
The driver app needs Firebase configuration:

```bash
cd driver-app
flutterfire configure --project=your-firebase-project-id
```

This will:
- Create `firebase_options.dart`
- Configure Firebase for the driver app

### 2. Android Configuration

#### Add Notification Channel (Android)

Create or update `android/app/src/main/res/values/strings.xml`:

```xml
<resources>
    <string name="default_notification_channel_id">incoming_calls</string>
</resources>
```

#### Update AndroidManifest.xml

Add notification channel and permissions:

```xml
<manifest>
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <application>
        <!-- Add notification channel -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="incoming_calls" />
    </application>
</manifest>
```

### 3. iOS Configuration

#### Update Info.plist

Add notification permissions:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

#### Enable Push Notifications Capability

1. Open Xcode
2. Select your project
3. Go to "Signing & Capabilities"
4. Add "Push Notifications" capability
5. Add "Background Modes" capability
6. Enable "Remote notifications"

#### Upload APNs Certificate

1. Go to Firebase Console
2. Project Settings → Cloud Messaging
3. Upload your APNs certificate or key

### 4. Backend Configuration

Ensure Firebase Admin SDK is configured:

1. **Service Account Key**
   - Download from Firebase Console
   - Place in backend directory or set environment variables

2. **Environment Variables** (for cloud deployment):
   ```
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_PRIVATE_KEY=your-private-key
   FIREBASE_CLIENT_EMAIL=your-client-email
   ```

## How It Works

### Call Flow

1. **Caller initiates call:**
   - Frontend calls `ZegoCallService.startCall()`
   - Emits `call-initiate` via Socket.IO

2. **Backend receives call:**
   - Socket service receives `call-initiate` event
   - Sends Socket.IO notification to receiver (if connected)
   - Sends FCM push notification to receiver (always)

3. **Receiver receives notification:**
   - **If app is active/background:** Socket.IO notification triggers call dialog
   - **If app is terminated:** FCM notification appears
   - **When notification tapped:** App launches and navigates to call screen

### Notification Handling

#### Foreground (App Open)
- FCM service receives notification
- Shows incoming call dialog immediately
- User can accept/reject

#### Background (App Minimized)
- FCM notification appears in notification tray
- When tapped, app comes to foreground
- Call dialog appears

#### Terminated (App Closed)
- FCM notification appears in notification tray
- When tapped, app launches
- FCM service checks for pending call
- Navigates directly to call screen

## Testing

### Test Scenarios

1. **Foreground Call:**
   - App is open
   - Caller initiates call
   - ✅ Call dialog appears immediately

2. **Background Call:**
   - App is minimized
   - Caller initiates call
   - ✅ Notification appears
   - ✅ Tapping notification opens call dialog

3. **Terminated Call:**
   - App is force-closed
   - Caller initiates call
   - ✅ Push notification appears
   - ✅ Tapping notification launches app and opens call screen

### Debugging

#### Check FCM Token Registration
```dart
final fcmService = FCMService();
print('FCM Token: ${fcmService.token}');
```

#### Check Backend Logs
- Look for: `📱 FCM notification sent to user...`
- Check for errors: `❌ Error sending push notification...`

#### Test Notification
Use Firebase Console → Cloud Messaging → Send test message:
- Title: "Incoming Call"
- Body: "Test call"
- Data:
  ```json
  {
    "type": "incoming_call",
    "orderId": "test-order",
    "roomId": "test-room",
    "callerId": "test-caller",
    "callerName": "Test User"
  }
  ```

## Troubleshooting

### Notifications Not Appearing

1. **Check FCM Token:**
   - Verify token is registered in backend
   - Check user's `fcmToken` field in database

2. **Check Permissions:**
   - Android: Check notification permissions
   - iOS: Check APNs certificate

3. **Check Firebase Configuration:**
   - Verify `firebase_options.dart` exists
   - Check Firebase project settings

4. **Check Backend Logs:**
   - Look for FCM sending errors
   - Check for invalid tokens

### App Not Opening from Notification

1. **Check Background Handler:**
   - Verify `firebaseMessagingBackgroundHandler` is set up
   - Check that it's a top-level function

2. **Check Notification Data:**
   - Verify `type: 'incoming_call'` is in data
   - Check that all required fields are present

3. **Check Navigation:**
   - Verify global navigator key is set up
   - Check that context is available

## Security Considerations

1. **FCM Tokens:**
   - Tokens are user-specific and should be kept secure
   - Tokens expire and refresh automatically
   - Invalid tokens are automatically removed

2. **Notification Data:**
   - Sensitive data should be minimal in notifications
   - Use notification data to trigger app actions
   - Don't store sensitive info in notification payload

## Future Enhancements

1. **CallKit Integration (iOS):**
   - Native call UI for iOS
   - Better integration with iOS call system

2. **Rich Notifications:**
   - Show caller name and photo
   - Add quick action buttons (Accept/Reject)

3. **Notification Grouping:**
   - Group multiple calls
   - Show call history

4. **Silent Notifications:**
   - Update app state without showing notification
   - Sync data in background

## API Reference

### Register FCM Token

**Endpoint:** `POST /api/users/fcm-token`

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Body:**
```json
{
  "fcmToken": "your-fcm-token"
}
```

**Response:**
```json
{
  "message": "FCM token updated successfully",
  "user": { ... }
}
```

## Notes

- FCM tokens are automatically refreshed when they expire
- Invalid tokens are automatically removed from the database
- Notifications work even when Socket.IO is disconnected
- Both Socket.IO and FCM are used for redundancy

