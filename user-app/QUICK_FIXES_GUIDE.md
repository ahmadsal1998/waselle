# Quick Fixes Guide - App Store Submission

This guide provides specific code changes needed to fix critical App Store issues.

## 🔴 CRITICAL FIXES

### Fix 1: App Name Consistency

**File**: `ios/Runner/Info.plist`

**Current**:
```xml
<key>CFBundleDisplayName</key>
<string>Wassle</string>
```

**If submitting as "User App"**, change to:
```xml
<key>CFBundleDisplayName</key>
<string>User App</string>
```

**OR** if keeping "Wassle", ensure App Store Connect listing matches.

---

### Fix 2: Remove Microphone Permission (If Calls Not Implemented)

**File**: `ios/Runner/Info.plist`

**Remove these lines** (lines 33-34):
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to enable voice calls with drivers.</string>
```

**Also check**: Remove any call-related code references in:
- `lib/services/fcm_service.dart` (lines 301-303 already disabled)
- Any other files referencing voice calls

---

### Fix 3: Add Photo Library/Camera Permissions (If Using Image Picker)

**File**: `ios/Runner/Info.plist`

**Add after line 34** (after microphone permission, or where appropriate):
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photos to upload profile pictures and attach images to your orders.</string>
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take photos for your profile and orders.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need permission to save photos to your library.</string>
```

**Note**: Only add if your app actually uses image picker functionality.

---

### Fix 4: Add Privacy Policy URL (iOS 14+)

**File**: `ios/Runner/Info.plist`

**Add before closing `</dict>` tag**:
```xml
<key>NSPrivacyPolicyURL</key>
<string>https://yourdomain.com/privacy-policy</string>
```

**Also**: Add privacy policy link in App Store Connect → App Information → Privacy Policy URL

---

### Fix 5: Improve Location Permission Description

**File**: `ios/Runner/Info.plist`

**Current** (lines 29-32):
```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs access to your location to help you find nearby delivery services and track your orders.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to your location to help you find nearby delivery services and track your orders.</string>
```

**Recommended** (more specific):
```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We use your location to show nearby delivery drivers and calculate delivery distances. Your location is only shared with drivers when you place an order.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>We use your location to show nearby delivery drivers and calculate delivery distances. Your location is only shared with drivers when you place an order.</string>
```

---

## 🟡 RECOMMENDED IMPROVEMENTS

### Improvement 1: Add Privacy Policy Screen

**Create new file**: `lib/screens/settings/privacy_policy_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Last Updated: [DATE]',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            // Add your privacy policy content here
            const Text(
              'We respect your privacy and are committed to protecting your personal data...',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final url = Uri.parse('https://yourdomain.com/privacy-policy');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('View Full Privacy Policy Online'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Add to pubspec.yaml** (if not already present):
```yaml
dependencies:
  url_launcher: ^6.2.0
```

**Add link in Profile/Settings screen**:
```dart
ListTile(
  leading: const Icon(Icons.privacy_tip),
  title: const Text('Privacy Policy'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PrivacyPolicyScreen(),
      ),
    );
  },
),
```

---

### Improvement 2: Add Terms of Service Screen

**Create new file**: `lib/screens/settings/terms_of_service_screen.dart`

Similar structure to privacy policy screen above.

---

### Improvement 3: Improve Notification Permission Flow

**File**: `lib/services/fcm_service.dart`

**Current**: Permission requested immediately on app launch (line 223)

**Recommended**: Request permission contextually

**Create new file**: `lib/widgets/notification_permission_dialog.dart`

```dart
import 'package:flutter/material.dart';
import 'package:delivery_user_app/l10n/app_localizations.dart';

Future<bool> showNotificationPermissionDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(l10n.enableNotifications ?? 'Enable Notifications'),
      content: const Text(
        'We\'ll send you notifications about your order status, driver updates, and important messages. You can change this in Settings anytime.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not Now'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Enable'),
        ),
      ],
    ),
  ) ?? false;
}
```

**Update**: `lib/services/fcm_service.dart` to use dialog before requesting permission.

---

## 📋 CHECKLIST

### Before Building for App Store

- [ ] App name is consistent everywhere
- [ ] Microphone permission removed (if calls not implemented)
- [ ] Photo library/camera permissions added (if needed)
- [ ] Privacy policy URL added to Info.plist and App Store Connect
- [ ] Terms of service URL added to App Store Connect
- [ ] Location permission descriptions are clear
- [ ] All permission descriptions are accurate

### Before Submission

- [ ] Privacy policy is live and accessible
- [ ] Terms of service is live and accessible
- [ ] App Store Connect metadata is complete
- [ ] Screenshots are uploaded (all required sizes)
- [ ] Support URL is valid
- [ ] App tested on physical iOS device
- [ ] All features work as described

---

## 🚀 BUILD COMMANDS

### Clean Build
```bash
cd user-app
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter build ios --release
```

### Archive in Xcode
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Any iOS Device" as target
3. Product → Archive
4. Distribute App → App Store Connect
5. Follow prompts

---

## 📝 NOTES

- **Privacy Policy**: Must be accessible without login
- **Terms of Service**: Should be accessible without login
- **Permissions**: Only request what you actually use
- **App Name**: Must match across all platforms and App Store Connect
- **Version**: Current version is 1.0.1+2 - increment for App Store submission

---

**Last Updated**: $(date)

