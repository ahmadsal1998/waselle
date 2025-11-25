# Security Setup Guide

## ⚠️ Important: Firebase API Keys Security

Firebase API keys in `firebase_options.dart` files have been removed from version control for security reasons.

## Setup Instructions

### For Driver App

1. Copy the template file:
   ```bash
   cp driver-app/lib/firebase_options.dart.example driver-app/lib/firebase_options.dart
   ```

2. Replace the placeholder values in `driver-app/lib/firebase_options.dart` with your actual Firebase configuration.

   You can get these values from:
   - Firebase Console → Project Settings → Your apps
   - Or regenerate using FlutterFire CLI:
     ```bash
     cd driver-app
     flutterfire configure
     ```

### For User App

1. Copy the template file:
   ```bash
   cp user-app/lib/firebase_options.dart.example user-app/lib/firebase_options.dart
   ```

2. Replace the placeholder values in `user-app/lib/firebase_options.dart` with your actual Firebase configuration.

   You can get these values from:
   - Firebase Console → Project Settings → Your apps
   - Or regenerate using FlutterFire CLI:
     ```bash
     cd user-app
     flutterfire configure
     ```

## Using FlutterFire CLI (Recommended)

The easiest way to generate `firebase_options.dart` files:

1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Navigate to your app directory:
   ```bash
   cd driver-app  # or user-app
   ```

3. Run the configuration:
   ```bash
   flutterfire configure
   ```

4. Select your Firebase project and platforms (Android, iOS, etc.)

This will automatically generate the `firebase_options.dart` file with the correct configuration.

## Security Best Practices

1. **Never commit `firebase_options.dart` to version control** - It's already in `.gitignore`
2. **Restrict API keys in Firebase Console** - Set up API key restrictions by:
   - Package name (Android)
   - Bundle ID (iOS)
   - HTTP referrer (Web)
3. **Rotate keys if exposed** - If keys were exposed, regenerate them in Firebase Console
4. **Use environment variables for sensitive data** - Consider using `flutter_dotenv` for other sensitive configurations

## Regenerating Firebase API Keys

If your keys were exposed:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: `wae-679cc`
3. Navigate to: **APIs & Services** → **Credentials**
4. Find the exposed API keys and either:
   - **Delete** them (if not in use)
   - **Regenerate** them (if still needed)
5. Update your `firebase_options.dart` files with the new keys
6. Update API key restrictions to prevent unauthorized use

## Notes

- The `firebase_options.dart` files are required for the app to build and run
- They should exist locally but never be committed to git
- Each developer needs to create their own `firebase_options.dart` from the template
- CI/CD pipelines should use secure environment variables or secrets management

