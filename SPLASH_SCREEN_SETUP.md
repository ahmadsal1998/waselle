# Splash Screen Setup Guide

## Overview
This guide explains how to add your splash.png image to both the driver-app and user-app Android projects.

## Current Status
✅ All XML configuration files have been set up
✅ Density folders have been created
❌ PNG image files need to be added

## File Locations

### Driver App
Place your `splash.png` files in:
```
driver-app/android/app/src/main/res/
├── drawable-mdpi/splash.png     (recommended: ~48x48dp)
├── drawable-hdpi/splash.png     (recommended: ~72x72dp)
├── drawable-xhdpi/splash.png    (recommended: ~96x96dp)
├── drawable-xxhdpi/splash.png   (recommended: ~144x144dp)
└── drawable-xxxhdpi/splash.png  (recommended: ~192x192dp)
```

### User App
Place your `splash.png` files in:
```
user-app/android/app/src/main/res/
├── drawable-mdpi/splash.png     (recommended: ~48x48dp)
├── drawable-hdpi/splash.png     (recommended: ~72x72dp)
├── drawable-xhdpi/splash.png    (recommended: ~96x96dp)
├── drawable-xxhdpi/splash.png   (recommended: ~144x144dp)
└── drawable-xxxhdpi/splash.png  (recommended: ~192x192dp)
```

## Quick Setup Method

### Option 1: Use the Setup Script
1. Place your splash.png file somewhere accessible (e.g., Desktop)
2. Run the setup script:
   ```bash
   cd /Users/ahmad/Desktop/Awsaltak
   ./setup-splash-images.sh /path/to/your/splash.png
   ```

### Option 2: Manual Copy
1. Copy your splash.png file to each density folder in both apps
2. You can use the same image for all densities, but for best results, create density-specific versions

## Image Specifications

For best results, create multiple versions of your splash image:

| Density | Size (dp) | Pixel Size | Folder |
|---------|-----------|------------|--------|
| mdpi    | 48x48     | ~48x48     | drawable-mdpi |
| hdpi    | 72x72     | ~108x108   | drawable-hdpi |
| xhdpi   | 96x96     | ~192x192   | drawable-xhdpi |
| xxhdpi  | 144x144   | ~432x432   | drawable-xxhdpi |
| xxxhdpi | 192x192   | ~768x768   | drawable-xxxhdpi |

**Note:** You can use a single high-resolution image (e.g., 768x768 or 1024x1024) for all densities, and Android will scale it automatically.

## Configuration Files

The following files have already been configured:

### Driver App
- ✅ `drawable/splash.xml` - Layer list referencing splash.png
- ✅ `drawable/launch_background.xml` - Updated to use PNG
- ✅ `drawable-v21/launch_background.xml` - Updated to use PNG
- ✅ `values/colors.xml` - Added splash_background color (#FFFFFF)
- ✅ Removed `drawable/logo_vector.xml` (old vector)

### User App
- ✅ `drawable/splash.xml` - Layer list referencing splash.png
- ✅ `drawable/launch_background.xml` - Updated to use PNG
- ✅ `drawable-v21/launch_background.xml` - Updated to use PNG
- ✅ `values/colors.xml` - Added splash_background color (#FFFFFF)
- ✅ Removed `drawable/logo_vector.xml` (old vector)

## Testing

After adding your splash.png files:

1. Clean the project:
   ```bash
   cd driver-app && flutter clean
   cd ../user-app && flutter clean
   ```

2. Rebuild:
   ```bash
   cd driver-app && flutter build apk
   cd ../user-app && flutter build apk
   ```

3. Install and test the splash screen on a device or emulator

## Troubleshooting

### Image not showing
- Check that the file is named exactly `splash.png` (case-sensitive)
- Verify the file is in the correct density folder
- Clean and rebuild the project

### Wrong background color
- Edit `values/colors.xml` and change the `splash_background` color value

### Image too large/small
- Create density-specific versions for better results
- Or adjust the image size in your image editor

## Next Steps

1. ✅ XML configuration - DONE
2. ✅ Folder structure - DONE
3. ⏳ Add splash.png files - **YOU ARE HERE**
4. ⏳ Test on device/emulator
5. ⏳ Adjust image sizes if needed

