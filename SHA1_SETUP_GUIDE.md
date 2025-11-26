# SHA-1 Fingerprint Setup Guide

This guide will help you get the Release SHA-1 fingerprints for both Android apps and add them to Firebase.

## Prerequisites

- You have the release keystore files for both apps
- You know the keystore aliases and passwords
- Firebase CLI is installed and authenticated

## Quick Start

### Option 1: Using the Interactive Script

Run the interactive script that will guide you through the process:

```bash
./get-sha1-and-add-to-firebase.sh
```

This script will:
1. Prompt you for keystore paths and aliases
2. Extract SHA-1 fingerprints
3. Add them to Firebase automatically

### Option 2: Manual Process

#### Step 1: Get SHA-1 Fingerprints

For each app, run:

```bash
# User App
./get-sha1.sh <path-to-user-keystore> <user-keystore-alias>

# Driver App  
./get-sha1.sh <path-to-driver-keystore> <driver-keystore-alias>
```

Or use keytool directly:

```bash
# User App
keytool -list -v -keystore <path-to-user-keystore> -alias <user-keystore-alias>

# Driver App
keytool -list -v -keystore <path-to-driver-keystore> -alias <driver-keystore-alias>
```

Look for the **SHA1:** line in the output and copy the fingerprint (format: `XX:XX:XX:XX:...`).

#### Step 2: Add SHA-1 to Firebase

Once you have the SHA-1 fingerprints, add them to Firebase:

**For User App:**
```bash
firebase apps:android:sha:create 1:365868224840:android:8c4c2a41c8ef5d8bd1237d "<SHA1_FINGERPRINT>" --project wae-679cc
```

**For Driver App:**
```bash
firebase apps:android:sha:create 1:365868224840:android:c4f47331b713292ed1237d "<SHA1_FINGERPRINT>" --project wae-679cc
```

Replace `<SHA1_FINGERPRINT>` with the actual SHA-1 value you copied.

#### Step 3: Verify in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/project/wae-679cc/settings/general)
2. Scroll down to "Your apps"
3. Click on each Android app
4. Verify that the SHA-1 fingerprints are listed under "SHA certificate fingerprints"

## App Information

### User App
- **Package Name:** `com.wassle.userapp`
- **Firebase App ID:** `1:365868224840:android:8c4c2a41c8ef5d8bd1237d`
- **Firebase Project:** `wae-679cc`

### Driver App
- **Package Name:** `com.wassle.driverapp`
- **Firebase App ID:** `1:365868224840:android:c4f47331b713292ed1237d`
- **Firebase Project:** `wae-679cc`

## Troubleshooting

### Error: "Could not extract SHA-1 fingerprint"
- Verify the keystore path is correct
- Verify the alias name is correct
- Make sure you're entering the correct password
- Check that the keystore file exists and is readable

### Error: "Failed to add SHA-1 to Firebase"
- Make sure you're authenticated with Firebase CLI: `firebase login`
- Verify the Firebase project ID is correct
- Check that the app ID is correct
- Ensure the SHA-1 format is correct (should be `XX:XX:XX:XX:...`)

### Getting Debug SHA-1 (for testing)

If you need the debug SHA-1 for testing:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

## Notes

- SHA-1 fingerprints are required for Firebase Authentication (especially Google Sign-In)
- You can add multiple SHA-1 fingerprints per app (e.g., debug and release)
- The SHA-1 fingerprint is unique to each keystore and alias combination
- Keep your keystore files secure and backed up

