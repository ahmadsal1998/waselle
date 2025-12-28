# iOS Production Notifications Fix - Complete Checklist

## Issue
Notifications work in Xcode but not in App Store/TestFlight.

## Root Cause Found
**The user-app AppDelegate.swift was missing notification registration code** that is required for production builds.

## ✅ Fixes Applied

### 1. User App AppDelegate.swift
- ✅ **FIXED**: Added `UserNotifications` import
- ✅ **FIXED**: Added notification center delegate setup
- ✅ **FIXED**: Added `application.registerForRemoteNotifications()` call
- ✅ **FIXED**: Added APNs token registration handlers

The driver-app already had this code, which is why it was working.

## 🔍 Verification Checklist

### iOS App Configuration

#### 1. Entitlements Files
- ✅ **user-app/ios/Runner/Runner.entitlements**: `aps-environment` = `production`
- ✅ **driver-app/ios/Runner/Runner.entitlements**: `aps-environment` = `production`

**Verification:**
```bash
# Check entitlements
grep -A 2 "aps-environment" user-app/ios/Runner/Runner.entitlements
grep -A 2 "aps-environment" driver-app/ios/Runner/Runner.entitlements
```

#### 2. Info.plist Files
- ✅ **user-app/ios/Runner/Info.plist**: Contains `UIBackgroundModes` with `remote-notification`
- ✅ **driver-app/ios/Runner/Info.plist**: Contains `UIBackgroundModes` with `remote-notification`

**Verification:**
```bash
# Check Info.plist
grep -A 3 "UIBackgroundModes" user-app/ios/Runner/Info.plist
grep -A 3 "UIBackgroundModes" driver-app/ios/Runner/Info.plist
```

#### 3. AppDelegate.swift Files
- ✅ **user-app/ios/Runner/AppDelegate.swift**: **NOW FIXED** - Has notification registration
- ✅ **driver-app/ios/Runner/AppDelegate.swift**: Already had notification registration

**Verification:**
```bash
# Check AppDelegate
grep -n "registerForRemoteNotifications" user-app/ios/Runner/AppDelegate.swift
grep -n "registerForRemoteNotifications" driver-app/ios/Runner/AppDelegate.swift
```

#### 4. Bundle IDs
- ✅ **user-app**: `com.wassle.userapp` (verify matches App Store Connect)
- ✅ **driver-app**: `com.wassle.driverapp` (verify matches App Store Connect)

**Verification:**
```bash
# Check Bundle IDs
grep "PRODUCT_BUNDLE_IDENTIFIER" user-app/ios/Runner.xcodeproj/project.pbxproj | grep Release
grep "PRODUCT_BUNDLE_IDENTIFIER" driver-app/ios/Runner.xcodeproj/project.pbxproj | grep Release
```

### Backend Configuration

#### 5. APNs Configuration in Backend
- ✅ **Backend services** use Firebase Admin SDK with proper APNs headers
- ✅ **APNs headers** include `apns-priority: '10'` and `apns-push-type: 'alert'`

**Location:** `backend/src/services/notificationService.ts` and `backend/src/services/fcmService.ts`

**Note:** Firebase Admin SDK automatically determines production vs sandbox based on the app's provisioning profile. However, you must ensure Firebase Console is configured correctly (see below).

#### 6. Server Sending to Production APNs
- ✅ **Backend code** correctly configured (Firebase handles APNs endpoint automatically)
- ⚠️ **ACTION REQUIRED**: Verify Firebase Console has production APNs key/certificate

### Firebase Console Configuration

#### 7. Firebase Console - APNs Configuration
⚠️ **CRITICAL**: You must verify this in Firebase Console:

1. **Go to Firebase Console** → Your Project → Project Settings → Cloud Messaging
2. **Under "Apple app configuration"**:
   - ✅ Check that **APNS Authentication Key** is uploaded (recommended for production)
   - OR **APNS Certificate** is uploaded (less preferred, but works)
   - ✅ Ensure **Bundle ID** matches your app's Bundle ID exactly:
     - User app: `com.wassle.userapp`
     - Driver app: `com.wassle.driverapp`
   - ✅ Ensure the key/certificate is for **Production APNs** (not Development/Sandbox)

**How to verify:**
- If you uploaded an APNS Authentication Key (.p8 file), it works for both development and production
- If you uploaded an APNS Certificate (.p12 file), ensure it's the **Production** certificate, not the Development certificate

**Common Issues:**
- ❌ Development APNS certificate uploaded instead of Production
- ❌ Wrong Bundle ID configured in Firebase Console
- ❌ APNS key/certificate expired or revoked
- ❌ APNS key doesn't have Push Notifications capability enabled

#### 8. Firebase Console - App Configuration
Verify both apps are properly configured:
- ✅ User app (`com.wassle.userapp`) exists in Firebase Console
- ✅ Driver app (`com.wassle.driverapp`) exists in Firebase Console
- ✅ Both have `GoogleService-Info.plist` files in the iOS project

### Xcode Configuration

#### 9. Push Notifications Capability
In Xcode, verify:
- ✅ Open `user-app/ios/Runner.xcworkspace` in Xcode
- ✅ Select **Runner** target → **Signing & Capabilities** tab
- ✅ Verify **Push Notifications** capability is enabled
- ✅ Verify **Background Modes** capability is enabled with:
  - ✅ Remote notifications (checked)
  - ✅ Background fetch (if needed)

- ✅ Repeat for `driver-app/ios/Runner.xcworkspace`

**How to verify in Xcode:**
1. Open the `.xcworkspace` file (NOT `.xcodeproj`)
2. Select Runner target
3. Go to "Signing & Capabilities"
4. Check that "Push Notifications" appears in the list
5. Check that "Background Modes" appears with "Remote notifications" checked

#### 10. Code Signing & Provisioning Profiles
- ✅ **Development Team** set correctly (P3F2N88NJF)
- ✅ **Provisioning Profile** for Release builds is an **App Store** or **Ad Hoc** profile (NOT Development)
- ✅ Provisioning profile includes **Push Notifications** entitlement

**How to verify:**
1. In Xcode, select Runner target → Signing & Capabilities
2. For Release configuration, check that "Automatically manage signing" is enabled OR
3. If manual, ensure Release provisioning profile is for App Store distribution

### Testing Checklist

#### 11. TestFlight Testing
After deploying to TestFlight:

1. ✅ **Install app from TestFlight** (not Xcode)
2. ✅ **Grant notification permissions** when prompted
3. ✅ **Verify FCM token** is generated and sent to backend
4. ✅ **Test notification** from backend
5. ✅ **Check device logs** for APNs registration success/failure

**How to check logs:**
```bash
# On Mac, connect iPhone and view console logs
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "Wassle"'
```

Or in Xcode: Window → Devices and Simulators → Select device → Open Console

**Look for:**
- ✅ "Successfully registered for remote notifications"
- ✅ "APNs token received: ..."
- ❌ Any errors about "Failed to register for remote notifications"

#### 12. Backend Logs
Check backend logs when sending notifications:
- ✅ Look for `✅ Push notification sent successfully`
- ❌ If you see `APNS Authentication Error`, Firebase Console APNs configuration is wrong
- ❌ If you see `invalid-registration-token`, the FCM token is invalid

## 📋 Summary of Changes Made

1. ✅ **FIXED**: Added notification registration to `user-app/ios/Runner/AppDelegate.swift`
   - Added `UserNotifications` import
   - Added `UNUserNotificationCenter.current().delegate = self`
   - Added `application.registerForRemoteNotifications()`
   - Added APNs token registration handlers

## 🚀 Next Steps

1. **Rebuild the app** for Release/App Store distribution
2. **Verify all checklist items** above
3. **Test in TestFlight** (not Xcode) to ensure notifications work
4. **Check Firebase Console** APNs configuration if notifications still fail

## 🔧 Troubleshooting

### If notifications still don't work in TestFlight:

1. **Check Firebase Console APNs configuration**
   - Most common issue: Wrong APNs certificate or missing APNs key
   - Solution: Upload production APNS Authentication Key (.p8) to Firebase Console

2. **Verify Bundle ID matches everywhere**
   - Firebase Console Bundle ID
   - Xcode Bundle Identifier
   - App Store Connect Bundle ID
   - All must match exactly: `com.wassle.userapp` or `com.wassle.driverapp`

3. **Check backend logs for errors**
   - Look for APNs authentication errors
   - Look for invalid token errors

4. **Verify device token registration**
   - Check that FCM token is saved in database after installing from TestFlight
   - Token should be different from Xcode build tokens

5. **Test with production APNs certificate directly**
   - Use a tool like Pusher or similar to test APNs directly
   - Verify the device token works with production APNs endpoint

## 📝 Notes

- **Xcode builds** use Development APNs automatically (even Release builds if run from Xcode)
- **TestFlight/App Store builds** use Production APNs
- **Firebase Admin SDK** automatically routes to correct APNs endpoint based on app provisioning
- **APNS Authentication Key (.p8)** works for both development and production (recommended)
- **APNS Certificate (.p12)** must match the environment (development vs production)

