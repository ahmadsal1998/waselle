# Firebase Phone Authentication Troubleshooting Guide

## Common Issues and Solutions

### 1. OTP Not Being Sent to Mobile Device

#### Check Firebase Console Configuration:

1. **Enable Phone Authentication:**
   - Go to Firebase Console → Authentication → Sign-in method
   - Enable "Phone" provider
   - Add authorized domains if needed

2. **Android Configuration:**
   - Go to Firebase Console → Project Settings → Your Android App
   - Add SHA-1 and SHA-256 fingerprints:
     ```bash
     # For debug keystore:
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     
     # For release keystore:
     keytool -list -v -keystore /path/to/your/release.keystore -alias your-alias
     ```
   - Download updated `google-services.json` and replace in `android/app/`

3. **iOS Configuration:**
   - Go to Firebase Console → Project Settings → Your iOS App
   - Upload APNs certificate or APNs Auth Key
   - Download updated `GoogleService-Info.plist` and replace in `ios/Runner/`

#### Check Phone Number Format:

- Phone numbers MUST include country code with `+` prefix
- Example: `+970XXXXXXXXX` (Palestine), `+1XXXXXXXXXX` (US/Canada)
- Current default in code: `+970` (Palestine)
- To change default, edit `user-app/lib/services/firebase_auth_service.dart` line 51

#### Check Error Messages:

The app now logs detailed error messages. Check console/logcat for:
- `📱 Attempting to send OTP to: +970XXXXXXXXX`
- `✅ OTP code sent successfully` or `❌ Firebase Auth Error`

### 2. Common Firebase Error Codes:

- **`invalid-phone-number`**: Phone number format is incorrect
- **`too-many-requests`**: Too many OTP requests. Wait before retrying
- **`quota-exceeded`**: Firebase SMS quota exceeded (Blaze plan required for production)
- **`app-not-authorized`**: SHA-1/SHA-256 not configured or app not authorized
- **`missing-verification-code`**: OTP code not provided
- **`invalid-verification-code`**: OTP code is incorrect

### 3. Testing Phone Authentication:

#### Test Phone Numbers (Firebase Console):
- Go to Firebase Console → Authentication → Sign-in method → Phone
- Add test phone numbers (e.g., `+970123456789`)
- Use test verification codes (e.g., `123456`)

#### Production:
- Requires Firebase Blaze plan (pay-as-you-go)
- SMS costs apply per verification
- Phone numbers must be real and verified

### 4. Debugging Steps:

1. **Check Logs:**
   ```bash
   # Android
   adb logcat | grep -i firebase
   
   # iOS (Xcode Console)
   # Look for Firebase-related messages
   ```

2. **Verify Firebase Initialization:**
   - Check that `firebase_options.dart` is properly configured
   - Verify `GoogleService-Info.plist` (iOS) and `google-services.json` (Android) are in place

3. **Test Phone Number Format:**
   - Ensure phone number includes country code
   - Remove any spaces, dashes, or special characters
   - Format: `+[country code][number]` (e.g., `+970123456789`)

4. **Check Network:**
   - Ensure device has internet connection
   - Check if Firebase services are accessible

### 5. Country Code Configuration:

To change the default country code, edit:
- `user-app/lib/services/firebase_auth_service.dart` line 51
- Change `'+970'` to your desired country code (e.g., `'+1'` for US, `'+44'` for UK)

Or add a country code selector in the UI.

### 6. Production Checklist:

- [ ] Firebase Phone Authentication enabled
- [ ] SHA-1/SHA-256 fingerprints added (Android)
- [ ] APNs certificate uploaded (iOS)
- [ ] Firebase Blaze plan activated
- [ ] Test phone numbers configured (for testing)
- [ ] Phone number format validated
- [ ] Error handling tested
- [ ] OTP verification flow tested end-to-end

## Need Help?

If OTP is still not being sent:
1. Check Firebase Console → Authentication → Usage tab for quota/errors
2. Review Firebase Console → Project Settings → Cloud Messaging for SMS configuration
3. Check device logs for specific error codes
4. Verify phone number format matches Firebase requirements

