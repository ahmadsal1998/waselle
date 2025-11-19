# Flutter iOS Debug Connection Troubleshooting

## Error: Connection closed before full header was received

This is a common Flutter/Xcode debugging connection issue. Try these solutions in order:

### 1. Kill Stuck Flutter Processes
```bash
# Kill all Flutter processes
pkill -f flutter
pkill -f dart

# Or kill specific stuck processes
kill -9 <PID>
```

### 2. Clean Build
```bash
cd user-app
flutter clean
flutter pub get
```

### 3. Close Xcode Completely
- Quit Xcode completely (Cmd+Q)
- Wait a few seconds
- Try running again

### 4. Restart iOS Simulator/Device
- If using simulator: Close and restart the simulator
- If using physical device: Disconnect and reconnect

### 5. Try Different Device
```bash
flutter run
# Choose a different device (simulator instead of physical device, or vice versa)
```

### 6. Reset iOS Simulator (if using simulator)
```bash
# In Terminal
xcrun simctl shutdown all
xcrun simctl erase all
```

### 7. Check Xcode Version
- Make sure Xcode is up to date
- Open Xcode → Preferences → Locations → Command Line Tools (should be selected)

### 8. Try Release Mode (to test if it's debug-specific)
```bash
flutter run --release
```

### 9. Check Network/Firewall
- Make sure no firewall is blocking localhost connections
- Try disabling VPN if active

### 10. Rebuild Pods (iOS specific)
```bash
cd user-app/ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter run
```

### 11. Check Device Connection (Physical Device)
- Make sure device is unlocked
- Trust the computer if prompted
- Check that device appears in Xcode → Window → Devices and Simulators

### 12. Try Building from Xcode Directly
```bash
cd user-app/ios
open Runner.xcworkspace
# Build and run from Xcode to see more detailed error messages
```

## Most Common Solutions

1. **Kill stuck processes** (most common fix)
2. **Clean build** (`flutter clean`)
3. **Close Xcode and restart**
4. **Try simulator instead of physical device** (or vice versa)

## If Nothing Works

Try running in release mode to see if the app actually works:
```bash
flutter run --release
```

If release mode works, the issue is specifically with the debug connection, not your code.

