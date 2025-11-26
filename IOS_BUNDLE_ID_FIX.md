# iOS Bundle ID Fix - Apple Developer Portal Issue

## Problem Identified

The main Runner target in the Xcode project had an **incorrect bundle identifier** set to `com.wassle.userapp.RunnerTests` (test bundle ID) instead of `com.wassle.userapp` (main app bundle ID).

This caused Apple Developer portal to reject the App ID creation because:
- Test bundle IDs cannot be used as main app bundle IDs
- Apple requires test bundle IDs to be sub-identifiers of the main app (e.g., `com.wassle.userapp.RunnerTests` must be a child of `com.wassle.userapp`)

## What Was Fixed

### User App (`user-app`)
Fixed the bundle identifier in all three build configurations:
- ✅ **Debug**: Changed from `com.wassle.userapp.RunnerTests` → `com.wassle.userapp`
- ✅ **Release**: Changed from `com.wassle.userapp.RunnerTests` → `com.wassle.userapp`
- ✅ **Profile**: Changed from `com.wassle.userapp.RunnerTests` → `com.wassle.userapp`

### Driver App (`driver-app`)
✅ Already correctly configured with `com.wassle.driverapp`

## Next Steps

### 1. Clean and Rebuild the Project

```bash
cd user-app/ios
rm -rf Pods Podfile.lock
pod install
cd ../..
flutter clean
flutter pub get
```

### 2. Verify Bundle ID in Xcode

1. Open `user-app/ios/Runner.xcworkspace` in Xcode
2. Select the **Runner** target (not RunnerTests)
3. Go to **Signing & Capabilities** tab
4. Verify **Bundle Identifier** shows: `com.wassle.userapp`
5. Verify **Team** is set correctly

### 3. Create App ID in Apple Developer Portal

Now you should be able to create the App ID:

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list)
2. Click **+** to create a new App ID
3. Select **App** type
4. Enter:
   - **Description**: Wassle User App
   - **Bundle ID**: Select **Explicit** and enter `com.wassle.userapp`
5. Enable **Push Notifications** capability
6. Click **Continue** and **Register**

### 4. Configure Push Notifications

1. After creating the App ID, click on it
2. Enable **Push Notifications** if not already enabled
3. Click **Configure** next to Push Notifications
4. Upload your APNs Authentication Key (.p8 file) or create a new one
5. Enter your **Team ID** and **Key ID**
6. Click **Save**

### 5. Verify Firebase Configuration

The Firebase iOS app is already configured with bundle ID `com.wassle.userapp`:
- Firebase App ID: `1:365868224840:ios:9105168c03354feed1237d`
- Bundle ID: `com.wassle.userapp`

Make sure the APNs Authentication Key is uploaded in Firebase Console:
1. Go to [Firebase Console](https://console.firebase.google.com/project/wae-679cc/settings/cloudmessaging)
2. Under **Apple app configuration**, verify:
   - APNs Authentication Key (.p8) is uploaded
   - Key ID is set
   - Team ID is set

### 6. Test Push Notifications

After completing the above steps:

1. Build and run the app on a physical iOS device (push notifications don't work on simulator)
2. The app should now be able to:
   - Get APNs token
   - Register for push notifications
   - Receive FCM messages

## Troubleshooting

### If you still get "App ID not available" error:

1. **Check if the bundle ID already exists**:
   - Go to Apple Developer Portal → Identifiers
   - Search for `com.wassle.userapp`
   - If it exists, check which account/team it belongs to

2. **Verify Team ID matches**:
   - In Xcode, check the Development Team matches your Apple Developer account
   - Current Team ID in project: `P3F2N88NJF`

3. **Check bundle ID format**:
   - Must be reverse domain notation: `com.wassle.userapp`
   - No spaces or special characters
   - All lowercase

4. **Try a different bundle ID** (if needed):
   - If `com.wassle.userapp` is truly unavailable, you may need to use a different one
   - Example: `com.wassle.userapp.ios` or `com.wassle.userapp.mobile`
   - **Note**: If you change it, you'll need to update:
     - Xcode project bundle identifier
     - Firebase iOS app bundle ID
     - GoogleService-Info.plist

## Summary

✅ **Fixed**: Bundle identifier corrected from test ID to main app ID  
✅ **Status**: Ready to create App ID in Apple Developer Portal  
✅ **Next**: Create App ID, enable Push Notifications, and test

The bundle identifier is now correctly set to `com.wassle.userapp` and should work in Apple Developer Portal.

