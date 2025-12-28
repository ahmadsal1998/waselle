# iOS Production Push Notifications Fix - APNS Authentication

## Issue Summary

**Error:** `APNS Authentication Error` - `messaging/third-party-auth-error`  
**Symptom:** Notifications work in Xcode (Sandbox) but fail in App Store/TestFlight (Production)  
**Root Cause:** Firebase Console is missing APNS Authentication Key for Production environment

## Quick Fix Steps

### Step 1: Get APNS Authentication Key from Apple Developer Portal

1. **Go to Apple Developer Portal:**
   - Visit: https://developer.apple.com/account/resources/authkeys/list
   - Sign in with your Apple Developer account

2. **Create or Use Existing APNS Key:**
   - Click the **"+"** button to create a new key
   - Give it a name (e.g., "Wassle APNS Production Key")
   - Check **"Apple Push Notifications service (APNs)"**
   - Click **"Continue"** then **"Register"**
   - **Download the `.p8` file** (⚠️ You can only download it once!)
   - **Note the Key ID** (10-character string, e.g., `ABC123DEF4`)

3. **Get Your Team ID:**
   - In Apple Developer Portal, go to **Membership** section
   - Find your **Team ID** (10-character string, e.g., `P3F2N88NJF`)

### Step 2: Upload APNS Key to Firebase Console

#### For User App (`com.wassle.userapp`)

1. **Go to Firebase Console:**
   - Visit: https://console.firebase.google.com/
   - Select your project

2. **Navigate to Cloud Messaging:**
   - Go to **Project Settings** (gear icon ⚙️)
   - Click on **"Cloud Messaging"** tab

3. **Configure APNS for User App:**
   - Scroll down to **"Apple app configuration"** section
   - Find your iOS app with bundle ID: **`com.wassle.userapp`**
   - Click **"Upload"** under **"APNs Authentication Key"**

4. **Upload the Key:**
   - **Key ID**: Enter the Key ID from Step 1 (e.g., `ABC123DEF4`)
   - **Upload .p8 file**: Upload the `.p8` file you downloaded
   - Click **"Upload"**

#### For Driver App (`com.wassle.driverapp`)

1. **Repeat the same steps above** but for the driver app:
   - Find iOS app with bundle ID: **`com.wassle.driverapp`**
   - Upload the **same APNS Authentication Key** (one key works for all apps)

### Step 3: Verify Configuration

After uploading:

1. **Check Firebase Console:**
   - The APNS configuration should show as **"Configured"** ✅
   - You should see your Key ID listed
   - Both apps (`com.wassle.userapp` and `com.wassle.driverapp`) should show APNS as configured

2. **Wait 2-5 minutes:**
   - Firebase may take a few minutes to propagate the configuration

3. **Test Notification:**
   - Install app from TestFlight or App Store (NOT Xcode)
   - Grant notification permissions
   - Send a test notification from your backend
   - The error should be resolved ✅

## Why This Happens

### Development vs Production APNs

- **Xcode Builds (Sandbox):**
  - Use APNS Development/Sandbox environment
  - Works even without production APNS key configured
  - This is why notifications work when running from Xcode

- **App Store / TestFlight (Production):**
  - Use APNS Production environment
  - **Requires** APNS Authentication Key or Production Certificate in Firebase Console
  - This is why notifications fail in production builds

### APNS Authentication Key vs Certificate

**APNS Authentication Key (.p8) - RECOMMENDED:**
- ✅ Works for both Development and Production
- ✅ Doesn't expire (certificates expire annually)
- ✅ One key works for all your apps
- ✅ Easier to manage

**APNS Certificate (.p12) - NOT RECOMMENDED:**
- ❌ Separate certificates needed for Development and Production
- ❌ Expires annually (must be renewed)
- ❌ App-specific (need one per app)
- ❌ More complex to manage

## Verification Checklist

### Firebase Console Configuration

- [ ] APNS Authentication Key created in Apple Developer Portal
- [ ] `.p8` file downloaded and saved securely
- [ ] Key ID noted (10-character string)
- [ ] Key uploaded to Firebase Console for `com.wassle.userapp`
- [ ] Key uploaded to Firebase Console for `com.wassle.driverapp`
- [ ] Both apps show APNS as "Configured" in Firebase Console
- [ ] Bundle IDs match exactly:
  - User app: `com.wassle.userapp`
  - Driver app: `com.wassle.driverapp`

### App Configuration

- [ ] User app AppDelegate.swift has notification registration (✅ Already fixed)
- [ ] Driver app AppDelegate.swift has notification registration (✅ Already fixed)
- [ ] Both apps have `UIBackgroundModes` with `remote-notification` in Info.plist
- [ ] Both apps have Push Notifications capability enabled in Xcode

### Testing

- [ ] App installed from TestFlight (NOT Xcode)
- [ ] Notification permissions granted
- [ ] FCM token generated and saved to backend
- [ ] Test notification sent from backend
- [ ] Notification received successfully ✅
- [ ] No `APNS Authentication Error` in backend logs

## Troubleshooting

### Error Still Persists After Configuration

1. **Wait a few minutes:**
   - Firebase may take 2-5 minutes to propagate the configuration
   - Try sending a notification again after waiting

2. **Verify Key Upload:**
   - Go back to Firebase Console → Cloud Messaging
   - Make sure the key is listed and shows as "Active"
   - Check that both apps show APNS as configured

3. **Check Bundle ID:**
   - Ensure bundle IDs match exactly (case-sensitive)
   - No extra spaces or characters
   - User app: `com.wassle.userapp`
   - Driver app: `com.wassle.driverapp`

4. **Verify App Installation:**
   - Make sure you're testing with an app installed from TestFlight or App Store
   - Xcode builds use Sandbox APNs (different environment)
   - Production APNs only works with App Store/TestFlight builds

5. **Check Backend Logs:**
   - Look for `APNS Authentication Error` messages
   - If still seeing errors, Firebase Console configuration may not be complete
   - Verify the key was uploaded correctly

6. **Regenerate Key (if needed):**
   - If the key was downloaded before and lost, create a new one
   - Old keys might have been revoked
   - Upload the new key to Firebase Console

### Key ID Not Found

- The Key ID is shown when you create the key in Apple Developer Portal
- If you lost it, you'll need to create a new key (old one can't be retrieved)
- The Key ID is a 10-character string (e.g., `ABC123DEF4`)

### .p8 File Lost

- You can only download the `.p8` file once from Apple Developer Portal
- If lost, create a new APNS Authentication Key
- Upload the new key to Firebase Console

### Wrong Bundle ID

- Verify bundle IDs in Firebase Console match your app exactly:
  - User app: `com.wassle.userapp`
  - Driver app: `com.wassle.driverapp`
- Check Xcode project settings:
  - User app: `ios/Runner.xcodeproj` → Build Settings → `PRODUCT_BUNDLE_IDENTIFIER`
  - Driver app: `ios/Runner.xcodeproj` → Build Settings → `PRODUCT_BUNDLE_IDENTIFIER`

## Backend Error Handling

The backend code already handles this error gracefully and logs helpful messages:

```typescript
// backend/src/services/notificationService.ts (lines 130-143)
if (error.code === 'messaging/third-party-auth-error') {
  console.error(`❌ APNS Authentication Error`);
  console.error(`   ⚠️  ACTION REQUIRED: Configure APNS in Firebase Console`);
  // ... detailed instructions logged
}
```

After fixing Firebase Console configuration, these errors should stop appearing.

## Security Notes

- **Never commit** `.p8` files to version control
- Store them securely (password manager, secure storage)
- Rotate keys periodically for security
- One key can be used for multiple apps (recommended approach)

## Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Apple Push Notification Service Documentation](https://developer.apple.com/documentation/usernotifications)
- [APNS Authentication Key Setup](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns)
- [Firebase APNS Configuration Guide](https://firebase.google.com/docs/cloud-messaging/ios/certs)

## Summary

**The fix is simple:** Upload the APNS Authentication Key (.p8) to Firebase Console for both apps. The code is already correctly configured - this is purely a Firebase Console configuration issue.

**Bundle IDs:**
- User app: `com.wassle.userapp`
- Driver app: `com.wassle.driverapp`

**Action Required:**
1. Get APNS Authentication Key from Apple Developer Portal
2. Upload to Firebase Console → Cloud Messaging → Apple app configuration
3. Upload for both apps (same key works for both)
4. Wait 2-5 minutes for propagation
5. Test with TestFlight/App Store build (NOT Xcode)

---

**Status:** ✅ Code is correctly configured - Firebase Console configuration needed

