# App Store Resubmission Guide
## Uploading New Version After Rejection Fix

**Last Updated:** 2024  
**Current Version:** 1.0.1+2  
**Fix Applied:** Location Permission Issue

---

## 📋 Quick Checklist

- [ ] Update version/build number
- [ ] Verify location permission fix is in place
- [ ] Build iOS archive
- [ ] Upload to App Store Connect
- [ ] Submit for review with fix explanation

---

## Step-by-Step Instructions

### Step 1: Verify the Fix is Complete ✅

**Check Location Permission Descriptions** (Already Fixed):

File: `ios/Runner/Info.plist`

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location access is optional and only used to show your location on the map and help you find nearby delivery services. You can still use the app and create orders without location by selecting addresses manually.</string>
```

✅ **Status:** Fix is already in place in Info.plist

---

### Step 2: Update Version Number

You need to increment the **build number** (the number after the `+` sign) for each new upload to App Store Connect.

#### Option A: Increment Build Number Only (Recommended)

**Current:** `1.0.1+2`  
**New:** `1.0.1+3` (or higher)

This keeps the same version name but increments the build.

#### Option B: Increment Version Name + Build Number

**Current:** `1.0.1+2`  
**New:** `1.0.2+3` (patch update)

Use this if you want to show users a new version number.

#### Update pubspec.yaml:

```yaml
version: 1.0.1+3  # Increment build number (recommended)
# OR
version: 1.0.2+3  # Increment both version and build number
```

**Command to update:**
```bash
cd user-app
# Edit pubspec.yaml and change the version line
```

---

### Step 3: Clean and Prepare Build

```bash
cd user-app

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Verify iOS setup
cd ios
pod install
cd ..
```

---

### Step 4: Build iOS Archive for App Store

#### Method 1: Using Xcode (Recommended - Easier)

1. **Open the project in Xcode:**
   ```bash
   cd user-app/ios
   open Runner.xcworkspace
   ```

2. **Select "Any iOS Device (arm64)" or "Generic iOS Device"** from the device dropdown (top left)

3. **Set Build Configuration:**
   - Go to **Product → Scheme → Edit Scheme**
   - Select **Run** in the left sidebar
   - Change **Build Configuration** to **Release**

4. **Archive the app:**
   - Go to **Product → Archive**
   - Wait for the archive to complete (this may take several minutes)

5. **When archive completes:**
   - The **Organizer** window will open automatically
   - You'll see your archive listed

#### Method 2: Using Command Line

```bash
cd user-app

# Build the iOS release
flutter build ipa --release

# The .ipa file will be created at:
# build/ios/ipa/delivery_user_app.ipa
```

---

### Step 5: Upload to App Store Connect

#### Option A: Upload via Xcode Organizer (Easiest)

1. **In Xcode Organizer:**
   - Select your archive
   - Click **"Distribute App"** button

2. **Choose distribution method:**
   - Select **"App Store Connect"**
   - Click **Next**

3. **Choose distribution options:**
   - Select **"Upload"**
   - Click **Next**

4. **Distribution options:**
   - ✅ Check **"Upload your app's symbols"** (for crash reports)
   - ✅ Check **"Manage Version and Build Number"** (if needed)
   - Click **Next**

5. **App Store Connect options:**
   - Select your distribution certificate
   - Select your provisioning profile
   - Click **Next**

6. **Review and upload:**
   - Review the summary
   - Click **"Upload"**
   - Wait for upload to complete (may take 10-30 minutes)

#### Option B: Upload via Transporter App

1. **Download Transporter from Mac App Store** (if not installed)

2. **Open Transporter:**
   - Click **"+"** or drag your `.ipa` file
   - Select `build/ios/ipa/delivery_user_app.ipa`

3. **Click "Deliver"** and wait for upload to complete

#### Option C: Upload via Command Line (altool)

```bash
# Navigate to your .ipa file
cd user-app/build/ios/ipa

# Upload using altool (requires App-Specific Password)
xcrun altool --upload-app \
  --type ios \
  --file "delivery_user_app.ipa" \
  --username "your-apple-id@example.com" \
  --password "your-app-specific-password"
```

**To generate App-Specific Password:**
1. Go to https://appleid.apple.com
2. Sign in with your Apple ID
3. Go to **Security** section
4. Under **App-Specific Passwords**, click **Generate Password**
5. Copy the password and use it above

---

### Step 6: Verify Upload in App Store Connect

1. **Go to App Store Connect:**
   - Visit https://appstoreconnect.apple.com
   - Sign in with your Apple ID

2. **Navigate to your app:**
   - Click **"My Apps"**
   - Select **"Wassle"** (or your app name)

3. **Check TestFlight:**
   - Click **"TestFlight"** tab
   - Your new build should appear under **"iOS Builds"**
   - Wait for processing (status will show "Processing..." then "Ready to Submit")

4. **Wait for processing:**
   - Usually takes 10-30 minutes
   - You'll receive an email when processing is complete

---

### Step 7: Submit for Review

Once the build is processed and shows "Ready to Submit":

1. **Go to App Store tab:**
   - In App Store Connect, click **"App Store"** tab (not TestFlight)

2. **Select the version:**
   - Click on **"1.0.1"** (or your version number) under **"iOS App"**

3. **Select the new build:**
   - Scroll to **"Build"** section
   - Click **"+"** or **"Select a build"**
   - Choose your newly uploaded build (e.g., Build 3)
   - Click **"Done"**

4. **Add "What's New in This Version":**
   - Scroll to **"What's New in This Version"**
   - Add release notes, for example:
     ```
     Fixed location permission descriptions to comply with App Store guidelines.
     Users can now clearly understand why location access is requested.
     ```

5. **Add Reviewer Notes (IMPORTANT):**
   - Scroll to **"App Review Information"**
   - In **"Notes"** field, add:
     ```
     This update fixes the location permission issue from the previous rejection.
     
     Changes made:
     - Updated NSLocationWhenInUseUsageDescription to clearly explain that location access is optional
     - Added explanation that users can still use the app without location by selecting addresses manually
     - Clarified that location is only used to show user's location on the map
     
     The location permission descriptions in Info.plist now comply with App Store Review Guidelines 2.1 - Performance: App Completeness.
     ```

6. **Save and submit:**
   - Click **"Save"** (top right)
   - Click **"Submit for Review"**
   - Confirm submission

---

### Step 8: Monitor Review Status

1. **Check status in App Store Connect:**
   - Status will show: **"Waiting for Review"**
   - You can check status anytime in the App Store Connect dashboard

2. **Response time:**
   - Usually 24-48 hours for resubmissions
   - You'll receive an email when review is complete

3. **If approved:**
   - Status changes to **"Ready for Sale"**
   - App will be live on App Store

4. **If rejected again:**
   - Review the feedback carefully
   - Make necessary fixes
   - Repeat this process

---

## 🔧 Troubleshooting

### Build Errors

**Issue:** "No such module 'xxx'**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

**Issue:** Code signing errors
- Go to Xcode → Target → Signing & Capabilities
- Ensure correct Team is selected
- Ensure correct Bundle Identifier

### Upload Errors

**Issue:** "Invalid Bundle"
- Check that version number is incremented
- Ensure Info.plist is properly formatted
- Verify all required app icons are present

**Issue:** "Upload Failed"
- Check internet connection
- Verify Apple ID credentials
- Try uploading via Xcode Organizer instead

### Processing Errors

**Issue:** Build stuck in "Processing"
- This is normal, can take 30+ minutes
- Check email for any error notifications
- If stuck > 2 hours, contact Apple Support

---

## 📝 Review Notes Template

Copy this template for your reviewer notes:

```
This update addresses the location permission issue identified in the previous review rejection.

FIXES APPLIED:
- Updated NSLocationWhenInUseUsageDescription in Info.plist
- Clarified that location access is optional
- Added explanation that app can be used without location permissions
- Users can select addresses manually as an alternative

The permission description now clearly states:
"Location access is optional and only used to show your location on the map and help you find nearby delivery services. You can still use the app and create orders without location by selecting addresses manually."

This complies with App Store Review Guidelines 2.1 - Performance: App Completeness, which requires clear and accurate permission usage descriptions.

TESTING:
- Location permission can be denied and app still functions
- Users can manually enter addresses without location access
- All core features work without location permissions
```

---

## ✅ Pre-Submission Checklist

Before submitting, verify:

- [ ] Version/build number incremented in `pubspec.yaml`
- [ ] Location permission descriptions updated in `Info.plist`
- [ ] App builds successfully in Release mode
- [ ] Archive created without errors
- [ ] Upload completed successfully
- [ ] Build processed in App Store Connect
- [ ] Build selected for submission
- [ ] "What's New" section filled out
- [ ] Reviewer notes added explaining the fix
- [ ] All required app information is complete

---

## 📞 Need Help?

- **App Store Connect Help:** https://help.apple.com/app-store-connect/
- **Apple Developer Support:** https://developer.apple.com/contact/
- **Review Guidelines:** https://developer.apple.com/app-store/review/guidelines/

---

## 🎯 Expected Timeline

1. **Build & Upload:** 30-60 minutes
2. **Processing in App Store Connect:** 10-30 minutes
3. **Waiting for Review:** 24-48 hours (usually faster for resubmissions)
4. **Total Time:** ~1-2 days from submission to approval

---

**Good luck with your resubmission! 🚀**

