# FCM Token Reinstallation Fix

## Problem
After reinstalling the driver app, push notifications were not being received because:
1. The old FCM token stored on the backend was invalid after reinstallation
2. The new FCM token wasn't being generated or synced to the backend immediately after login
3. Server logs showed "Invalid FCM token for user <driver_id>, removing token"

## Solution
Implemented comprehensive FCM token management to ensure tokens are always generated and synced after app reinstallation.

## Changes Made

### 1. Enhanced FCM Service (`driver-app/lib/services/fcm_service.dart`)

#### Added Methods:
- **`_retrieveIOSTokenWithRetry()`**: Retrieves iOS FCM token with retry logic and exponential backoff
- **`forceRefreshAndSyncToken()`**: Forces a fresh token retrieval and syncs to backend

#### Enhanced Methods:
- **`savePendingToken()`**: 
  - Now forces a fresh token retrieval after authentication
  - Includes retry logic with up to 5 attempts
  - Handles both Android and iOS platforms
  - Automatically retries if token retrieval fails
  
- **`_saveTokenToBackend()`**: 
  - Now returns `bool` to indicate success/failure
  - Better error handling and retry logic

#### Key Features:
- Token refresh flags stored in SharedPreferences (`needs_fcm_token_refresh`)
- Automatic retry with exponential backoff
- Platform-specific token retrieval (Android vs iOS)
- Handles cases where Firebase isn't fully initialized yet

### 2. Updated AuthViewModel (`driver-app/lib/view_models/auth_view_model.dart`)

#### Changes:
- After successful login, forces FCM token refresh and sync
- Uses `forceRefreshAndSyncToken()` to ensure latest token is retrieved
- Falls back to `savePendingToken()` if needed
- Small delay (500ms) to ensure Firebase is fully ready

### 3. Updated Main App (`driver-app/lib/main.dart`)

#### Changes:
- `AuthWrapper` converted to `StatefulWidget` to track FCM token check status
- On app launch, if user is already authenticated:
  - Checks for `needs_fcm_token_refresh` flag
  - Checks for pending FCM token
  - Verifies token is synced or forces refresh
  - Handles app reinstallation scenarios

## How It Works

### After App Reinstallation:

1. **App Launch**:
   - FCM service initializes and attempts to retrieve token
   - If token retrieval fails or user isn't authenticated, token is stored as `pending_fcm_token`
   - Flag `needs_fcm_token_refresh` may be set

2. **User Login**:
   - After successful login, `AuthViewModel` triggers token refresh
   - `forceRefreshAndSyncToken()` is called to get fresh token
   - Token is immediately synced to backend via `/users/fcm-token` endpoint
   - Any pending tokens are cleared

3. **App Launch (Already Authenticated)**:
   - `AuthWrapper` checks if token needs refresh
   - If flag is set or pending token exists, refreshes and syncs
   - Even if no flag, verifies token is synced

### Token Refresh Flow:

```
App Reinstallation
    ↓
Firebase Initialization
    ↓
Token Retrieval Attempt
    ↓
[If Failed] Store Flag + Pending Token
    ↓
User Login
    ↓
Force Token Refresh (with retry)
    ↓
Sync to Backend
    ↓
Clear Flags + Pending Token
    ↓
✅ Notifications Working
```

## Testing

### Test Scenario 1: Fresh Installation
1. Uninstall the driver app
2. Reinstall the driver app
3. Login with driver credentials
4. **Expected**: FCM token should be generated and synced immediately after login
5. Create a test order from user app
6. **Expected**: Driver should receive push notification

### Test Scenario 2: App Already Installed
1. Open driver app (already logged in)
2. **Expected**: Token should be verified/synced on app launch
3. Create a test order
4. **Expected**: Driver should receive push notification

### Test Scenario 3: Token Refresh
1. Login to driver app
2. Force stop the app
3. Clear app data (simulating reinstallation)
4. Reopen app and login
5. **Expected**: New token should be generated and synced
6. Create a test order
7. **Expected**: Driver should receive push notification

## Debugging

### Check FCM Token Status:
```dart
final diagnostics = await FCMService().getDiagnostics();
print('FCM Diagnostics: $diagnostics');
```

### Manual Token Refresh:
```dart
await FCMService().forceRefreshAndSyncToken();
```

### Check Logs:
Look for these log messages:
- `📱 Starting FCM token sync after authentication...`
- `🔄 Forcing FCM token refresh after authentication...`
- `✅ FCM token synced to backend successfully`
- `❌ Error saving FCM token to backend` (indicates issue)

## Backend Compatibility

The backend endpoint `/users/fcm-token` (POST) expects:
```json
{
  "fcmToken": "string"
}
```

The backend will:
- Update the user's `fcmToken` field
- Remove invalid tokens automatically when sending notifications fails
- Log "Invalid FCM token for user <driver_id>, removing token" when token is invalid

## Notes

- Token retrieval may take a few seconds, especially on iOS
- Retry logic uses exponential backoff (2s, 4s, 6s, etc.)
- Tokens are stored in SharedPreferences for retry scenarios
- The fix handles both Android and iOS platforms separately
- Token refresh happens automatically, no manual intervention needed

## Future Improvements

1. **Notification Queue**: Queue notifications for drivers without valid tokens until token is synced
2. **Token Validation**: Periodically validate token with Firebase
3. **Background Sync**: Sync token in background periodically
4. **Analytics**: Track token sync success/failure rates

