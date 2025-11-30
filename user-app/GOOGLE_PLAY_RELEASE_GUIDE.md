# Google Play Release Guide - Wassle User App

This guide will help you prepare and upload a new release of the Wassle User App to Google Play.

## 📋 Prerequisites

- Flutter SDK installed and in PATH
- Java JDK installed (for keystore creation)
- Google Play Console account with app access
- Keystore file for signing (see setup below)

## 🔐 Step 1: Keystore Setup

**IMPORTANT:** You need a signing keystore to build a production AAB. If you've already published the app before, you MUST use the same keystore.

### If you don't have a keystore yet:

Run the setup script:
```bash
cd /Users/ahmad/Desktop/Awsaltak/user-app
./setup-keystore.sh
```

This will:
1. Create a keystore file at `~/wassle-user-keystore.jks`
2. Prompt you for passwords (save these securely!)
3. Create `android/key.properties` file
4. Update `.gitignore` to exclude keystore files

### If you already have a keystore:

1. Copy your keystore file to `~/wassle-user-keystore.jks` (or update the path in `key.properties`)
2. Create `android/key.properties` with:
   ```
   storePassword=YOUR_KEYSTORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=wassle-user
   storeFile=/Users/ahmad/wassle-user-keystore.jks
   ```

## 📱 Step 2: Version Check

Current version: **1.0.1+2**
- Version name: 1.0.1 (shown to users)
- Version code: 2 (internal build number)

**Before releasing:**
- If this is a new release, increment the version in `pubspec.yaml`
- Format: `version: X.Y.Z+BUILD_NUMBER`
- Version code must be higher than the previous release on Google Play

To update version:
```bash
# Edit pubspec.yaml and update the version line
# Example: version: 1.0.2+3
```

## 🚀 Step 3: Build AAB

Run the build script:
```bash
cd /Users/ahmad/Desktop/Awsaltak/user-app
./build-aab.sh
```

The script will:
1. Clean previous builds
2. Get dependencies
3. Build the release AAB file
4. Output location: `build/app/outputs/bundle/release/app-release.aab`

## 📤 Step 4: Upload to Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Go to **Production** (or **Internal testing** / **Closed testing**)
4. Click **Create new release**
5. Upload the AAB file: `build/app/outputs/bundle/release/app-release.aab`
6. Fill in release notes
7. Review and roll out

## ✅ Pre-Release Checklist

- [ ] Keystore is set up and backed up
- [ ] Version number is incremented (if needed)
- [ ] App is tested on multiple devices
- [ ] All features are working correctly
- [ ] Firebase configuration is correct
- [ ] App icons and splash screens are correct
- [ ] Store listing is complete (screenshots, description, etc.)
- [ ] Privacy policy is linked (if required)
- [ ] Content rating is complete
- [ ] AAB file is built successfully

## 🔒 Security Reminders

- **Never commit** `android/key.properties` or keystore files to git
- **Backup your keystore** in a secure location
- **Save passwords** in a password manager
- **If you lose the keystore**, you cannot update your app on Google Play

## 🐛 Troubleshooting

### "keytool: command not found"
- Install Java JDK: `brew install openjdk` (macOS)
- Verify: `keytool -version`

### "Keystore was tampered with, or password was incorrect"
- Check passwords in `android/key.properties`
- Verify keystore file path is correct

### "Cannot find keystore file"
- Check the path in `android/key.properties`
- Use absolute path: `/Users/ahmad/wassle-user-keystore.jks`

### Build fails with signing errors
- Ensure `android/key.properties` exists
- Verify all passwords are correct
- Check keystore file exists at specified path

## 📞 Support

If you encounter issues:
1. Check the error messages carefully
2. Verify all prerequisites are met
3. Ensure keystore setup is correct
4. Try cleaning and rebuilding: `flutter clean && flutter pub get`

---

**Ready to build?** Run `./build-aab.sh` to create your AAB file!

