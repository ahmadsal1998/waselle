# App Store Submission Setup - Summary

This document summarizes all the changes made to prepare the Driver App for Apple App Store submission with Production push notifications.

## Changes Made

### 1. ✅ iOS Entitlements File Created
**File**: `ios/Runner/Runner.entitlements`
- Created entitlements file with `aps-environment: production`
- Required for push notifications to work in Production/App Store builds
- Added to Xcode project configuration

### 2. ✅ AppDelegate Updated
**File**: `ios/Runner/AppDelegate.swift`
- Added `UserNotifications` import
- Added APNs token registration methods
- Registers for remote notifications on app launch
- Handles APNs token registration success/failure

### 3. ✅ FCM Service Modified
**File**: `lib/services/fcm_service.dart`
- **CRITICAL**: Notifications are now **DISABLED in debug mode**
- Notifications only work in Release/Production builds
- This ensures production notifications are properly tested before release
- Debug builds will show a warning message that notifications are disabled

### 4. ✅ Xcode Project Updated
**File**: `ios/Runner.xcodeproj/project.pbxproj`
- Added entitlements file reference
- Added `CODE_SIGN_ENTITLEMENTS` to all build configurations (Debug, Release, Profile)
- Entitlements file properly linked to the project

### 5. ✅ Documentation Created
**Files**:
- `APP_STORE_SUBMISSION_GUIDE.md` - Comprehensive step-by-step guide
- `QUICK_SUBMISSION_CHECKLIST.md` - Quick reference checklist
- `scripts/build-ios-release.sh` - Build script for release
- `scripts/upload-to-appstore.sh` - Upload helper script

## Key Features

### Push Notifications Configuration

1. **Production Only**: Notifications only work in Release builds
   - Debug builds: Notifications disabled (prevents accidental production notifications)
   - Release builds: Notifications enabled (Production APNs)

2. **APNs Configuration**: 
   - Entitlements file set to `production`
   - AppDelegate registers for remote notifications
   - FCM service handles APNs token properly

3. **TestFlight Ready**: 
   - TestFlight builds use Production APNs
   - Best way to test notifications before App Store release

## Next Steps

### 1. Verify APNs Configuration in Firebase
- Go to Firebase Console → Project Settings → Cloud Messaging
- Verify APNs Authentication Key or Certificate is uploaded
- Ensure it's configured for `com.wassle.driverapp`

### 2. Verify Code Signing
```bash
cd driver-app/ios
open Runner.xcworkspace
```
- In Xcode: Runner → Signing & Capabilities
- Verify Team is selected
- Verify Provisioning Profile is valid
- Verify Push Notifications capability is enabled

### 3. Build and Test
```bash
cd driver-app
./scripts/build-ios-release.sh
```
Or manually:
```bash
flutter clean
flutter pub get
flutter build ios --release
cd ios && open Runner.xcworkspace
```

### 4. Create Archive in Xcode
1. Open `Runner.xcworkspace` in Xcode
2. Select Product → Destination → Any iOS Device (arm64)
3. Select Product → Archive
4. Wait for archive to complete

### 5. Upload to App Store Connect
1. In Xcode Organizer, select your archive
2. Click "Distribute App"
3. Select "App Store Connect"
4. Follow the prompts to upload

### 6. Test in TestFlight
1. Wait for processing (10-30 minutes)
2. Install app from TestFlight
3. **Test push notifications** - this is critical!
4. Verify all features work correctly

### 7. Submit for Review
1. Complete App Store listing information
2. Select build for submission
3. Submit for review

## Important Notes

⚠️ **Debug vs Release**:
- Debug builds: Notifications disabled (by design)
- Release builds: Notifications enabled (Production APNs)
- TestFlight: Uses Production APNs (best for testing)

⚠️ **APNs Environment**:
- Must be set to `production` in entitlements file
- This is already configured

⚠️ **Build Numbers**:
- Each App Store submission requires a unique build number
- Format: `VERSION+BUILD_NUMBER` (e.g., `1.0.2+3`)
- Increment build number for each new submission

## Files Modified

1. `ios/Runner/Runner.entitlements` - **NEW** - Push notifications entitlements
2. `ios/Runner/AppDelegate.swift` - **MODIFIED** - APNs registration
3. `lib/services/fcm_service.dart` - **MODIFIED** - Debug mode check
4. `ios/Runner.xcodeproj/project.pbxproj` - **MODIFIED** - Entitlements configuration

## Files Created

1. `APP_STORE_SUBMISSION_GUIDE.md` - Comprehensive guide
2. `QUICK_SUBMISSION_CHECKLIST.md` - Quick checklist
3. `scripts/build-ios-release.sh` - Build script
4. `scripts/upload-to-appstore.sh` - Upload script
5. `SUBMISSION_SETUP_SUMMARY.md` - This file

## Testing Push Notifications

### In Debug Mode (Notifications Disabled)
- App will show warning: "FCM Service: Running in DEBUG mode - Push notifications are DISABLED"
- This is expected behavior

### In Release Mode (Notifications Enabled)
1. Build with: `flutter build ios --release`
2. Install on device
3. Log in to app
4. Verify FCM token is generated
5. Send test notification from backend
6. Verify notification is received

### In TestFlight (Best for Testing)
1. Upload build to App Store Connect
2. Install from TestFlight
3. Test notifications in all states:
   - App in foreground
   - App in background
   - App terminated
4. Verify notification tap navigation works

## Troubleshooting

### Notifications Not Working
1. Verify APNs is configured in Firebase Console
2. Verify entitlements file has `aps-environment: production`
3. Verify app is built with Release configuration
4. Check FCM token is generated (check app logs)
5. Verify backend is sending to correct FCM token

### Build Errors
- See `APP_STORE_SUBMISSION_GUIDE.md` → Troubleshooting section

### Upload Errors
- See `APP_STORE_SUBMISSION_GUIDE.md` → Troubleshooting section

## Support

For detailed instructions, see:
- `APP_STORE_SUBMISSION_GUIDE.md` - Full step-by-step guide
- `QUICK_SUBMISSION_CHECKLIST.md` - Quick reference

---

**Setup Complete! 🎉**

You're now ready to build and submit your app to the App Store. Follow the steps in `APP_STORE_SUBMISSION_GUIDE.md` for detailed instructions.

