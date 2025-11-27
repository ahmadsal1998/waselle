# App Store Submission Guide
## Wassle User App - Complete Step-by-Step Process

**Last Updated**: $(date)  
**App Version**: 1.0.1+2  
**Target Platforms**: iOS (iPhone)

---

## 📋 TABLE OF CONTENTS

1. [Pre-Submission Preparation](#pre-submission-preparation)
2. [Versioning & Build Configuration](#versioning--build-configuration)
3. [Info.plist Configuration](#infoplist-configuration)
4. [App Icons & Assets](#app-icons--assets)
5. [Screenshots & Marketing Materials](#screenshots--marketing-materials)
6. [Localization Verification](#localization-verification)
7. [App Store Connect Setup](#app-store-connect-setup)
8. [Building the Release Version](#building-the-release-version)
9. [Uploading to App Store](#uploading-to-app-store)
10. [Testing Scenarios](#testing-scenarios)
11. [Common Rejection Issues & Fixes](#common-rejection-issues--fixes)
12. [Post-Submission Checklist](#post-submission-checklist)

---

## 1. PRE-SUBMISSION PREPARATION

### 1.1 Verify Project Status

**Check Git Status**:
```bash
cd user-app
git status
```

**Ensure**:
- ✅ All critical fixes are committed
- ✅ No uncommitted changes (or commit them)
- ✅ Working directory is clean
- ✅ You're on the correct branch (typically `main` or `release`)

### 1.2 Review Recent Changes

**Verify all fixes from store review are in place**:
- ✅ All hardcoded text is localized
- ✅ Privacy Policy URL configured
- ✅ Terms of Service URL configured
- ✅ All permissions have proper descriptions
- ✅ No debug code in production

### 1.3 Backup Current State

**Create a backup branch**:
```bash
git checkout -b backup/pre-submission-$(date +%Y%m%d)
git push origin backup/pre-submission-$(date +%Y%m%d)
```

**Or create a tag**:
```bash
git tag -a v1.0.1-pre-submission -m "Pre-submission backup"
git push origin v1.0.1-pre-submission
```

---

## 2. VERSIONING & BUILD CONFIGURATION

### 2.1 Current Configuration

**File**: `pubspec.yaml`

**Current Settings**:
```yaml
version: 1.0.1+2
```

**Format**: `VERSION_NAME+BUILD_NUMBER`
- `1.0.1` = Version Name (shown to users)
- `2` = Build Number (internal, must increment for each upload)

### 2.2 Update Version for Submission

**For First Submission**:
- Version Name: `1.0.1` (or `1.0.0` if first release)
- Build Number: `1` (start from 1)

**For Updates**:
- Increment Version Name: `1.0.1` → `1.0.2` (patch), `1.1.0` (minor), `2.0.0` (major)
- Increment Build Number: Must be higher than previous submission

**Update `pubspec.yaml`**:
```yaml
version: 1.0.1+1  # For first submission
# or
version: 1.0.2+3  # For update (build number must be > previous)
```

### 2.3 Verify iOS Build Settings

**Check Xcode Project Settings**:

1. Open project in Xcode:
   ```bash
   cd user-app/ios
   open Runner.xcworkspace
   ```

2. Select **Runner** target → **General** tab

3. Verify:
   - **Display Name**: `Wassle` (matches Info.plist)
   - **Bundle Identifier**: `com.wassle.userapp` (or your configured ID)
   - **Version**: `1.0.1` (matches pubspec.yaml version name)
   - **Build**: `1` (matches pubspec.yaml build number)

4. Select **Runner** target → **Signing & Capabilities**:
   - ✅ **Automatically manage signing** is enabled
   - ✅ **Team** is selected (your Apple Developer account)
   - ✅ **Provisioning Profile** is valid
   - ✅ **Signing Certificate** is valid

### 2.4 Verify Bundle Identifier

**File**: `ios/Runner.xcodeproj/project.pbxproj` (or check in Xcode)

**Ensure**:
- Bundle ID matches App Store Connect app
- Format: `com.wassle.userapp` (or your configured ID)
- No conflicts with existing apps

---

## 3. INFOPLIST CONFIGURATION

### 3.1 Current Configuration

**File**: `ios/Runner/Info.plist`

### 3.2 Required Keys Verification

**✅ App Display Name**:
```xml
<key>CFBundleDisplayName</key>
<string>Wassle</string>
```
- Must match App Store Connect listing name
- No special characters or emojis

**✅ Privacy Policy URL** (REQUIRED):
```xml
<key>NSPrivacyPolicyURL</key>
<string>https://wassle.ps/privacy-policy</string>
```
- Must be accessible without login
- Must be HTTPS
- Must contain comprehensive privacy policy

**✅ Terms of Service URL** (RECOMMENDED):
```xml
<key>NSTermsOfServiceURL</key>
<string>https://wassle.ps/terms-of-service</string>
```
- Must be accessible without login
- Must be HTTPS

**✅ Location Permissions**:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to your location to help you find nearby delivery services and track your orders.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs access to your location to help you find nearby delivery services and track your orders.</string>
```
- Descriptions must be clear and specific
- Must explain why location is needed

**✅ Background Modes** (if using):
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```
- Only include if app uses background notifications

### 3.3 Verify All Permissions

**Check for any missing permission descriptions**:
- ❌ Microphone: Should NOT be present (unless voice calls are implemented)
- ❌ Camera: Add if app uses camera
- ❌ Photo Library: Add if app accesses photos

**If you need camera/photo library**:
```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take photos for your profile and orders.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photos to upload profile pictures and order images.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need permission to save photos to your library.</string>
```

### 3.4 Verify URLs Are Accessible

**Test URLs**:
```bash
# Test Privacy Policy
curl -I https://wassle.ps/privacy-policy

# Test Terms of Service
curl -I https://wassle.ps/terms-of-service
```

**Ensure**:
- ✅ URLs return HTTP 200 (not 404 or 500)
- ✅ URLs are accessible without authentication
- ✅ URLs use HTTPS (not HTTP)
- ✅ Content is properly formatted and readable

---

## 4. APP ICONS & ASSETS

### 4.1 Required Icon Sizes

**iOS App Icons** (all required):

| Size | Purpose | File Location |
|------|---------|---------------|
| 1024x1024 | App Store | `ios/Runner/Assets.xcassets/AppIcon.appiconset/` |
| 180x180 | iPhone (3x) | Same location |
| 120x120 | iPhone (2x) | Same location |
| 152x152 | iPad (2x) | Same location |
| 167x167 | iPad Pro (2x) | Same location |

### 4.2 Verify Icons

**Check in Xcode**:
1. Open `ios/Runner.xcworkspace`
2. Navigate to `Runner` → `Assets.xcassets` → `AppIcon`
3. Verify all required sizes are present
4. Ensure icons:
   - ✅ No transparency (App Store icon)
   - ✅ Proper corner radius (iOS applies automatically)
   - ✅ High quality (no pixelation)
   - ✅ Matches app branding

### 4.3 Launch Screen

**File**: `ios/Runner/Base.lproj/LaunchScreen.storyboard`

**Verify**:
- ✅ Launch screen displays correctly
- ✅ No deprecated LaunchImage references
- ✅ Works on all device sizes

---

## 5. SCREENSHOTS & MARKETING MATERIALS

### 5.1 Required Screenshots

**iPhone Screenshots** (Required for all device sizes):

| Device | Resolution | Required |
|--------|------------|----------|
| iPhone 6.7" (iPhone 14 Pro Max) | 1290 x 2796 | ✅ Yes |
| iPhone 6.5" (iPhone 11 Pro Max) | 1242 x 2688 | ✅ Yes |
| iPhone 5.5" (iPhone 8 Plus) | 1242 x 2208 | ✅ Yes |

**Minimum Required**: 3 screenshots per device size

### 5.2 Screenshot Guidelines

**Content Requirements**:
- ✅ Show actual app functionality (not mockups)
- ✅ Must match current app version
- ✅ No placeholder text or images
- ✅ Show key features:
  - Home screen
  - Order placement
  - Order tracking
  - Profile/Settings

**Design Guidelines**:
- ✅ No device frames (Apple adds automatically)
- ✅ No status bar text (or use realistic data)
- ✅ No watermarks or promotional text
- ✅ High quality (no compression artifacts)

### 5.3 App Preview Video (Optional)

**If creating app preview**:
- ✅ Maximum 30 seconds
- ✅ Show key features
- ✅ No text overlays (use captions in App Store Connect)
- ✅ High quality (1080p minimum)

### 5.4 App Icon (App Store)

**Requirements**:
- ✅ 1024x1024 pixels
- ✅ PNG format
- ✅ No transparency
- ✅ No rounded corners (Apple adds automatically)
- ✅ Matches app icon

---

## 6. LOCALIZATION VERIFICATION

### 6.1 Check for Hardcoded Text

**Run Search**:
```bash
cd user-app
# Search for hardcoded English strings in Dart files
grep -r "Text(['\"].*[A-Za-z].*['\"])" lib/ --include="*.dart" | grep -v "l10n\." | grep -v "AppLocalizations"
```

**Common Issues to Check**:
- ❌ Hardcoded error messages
- ❌ Hardcoded button labels
- ❌ Hardcoded placeholder text
- ❌ Hardcoded dialog messages

### 6.2 Verify Localization Files

**Method 1: Using jq (if installed)**:
```bash
cd user-app

# Verify English
cat lib/l10n/app_en.arb | jq 'keys | length'

# Verify Arabic
cat lib/l10n/app_ar.arb | jq 'keys | length'

# Compare key counts (should be equal)
cat lib/l10n/app_en.arb | jq 'keys | length' > /tmp/en_count.txt
cat lib/l10n/app_ar.arb | jq 'keys | length' > /tmp/ar_count.txt
diff /tmp/en_count.txt /tmp/ar_count.txt
```

**Method 2: Using Flutter (Recommended)**:
```bash
cd user-app

# Generate localization files (will show errors if keys are missing)
flutter gen-l10n

# Analyze code for localization issues
flutter analyze
```

**Method 3: Manual Count (if jq not available)**:
```bash
cd user-app

# Count keys in English file (excluding metadata keys starting with @)
grep -E '^  "[^@]' lib/l10n/app_en.arb | wc -l

# Count keys in Arabic file
grep -E '^  "[^@]' lib/l10n/app_ar.arb | wc -l

# Find missing keys (keys in English but not in Arabic)
grep -E '^  "[^@]' lib/l10n/app_en.arb | sed 's/^  "\([^"]*\)".*/\1/' | while read key; do
  if ! grep -q "^  \"$key\"" lib/l10n/app_ar.arb; then
    echo "Missing in Arabic: $key"
  fi
done
```

**Method 4: Using Python (if available)**:
```bash
cd user-app

# Create a simple verification script
python3 << 'EOF'
import json

with open('lib/l10n/app_en.arb', 'r', encoding='utf-8') as f:
    en_data = json.load(f)
    
with open('lib/l10n/app_ar.arb', 'r', encoding='utf-8') as f:
    ar_data = json.load(f)

# Get keys (excluding metadata keys)
en_keys = {k for k in en_data.keys() if not k.startswith('@')}
ar_keys = {k for k in ar_data.keys() if not k.startswith('@')}

print(f"English keys: {len(en_keys)}")
print(f"Arabic keys: {len(ar_keys)}")

missing_in_ar = en_keys - ar_keys
missing_in_en = ar_keys - en_keys

if missing_in_ar:
    print(f"\n⚠️  Missing in Arabic: {missing_in_ar}")
if missing_in_en:
    print(f"\n⚠️  Missing in English: {missing_in_en}")
if not missing_in_ar and not missing_in_en:
    print("\n✅ All keys are present in both files!")
EOF
```

**Ensure**:
- ✅ Both files have same number of keys (excluding metadata keys)
- ✅ No missing translations
- ✅ All keys have proper descriptions (keys starting with `@`)
- ✅ JSON syntax is valid (no parsing errors)
- ✅ All placeholders match between languages

### 6.3 Test Localization

**Manual Testing**:
1. Run app on simulator/device
2. Change language in Settings → App → Language
3. Verify:
   - ✅ All text translates correctly
   - ✅ RTL layout works for Arabic
   - ✅ No English text appears in Arabic mode
   - ✅ No Arabic text appears in English mode

**Automated Check**:
```bash
flutter gen-l10n
flutter analyze
```

### 6.4 Key Localization Points

**Critical Screens to Test**:
- ✅ Login/Registration
- ✅ Home screen
- ✅ Order placement
- ✅ Order tracking
- ✅ Profile/Settings
- ✅ Privacy Policy screen
- ✅ Terms of Service screen
- ✅ Error messages
- ✅ Success messages
- ✅ Empty states

---

## 7. APP STORE CONNECT SETUP

### 7.1 Create App Record

**Steps**:
1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to **My Apps** → **+** → **New App**
3. Fill in:
   - **Platform**: iOS
   - **Name**: `Wassle` (must match Info.plist)
   - **Primary Language**: English
   - **Bundle ID**: Select your bundle identifier
   - **SKU**: Unique identifier (e.g., `wassle-user-ios`)
   - **User Access**: Full Access (or as needed)

### 7.2 App Information

**Required Fields**:
- ✅ **Name**: `Wassle` (30 characters max)
- ✅ **Subtitle**: Brief description (30 characters max)
- ✅ **Category**: 
   - Primary: `Food & Drink` or `Lifestyle`
   - Secondary: (optional)
- ✅ **Content Rights**: Confirm you have rights to all content

### 7.3 Pricing and Availability

**Settings**:
- **Price**: Free (or set price)
- **Availability**: All countries (or select specific)
- **Discounts**: (if applicable)

### 7.4 App Privacy

**Privacy Policy**:
- ✅ **Privacy Policy URL**: `https://wassle.ps/privacy-policy`
- ✅ Must match Info.plist `NSPrivacyPolicyURL`

**Data Collection** (Answer honestly):
- Location data: Yes (explain usage)
- User content: Yes/No (explain)
- Identifiers: Yes (device ID, user ID)
- Usage data: Yes/No (analytics)
- Diagnostics: Yes/No (crash reports)

**For each data type**:
- Explain what data is collected
- Explain how it's used
- Explain if it's linked to user identity
- Explain if it's used for tracking

### 7.5 Version Information

**App Store Version**:
- **Version**: `1.0.1` (matches pubspec.yaml)
- **Copyright**: `© 2024 Wassle` (or your company)

**What's New in This Version**:
```
Initial release of Wassle - Your delivery service app.

Features:
• Place delivery orders easily
• Track orders in real-time
• Save favorite addresses
• View order history
• Support for English and Arabic
```

### 7.6 App Description

**Description** (up to 4000 characters):

```
Wassle - Your Trusted Delivery Partner

Wassle makes it easy to send and receive packages across your city. Whether you need to send a package to a friend or receive one from a store, Wassle connects you with reliable delivery drivers.

KEY FEATURES:
• Easy Order Placement - Create delivery requests in minutes
• Real-Time Tracking - Track your orders from pickup to delivery
• Multiple Vehicle Types - Choose from bike, car, or cargo
• Saved Addresses - Save your favorite locations for quick access
• Order History - View all your past deliveries
• Bilingual Support - Available in English and Arabic
• Secure Payments - Safe and secure payment processing

HOW IT WORKS:
1. Open the app and select your delivery type
2. Enter pickup and delivery locations
3. Choose your preferred vehicle type
4. Review estimated cost and place order
5. Track your order in real-time
6. Receive notifications when driver accepts and completes delivery

WHY CHOOSE WASLLE:
• Fast and Reliable - Quick delivery times
• Transparent Pricing - See costs before ordering
• Professional Drivers - Verified and experienced drivers
• 24/7 Support - Get help whenever you need it

Download Wassle today and experience the future of delivery services!
```

### 7.7 Keywords

**Keywords** (100 characters max, comma-separated):
```
delivery, courier, shipping, package, transport, logistics, same-day delivery, local delivery, express delivery
```

**Tips**:
- ✅ Use relevant keywords
- ✅ Separate with commas
- ✅ No spaces after commas
- ✅ No brand names (except your own)

### 7.8 Support URL

**Required**:
- **Support URL**: `https://wassle.ps/support` (or your support page)
- Must be accessible
- Should have contact information

### 7.9 Marketing URL (Optional)

**Optional**:
- **Marketing URL**: `https://wassle.ps` (your website)
- Used for promotional purposes

### 7.10 App Review Information

**Contact Information**:
- **First Name**: [Your first name]
- **Last Name**: [Your last name]
- **Phone Number**: [Your phone with country code]
- **Email**: [Your email]

**Demo Account** (if app requires login):
- **Username**: `demo@wassle.ps`
- **Password**: `Demo123!`
- **Notes**: "This is a demo account for app review. Full functionality is available."

**Notes for Review**:
```
Thank you for reviewing Wassle!

This is a delivery service app that connects users with delivery drivers.

Key points for testing:
1. App works without login - users can browse and place orders
2. Login is optional but recommended for order history
3. Location permission is required for order placement
4. Push notifications are used for order updates

If you encounter any issues, please contact us at support@wassle.ps

Demo Account (if needed):
Email: demo@wassle.ps
Password: Demo123!
```

**Attachment** (if needed):
- Upload any additional documentation
- User guide or manual
- Architecture diagrams (if complex)

### 7.11 Version Release

**Release Options**:
- **Automatically release this version**: Recommended for first submission
- **Manually release this version**: For staged rollouts
- **Schedule release**: For specific launch dates

---

## 8. BUILDING THE RELEASE VERSION

### 8.1 Pre-Build Checklist

**Before Building**:
- ✅ All code changes committed
- ✅ Version number updated in `pubspec.yaml`
- ✅ Info.plist verified
- ✅ Icons and assets in place
- ✅ No debug code
- ✅ Localization complete

### 8.2 Clean Build

**Clean Previous Builds**:
```bash
cd user-app

# Clean Flutter build
flutter clean

# Clean iOS build
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..

# Get dependencies
flutter pub get
```

### 8.3 Build Configuration

**Set Release Mode**:
```bash
# Verify release configuration
flutter build ios --release
```

**Or use Xcode**:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Product** → **Scheme** → **Runner**
3. Select **Product** → **Destination** → **Any iOS Device**
4. Select **Product** → **Edit Scheme**
5. Set **Build Configuration** to **Release**

### 8.4 Archive Build

**Using Xcode** (Recommended):

1. **Open Project**:
   ```bash
   cd user-app/ios
   open Runner.xcworkspace
   ```

2. **Select Device**:
   - Select **Any iOS Device** (not simulator)

3. **Archive**:
   - **Product** → **Archive**
   - Wait for build to complete (5-15 minutes)

4. **Verify Archive**:
   - Check **Organizer** window opens
   - Verify archive appears
   - Check version and build number

**Using Command Line**:
```bash
cd user-app

# Build for release
flutter build ipa --release

# Output: build/ios/ipa/wassle.ipa
```

### 8.5 Verify Build

**Check Archive**:
- ✅ Version number correct
- ✅ Build number correct
- ✅ Bundle identifier correct
- ✅ Signing certificate valid
- ✅ No errors or warnings

**Test Build Locally** (Optional):
```bash
# Install on connected device
flutter install --release
```

---

## 9. UPLOADING TO APP STORE

### 9.1 Using Xcode Organizer

**Steps**:
1. Open **Xcode** → **Window** → **Organizer**
2. Select your archive
3. Click **Distribute App**
4. Select **App Store Connect**
5. Click **Next**
6. Select **Upload**
7. Click **Next**
8. Review options:
   - ✅ **Include bitcode**: No (Flutter doesn't support)
   - ✅ **Upload symbols**: Yes (for crash reports)
9. Click **Next**
10. Review signing:
    - ✅ **Automatically manage signing**: Yes
    - ✅ **Distribution certificate**: Valid
11. Click **Upload**
12. Wait for upload to complete (10-30 minutes)

### 9.2 Using Transporter App

**Alternative Method**:

1. **Export IPA**:
   - In Xcode Organizer, select archive
   - Click **Distribute App**
   - Select **App Store Connect**
   - Select **Export** (not Upload)
   - Save IPA file

2. **Upload via Transporter**:
   - Download [Transporter](https://apps.apple.com/us/app/transporter/id1450874784) from Mac App Store
   - Open Transporter
   - Drag IPA file into Transporter
   - Click **Deliver**
   - Wait for upload to complete

### 9.3 Using Command Line (Fastlane)

**If using Fastlane**:
```bash
cd user-app/ios
fastlane deliver
```

### 9.4 Verify Upload

**Check App Store Connect**:
1. Go to **App Store Connect** → **My Apps** → **Wassle**
2. Go to **TestFlight** tab (if using) or **App Store** tab
3. Check **Builds** section
4. Verify:
   - ✅ Build appears in list
   - ✅ Processing status (may take 30-60 minutes)
   - ✅ No errors

**Processing Time**:
- Initial processing: 30-60 minutes
- Additional processing: Up to 24 hours
- Check email for notifications

---

## 10. TESTING SCENARIOS

### 10.1 Pre-Submission Testing

**Test on Physical Devices**:
- ✅ iPhone (latest iOS version)
- ✅ iPhone (older iOS version, if supporting)
- ✅ Different screen sizes

### 10.2 Critical Test Scenarios

#### 10.2.1 First Launch
- [ ] App launches without crashes
- [ ] No forced login (users can browse)
- [ ] Permission requests appear appropriately
- [ ] Language selection works
- [ ] No hardcoded English text in Arabic mode

#### 10.2.2 Order Placement
- [ ] Can place order without login (if allowed)
- [ ] Location permission requested appropriately
- [ ] Form validation works
- [ ] Error messages are clear and localized
- [ ] Success messages appear
- [ ] Order appears in tracking

#### 10.2.3 Order Tracking
- [ ] Orders appear in tracking screen
- [ ] Real-time updates work
- [ ] Map displays correctly
- [ ] Location data shows correctly
- [ ] Status updates correctly

#### 10.2.4 Authentication
- [ ] Login works
- [ ] Registration works
- [ ] OTP verification works
- [ ] Logout works
- [ ] Session persists correctly

#### 10.2.5 Legal Compliance
- [ ] Privacy Policy accessible
- [ ] Terms of Service accessible
- [ ] Links open in browser
- [ ] URLs are correct and accessible

#### 10.2.6 Localization
- [ ] Switch between English/Arabic
- [ ] RTL layout works in Arabic
- [ ] All text translates correctly
- [ ] No mixed languages

#### 10.2.7 Error Scenarios
- [ ] Network errors handled gracefully
- [ ] Location unavailable handled
- [ ] Empty states show helpful messages
- [ ] API errors show user-friendly messages

#### 10.2.8 Notifications
- [ ] Push notifications work
- [ ] Notification permissions requested
- [ ] Notifications appear correctly
- [ ] Tapping notification opens app

#### 10.2.9 Background Functionality
- [ ] App works in background
- [ ] Notifications work when app closed
- [ ] Location updates work (if applicable)

### 10.3 Device-Specific Testing

**Test on**:
- [ ] iPhone 14 Pro Max (6.7")
- [ ] iPhone 13 (6.1")
- [ ] iPhone SE (4.7") - if supporting
- [ ] iPad (if supporting)

**iOS Versions**:
- [ ] iOS 16 (minimum supported)
- [ ] iOS 17 (latest)

### 10.4 Performance Testing

**Check**:
- [ ] App launches quickly (< 3 seconds)
- [ ] No memory leaks
- [ ] Smooth scrolling
- [ ] No crashes during extended use
- [ ] Battery usage reasonable

### 10.5 Accessibility Testing

**Basic Checks**:
- [ ] VoiceOver works (if supporting)
- [ ] Text is readable
- [ ] Buttons are tappable
- [ ] Colors have sufficient contrast

---

## 11. COMMON REJECTION ISSUES & FIXES

### 11.1 Guideline 2.1 - App Completeness

**Issue**: App crashes or has broken functionality

**Prevention**:
- ✅ Test thoroughly on physical devices
- ✅ Test all user flows
- ✅ Handle all error cases
- ✅ Test with poor network conditions

**Fix**:
- Fix crashes immediately
- Add proper error handling
- Test edge cases

### 11.2 Guideline 2.3.1 - Accurate Metadata

**Issue**: App name doesn't match Info.plist or App Store listing

**Prevention**:
- ✅ Ensure `CFBundleDisplayName` matches App Store name
- ✅ Verify all metadata is consistent

**Fix**:
- Update Info.plist to match App Store name
- Or update App Store listing to match Info.plist

### 11.3 Guideline 2.5.1 - Software Requirements

**Issue**: Permission requested but not used

**Prevention**:
- ✅ Only request permissions you actually use
- ✅ Remove unused permission descriptions

**Fix**:
- Remove permission from Info.plist
- Or implement the feature that uses the permission

### 11.4 Guideline 2.1 - Privacy Policy

**Issue**: Missing or inaccessible privacy policy

**Prevention**:
- ✅ Privacy policy URL in Info.plist
- ✅ Privacy policy URL in App Store Connect
- ✅ URL is accessible without login
- ✅ URL uses HTTPS

**Fix**:
- Add privacy policy URL
- Ensure URL is accessible
- Update privacy policy content

### 11.5 Guideline 2.1 - Localization

**Issue**: Hardcoded text in non-English languages

**Prevention**:
- ✅ All user-facing text is localized
- ✅ Test in all supported languages
- ✅ No hardcoded strings

**Fix**:
- Add missing localization keys
- Replace hardcoded text with localized strings
- Test in all languages

### 11.6 Guideline 3.1.1 - In-App Purchase

**Issue**: Using payment methods other than IAP (if applicable)

**Prevention**:
- ✅ Use IAP for digital goods
- ✅ Use external payment for physical goods/services

**Fix**:
- Implement IAP if selling digital goods
- Or clarify that payments are for physical services

### 11.7 Guideline 4.0 - Design

**Issue**: Poor UI/UX, placeholder content

**Prevention**:
- ✅ Professional design
- ✅ No placeholder content
- ✅ Consistent UI

**Fix**:
- Improve design
- Remove placeholder content
- Ensure consistency

### 11.8 Guideline 5.1.1 - Privacy

**Issue**: Data collection not disclosed

**Prevention**:
- ✅ Complete privacy questionnaire in App Store Connect
- ✅ Privacy policy covers all data collection
- ✅ Explain data usage clearly

**Fix**:
- Update privacy questionnaire
- Update privacy policy
- Be transparent about data collection

### 11.9 Guideline 2.5.2 - Software Requirements

**Issue**: App requires specific hardware not available to reviewers

**Prevention**:
- ✅ Provide demo account
- ✅ Explain any special requirements
- ✅ Provide test instructions

**Fix**:
- Add demo account in App Review Information
- Provide detailed testing instructions
- Consider alternative testing methods

### 11.10 Guideline 2.3.7 - Metadata

**Issue**: Screenshots don't match app functionality

**Prevention**:
- ✅ Use actual app screenshots
- ✅ Screenshots match current version
- ✅ No misleading content

**Fix**:
- Update screenshots to match app
- Remove misleading content
- Use actual app screens

---

## 12. POST-SUBMISSION CHECKLIST

### 12.1 Immediate Actions

**After Uploading**:
- [ ] Verify build appears in App Store Connect
- [ ] Check processing status
- [ ] Monitor email for notifications
- [ ] Ensure contact information is correct

### 12.2 During Review

**Monitor Status**:
- [ ] Check App Store Connect daily
- [ ] Respond to any reviewer questions within 24 hours
- [ ] Be available for phone calls (if provided)

**If Rejected**:
- [ ] Read rejection reason carefully
- [ ] Identify the specific issue
- [ ] Fix the issue
- [ ] Update app version
- [ ] Resubmit with explanation

### 12.3 After Approval

**Pre-Launch**:
- [ ] Verify app is ready for users
- [ ] Test final version one more time
- [ ] Prepare marketing materials
- [ ] Announce launch

**Post-Launch**:
- [ ] Monitor crash reports
- [ ] Monitor user reviews
- [ ] Respond to user feedback
- [ ] Plan updates

### 12.4 Update Process

**For Future Updates**:
1. Follow steps 2-9 (versioning, building, uploading)
2. Increment version number
3. Update "What's New" section
4. Test thoroughly
5. Submit for review

---

## 13. QUICK REFERENCE CHECKLIST

### Pre-Submission
- [ ] Version number updated
- [ ] Build number incremented
- [ ] Info.plist verified
- [ ] Icons in place
- [ ] Screenshots prepared
- [ ] Localization complete
- [ ] No hardcoded text
- [ ] Privacy policy accessible
- [ ] Terms of service accessible
- [ ] All permissions have descriptions

### App Store Connect
- [ ] App record created
- [ ] Metadata complete
- [ ] Description written
- [ ] Keywords added
- [ ] Screenshots uploaded
- [ ] Privacy questionnaire completed
- [ ] App Review Information filled
- [ ] Demo account provided (if needed)

### Building
- [ ] Clean build performed
- [ ] Release configuration set
- [ ] Archive created successfully
- [ ] Signing verified
- [ ] Build uploaded

### Testing
- [ ] Tested on physical devices
- [ ] All features work
- [ ] Error handling verified
- [ ] Localization tested
- [ ] Performance acceptable

---

## 14. TROUBLESHOOTING

### Build Issues

**"No signing certificate found"**:
- Check Apple Developer account membership
- Verify team selection in Xcode
- Regenerate certificates if needed

**"Bundle identifier already exists"**:
- Use different bundle identifier
- Or transfer existing app

**"Archive failed"**:
- Clean build folder
- Check for errors in Xcode
- Verify all dependencies are installed

### Upload Issues

**"Upload failed"**:
- Check internet connection
- Verify Apple ID credentials
- Try using Transporter app instead

**"Processing failed"**:
- Check email for details
- Verify IPA file is valid
- Contact Apple Developer Support

### Review Issues

**"App rejected"**:
- Read rejection reason carefully
- Address specific issues mentioned
- Resubmit with explanation

**"In Review for too long"**:
- Normal review time: 24-48 hours
- Can take up to 7 days
- Contact App Review if > 7 days

---

## 15. RESOURCES

### Official Documentation
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

### Tools
- [App Store Connect](https://appstoreconnect.apple.com)
- [Transporter App](https://apps.apple.com/us/app/transporter/id1450874784)
- [TestFlight](https://developer.apple.com/testflight/)

### Support
- [Apple Developer Support](https://developer.apple.com/support/)
- [App Review Contact](https://developer.apple.com/contact/app-store/)

---

## 16. VERSION HISTORY

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | $(date) | Initial submission guide created |

---

**Good luck with your submission! 🚀**

*Remember: The review process can take 24-48 hours. Be patient and responsive to any reviewer questions.*

