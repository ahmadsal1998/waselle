# Android Push Notification Fix

## Problem Summary
The Android app was not receiving FCM tokens, causing the server to skip sending notifications with the error:
```
User 6925020bbcd29965cb103893 has no FCM token, skipping notification
```

## Root Causes Identified

1. **Android 13+ Notification Permission**: The app was using iOS-specific permission request (`firebase_messaging.requestPermission()`), which doesn't work on Android 13+ where explicit `POST_NOTIFICATIONS` permission is required.

2. **Token Registration Timing**: FCM tokens were being retrieved before user authentication, causing token save requests to fail silently.

3. **Missing Notification Channel**: The `order_updates` notification channel was not created in `MainActivity`, only `incoming_calls` existed.

4. **No Custom FirebaseMessagingService**: Using default service without custom implementation for better token handling and debugging.

## Fixes Applied

### 1. Android 13+ Notification Permission (`fcm_service.dart`)
- Added `permission_handler` package import
- Created `_requestNotificationPermissions()` method that:
  - Uses `Permission.notification` for Android 13+
  - Falls back to default behavior for Android < 13
  - Maintains iOS-specific permission handling

### 2. Token Registration After Authentication (`fcm_service.dart` & `auth_view_model.dart`)
- Modified `_saveTokenToBackend()` to check authentication status
- Stores pending tokens in SharedPreferences when user is not authenticated
- Added `savePendingToken()` method to save tokens after login
- Integrated token saving into `AuthViewModel` after successful login/auth check

### 3. Notification Channels (`MainActivity.kt`)
- Added `order_updates` notification channel creation
- Both channels now properly configured with:
  - High importance
  - Vibration enabled
  - Lights enabled
  - Badge support

### 4. Custom FirebaseMessagingService (`MyFirebaseMessagingService.kt`)
- Created custom service extending `FirebaseMessagingService`
- Handles token refresh in background
- Added logging for debugging
- Updated `AndroidManifest.xml` to use custom service

### 5. Enhanced Logging (`fcm_service.dart`)
- Added full FCM token logging for debugging
- Better error messages for token retrieval failures
- Clear status messages for permission states

## Files Modified

1. `driver-app/lib/services/fcm_service.dart`
   - Added Android 13+ permission handling
   - Added pending token storage and retrieval
   - Enhanced error handling and logging

2. `driver-app/lib/view_models/auth_view_model.dart`
   - Added FCM token saving after authentication
   - Integrated with FCMService

3. `driver-app/android/app/src/main/kotlin/com/example/delivery_driver_app/MainActivity.kt`
   - Added `order_updates` notification channel

4. `driver-app/android/app/src/main/kotlin/com/example/delivery_driver_app/MyFirebaseMessagingService.kt`
   - Created custom FirebaseMessagingService

5. `driver-app/android/app/src/main/AndroidManifest.xml`
   - Updated to use custom FirebaseMessagingService

## Testing Steps

1. **Clean Build**:
   ```bash
   cd driver-app
   flutter clean
   flutter pub get
   ```

2. **Rebuild and Install**:
   ```bash
   flutter build apk --debug
   # Or for release:
   flutter build apk --release
   ```

3. **Test on Android Device (13+)**:
   - Install the app
   - On first launch, you should see a notification permission dialog
   - Grant permission
   - Login to the app
   - Check logs for FCM token retrieval and backend save:
     ```
     📱 FCM Token retrieved: ...
     ✅ FCM token saved to backend
     ```

4. **Verify Token Registration**:
   - Check server logs - should show token being saved
   - Send a test notification from admin dashboard
   - Verify notification appears on device

5. **Test All App States**:
   - **Foreground**: App open, notification should appear
   - **Background**: App in background, notification should appear
   - **Terminated**: App closed, notification should appear and open app when tapped

## Expected Behavior

### On App Launch:
1. App requests notification permission (Android 13+)
2. FCM token is retrieved
3. If user is authenticated, token is saved immediately
4. If user is not authenticated, token is stored for later

### After Login:
1. User logs in successfully
2. Pending FCM token (if any) is automatically saved
3. Current FCM token is also saved to ensure it's up to date

### Token Refresh:
- Token refresh is handled automatically by Firebase
- Custom service ensures refresh works in all app states
- Token is automatically saved to backend when refreshed

## Troubleshooting

### If token is still null:
1. Verify `google-services.json` is in `android/app/` directory
2. Check Firebase project configuration matches package name
3. Verify Google Services plugin is applied in `build.gradle.kts`
4. Check device logs for Firebase initialization errors

### If permission is denied:
1. Go to Android Settings > Apps > Delivery Driver > Notifications
2. Enable notifications manually
3. Restart the app

### If token is not saved to backend:
1. Check authentication token is valid
2. Verify backend endpoint `/api/users/fcm-token` is accessible
3. Check network connectivity
4. Review server logs for errors

## Additional Notes

- The app now handles both Android < 13 (permission granted by default) and Android 13+ (explicit permission required)
- Token is saved automatically after authentication, no manual action needed
- All notification channels are properly configured for Android 8.0+
- Custom FirebaseMessagingService ensures reliable token refresh

