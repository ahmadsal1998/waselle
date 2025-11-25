# Android FCM Token Retrieval Fix

## Problem
Some Android devices were not receiving push notifications because FCM tokens were not being retrieved or saved to the backend. Server logs showed:
```
User 6925020bbcd29965cb103893 has no FCM token, skipping notification
```

## Root Causes Identified
1. **Silent token retrieval failures** - Errors were caught but not properly retried
2. **No retry logic** - If token retrieval failed initially, it wouldn't retry
3. **Missing token retrieval after authentication** - Token wasn't retrieved if user logged in before Firebase initialized
4. **Insufficient error logging** - Made debugging difficult

## Fixes Implemented

### 1. Enhanced Token Retrieval with Retry Logic
- Added `_retrieveAndroidToken()` method with exponential backoff retry (up to 3 attempts)
- Ensures Firebase is initialized before attempting token retrieval
- Comprehensive error logging with actionable debug messages
- Token can be retrieved even if notification permissions are denied

### 2. Improved Token Saving
- Enhanced `_saveTokenToBackend()` with better error handling
- Validates token before saving
- Stores token for retry if user is not authenticated
- Better logging for debugging

### 3. Enhanced savePendingToken()
- Now attempts to retrieve token if none exists
- Handles both Android and iOS platforms
- Ensures token is saved after authentication

### 4. Added Diagnostic Methods
- `retryTokenRetrieval()` - Manually retry token retrieval
- `getDiagnostics()` - Check FCM setup status
- `hasToken` getter - Check if token is available

## Verification Checklist

### ✅ Configuration Files
- [x] `google-services.json` exists at `android/app/google-services.json`
- [x] Google Services plugin configured in `build.gradle.kts`
- [x] Firebase Messaging Service declared in `AndroidManifest.xml`
- [x] `POST_NOTIFICATIONS` permission declared in `AndroidManifest.xml`
- [x] Notification channels created in `MainActivity.kt`

### ✅ Code Implementation
- [x] Platform-specific code separates Android and iOS (no APNS code on Android)
- [x] Token retrieval happens during initialization
- [x] Token is saved after authentication
- [x] Token refresh listener is registered
- [x] Background message handler is registered

## Testing Steps

### 1. Test Token Retrieval on Fresh Install
```dart
// Check diagnostics
final diagnostics = await FCMService().getDiagnostics();
print('FCM Diagnostics: $diagnostics');

// Check if token exists
if (FCMService().hasToken) {
  print('Token: ${FCMService().token}');
} else {
  print('No token - attempting retry...');
  await FCMService().retryTokenRetrieval();
}
```

### 2. Test Token After Login
1. Install app fresh (or clear app data)
2. Login with credentials
3. Check logs for:
   - `✅ FCM Token retrieved successfully (Android)`
   - `✅ FCM token saved to backend successfully`

### 3. Test Token Refresh
1. Uninstall and reinstall app (triggers token refresh)
2. Login
3. Verify new token is saved to backend

### 4. Test Notification Permissions
1. Deny notification permissions when prompted
2. Verify token is still retrieved (permissions not required for token)
3. Grant permissions later - notifications should work

## Debugging

### Check Logs for These Messages

**Success Indicators:**
- `✅ FCM Token retrieved successfully (Android): ...`
- `✅ FCM token saved to backend successfully`
- `✅ FCM Service initialized`

**Warning Indicators:**
- `⚠️ FCM Token is null or empty on Android` - Firebase config issue
- `⚠️ User not authenticated, storing FCM token for later` - Normal, will save after login
- `⚠️ Error getting FCM token on Android` - Check Firebase config

**Error Indicators:**
- `❌ Failed to retrieve FCM token after 3 attempts` - Firebase setup issue
- `❌ Error saving FCM token to backend` - Backend/network issue

### Common Issues and Solutions

#### Issue: Token is null
**Possible causes:**
1. `google-services.json` missing or incorrect
2. Firebase project not configured correctly
3. Network connectivity issue
4. Device/emulator Firebase setup issue

**Solution:**
- Verify `google-services.json` exists and matches Firebase project
- Check Firebase Console for correct package name
- Ensure device has internet connection
- Try `retryTokenRetrieval()` method

#### Issue: Token retrieved but not saved
**Possible causes:**
1. User not authenticated
2. Backend endpoint error
3. Network error

**Solution:**
- Token will be saved automatically after login
- Check backend logs for errors
- Verify `/users/fcm-token` endpoint is working

#### Issue: Notifications not received
**Possible causes:**
1. Token not saved to backend
2. Notification permissions denied (Android 13+)
3. App in foreground without local notification handling
4. Backend not sending to correct token

**Solution:**
- Verify token in backend database
- Check notification permissions
- Verify foreground notification handling
- Check backend notification sending logic

## Code Changes Summary

### Modified Files
1. `lib/services/fcm_service.dart`
   - Added `_retrieveAndroidToken()` method with retry logic
   - Enhanced `savePendingToken()` to retrieve token if missing
   - Improved `_saveTokenToBackend()` error handling
   - Added `retryTokenRetrieval()` and `getDiagnostics()` methods

### Unchanged Files (Verified Correct)
1. `android/app/src/main/AndroidManifest.xml` - ✅ Correct
2. `android/app/build.gradle.kts` - ✅ Correct
3. `android/app/google-services.json` - ✅ Present
4. `android/app/src/main/kotlin/.../MainActivity.kt` - ✅ Correct
5. `android/app/src/main/kotlin/.../MyFirebaseMessagingService.kt` - ✅ Correct

## Next Steps

1. **Test on physical Android device** - Verify token retrieval works
2. **Monitor server logs** - Check for successful token saves
3. **Test notifications** - Send test notification to verify delivery
4. **Monitor user reports** - Check if issue is resolved

## API Endpoint

The app sends FCM tokens to:
```
POST /api/users/fcm-token
Authorization: Bearer <auth_token>
Body: { "fcmToken": "<token>" }
```

Backend saves token to user document in MongoDB.

