# Review Mode Setup Guide

## Overview

Review Mode is a special mode that automatically activates during Apple App Store review, allowing Apple reviewers to fully test the app without requiring the driver app. It provides mock data including test user accounts, predefined addresses, sample orders, test drivers, and predefined routes.

## Features

- **Automatic Activation**: Review Mode activates automatically via compile-time environment variables
- **Zero Manual Configuration**: No code changes needed - controlled at build time
- **Mock Data**: Provides complete test data for full app functionality testing
- **Hidden from Users**: Completely hidden from regular users in production builds
- **No UI Changes**: No visible UI elements or settings for Review Mode

## Build Configuration

### For TestFlight Builds (App Store Review)

**Build Command:**
```bash
flutter build ios --release --dart-define=TESTFLIGHT=true
```

**Or in Xcode:**
1. Open your project in Xcode
2. Go to Product → Scheme → Edit Scheme
3. Select "Run" or "Archive"
4. Go to "Arguments" tab
5. Add to "Arguments Passed On Launch":
   ```
   --dart-define=TESTFLIGHT=true
   ```
6. Build and upload to TestFlight

**Result**: Review Mode automatically ON for Apple reviewers

### For Final App Store Release

**Build Command (Standard):**
```bash
flutter build ios --release
```

**Or in Xcode:**
- Build normally without the TESTFLIGHT define
- Review Mode automatically OFF

**Result**: Review Mode automatically disabled - no manual code changes needed

**Key Point**: Simply don't include `--dart-define=TESTFLIGHT=true` when building for App Store release, and Review Mode will be automatically disabled.

## Mock Data Provided

When Review Mode is active, the following mock data is available:

### Test User Account
- Name: "App Review Tester"
- Email: reviewer@apple.com
- Phone: +972501234567

### Predefined Addresses
- Central Market, Ramallah City Center
- Al-Bireh Park, Al-Bireh
- Birzeit University, Birzeit

### Sample Orders
- Multiple orders in different states (pending, accepted, on_the_way)
- Both "send" and "receive" order types
- Various vehicle types and order categories

### Test Driver
- Name: "Review Test Driver"
- Available status
- Location on map

### Predefined Route
- Route from Ramallah City Center to Al-Bireh Park
- For order tracking testing

## Testing Review Mode Locally (Debug Only)

To test Review Mode during development:

**Debug Build Command:**
```bash
flutter run --dart-define=ENABLE_DEBUG_REVIEW_MODE=true
```

**Or in VS Code/Android Studio:**
Add to launch configuration:
```json
{
  "args": ["--dart-define=ENABLE_DEBUG_REVIEW_MODE=true"]
}
```

**Note**: Review Mode in debug mode is only for testing. It has no effect in release builds unless TESTFLIGHT is also set.

## How It Works

1. **Compile-Time Detection**: Review Mode uses Dart's `bool.fromEnvironment()` to detect build-time flags
   - TestFlight builds: `--dart-define=TESTFLIGHT=true` → Review Mode ON
   - App Store releases: No TESTFLIGHT define → Review Mode OFF automatically

2. **Automatic Activation**: When Review Mode is active:
   - `AuthViewModel` uses mock user data
   - `OrderViewModel` uses mock orders
   - `DriverViewModel` uses mock driver locations
   - `LocationViewModel` uses mock location data

3. **Zero Manual Intervention**: No code changes needed - controlled entirely at build time via environment variables

## Security Notes

- Review Mode is **automatically disabled** in production App Store releases (TESTFLIGHT not set)
- Regular users will **never** see Review Mode or mock data
- Mock data is only visible to Apple reviewers during TestFlight review
- No UI indicators or settings expose Review Mode to users
- Compile-time detection ensures no runtime activation possible

## Files Modified

- `lib/services/review_mode_service.dart` - Core service for detecting and managing Review Mode
- `lib/services/review_mode_mock_data.dart` - Mock data provider
- `lib/config/review_mode_config.dart` - Compile-time environment variable detection
- `lib/view_models/auth_view_model.dart` - Integrated to use mock user
- `lib/view_models/order_view_model.dart` - Integrated to use mock orders
- `lib/view_models/driver_view_model.dart` - Integrated to use mock drivers
- `lib/view_models/location_view_model.dart` - Integrated to use mock location

## Checklist Before App Store Submission

### For TestFlight Build
- [ ] Build with `--dart-define=TESTFLIGHT=true`
- [ ] Test Review Mode in TestFlight build
- [ ] Submit TestFlight build for App Store review

### For Final App Store Release
- [ ] Build **without** `--dart-define=TESTFLIGHT=true` (standard build)
- [ ] Review Mode automatically disabled - no code changes needed
- [ ] Verify final App Store release doesn't have Review Mode
- [ ] Submit final App Store release

## Troubleshooting

### Review Mode not activating in TestFlight

1. Verify you used `--dart-define=TESTFLIGHT=true` in build command
2. Ensure you're building a release build (not debug)
3. Check that you're testing on iOS device (Review Mode is iOS-only)
4. Verify the environment variable is being passed correctly

### Review Mode appearing in production

**This should never happen** if you follow the build process correctly:
1. App Store builds should NOT include `--dart-define=TESTFLIGHT=true`
2. Review Mode automatically disabled when TESTFLIGHT is not set
3. If it appears, verify your build command doesn't include TESTFLIGHT define

## Support

For questions or issues with Review Mode, check the configuration file and ensure you're following the setup instructions correctly.

