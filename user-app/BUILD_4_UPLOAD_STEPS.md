# Build 4 Upload Steps
## Building and Uploading New Version with Location Permission Fix

**Target:** Build 4 (Version 1.0.1, Build Number 3)  
**Fix:** Location permission descriptions updated

---

## ✅ Pre-Build Checklist

- [x] Version updated to `1.0.1+3` in pubspec.yaml
- [x] Location permission fix in Info.plist
- [ ] Ready to build and upload

---

## Step 1: Clean and Prepare

Open Terminal and run:

```bash
cd /Users/ahmad/Desktop/Awsaltak/user-app

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Update iOS pods
cd ios
pod install
cd ..
```

**Expected output:** All packages installed successfully

---

## Step 2: Build iOS Archive

You have **two options** for building. Choose one:

### Option A: Using Xcode (Recommended - Easier) ✅

1. **Open project in Xcode:**
   ```bash
   cd /Users/ahmad/Desktop/Awsaltak/user-app/ios
   open Runner.xcworkspace
   ```

2. **Select Device:**
   - In Xcode top bar, click the device dropdown
   - Select **"Any iOS Device (arm64)"** or **"Generic iOS Device"**
   - ⚠️ **IMPORTANT:** Must select a device, not a simulator

3. **Set Build Configuration:**
   - Go to **Product → Scheme → Edit Scheme...**
   - Select **"Run"** in left sidebar
   - Change **Build Configuration** from "Debug" to **"Release"**
   - Click **"Close"**

4. **Archive:**
   - Go to **Product → Archive**
   - Wait for archive to complete (5-15 minutes)
   - When done, **Organizer** window will open automatically

### Option B: Using Command Line

```bash
cd /Users/ahmad/Desktop/Awsaltak/user-app

# Build IPA for App Store
flutter build ipa --release

# The .ipa file will be at:
# build/ios/ipa/delivery_user_app.ipa
```

**Expected:** Build completes without errors

---

## Step 3: Upload to App Store Connect

### If using Xcode (Option A):

1. **In Xcode Organizer:**
   - Your archive should be visible
   - Click **"Distribute App"** button

2. **Choose distribution method:**
   - Select **"App Store Connect"**
   - Click **"Next"**

3. **Choose distribution options:**
   - Select **"Upload"**
   - Click **"Next"**

4. **Distribution options:**
   - ✅ Check **"Upload your app's symbols"**
   - ✅ Check **"Manage Version and Build Number"** (optional)
   - Click **"Next"**

5. **App Store Connect options:**
   - Your signing certificate should auto-select
   - Click **"Next"**

6. **Review and upload:**
   - Review the summary
   - Click **"Upload"**
   - Wait for upload (10-30 minutes)
   - You'll see progress bar

7. **Upload complete:**
   - You'll see "Upload Successful" message
   - Click **"Done"**

### If using Command Line (Option B):

**Using Transporter App:**

1. **Download Transporter** from Mac App Store (if not installed)

2. **Open Transporter:**
   - Click **"+"** button or drag your .ipa file
   - Navigate to: `user-app/build/ios/ipa/delivery_user_app.ipa`
   - Select the file

3. **Deliver:**
   - Click **"Deliver"** button
   - Sign in with your Apple ID if prompted
   - Wait for upload to complete

**Or using Command Line (altool):**

```bash
cd /Users/ahmad/Desktop/Awsaltak/user-app/build/ios/ipa

# Upload (requires App-Specific Password)
xcrun altool --upload-app \
  --type ios \
  --file "delivery_user_app.ipa" \
  --username "your-apple-id@example.com" \
  --password "your-app-specific-password"
```

**To create App-Specific Password:**
1. Go to https://appleid.apple.com
2. Sign in → Security section
3. Under "App-Specific Passwords" → Generate Password
4. Copy and use the password above

---

## Step 4: Verify Upload in App Store Connect

1. **Go to App Store Connect:**
   - Visit https://appstoreconnect.apple.com
   - Sign in with your Apple ID

2. **Navigate to your app:**
   - Click **"My Apps"**
   - Select **"Wassle"** (or your app name)

3. **Check TestFlight tab:**
   - Click **"TestFlight"** tab
   - Your new build should appear under **"iOS Builds"**
   - Status will show: **"Processing..."**

4. **Wait for processing:**
   - Usually takes **10-30 minutes**
   - Status will change to **"Ready to Submit"**
   - You'll receive an email when processing completes

---

## Step 5: Submit Build 4 for Review

Once build status shows **"Ready to Submit"**:

1. **Go to App Store tab:**
   - In App Store Connect, click **"App Store"** tab (not TestFlight)

2. **Select version:**
   - Click on **"1.0.1"** under **"iOS App"** section

3. **Select new build:**
   - Scroll down to **"Build"** section
   - Click **"+"** or **"Select a build"**
   - You should see **Build 4** (version 1.0.1)
   - Select it and click **"Done"**

4. **Add "What's New in This Version":**
   - Scroll to **"What's New in This Version"**
   - Add release notes:
     ```
     Fixed location permission descriptions to comply with App Store guidelines.
     Users can now clearly understand why location access is requested and that it's optional.
     ```

5. **Add Reviewer Notes (CRITICAL):**
   - Scroll to **"App Review Information"** section
   - In **"Notes"** field, add:
     ```
     This update fixes the location permission issue from the previous rejection.
     
     Changes made:
     - Updated NSLocationWhenInUseUsageDescription in Info.plist
     - Clarified that location access is optional and not required
     - Added explanation that users can still use the app without location by selecting addresses manually
     - Clarified that location is only used to show user's location on the map
     
     The permission description now clearly states:
     "Location access is optional and only used to show your location on the map and help you find nearby delivery services. You can still use the app and create orders without location by selecting addresses manually."
     
     This complies with App Store Review Guidelines 2.1 - Performance: App Completeness.
     
     TESTING:
     - Location permission can be denied and app still functions correctly
     - Users can manually enter addresses without location access
     - All core delivery features work without location permissions
     ```

6. **Save:**
   - Click **"Save"** (top right)

7. **Submit for Review:**
   - Click **"Submit for Review"** button
   - Confirm submission

---

## Step 6: Monitor Review Status

1. **Check status:**
   - In App Store Connect → App Store tab
   - Status will show: **"Waiting for Review"**

2. **Review time:**
   - Usually **24-48 hours** for resubmissions
   - You'll receive email notifications at each stage

3. **If approved:**
   - Status changes to **"Ready for Sale"**
   - App goes live on App Store!

4. **If rejected again:**
   - Review feedback carefully
   - Make necessary fixes
   - Upload new build and repeat

---

## 🔧 Troubleshooting

### Build Errors

**"No such module" error:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

**Code signing errors:**
- Open Xcode → Target → Signing & Capabilities
- Ensure correct Team is selected
- Ensure Bundle Identifier is correct: `com.wassle.userapp`

**Archive button is grayed out:**
- Make sure you selected "Any iOS Device" (not simulator)
- Clean build folder: Product → Clean Build Folder

### Upload Errors

**"Invalid Bundle":**
- Check version number is incremented (should be 1.0.1+3)
- Verify Info.plist is valid XML
- Check all app icons are present

**"Upload Failed":**
- Check internet connection
- Verify Apple ID credentials
- Try uploading via Xcode Organizer instead of Transporter

**"Duplicate build":**
- Build number already exists
- Increment build number in pubspec.yaml to +4

### Processing Errors

**Build stuck in "Processing":**
- Normal, can take 30+ minutes
- Check email for error notifications
- If stuck > 2 hours, contact Apple Support

---

## ✅ Final Checklist Before Submission

- [ ] Build 4 uploaded successfully
- [ ] Build status shows "Ready to Submit"
- [ ] Build 4 selected in App Store tab
- [ ] "What's New" section filled out
- [ ] Reviewer notes added explaining the fix
- [ ] All app information complete
- [ ] Screenshots up to date (if needed)
- [ ] App submitted for review

---

## 📞 Quick Reference

- **App Store Connect:** https://appstoreconnect.apple.com
- **Apple Developer Support:** https://developer.apple.com/contact/
- **Review Guidelines:** https://developer.apple.com/app-store/review/guidelines/

---

## 🎯 Expected Timeline

1. **Build & Upload:** 30-60 minutes
2. **Processing:** 10-30 minutes
3. **Waiting for Review:** 24-48 hours
4. **Total:** ~1-2 days from upload to approval

---

**Ready to start? Begin with Step 1! 🚀**

