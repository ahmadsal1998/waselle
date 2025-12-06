# Quick Submission Checklist

Use this checklist before submitting to the App Store.

## Pre-Build Checklist

- [ ] **Version Updated**: Check `pubspec.yaml` - format: `VERSION+BUILD_NUMBER` (e.g., `1.0.2+3`)
- [ ] **APNs Configured**: Firebase Console → Cloud Messaging → APNs key/certificate uploaded
- [ ] **Entitlements File**: `ios/Runner/Runner.entitlements` exists with `aps-environment: production`
- [ ] **Code Signing**: Xcode → Signing & Capabilities → Team selected, Provisioning Profile valid
- [ ] **Push Notifications**: Capability enabled in Xcode

## Build Checklist

- [ ] **Clean Build**: Run `flutter clean` and `pod install`
- [ ] **Release Build**: Build with `flutter build ios --release` or Xcode Archive
- [ ] **Archive Created**: Archive built successfully in Xcode Organizer

## Upload Checklist

- [ ] **Archive Uploaded**: Uploaded to App Store Connect via Xcode Organizer or Transporter
- [ ] **Processing Complete**: Build appears in App Store Connect → TestFlight (wait 10-30 min)

## TestFlight Checklist

- [ ] **Build Installed**: App installed from TestFlight on test device
- [ ] **Login Tested**: Can log in successfully
- [ ] **Push Notifications Tested**: 
  - [ ] Notification received when app is in foreground
  - [ ] Notification received when app is in background
  - [ ] Notification received when app is terminated
  - [ ] Notification tap navigation works correctly
- [ ] **Core Features Tested**: All main app features work correctly
- [ ] **No Crashes**: App runs without crashes

## App Store Connect Checklist

- [ ] **App Information**: All required fields filled (name, description, keywords, etc.)
- [ ] **Screenshots**: Screenshots uploaded for all required device sizes
- [ ] **App Icon**: 1024x1024 PNG uploaded
- [ ] **Privacy Policy**: Privacy policy URL provided
- [ ] **Support URL**: Support URL provided
- [ ] **App Review Info**: Contact information and demo account (if needed) provided
- [ ] **Build Selected**: Correct build selected for submission
- [ ] **Export Compliance**: Answered if applicable
- [ ] **Content Rights**: Answered if applicable

## Final Submission

- [ ] **Review All Info**: Double-check all information is correct
- [ ] **Submit for Review**: Click "Submit for Review" button
- [ ] **Monitor Status**: Check App Store Connect for review status

## Important Reminders

⚠️ **Push Notifications**: Only work in Release/Production builds. Debug builds have notifications disabled.

⚠️ **APNs Environment**: Must be `production` in entitlements file.

⚠️ **Build Numbers**: Each submission requires a unique, incrementing build number.

⚠️ **TestFlight**: Uses Production APNs - best way to test notifications before release.

---

## Quick Commands

```bash
# Build release
cd driver-app
./scripts/build-ios-release.sh

# Or manually:
flutter clean
flutter pub get
flutter build ios --release
cd ios && open Runner.xcworkspace
```

---

**Good luck with your submission! 🚀**

