# Google Play Assets Directory

This directory contains all assets required for Google Play submission.

## Required Files:

1. **app-release.aab** - The production AAB build file
2. **app-icon-512x512.png** - App icon (512×512 pixels)
3. **feature-graphic-1024x500.png** - Feature graphic (1024×500 pixels)
4. **screenshot1_*.png** - First screenshot (1080×1920)
5. **screenshot2_*.png** - Second screenshot (1080×1920)
6. **screenshot3_*.png** - Third screenshot (optional, 1080×1920)
7. **screenshot4_*.png** - Fourth screenshot (optional, 1080×1920)

## File Specifications:

### AAB File:
- **Location after build:** `../build/app/outputs/bundle/release/app-release.aab`
- **Copy here after building**

### App Icon:
- **Size:** 512×512 pixels
- **Format:** PNG
- **Background:** Solid or transparent

### Feature Graphic:
- **Size:** 1024×500 pixels
- **Format:** PNG or JPEG
- **Content:** Promotional graphic for store listing

### Screenshots:
- **Size:** 1080×1920 pixels (portrait)
- **Format:** PNG or JPEG
- **Quantity:** Minimum 2, recommended 4

## Privacy Policy URL:
- **URL:** https://www.wassle.ps/privacy-policy
- **Status:** ✅ Configured (verify accessibility)

## Next Steps:

1. Build AAB: `flutter build appbundle --release`
2. Copy AAB to this directory
3. Create/obtain app icon (512×512)
4. Create feature graphic (1024×500)
5. Capture screenshots (1080×1920)
6. Upload all files to Google Play Console

See `../GOOGLE_PLAY_SUBMISSION_GUIDE.md` for detailed instructions.

