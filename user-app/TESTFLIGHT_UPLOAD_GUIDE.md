# TestFlight Upload Guide - Step by Step

**Date:** December 2024  
**Current Version:** 1.0.1+4  
**Bundle ID:** com.wassle.userapp  
**App Name:** Wassle

---

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] **Apple Developer Account** (active membership)
- [ ] **App Store Connect Access** (admin or app manager role)
- [ ] **Xcode** installed (latest version recommended)
- [ ] **Flutter** installed and up to date
- [ ] **CocoaPods** installed (`pod --version`)
- [ ] **Valid Code Signing Certificate** in Xcode
- [ ] **App already created** in App Store Connect

---

## Step 1: Update Build Number

**Current build:** 4  
**Next build:** 5 (or higher if 5 already exists)

### Update pubspec.yaml

1. Open `/Users/ahmad/Desktop/Awsaltak/user-app/pubspec.yaml`
2. Find the version line:
   ```yaml
   version: 1.0.1+5
   ```
3. Increment the build number (the number after `+`):
   ```yaml
   version: 1.0.1+5
   ```
   - **Version format:** `MAJOR.MINOR.PATCH+BUILD_NUMBER`
   - **Version:** 1.0.1 (marketing version)
   - **Build:** 5 (must be unique and incrementing)

4. Save the file

**Note:** Each TestFlight upload requires a unique build number that's higher than the previous one.

---

## Step 2: Clean and Prepare Project

Open Terminal and run these commands:

```bash
# Navigate to project directory
cd /Users/ahmad/Desktop/Awsaltak/user-app

# Clean previous builds
flutter clean

# Get Flutter dependencies
flutter pub get

# Navigate to iOS directory
cd ios

# Clean CocoaPods cache (optional but recommended)
rm -rf Pods Podfile.lock

# Install/update CocoaPods dependencies
pod install

# Return to project root
cd ..
```

**Expected output:**
- ✅ Flutter packages installed
- ✅ CocoaPods installed successfully
- ✅ No errors

**If you see errors:**
- Run `pod repo update` if CocoaPods fails
- Run `flutter doctor` to check Flutter setup

---

## Step 3: Open Project in Xcode

```bash
cd /Users/ahmad/Desktop/Awsaltak/user-app/ios
open Runner.xcworkspace
```

**⚠️ IMPORTANT:** Open `Runner.xcworkspace` (NOT `Runner.xcodeproj`)

Xcode will open automatically.

---

## Step 4: Configure Build Settings in Xcode

### 4.1 Select the Correct Target

1. In Xcode, click on **"Runner"** in the left sidebar (blue project icon)
2. Make sure **"Runner"** target is selected (not RunnerTests)

### 4.2 Select Device for Archive

1. In the top toolbar, click the device dropdown (next to the Run button)
2. Select **"Any iOS Device (arm64)"** or **"Generic iOS Device"**
   - ⚠️ **CRITICAL:** You MUST select a device, NOT a simulator
   - If you select a simulator, the Archive option will be grayed out

### 4.3 Verify Signing & Capabilities

1. In Xcode, select **"Runner"** project → **"Runner"** target
2. Click on **"Signing & Capabilities"** tab
3. Verify:
   - ✅ **Team:** Your Apple Developer team is selected
   - ✅ **Bundle Identifier:** `com.wassle.userapp`
   - ✅ **Automatically manage signing:** Checked (recommended)
   - ✅ **Provisioning Profile:** Should show "Xcode Managed Profile"

**If signing errors appear:**
- Select the correct Team from the dropdown
- If no team appears, you need to add your Apple ID in Xcode → Preferences → Accounts

### 4.4 Verify Version Numbers

1. Still in **"Signing & Capabilities"** tab
2. Click on **"General"** tab (next to Signing & Capabilities)
3. Verify:
   - **Version:** 1.0.1 (should match pubspec.yaml)
   - **Build:** 5 (should match pubspec.yaml build number)

**Note:** These should automatically sync from pubspec.yaml, but verify they're correct.

---

## Step 5: Build Archive

### 5.1 Set Build Configuration to Release

1. In Xcode, go to **Product → Scheme → Edit Scheme...**
2. In the left sidebar, select **"Run"**
3. In the **"Build Configuration"** dropdown, select **"Release"**
4. Click **"Close"**

### 5.2 Create Archive

1. In Xcode menu bar, go to **Product → Archive**
   - Or press: `Cmd + B` then `Product → Archive`
   - Or use shortcut: `Cmd + Shift + B` (if configured)

2. **Wait for build to complete:**
   - This can take **5-15 minutes** depending on your Mac
   - You'll see progress in the top bar
   - Don't close Xcode during this process

3. **When archive completes:**
   - Xcode will automatically open the **Organizer** window
   - Your archive will appear in the list
   - You should see: **"Wassle"** with version **1.0.1 (5)**

**If Archive button is grayed out:**
- Make sure you selected "Any iOS Device" (not simulator)
- Try: **Product → Clean Build Folder** (`Cmd + Shift + K`)
- Then try Archive again

---

## Step 6: Upload to TestFlight

### 6.1 Distribute App

1. In the **Organizer** window (that opened automatically)
2. Select your archive (the one you just created)
3. Click **"Distribute App"** button (top right)

### 6.2 Choose Distribution Method

1. Select **"App Store Connect"**
2. Click **"Next"**

### 6.3 Choose Distribution Options

1. Select **"Upload"**
   - This uploads to TestFlight/App Store Connect
   - NOT "Export" (that's for Ad Hoc/Enterprise)
2. Click **"Next"**

### 6.4 Distribution Options

1. **Upload your app's symbols:** ✅ **CHECK THIS**
   - This helps with crash reports and debugging
2. **Manage Version and Build Number:** ✅ **CHECK THIS** (optional but recommended)
   - This ensures version numbers are correct
3. Click **"Next"**

### 6.5 App Store Connect Options

1. **Distribution certificate:** Should auto-select
2. **Provisioning profile:** Should auto-select
3. Click **"Next"**

### 6.6 Review and Upload

1. **Review the summary:**
   - App: Wassle
   - Version: 1.0.1
   - Build: 5
   - Bundle ID: com.wassle.userapp

2. **Click "Upload"**

3. **Wait for upload:**
   - Progress bar will show upload status
   - This can take **10-30 minutes** depending on:
     - Your internet speed
     - App size
     - Apple's servers

4. **Upload complete:**
   - You'll see **"Upload Successful"** message
   - Click **"Done"**

**If upload fails:**
- Check your internet connection
- Verify Apple ID credentials
- Check Xcode → Preferences → Accounts (sign in again if needed)
- Try uploading again

---

## Step 7: Verify Upload in App Store Connect

### 7.1 Access App Store Connect

1. Go to: https://appstoreconnect.apple.com
2. Sign in with your Apple ID (the one associated with your developer account)

### 7.2 Navigate to Your App

1. Click **"My Apps"** in the top menu
2. Find and click on **"Wassle"** (or your app name)

### 7.3 Check TestFlight Tab

1. Click on **"TestFlight"** tab (top navigation)
2. You should see your build under **"iOS Builds"** section
3. Status will show: **"Processing..."**

**Build information:**
- **Version:** 1.0.1
- **Build:** 5
- **Status:** Processing...

---

## Step 8: Wait for Processing

### 8.1 Processing Time

- **Usually takes:** 10-30 minutes
- **Can take up to:** 1-2 hours in some cases
- **You'll receive an email** when processing completes

### 8.2 Processing Status

The build will go through these stages:

1. **"Processing..."** - Apple is processing your build
2. **"Ready to Test"** - Build is ready for TestFlight testing
3. **"Missing Compliance"** - If export compliance info is needed (see Step 9)

### 8.3 Check Email

- Apple will send an email to your registered email address
- Subject: "Your build is ready for testing" or "Build processing complete"
- Check spam folder if you don't see it

**If processing takes > 2 hours:**
- Check email for error notifications
- Check App Store Connect for error messages
- Contact Apple Support if needed

---

## Step 9: Export Compliance (If Required)

### 9.1 Check for Compliance Notice

If you see **"Missing Compliance"** status:

1. In TestFlight tab, click on your build
2. You'll see a message about export compliance

### 9.2 Answer Compliance Questions

1. Click **"Provide Export Compliance Information"**
2. Answer the questions:
   - **"Does your app use encryption?"**
     - Usually: **"No"** (unless you're using custom encryption)
     - If using HTTPS (which you are), select **"Yes, but it's exempt"**
   - **"Does your app use, contain, or incorporate cryptography?"**
     - Usually: **"Yes, but it's exempt"** (HTTPS is exempt)
3. Click **"Start Internal Testing"** or **"Save"**

**Note:** Most apps using standard HTTPS can select "Yes, but it's exempt" as HTTPS is exempt from export compliance requirements.

---

## Step 10: Add Build to TestFlight Testing

### 10.1 Internal Testing (Automatic)

- Builds are automatically available for **Internal Testing**
- Internal testers can access immediately after processing

### 10.2 External Testing (Optional)

If you want to test with external testers:

1. In TestFlight tab, click **"External Testing"** (left sidebar)
2. Click **"+"** to create a new group (or select existing)
3. Click **"Add Build"**
4. Select your build (1.0.1 (5))
5. Click **"Next"**
6. Fill in **"What to Test"** section:
   ```
   Test this build for:
   - General functionality testing
   - Location services (optional permissions)
   - Order creation and tracking
   - Push notifications
   - All core features
   ```
7. Click **"Next"**
8. Review and click **"Start Testing"**

**Note:** External testing requires App Review (usually 24-48 hours) for the first build of a version.

---

## Step 11: Invite Testers (Optional)

### 11.1 Add Internal Testers

1. In TestFlight tab, click **"Internal Testing"**
2. Click **"Add Testers"**
3. Add email addresses of team members
4. They'll receive an email invitation

### 11.2 Add External Testers

1. In TestFlight tab, click **"External Testing"**
2. Select your testing group
3. Click **"Add Testers"**
4. Add email addresses or create a public link
5. Testers will receive an email invitation

---

## Step 12: Testers Install TestFlight

### 12.1 Testers Need to:

1. **Install TestFlight app** from App Store (if not installed)
2. **Accept invitation** via email or public link
3. **Open TestFlight app**
4. **Install your app** from TestFlight

### 12.2 Testing Period

- TestFlight builds expire after **90 days**
- You'll need to upload a new build before expiration
- Testers will be notified when builds expire

---

## ✅ Final Checklist

Before considering the upload complete:

- [ ] Build number incremented in `pubspec.yaml` (1.0.1+5)
- [ ] Project cleaned (`flutter clean`)
- [ ] Dependencies updated (`flutter pub get`, `pod install`)
- [ ] Archive created successfully in Xcode
- [ ] Archive uploaded to App Store Connect
- [ ] Build appears in TestFlight tab
- [ ] Build status is "Ready to Test" (or "Processing" if still processing)
- [ ] Export compliance completed (if required)
- [ ] Testers invited (if needed)

---

## 🔧 Troubleshooting

### Build Errors

**"Archive button is grayed out":**
- ✅ Select "Any iOS Device" (not simulator)
- ✅ Product → Clean Build Folder (`Cmd + Shift + K`)
- ✅ Close and reopen Xcode

**"Code signing error":**
- ✅ Check Xcode → Preferences → Accounts
- ✅ Add your Apple ID if missing
- ✅ Select correct Team in Signing & Capabilities
- ✅ Ensure Bundle ID matches: `com.wassle.userapp`

**"No such module" error:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

**"Duplicate build number":**
- ✅ Increment build number in `pubspec.yaml` (use +6 instead of +5)
- ✅ Rebuild and upload

### Upload Errors

**"Upload failed":**
- ✅ Check internet connection
- ✅ Verify Apple ID in Xcode → Preferences → Accounts
- ✅ Try uploading again
- ✅ Check if build number is unique

**"Invalid bundle":**
- ✅ Verify version numbers are correct
- ✅ Check Info.plist is valid
- ✅ Ensure all required assets are present

### Processing Errors

**"Build stuck in Processing":**
- ✅ Normal, can take 30+ minutes
- ✅ Check email for notifications
- ✅ Wait at least 2 hours before contacting support

**"Build processing failed":**
- ✅ Check email from Apple for specific error
- ✅ Common issues:
  - Invalid code signing
  - Missing required assets
  - Version/build number conflicts
  - Export compliance issues

**"Missing Compliance":**
- ✅ Answer export compliance questions
- ✅ Select "Yes, but it's exempt" for HTTPS encryption

---

## 📞 Quick Reference

- **App Store Connect:** https://appstoreconnect.apple.com
- **TestFlight:** https://appstoreconnect.apple.com → My Apps → [Your App] → TestFlight
- **Apple Developer Support:** https://developer.apple.com/contact/
- **TestFlight Documentation:** https://developer.apple.com/testflight/

---

## 🎯 Expected Timeline

1. **Build & Archive:** 5-15 minutes
2. **Upload:** 10-30 minutes
3. **Processing:** 10-30 minutes (can be up to 2 hours)
4. **Total:** ~30-90 minutes from start to "Ready to Test"

---

## 📝 Important Notes

### Build Number Rules:
- ✅ Must be unique and incrementing
- ✅ Cannot reuse a build number that's already been uploaded
- ✅ Each upload requires a higher build number

### Version vs Build:
- **Version (1.0.1):** Marketing version, shown to users
- **Build (5):** Internal build number, must increment each upload

### TestFlight Limits:
- **Internal Testers:** Up to 100 people (immediate access)
- **External Testers:** Up to 10,000 people (requires review for first build)
- **Build Expiration:** 90 days

### Best Practices:
- ✅ Test builds internally before external testing
- ✅ Upload builds regularly to avoid expiration
- ✅ Keep build numbers sequential
- ✅ Document what's new in each build

---

## 🚀 Next Steps After Upload

1. **Wait for processing** (10-30 minutes)
2. **Check TestFlight tab** for "Ready to Test" status
3. **Add testers** (if needed)
4. **Test the build** yourself first
5. **Share with testers** and collect feedback
6. **Fix any issues** found during testing
7. **Upload new build** with fixes (increment build number)

---

**Ready to start? Begin with Step 1! 🚀**

Good luck with your TestFlight upload!

