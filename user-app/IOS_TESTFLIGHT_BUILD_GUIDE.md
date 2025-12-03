# iOS TestFlight Build Guide with Review Mode

**Date:** December 2024  
**Version:** 1.0.1+6  
**Bundle ID:** com.wassle.userapp  
**App Name:** Wassle

---

## 🎯 Objective

Prepare a build of the iOS app using Flutter, ensuring Review Mode works correctly for TestFlight. Review Mode automatically activates when the app runs from TestFlight, providing mock data for Apple reviewers.

---

## ✅ Prerequisites

Before starting, ensure you have:

- [ ] **Apple Developer Account** (active membership)
- [ ] **App Store Connect Access** (admin or app manager role)
- [ ] **Xcode** installed (latest version recommended)
- [ ] **Flutter** installed and up to date (`flutter --version`)
- [ ] **CocoaPods** installed (`pod --version`)
- [ ] **Valid Code Signing Certificate** in Xcode
- [ ] **App already created** in App Store Connect

---

## 🚀 Quick Start (Automated)

### Option 1: Use Build Script (Recommended)

```bash
cd /Users/ahmad/Desktop/Awsaltak/user-app
./build-ios-testflight.sh
```

The script will:
1. ✅ Clean previous builds
2. ✅ Install Flutter dependencies
3. ✅ Update CocoaPods
4. ✅ Verify Review Mode configuration
5. ✅ Build iOS app with Review Mode support
6. ✅ Provide next steps for Xcode

---

## 📋 Manual Build Steps

### Step 1: Update Build Number (if needed)

Check current version in `pubspec.yaml`:
```yaml
version: 1.0.1+6
```

**Important:** Each TestFlight upload requires a unique, incrementing build number. If build 6 already exists in App Store Connect, increment to 7 or higher.

---

### Step 2: Clean and Prepare Project

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
pod install --repo-update

# Return to project root
cd ..
```

---

### Step 3: Build iOS App

#### Option A: Flutter CLI (with Review Mode fallback)

```bash
flutter build ios --release --dart-define=TESTFLIGHT=true
```

**Note:** This sets the compile-time flag as a fallback. The primary method is runtime detection, which works automatically in TestFlight.

#### Option B: Xcode Build (Runtime Detection - Recommended)

Runtime detection works automatically when building through Xcode, so no special flags are needed.

---

### Step 4: Open in Xcode

```bash
cd ios
open Runner.xcworkspace
```

**⚠️ IMPORTANT:** Open `Runner.xcworkspace` (NOT `Runner.xcodeproj`)

---

### Step 5: Configure Archive in Xcode

1. **Select Target Device:**
   - In Xcode toolbar, select "Any iOS Device" or a connected physical device
   - Do NOT select a simulator (simulators cannot create archives)

2. **Verify Signing:**
   - Select "Runner" in project navigator
   - Go to "Signing & Capabilities" tab
   - Ensure "Automatically manage signing" is checked
   - Verify Team is selected
   - Verify Bundle Identifier: `com.wassle.userapp`

3. **Create Archive:**
   - Go to **Product → Archive**
   - Wait for archive to complete (may take several minutes)
   - Xcode Organizer window will open automatically

---

### Step 6: Upload to TestFlight

1. **In Xcode Organizer:**
   - Select your archive
   - Click **"Distribute App"**

2. **Distribution Method:**
   - Select **"App Store Connect"**
   - Click **"Next"**

3. **Distribution Options:**
   - Select **"Upload"**
   - Click **"Next"**

4. **App Thinning:**
   - Select **"All compatible device variants"** (recommended)
   - Click **"Next"**

5. **Review:**
   - Review the summary
   - Click **"Upload"**

6. **Wait for Upload:**
   - Upload may take 10-30 minutes depending on network speed
   - You'll see progress in Xcode

7. **Processing:**
   - After upload, App Store Connect will process the build
   - Processing typically takes 10-60 minutes
   - You'll receive an email when processing is complete

---

## 🍎 Review Mode Configuration

### How Review Mode Works

Review Mode uses **dual detection methods**:

1. **Runtime Detection (Primary):**
   - Automatically detects TestFlight environment at runtime
   - Uses iOS method channel to check app receipt
   - TestFlight apps have "sandboxReceipt" in receipt URL
   - Works automatically for all Xcode builds uploaded to TestFlight

2. **Compile-Time Detection (Fallback):**
   - Uses `--dart-define=TESTFLIGHT=true` flag
   - Useful if runtime detection fails
   - Ensures Review Mode works even in edge cases

### Review Mode Activation

Review Mode **automatically activates** when:
- ✅ App is installed from TestFlight
- ✅ App detects TestFlight environment at runtime
- ✅ OR compile-time flag `TESTFLIGHT=true` is set

Review Mode **will NOT activate** when:
- ❌ App is from App Store (production release)
- ❌ App is installed directly from Xcode (development)
- ❌ App is running in debug mode (unless debug flag is set)

### Mock Data Provided

When Review Mode is active, the app provides:

- **Test User Account:**
  - Name: "App Review Tester"
  - Email: reviewer@apple.com
  - Phone: +972501234567
  - Automatically logged in

- **Sample Orders:**
  - 3 pre-configured orders in different states
  - Both "send" and "receive" order types
  - Various vehicle types and categories

- **Test Drivers:**
  - "Review Test Driver" available on map
  - Predefined locations

- **Predefined Addresses:**
  - Central Market, Ramallah City Center
  - Al-Bireh Park, Al-Bireh
  - Birzeit University, Birzeit

- **Default Location:**
  - Ramallah City Center (for map testing)

---

## ✅ Verification Checklist

After uploading to TestFlight, verify:

### Build Upload
- [ ] Archive created successfully
- [ ] Upload completed without errors
- [ ] Build appears in App Store Connect
- [ ] Build processing completed
- [ ] Build is available in TestFlight

### Review Mode Activation
- [ ] App installs successfully from TestFlight
- [ ] App launches without errors
- [ ] Review Mode activates automatically (no login required)
- [ ] Mock user account is shown ("App Review Tester")
- [ ] 3 sample orders appear in order history
- [ ] Test drivers appear on the map
- [ ] Default location (Ramallah center) is shown
- [ ] All app features work with mock data

### App Functionality
- [ ] Map displays correctly
- [ ] Order creation works
- [ ] Order tracking works
- [ ] Navigation works
- [ ] All screens accessible
- [ ] No crashes or errors

---

## 🔍 Troubleshooting

### Build Errors

**Issue:** CocoaPods installation fails
```bash
# Solution:
cd ios
pod repo update
pod install
```

**Issue:** Flutter build fails
```bash
# Solution:
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release
```

**Issue:** Code signing errors
- Verify Apple Developer account is active
- Check signing certificate in Xcode
- Ensure Bundle ID matches App Store Connect

### Review Mode Not Activating

**Issue:** Review Mode doesn't activate in TestFlight

1. **Verify Runtime Detection:**
   - Check that `AppDelegate.swift` has TestFlight detection
   - Verify method channel is set up correctly
   - Check app is actually installed from TestFlight (not Xcode)

2. **Check Logs:**
   - Look for: `🍎 Review Mode: Activated (TestFlight detected at runtime)`
   - If you see fallback message, runtime detection may have failed

3. **Use Fallback Method:**
   - Build with compile-time flag:
   ```bash
   flutter build ios --release --dart-define=TESTFLIGHT=true
   ```

**Issue:** Review Mode appears in App Store builds

This should never happen, but if it does:
- Verify receipt detection logic
- Check that `isRunningInTestFlight()` returns false for production receipts
- Ensure compile-time flag is NOT set for App Store builds

### Upload Issues

**Issue:** Upload fails in Xcode
- Check internet connection
- Verify Apple Developer account access
- Try uploading again after a few minutes

**Issue:** Build processing fails in App Store Connect
- Check email for error details
- Verify app configuration in App Store Connect
- Check that all required information is provided

---

## 📝 Important Notes

### For TestFlight Builds
- ✅ Review Mode automatically activates via runtime detection
- ✅ No manual configuration needed in Xcode
- ✅ Works for all TestFlight uploads
- ✅ Apple reviewers will see mock data automatically

### For App Store Releases
- ✅ Review Mode automatically disabled
- ✅ No code changes needed
- ✅ Build normally without TESTFLIGHT flag
- ✅ App functions normally for users

### Security
- ✅ Review Mode is compile-time and runtime protected
- ✅ Cannot be activated by users
- ✅ Only visible in TestFlight environment
- ✅ Completely hidden in production

---

## 🎯 Next Steps After Upload

1. **Wait for Processing:**
   - Build processing typically takes 10-60 minutes
   - You'll receive an email when complete

2. **Add to TestFlight:**
   - Go to App Store Connect → TestFlight
   - Select your app
   - Add build to internal/external testing groups

3. **Test Review Mode:**
   - Install app from TestFlight
   - Verify Review Mode activates
   - Test all features with mock data

4. **Submit for Review:**
   - Apple reviewers will automatically see Review Mode
   - No additional configuration needed

---

## 📚 Related Documentation

- `REVIEW_MODE_SETUP.md` - Detailed Review Mode setup
- `REVIEW_MODE_BUILD_INSTRUCTIONS.md` - Build instructions
- `REVIEW_MODE_TESTFLIGHT_FIX.md` - TestFlight detection fix
- `TESTFLIGHT_UPLOAD_GUIDE.md` - Complete TestFlight upload guide

---

## 🆘 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review the related documentation files
3. Verify all prerequisites are met
4. Check Xcode and Flutter versions are up to date

---

**Status:** ✅ Ready for TestFlight Build  
**Last Updated:** December 2024  
**Version:** 1.0.1+6

