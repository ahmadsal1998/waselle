# APNS (Apple Push Notification Service) Setup Guide

This guide explains how to fix the "Auth error from APNS" error when sending push notifications to iOS devices.

## Error Message

```
❌ Error sending push notification: Auth error from APNS or Web Push Service
Error code: messaging/third-party-auth-error
```

## Root Cause

This error occurs when Firebase Admin SDK cannot authenticate with Apple's APNS service. This is a **Firebase Console configuration issue**, not a code issue.

## Solution: Configure APNS in Firebase Console

### Step 1: Get Your APNS Authentication Key

You need an APNS Authentication Key from Apple Developer Portal:

1. **Go to Apple Developer Portal:**
   - Visit: https://developer.apple.com/account/resources/authkeys/list
   - Sign in with your Apple Developer account

2. **Create or Use Existing APNS Key:**
   - Click the **"+"** button to create a new key
   - Give it a name (e.g., "Wassle APNS Key")
   - Check **"Apple Push Notifications service (APNs)"**
   - Click **"Continue"** then **"Register"**
   - **Download the `.p8` file** (you can only download it once!)
   - **Note the Key ID** (you'll need this)

3. **Get Your Team ID:**
   - In Apple Developer Portal, go to **Membership** section
   - Find your **Team ID** (10-character string)

### Step 2: Upload APNS Key to Firebase Console

1. **Go to Firebase Console:**
   - Visit: https://console.firebase.google.com/
   - Select your project

2. **Navigate to Cloud Messaging:**
   - Go to **Project Settings** (gear icon)
   - Click on **"Cloud Messaging"** tab

3. **Configure APNS:**
   - Scroll down to **"Apple app configuration"** section
   - Find your iOS app (bundle ID: `com.wassle.userapp`)
   - Click **"Upload"** under **"APNs Authentication Key"**

4. **Upload the Key:**
   - **Key ID**: Enter the Key ID from Step 1
   - **Upload .p8 file**: Upload the `.p8` file you downloaded
   - Click **"Upload"**

### Alternative: Using APNS Certificate (Not Recommended)

If you prefer using a certificate instead of an authentication key:

1. **Generate APNS Certificate:**
   - Go to Apple Developer Portal → Certificates
   - Create a new certificate for "Apple Push Notification service SSL"
   - Download and install it on your Mac
   - Export it as `.p12` file

2. **Upload to Firebase:**
   - In Firebase Console → Cloud Messaging
   - Upload the `.p12` certificate
   - Enter the certificate password

**Note:** APNS Authentication Key is recommended because:
- It doesn't expire (certificates expire annually)
- Works for all your apps (certificates are app-specific)
- Easier to manage

### Step 3: Verify Configuration

After uploading:

1. **Check Firebase Console:**
   - The APNS configuration should show as "Configured"
   - You should see your Key ID or certificate listed

2. **Test Notification:**
   - Try sending a push notification from your app
   - The error should be resolved

## Bundle ID Verification

Make sure the bundle ID in your iOS app matches Firebase:

- **App Bundle ID:** `com.wassle.userapp`
- **Firebase App Bundle ID:** Should match exactly

To verify:
1. Firebase Console → Project Settings → Your Apps
2. Check the bundle ID of your iOS app
3. Make sure it matches `com.wassle.userapp`

## Development vs Production

### Development (Sandbox)
- Uses APNS Development environment
- Works with development builds and TestFlight

### Production
- Uses APNS Production environment
- Works with App Store builds
- **Important:** You need to configure APNS for production separately

**Note:** APNS Authentication Key works for both development and production.

## Troubleshooting

### Error Still Persists After Configuration

1. **Wait a few minutes:**
   - Firebase may take a few minutes to propagate the configuration

2. **Verify Key Upload:**
   - Go back to Firebase Console → Cloud Messaging
   - Make sure the key is listed and shows as "Active"

3. **Check Bundle ID:**
   - Ensure bundle ID matches exactly (case-sensitive)
   - No extra spaces or characters

4. **Regenerate Key:**
   - If the key was downloaded before, you might need to create a new one
   - Old keys might have been revoked

5. **Check Apple Developer Account:**
   - Make sure your Apple Developer account is active
   - Verify you have the necessary permissions

### Key ID Not Found

- The Key ID is shown when you create the key in Apple Developer Portal
- If you lost it, you'll need to create a new key (old one can't be retrieved)

### .p8 File Lost

- You can only download the `.p8` file once
- If lost, create a new APNS Authentication Key

## Security Notes

- **Never commit** `.p8` files to version control
- Store them securely (password manager, secure storage)
- Rotate keys periodically for security
- One key can be used for multiple apps

## Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Apple Push Notification Service Documentation](https://developer.apple.com/documentation/usernotifications)
- [APNS Authentication Key Setup](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns)

## Quick Checklist

- [ ] Created APNS Authentication Key in Apple Developer Portal
- [ ] Downloaded `.p8` file (saved securely)
- [ ] Noted the Key ID
- [ ] Uploaded key to Firebase Console → Cloud Messaging
- [ ] Verified bundle ID matches (`com.wassle.userapp`)
- [ ] Tested sending a notification
- [ ] Error resolved

