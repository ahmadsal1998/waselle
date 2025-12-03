# Review Mode Build Instructions

## Quick Reference

### TestFlight Build (Review Mode ON)
```bash
flutter build ios --release --dart-define=TESTFLIGHT=true
```

### App Store Release (Review Mode OFF)
```bash
flutter build ios --release
```

## Detailed Instructions

### Building for TestFlight (App Store Review)

Review Mode will be **automatically enabled** for Apple reviewers.

#### Using Flutter CLI:
```bash
cd user-app
flutter build ios --release --dart-define=TESTFLIGHT=true
```

#### Using Xcode:
1. Open `user-app/ios/Runner.xcworkspace` in Xcode
2. Select Product → Scheme → Edit Scheme
3. Choose "Archive" (for TestFlight) or "Run"
4. Go to "Arguments" tab
5. Under "Arguments Passed On Launch", add:
   ```
   --dart-define=TESTFLIGHT=true
   ```
6. Build and upload to TestFlight

**Result**: Review Mode automatically ON ✅

### Building for App Store Release

Review Mode will be **automatically disabled** - no manual code changes needed.

#### Using Flutter CLI:
```bash
cd user-app
flutter build ios --release
```

#### Using Xcode:
1. Open `user-app/ios/Runner.xcworkspace` in Xcode
2. Build normally (Archive → Distribute)
3. **Do NOT** add TESTFLIGHT define

**Result**: Review Mode automatically OFF ✅

## How It Works

The build system automatically detects the environment:

```dart
// In lib/config/review_mode_config.dart
static const bool isTestFlight = bool.fromEnvironment(
  'TESTFLIGHT',
  defaultValue: false,
);
```

- **TestFlight build**: `TESTFLIGHT=true` → Review Mode ON
- **App Store build**: `TESTFLIGHT` not set → Review Mode OFF automatically

## Verification

### Verify Review Mode is ON (TestFlight):
1. Build with `--dart-define=TESTFLIGHT=true`
2. Run the app
3. Check logs for: `🍎 Review Mode: Activated (TestFlight build detected)`
4. Mock data should be visible

### Verify Review Mode is OFF (App Store):
1. Build without TESTFLIGHT define
2. Run the app
3. No Review Mode log messages
4. Real backend data should be used

## Important Notes

✅ **No code changes needed** - Everything is controlled at build time
✅ **Automatic detection** - Review Mode ON in TestFlight, OFF in App Store
✅ **Production safe** - Review Mode disabled by default when TESTFLIGHT not set
✅ **Zero manual intervention** - Build system handles everything

## Troubleshooting

### Review Mode not activating in TestFlight
- Verify: `--dart-define=TESTFLIGHT=true` is included in build command
- Check: Build logs for Review Mode activation message
- Ensure: Release build (not debug)

### Review Mode appearing in production
- Verify: Build command does NOT include `--dart-define=TESTFLIGHT=true`
- Check: Standard release build is used
- Review Mode automatically disabled when TESTFLIGHT not set

## Summary

| Build Type | Command | Review Mode |
|------------|---------|-------------|
| TestFlight | `flutter build ios --release --dart-define=TESTFLIGHT=true` | ✅ ON |
| App Store | `flutter build ios --release` | ❌ OFF |

**That's it!** No manual configuration changes needed.

