# iOS Production APNS Fix - Quick Reference

## The Problem

**Error:** `APNS Authentication Error` - `messaging/third-party-auth-error`  
**Symptom:** Notifications work in Xcode but fail in App Store/TestFlight  
**Cause:** Missing APNS Authentication Key in Firebase Console for Production

## The Solution (5 Steps)

### 1. Get APNS Key from Apple Developer Portal
- Go to: https://developer.apple.com/account/resources/authkeys/list
- Create new key → Enable "Apple Push Notifications service (APNs)"
- Download `.p8` file (⚠️ Only once!)
- Note the Key ID (10 characters)

### 2. Upload to Firebase Console
- Firebase Console → Project Settings → Cloud Messaging
- Under "Apple app configuration":
  - Find `com.wassle.userapp` → Upload APNS Authentication Key
  - Find `com.wassle.driverapp` → Upload APNS Authentication Key (same key)
- Enter Key ID and upload `.p8` file

### 3. Wait 2-5 Minutes
- Firebase needs time to propagate the configuration

### 4. Test with TestFlight/App Store Build
- ⚠️ Must test with app installed from TestFlight or App Store
- Xcode builds use Sandbox APNs (different environment)

### 5. Verify
- Check backend logs - no more `APNS Authentication Error`
- Notifications should work ✅

## Bundle IDs

- **User App:** `com.wassle.userapp`
- **Driver App:** `com.wassle.driverapp`

## Why Xcode Works But Production Doesn't

- **Xcode builds** → Use APNS Sandbox (works without production key)
- **App Store/TestFlight** → Use APNS Production (requires production key in Firebase)

## Full Documentation

See `IOS_PRODUCTION_APNS_FIX.md` for detailed instructions and troubleshooting.

