# Apple App Store Submission Guide - Driver App

This guide provides step-by-step instructions for submitting the Driver App to the Apple App Store using Flutter CLI, with a focus on Production push notifications and proper build configuration.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Pre-Submission Checklist](#pre-submission-checklist)
3. [APNs Configuration](#apns-configuration)
4. [Build Configuration](#build-configuration)
5. [Building the App](#building-the-app)
6. [Uploading to App Store Connect](#uploading-to-app-store-connect)
7. [TestFlight Testing](#testflight-testing)
8. [Final Submission](#final-submission)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have:

- ✅ **Apple Developer Account** (paid membership required)
- ✅ **Xcode** installed (latest version recommended)
- ✅ **Flutter** installed and configured
- ✅ **CocoaPods** installed (`sudo gem install cocoapods`)
- ✅ **App Store Connect** access
- ✅ **APNs Authentication Key** or Certificate configured in Firebase Console
- ✅ **Provisioning Profile** for App Store distribution
- ✅ **Signing Certificate** for App Store distribution

---

## Pre-Submission Checklist

### 1. Verify App Information

- [ ] **Bundle Identifier**: `com.wassle.driverapp` (verify in `ios/Runner.xcodeproj`)
- [ ] **Version**: Check `pubspec.yaml` (current: `1.0.2+3`)
  - Format: `VERSION+BUILD_NUMBER` (e.g., `1.0.2+3` means version 1.0.2, build 3)
- [ ] **Display Name**: "Wassle Driver" (verify in `Info.plist`)
- [ ] **App Icon**: 1024x1024 PNG (no transparency, no rounded corners)
- [ ] **Screenshots**: Required for all device sizes you support

### 2. Verify Push Notification Configuration

- [ ] **Entitlements File**: `ios/Runner/Runner.entitlements` exists with `aps-environment: production`
- [ ] **Info.plist**: Contains `UIBackgroundModes` with `remote-notification`
- [ ] **AppDelegate**: Registers for remote notifications
- [ ] **FCM Service**: Disabled in debug mode (only works in release builds)

### 3. Verify Code Signing

- [ ] **Provisioning Profile**: App Store distribution profile created
- [ ] **Signing Certificate**: Valid distribution certificate
- [ ] **Xcode Project**: Configured to use automatic or manual signing

---

## APNs Configuration

### Step 1: Verify APNs in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Project Settings** → **Cloud Messaging** tab
4. Under **Apple app configuration**, find your iOS app (`com.wassle.driverapp`)
5. Verify **APNs Authentication Key** or **APNs Certificate** is uploaded

### Step 2: Verify APNs Key/Certificate in Apple Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
2. Verify you have an APNs Authentication Key (`.p8` file) or Certificate
3. **Note**: APNs Authentication Key is recommended (doesn't expire, works for all apps)

### Step 3: Verify Entitlements File

The entitlements file should be located at:
```
driver-app/ios/Runner/Runner.entitlements
```

Content should be:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>production</string>
</dict>
</plist>
```

**CRITICAL**: The `aps-environment` must be set to `production` for App Store builds.

---

## Build Configuration

### Step 1: Update Version and Build Number

Edit `pubspec.yaml`:
```yaml
version: 1.0.2+3  # Format: VERSION+BUILD_NUMBER
```

- **Version** (1.0.2): User-facing version (increment for new releases)
- **Build Number** (+3): Internal build number (increment for each build)

**Important**: Each App Store submission requires a unique build number.

### Step 2: Clean Previous Builds

```bash
cd driver-app
flutter clean
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

### Step 3: Verify Signing Configuration

Open the project in Xcode to verify signing:

```bash
cd driver-app/ios
open Runner.xcworkspace
```

In Xcode:
1. Select **Runner** project in navigator
2. Select **Runner** target
3. Go to **Signing & Capabilities** tab
4. Verify:
   - ✅ **Automatically manage signing** is checked (or manual signing configured)
   - ✅ **Team** is selected
   - ✅ **Bundle Identifier** is `com.wassle.driverapp`
   - ✅ **Provisioning Profile** shows "App Store" or "Xcode Managed Profile"
   - ✅ **Signing Certificate** is valid

### Step 4: Verify Entitlements

In Xcode, under **Signing & Capabilities**:
- ✅ **Push Notifications** capability should be enabled
- ✅ **Background Modes** should include "Remote notifications"

---

## Building the App

### Option 1: Build Archive Using Flutter CLI (Recommended)

```bash
cd driver-app

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build iOS release (creates .app bundle)
flutter build ios --release

# Note: This creates the app bundle but doesn't create an archive
# You'll need to use Xcode or xcodebuild to create the archive
```

### Option 2: Build Archive Using Xcode

1. Open the workspace in Xcode:
   ```bash
   cd driver-app/ios
   open Runner.xcworkspace
   ```

2. In Xcode:
   - Select **Product** → **Scheme** → **Runner**
   - Select **Product** → **Destination** → **Any iOS Device (arm64)**
   - Select **Product** → **Archive**

3. Wait for the archive to complete (may take 5-10 minutes)

4. The **Organizer** window will open automatically

### Option 3: Build Archive Using xcodebuild (CLI)

```bash
cd driver-app/ios

# Build archive
xcodebuild clean archive \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/Runner.xcarchive \
  CODE_SIGN_IDENTITY="iPhone Distribution" \
  CODE_SIGN_STYLE="Automatic" \
  PROVISIONING_PROFILE_SPECIFIER="" \
  DEVELOPMENT_TEAM="YOUR_TEAM_ID"

# Replace YOUR_TEAM_ID with your Apple Developer Team ID
```

---

## Uploading to App Store Connect

### Option 1: Upload Using Xcode Organizer

1. After creating the archive, the **Organizer** window opens
2. Select your archive
3. Click **Distribute App**
4. Select **App Store Connect**
5. Click **Next**
6. Select **Upload**
7. Click **Next**
8. Review signing options (usually "Automatically manage signing")
9. Click **Next**
10. Review the summary
11. Click **Upload**
12. Wait for upload to complete (may take 10-30 minutes)

### Option 2: Upload Using Transporter App

1. Export the archive from Xcode:
   - In Organizer, select archive
   - Click **Distribute App**
   - Select **App Store Connect**
   - Select **Export** (not Upload)
   - Save the `.ipa` file

2. Open **Transporter** app (download from Mac App Store if needed)

3. Drag and drop the `.ipa` file into Transporter

4. Click **Deliver**

5. Wait for upload to complete

### Option 3: Upload Using xcodebuild (CLI)

```bash
cd driver-app/ios

# Export IPA for App Store
xcodebuild -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist

# Upload using altool (deprecated) or use Transporter/Xcode instead
# Note: altool is deprecated, use Transporter or Xcode Organizer
```

### Option 4: Upload Using fastlane (If Configured)

```bash
cd driver-app
fastlane ios beta  # or fastlane ios release
```

---

## TestFlight Testing

### Step 1: Wait for Processing

After uploading:
1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Navigate to **My Apps** → **Your App** → **TestFlight**
3. Wait for processing (usually 10-30 minutes, can take up to 24 hours)

### Step 2: Add Test Information (If First Time)

1. Fill in **Test Information**:
   - What to Test
   - Description
   - Feedback Email

### Step 3: Add Internal Testers

1. Go to **Internal Testing** tab
2. Click **+** to add internal testers
3. Select users from your team
4. Select the build
5. Click **Start Testing**

### Step 4: Add External Testers (Optional)

1. Go to **External Testing** tab
2. Create a new group or use existing
3. Add testers (up to 10,000)
4. Select the build
5. Submit for Beta App Review (if first external test)

### Step 5: Test Push Notifications

**CRITICAL**: Test push notifications in TestFlight build:

1. Install the app from TestFlight
2. Log in to the app
3. Verify FCM token is generated (check app logs or backend)
4. Send a test notification from your backend
5. Verify notification is received
6. Test notification when app is:
   - In foreground
   - In background
   - Terminated

**Important**: TestFlight builds use **Production APNs**, so notifications should work exactly as they will in the App Store version.

---

## Final Submission

### Step 1: Prepare App Store Listing

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Navigate to **My Apps** → **Your App** → **App Store** tab
3. Fill in required information:
   - **App Name**: Wassle Driver
   - **Subtitle** (optional)
   - **Category**: Food & Drink, Navigation, etc.
   - **Privacy Policy URL** (required)
   - **Support URL**
   - **Marketing URL** (optional)
   - **App Icon**: 1024x1024 PNG
   - **Screenshots**: Required for all device sizes
   - **Description**: App description
   - **Keywords**: Search keywords
   - **Promotional Text** (optional)
   - **What's New**: Release notes

### Step 2: Select Build for Submission

1. Go to **App Store** tab → **iOS App** section
2. Click **+ Version or Platform**
3. Enter new version number (e.g., `1.0.2`)
4. Click **Create**
5. Scroll to **Build** section
6. Click **+** next to Build
7. Select your uploaded build
8. Click **Done**

### Step 3: Answer App Review Information

1. **Contact Information**:
   - First Name, Last Name
   - Phone Number
   - Email Address

2. **Demo Account** (if required):
   - Username
   - Password
   - Notes

3. **Notes** (optional):
   - Any additional information for reviewers

### Step 4: Submit for Review

1. Review all information
2. Check **Export Compliance** (if applicable)
3. Check **Content Rights** (if applicable)
4. Click **Submit for Review**
5. Confirm submission

### Step 5: Monitor Review Status

- **Waiting for Review**: App is in queue
- **In Review**: Apple is reviewing your app
- **Pending Developer Release**: Approved, waiting for you to release
- **Ready for Sale**: App is live in App Store
- **Rejected**: Review failed (check Resolution Center)

---

## Troubleshooting

### Build Errors

#### Error: "No signing certificate found"
**Solution**: 
1. Open Xcode → Preferences → Accounts
2. Add your Apple ID
3. Download certificates
4. In project settings, select your team

#### Error: "Provisioning profile not found"
**Solution**:
1. In Xcode, go to Signing & Capabilities
2. Enable "Automatically manage signing"
3. Select your team
4. Xcode will create/update provisioning profile

#### Error: "Code signing is required"
**Solution**:
1. Verify you're building for a device (not simulator)
2. Check signing configuration in Xcode
3. Ensure you have a valid distribution certificate

### Upload Errors

#### Error: "Invalid Bundle"
**Solution**:
- Verify bundle identifier matches App Store Connect
- Check version and build number are unique
- Ensure all required assets are included

#### Error: "Missing Compliance"
**Solution**:
- Answer export compliance questions in App Store Connect
- If using encryption, provide compliance documentation

### Push Notification Issues

#### Notifications Not Working in TestFlight
**Checklist**:
1. ✅ Verify APNs key/certificate is uploaded to Firebase Console
2. ✅ Verify entitlements file has `aps-environment: production`
3. ✅ Verify app is built with Release configuration
4. ✅ Check FCM token is generated (check app logs)
5. ✅ Verify backend is sending to correct FCM token
6. ✅ Check Firebase Console → Cloud Messaging → APNs status

#### Notifications Work in Debug but Not in Release
**Solution**:
- This is expected! Notifications are **disabled in debug mode**
- Build with `flutter build ios --release` to test notifications
- Use TestFlight for final testing

#### APNs Token Not Available
**Solution**:
1. Verify app is registered for remote notifications (AppDelegate)
2. Check device has internet connection
3. Verify APNs configuration in Firebase Console
4. Check device logs for APNs errors

### TestFlight Issues

#### Build Not Appearing in TestFlight
**Solution**:
- Wait up to 24 hours for processing
- Check email for processing errors
- Verify build was uploaded successfully
- Check App Store Connect → Activity for errors

#### Build Processing Failed
**Solution**:
- Check email for specific error
- Verify bundle identifier matches
- Check code signing is correct
- Review App Store Connect → Activity for details

---

## Quick Reference Commands

### Build Commands

```bash
# Clean and rebuild
cd driver-app
flutter clean
flutter pub get
flutter build ios --release

# Open in Xcode
cd ios
open Runner.xcworkspace
```

### Version Management

```bash
# Update version in pubspec.yaml
# Format: version: 1.0.2+3
# Then rebuild
flutter build ios --release
```

### Check Build Configuration

```bash
# Verify Flutter configuration
flutter doctor -v

# Check iOS configuration
cd driver-app/ios
pod --version
xcodebuild -version
```

---

## Important Notes

1. **Push Notifications**: Only work in Release/Production builds. Debug builds have notifications disabled.

2. **APNs Environment**: Must be set to `production` in entitlements file for App Store builds.

3. **Build Numbers**: Each App Store submission requires a unique, incrementing build number.

4. **TestFlight**: Uses Production APNs, so it's the best way to test notifications before App Store release.

5. **Processing Time**: App Store processing can take 10-30 minutes, sometimes up to 24 hours.

6. **Review Time**: App review typically takes 24-48 hours, can take up to 7 days.

---

## Support

If you encounter issues:

1. Check [Apple Developer Forums](https://developer.apple.com/forums/)
2. Review [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
3. Check [Flutter iOS Deployment Documentation](https://docs.flutter.dev/deployment/ios)
4. Review Firebase Console for APNs configuration issues

---

## Checklist Summary

Before submitting, ensure:

- [ ] Version and build number updated
- [ ] APNs configured in Firebase Console
- [ ] Entitlements file set to production
- [ ] App built with Release configuration
- [ ] Code signing configured correctly
- [ ] App tested in TestFlight
- [ ] Push notifications tested in TestFlight
- [ ] App Store listing information complete
- [ ] Screenshots and app icon uploaded
- [ ] Privacy policy URL provided
- [ ] App review information completed

Good luck with your submission! 🚀

