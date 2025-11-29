# Quick Start - Google Play Submission

## 🎯 Fast Track Checklist

### Step 1: Build AAB (5-10 minutes)

```bash
cd /Users/ahmad/Desktop/Awsaltak/driver-app
./build-aab.sh
```

**OR manually:**
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

---

### Step 2: Create Assets (30-60 minutes)

#### A. App Icon (512×512)
- [ ] Take your current app icon
- [ ] Resize to exactly 512×512 pixels
- [ ] Save as: `google-play-assets/app-icon-512x512.png`

#### B. Feature Graphic (1024×500)
- [ ] Create promotional graphic
- [ ] Include: App name, tagline, key features
- [ ] Size: exactly 1024×500 pixels
- [ ] Save as: `google-play-assets/feature-graphic-1024x500.png`

#### C. Screenshots (2-4 images)
- [ ] Capture Terms Acceptance Screen
- [ ] Capture Login Screen
- [ ] Capture Home/Orders Screen
- [ ] Capture Order Details Screen
- [ ] Resize each to 1080×1920 pixels
- [ ] Save as: `google-play-assets/screenshot1.png`, etc.

---

### Step 3: Verify Privacy Policy

```bash
# Test URL accessibility
curl -I https://www.wassle.ps/privacy-policy
```

**Should return:** `HTTP/2 200` or `HTTP/1.1 200 OK`

---

### Step 4: Upload to Google Play Console

1. Go to: https://play.google.com/console
2. Create new app (if first time)
3. Upload AAB file
4. Upload assets (icon, feature graphic, screenshots)
5. Add Privacy Policy URL: `https://www.wassle.ps/privacy-policy`
6. Complete store listing
7. Submit for review

---

## 📦 Files You Need

```
google-play-assets/
├── app-release.aab          ← Build output
├── app-icon-512x512.png     ← Create this
├── feature-graphic-1024x500.png  ← Create this
├── screenshot1.png          ← Capture this
├── screenshot2.png          ← Capture this
└── screenshot3.png          ← Optional
```

---

## ⚡ Quick Commands

```bash
# Build AAB
./build-aab.sh

# Or manually:
flutter build appbundle --release

# Check AAB location
ls -lh build/app/outputs/bundle/release/app-release.aab

# Verify privacy policy
curl -I https://www.wassle.ps/privacy-policy

# Create assets directory
mkdir -p google-play-assets
```

---

## 📝 App Information

- **App Name:** Wassle Driver
- **Package:** com.wassle.driverapp
- **Version:** 1.0.1 (Build: 2)
- **Privacy Policy:** https://www.wassle.ps/privacy-policy

---

## 🆘 Need Help?

See detailed guide: `GOOGLE_PLAY_SUBMISSION_GUIDE.md`

