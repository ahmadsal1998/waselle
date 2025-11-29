# Google Play Submission Guide - Wassle Driver App

This guide will help you prepare all required items for Google Play submission.

---

## 📦 1. AAB Build File (Required)

### Prerequisites

#### A. Create Signing Keystore (If Not Already Created)

**IMPORTANT:** If you already have a keystore file, skip this step. If you lose your keystore, you cannot update your app on Google Play.

1. **Create the keystore file:**

```bash
cd /Users/ahmad/Desktop/Awsaltak/driver-app/android
keytool -genkey -v -keystore ~/wassle-driver-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias wassle-driver
```

**You will be prompted for:**
- Password (remember this!)
- Name, Organization, etc.
- Confirm password

**IMPORTANT:** Save the keystore file in a secure location and backup the password!

2. **Create `key.properties` file:**

```bash
cd /Users/ahmad/Desktop/Awsaltak/driver-app/android
cat > key.properties << EOF
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=wassle-driver
storeFile=/Users/ahmad/wassle-driver-keystore.jks
EOF
```

**Replace:**
- `YOUR_KEYSTORE_PASSWORD` with your keystore password
- `YOUR_KEY_PASSWORD` with your key password (usually same as keystore password)
- Update `storeFile` path if you saved keystore in different location

3. **Add `key.properties` to `.gitignore`:**

```bash
echo "android/key.properties" >> .gitignore
echo "*.jks" >> .gitignore
echo "*.keystore" >> .gitignore
```

### Build the AAB File

1. **Navigate to project directory:**

```bash
cd /Users/ahmad/Desktop/Awsaltak/driver-app
```

2. **Clean previous builds:**

```bash
flutter clean
```

3. **Get dependencies:**

```bash
flutter pub get
```

4. **Build the AAB file:**

```bash
flutter build appbundle --release
```

5. **Locate the AAB file:**

The AAB file will be created at:
```
build/app/outputs/bundle/release/app-release.aab
```

**File size:** Typically 20-50 MB (depending on assets)

**Next Steps:**
- Upload this file to Google Play Console
- File name: `app-release.aab`

---

## 📸 2. App Screenshots (Required)

### Requirements:
- **Quantity:** 2-4 screenshots (minimum 2, recommended 4)
- **Format:** PNG or JPEG
- **Size:** 
  - **Portrait:** 1080×1920 pixels (recommended)
  - **Alternative:** 1242×2688 pixels
- **Content:** Must show actual app functionality

### Recommended Screenshots:

1. **Terms Acceptance Screen** (First launch)
   - Shows Privacy Policy and Terms of Service links
   - Demonstrates compliance

2. **Login Screen**
   - Shows authentication interface

3. **Home Screen / Available Orders**
   - Shows main app functionality
   - Displays order list

4. **Order Details / Active Order**
   - Shows order management
   - Demonstrates core features

### How to Capture Screenshots:

#### Option 1: Using Android Emulator
```bash
# Start emulator
flutter emulators --launch <emulator_id>

# Run app
flutter run --release

# Take screenshots using emulator controls or:
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png screenshot1.png
```

#### Option 2: Using Physical Device
1. Install app on physical Android device
2. Navigate to each screen
3. Take screenshot (Power + Volume Down)
4. Transfer to computer

#### Option 3: Using Screenshot Tools
- Use Android Studio's screenshot tool
- Use third-party tools like `scrcpy`

### Screenshot Preparation:

1. **Resize to required dimensions:**
   - Use image editor (Photoshop, GIMP, or online tools)
   - Resize to exactly 1080×1920 pixels
   - Maintain aspect ratio

2. **Optimize:**
   - Compress if needed (keep quality high)
   - Ensure file size is reasonable (< 5MB per screenshot)

3. **Naming convention:**
   - `screenshot1_terms_acceptance.png`
   - `screenshot2_login.png`
   - `screenshot3_home.png`
   - `screenshot4_order_details.png`

**Save location:** Create a folder `google-play-assets/` in the project root

---

## 🎨 3. App Icon (Required)

### Requirements:
- **Format:** PNG
- **Size:** 512×512 pixels (exact)
- **Background:** Solid or transparent
- **Content:** App logo/icon

### Current Status:

Your app currently has launcher icons in various sizes, but Google Play requires a **512×512** icon specifically.

### Steps to Create:

1. **Check current icon:**
   ```bash
   # Current icon is 192x192, need to create 512x512 version
   ```

2. **Create 512×512 icon:**

   **Option A: Use existing icon as base**
   - Take the highest quality version of your current icon
   - Resize to 512×512 pixels
   - Ensure it looks good at this size

   **Option B: Design new icon**
   - Create a 512×512 PNG
   - Use your app's branding
   - Ensure it's recognizable at small sizes

3. **Design Guidelines:**
   - Simple, recognizable design
   - Works well at small sizes (appears as 48×48 on device)
   - No text (unless it's part of the logo)
   - High contrast for visibility

4. **Save as:**
   ```
   google-play-assets/app-icon-512x512.png
   ```

### Tools:
- **Online:** Canva, Figma, Adobe Express
- **Desktop:** Photoshop, GIMP, Sketch
- **Command line:** ImageMagick (if you have source image)

**Example using ImageMagick (if installed):**
```bash
convert android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png -resize 512x512 google-play-assets/app-icon-512x512.png
```

---

## 🖼️ 4. Feature Graphic (Required)

### Requirements:
- **Size:** 1024×500 pixels (exact)
- **Format:** PNG or JPEG
- **Content:** Promotional graphic for Google Play listing
- **Text:** Should be readable at small sizes

### Design Guidelines:

1. **Content Ideas:**
   - App name: "Wassle Driver"
   - Tagline: "Delivery Driver App" or "Earn with Deliveries"
   - Key features: "Real-time Orders", "Easy Navigation", etc.
   - App logo/icon

2. **Design Tips:**
   - Keep text minimal and large
   - Use high contrast colors
   - Include app branding
   - Make it visually appealing
   - Test how it looks at small sizes

3. **Create the graphic:**

   **Option A: Design Tool**
   - Use Canva, Figma, or Photoshop
   - Create 1024×500 canvas
   - Add app branding and text
   - Export as PNG

   **Option B: Template**
   - Use Google Play's feature graphic templates
   - Available in Google Play Console

4. **Save as:**
   ```
   google-play-assets/feature-graphic-1024x500.png
   ```

### Example Layout:
```
┌─────────────────────────────────────────┐
│  [App Logo]  Wassle Driver              │
│                                         │
│  Your Delivery Partner                  │
│                                         │
│  [Key Feature Icons]                   │
│  Real-time Orders • Easy Navigation    │
└─────────────────────────────────────────┘
```

---

## 🔗 5. Privacy Policy URL (Required)

### Current Status: ✅ **CONFIGURED**

**Privacy Policy URL:** `https://www.wassle.ps/privacy-policy`

### Verification Checklist:

- [ ] **URL is accessible** - Test in browser
- [ ] **Returns 200 status code** - No 404 errors
- [ ] **Content is complete** - Not placeholder text
- [ ] **Covers all data collection:**
  - [ ] Location data
  - [ ] FCM tokens
  - [ ] Profile data (name, email, phone)
  - [ ] Order data
  - [ ] Third-party services (Firebase, Cloudinary, Socket.io)
- [ ] **Available in both languages** (English and Arabic)
- [ ] **Mobile-friendly** - Readable on mobile devices

### Test the URL:

```bash
# Test if URL is accessible
curl -I https://www.wassle.ps/privacy-policy

# Should return: HTTP/2 200
```

**If URL is not accessible:**
- Fix the URL or create the page
- Update in `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`
- Regenerate localizations: `flutter pub get`

---

## 📋 Pre-Submission Checklist

### Build & Assets:
- [ ] AAB file built (`app-release.aab`)
- [ ] AAB file tested (install on device if possible)
- [ ] 2-4 screenshots prepared (1080×1920)
- [ ] App icon created (512×512)
- [ ] Feature graphic created (1024×500)
- [ ] Privacy Policy URL verified and accessible

### App Information:
- [ ] App name: "Wassle Driver"
- [ ] Package name: `com.wassle.driverapp`
- [ ] Version: `1.0.1` (versionCode: 2)
- [ ] App description prepared
- [ ] Short description prepared (80 characters max)
- [ ] Category selected (likely "Business" or "Food & Drink")

### Content Rating:
- [ ] Content rating questionnaire completed
- [ ] Appropriate rating selected

### Store Listing:
- [ ] App description written
- [ ] Feature list prepared
- [ ] Support URL (if applicable)
- [ ] Contact email

---

## 🚀 Submission Steps

### 1. Prepare Assets Folder

```bash
cd /Users/ahmad/Desktop/Awsaltak/driver-app
mkdir -p google-play-assets
```

**Folder structure:**
```
google-play-assets/
├── app-release.aab
├── app-icon-512x512.png
├── feature-graphic-1024x500.png
├── screenshot1_terms_acceptance.png
├── screenshot2_login.png
├── screenshot3_home.png
└── screenshot4_order_details.png
```

### 2. Upload to Google Play Console

1. **Go to Google Play Console:**
   - https://play.google.com/console

2. **Create New App:**
   - Click "Create app"
   - Fill in app details
   - Select default language
   - Accept declarations

3. **Upload AAB:**
   - Go to "Production" → "Create new release"
   - Upload `app-release.aab`
   - Add release notes

4. **Store Listing:**
   - Upload app icon (512×512)
   - Upload feature graphic (1024×500)
   - Upload screenshots (2-4 images)
   - Add app description
   - Add Privacy Policy URL

5. **Content Rating:**
   - Complete questionnaire
   - Get rating

6. **Review & Publish:**
   - Review all information
   - Submit for review

---

## 📝 Quick Commands Reference

### Build AAB:
```bash
cd /Users/ahmad/Desktop/Awsaltak/driver-app
flutter clean
flutter pub get
flutter build appbundle --release
```

### Check AAB Location:
```bash
ls -lh build/app/outputs/bundle/release/app-release.aab
```

### Verify Privacy Policy:
```bash
curl -I https://www.wassle.ps/privacy-policy
```

### Create Assets Directory:
```bash
mkdir -p google-play-assets
```

---

## ⚠️ Important Notes

1. **Keystore Security:**
   - Never commit keystore to git
   - Backup keystore file securely
   - Store password in password manager
   - If lost, you cannot update the app

2. **Version Management:**
   - Current version: `1.0.1+2`
   - For updates, increment version in `pubspec.yaml`
   - Format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`

3. **Testing:**
   - Test AAB on physical device before submission
   - Use Google Play Internal Testing track first
   - Verify all features work

4. **Privacy Policy:**
   - Must be accessible during review
   - Must be complete and accurate
   - Must cover all data collection

---

## 🎯 Next Steps

1. **Create/Verify Keystore** (if not exists)
2. **Build AAB File**
3. **Create Screenshots** (2-4 images)
4. **Create App Icon** (512×512)
5. **Create Feature Graphic** (1024×500)
6. **Verify Privacy Policy URL**
7. **Prepare App Description**
8. **Upload to Google Play Console**

---

## 📞 Support

If you encounter issues:
- Check Flutter documentation: https://flutter.dev/docs/deployment/android
- Google Play Console Help: https://support.google.com/googleplay/android-developer
- Flutter community: https://flutter.dev/community

---

**Last Updated:** After Terms Acceptance Implementation  
**App Version:** 1.0.1+2  
**Package:** com.wassle.driverapp

