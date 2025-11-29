# Google Play Submission Checklist

## ✅ Status Summary

| Item | Status | Notes |
|------|--------|-------|
| **AAB Build** | ⚠️ Ready to build | Run `./build-aab.sh` |
| **App Icon (512×512)** | ⚠️ Needs creation | Create from existing icon |
| **Feature Graphic (1024×500)** | ⚠️ Needs creation | Design promotional graphic |
| **Screenshots (2-4)** | ⚠️ Needs capture | Capture from app |
| **Privacy Policy URL** | ✅ Verified | https://www.wassle.ps/privacy-policy (HTTP 200) |

---

## 📦 1. AAB Build File

### Status: ⚠️ **Ready to Build**

**Action Required:**
```bash
cd /Users/ahmad/Desktop/Awsaltak/driver-app
./build-aab.sh
```

**Output Location:**
```
build/app/outputs/bundle/release/app-release.aab
```

**Prerequisites:**
- [ ] Keystore file created (if first time)
- [ ] `android/key.properties` configured
- [ ] Flutter dependencies installed

**After Build:**
- [ ] Copy AAB to `google-play-assets/` directory
- [ ] Verify file size (typically 20-50 MB)

---

## 🎨 2. App Icon (512×512)

### Status: ⚠️ **Needs Creation**

**Current Status:**
- App has launcher icons (192×192)
- Need to create 512×512 version for Google Play

**Action Required:**
1. Take highest quality version of current icon
2. Resize to exactly 512×512 pixels
3. Save as: `google-play-assets/app-icon-512x512.png`

**Tools:**
- ImageMagick: `convert ic_launcher.png -resize 512x512 app-icon-512x512.png`
- Online: Canva, Figma, Adobe Express
- Desktop: Photoshop, GIMP

**Requirements:**
- ✅ Format: PNG
- ✅ Size: 512×512 pixels (exact)
- ✅ Background: Solid or transparent

---

## 🖼️ 3. Feature Graphic (1024×500)

### Status: ⚠️ **Needs Creation**

**Action Required:**
1. Design promotional graphic
2. Include: App name, tagline, key features
3. Size: exactly 1024×500 pixels
4. Save as: `google-play-assets/feature-graphic-1024x500.png`

**Design Suggestions:**
- App name: "Wassle Driver"
- Tagline: "Your Delivery Partner" or "Earn with Deliveries"
- Features: "Real-time Orders", "Easy Navigation", "Track Earnings"
- Include app logo/icon

**Tools:**
- Canva (templates available)
- Figma
- Photoshop
- Google Play Console templates

**Requirements:**
- ✅ Format: PNG or JPEG
- ✅ Size: 1024×500 pixels (exact)
- ✅ Text readable at small sizes

---

## 📸 4. App Screenshots

### Status: ⚠️ **Needs Capture**

**Action Required:**
1. Capture 2-4 screenshots from the app
2. Resize each to 1080×1920 pixels
3. Save to `google-play-assets/` directory

**Recommended Screenshots:**

1. **Terms Acceptance Screen** ✅
   - Shows Privacy Policy and Terms links
   - Demonstrates compliance

2. **Login Screen** ✅
   - Shows authentication interface

3. **Home/Orders Screen** ✅
   - Shows main functionality
   - Displays order list

4. **Order Details Screen** (Optional)
   - Shows order management
   - Demonstrates core features

**How to Capture:**
- Android Emulator: Use screenshot tool
- Physical Device: Power + Volume Down
- Android Studio: Device screenshot tool
- ADB: `adb shell screencap -p /sdcard/screenshot.png`

**Requirements:**
- ✅ Format: PNG or JPEG
- ✅ Size: 1080×1920 pixels (portrait)
- ✅ Quantity: Minimum 2, recommended 4
- ✅ Content: Actual app screens (no mockups)

---

## 🔗 5. Privacy Policy URL

### Status: ✅ **VERIFIED**

**URL:** https://www.wassle.ps/privacy-policy

**Verification:**
- ✅ Accessible (HTTP 200)
- ✅ Returns valid response
- ✅ Configured in app localization

**Action Required:**
- [ ] Verify content is complete
- [ ] Ensure covers all data collection
- [ ] Verify available in both languages

---

## 📋 Complete Checklist

### Before Building AAB:
- [ ] Keystore created (if first time)
- [ ] `android/key.properties` configured
- [ ] Flutter dependencies up to date

### Build AAB:
- [ ] Run `./build-aab.sh` or `flutter build appbundle --release`
- [ ] Verify AAB file created
- [ ] Copy to `google-play-assets/` directory

### Create Assets:
- [ ] App icon (512×512) created
- [ ] Feature graphic (1024×500) created
- [ ] Screenshot 1 captured (1080×1920)
- [ ] Screenshot 2 captured (1080×1920)
- [ ] Screenshot 3 captured (optional)
- [ ] Screenshot 4 captured (optional)

### Verify:
- [ ] Privacy Policy URL accessible
- [ ] All assets in `google-play-assets/` directory
- [ ] File sizes reasonable (< 5MB per image)

### Upload to Google Play:
- [ ] Create app in Google Play Console
- [ ] Upload AAB file
- [ ] Upload app icon
- [ ] Upload feature graphic
- [ ] Upload screenshots
- [ ] Add Privacy Policy URL
- [ ] Complete store listing
- [ ] Submit for review

---

## 🚀 Quick Start Commands

```bash
# 1. Build AAB
cd /Users/ahmad/Desktop/Awsaltak/driver-app
./build-aab.sh

# 2. Verify Privacy Policy
curl -I https://www.wassle.ps/privacy-policy

# 3. Create assets directory (if needed)
mkdir -p google-play-assets

# 4. Check AAB location
ls -lh build/app/outputs/bundle/release/app-release.aab
```

---

## 📁 File Structure

```
driver-app/
├── build/
│   └── app/
│       └── outputs/
│           └── bundle/
│               └── release/
│                   └── app-release.aab  ← AAB file
├── google-play-assets/
│   ├── app-release.aab                ← Copy here
│   ├── app-icon-512x512.png           ← Create this
│   ├── feature-graphic-1024x500.png   ← Create this
│   ├── screenshot1.png                 ← Capture this
│   ├── screenshot2.png                 ← Capture this
│   └── screenshot3.png                 ← Optional
├── build-aab.sh                        ← Build script
├── GOOGLE_PLAY_SUBMISSION_GUIDE.md     ← Detailed guide
└── QUICK_START_GOOGLE_PLAY.md          ← Quick reference
```

---

## ⏱️ Estimated Time

- **AAB Build:** 5-10 minutes
- **App Icon:** 15-30 minutes
- **Feature Graphic:** 30-60 minutes
- **Screenshots:** 15-30 minutes
- **Total:** 1-2 hours

---

## 🎯 Priority Order

1. **Build AAB** (Required)
2. **Create App Icon** (Required)
3. **Create Feature Graphic** (Required)
4. **Capture Screenshots** (Required - minimum 2)
5. **Verify Privacy Policy** (Already done ✅)

---

## 📞 Need Help?

- **Detailed Guide:** `GOOGLE_PLAY_SUBMISSION_GUIDE.md`
- **Quick Start:** `QUICK_START_GOOGLE_PLAY.md`
- **Flutter Docs:** https://flutter.dev/docs/deployment/android
- **Google Play Help:** https://support.google.com/googleplay/android-developer

---

**Last Updated:** Current  
**App Version:** 1.0.1+2  
**Privacy Policy:** ✅ Verified

