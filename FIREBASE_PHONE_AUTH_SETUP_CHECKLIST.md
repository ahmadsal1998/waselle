# Firebase Phone Authentication Setup Checklist

## ⚠️ Important: Firebase Phone Auth sends SMS automatically - no backend OTP needed!

Firebase Phone Authentication handles SMS sending automatically. The Flutter app calls Firebase directly, and Firebase sends the SMS to the user's phone. You should NOT see backend OTP generation logs for Firebase Phone Auth.

## ✅ Firebase Console Setup Checklist

### 1. Enable Phone Authentication
- [ ] Go to [Firebase Console](https://console.firebase.google.com/)
- [ ] Select your project: `wae-679cc`
- [ ] Navigate to **Authentication** → **Sign-in method**
- [ ] Find **Phone** provider
- [ ] Click **Enable**
- [ ] Save

### 2. Configure Authorized Domains (if needed)
- [ ] In Authentication → Settings → Authorized domains
- [ ] Add your domain if using web authentication

### 3. Android Configuration
- [ ] Go to **Project Settings** → **Your apps** → **Android app**
- [ ] Add **SHA-1 fingerprint**:
  ```bash
  # For debug keystore:
  keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
  
  # For release keystore:
  keytool -list -v -keystore /path/to/your/release.keystore -alias your-alias | grep SHA1
  ```
- [ ] Add **SHA-256 fingerprint** (same command, look for SHA256)
- [ ] Download updated `google-services.json`
- [ ] Replace `user-app/android/app/google-services.json`

### 4. iOS Configuration
- [ ] Go to **Project Settings** → **Your apps** → **iOS app**
- [ ] Upload **APNs Authentication Key** or **APNs Certificate**
  - Get from Apple Developer account
  - Upload to Firebase Console
- [ ] Download updated `GoogleService-Info.plist`
- [ ] Replace `user-app/ios/Runner/GoogleService-Info.plist`

### 5. Firebase Blaze Plan (REQUIRED for Production SMS)
- [ ] Go to **Project Settings** → **Usage and billing**
- [ ] Upgrade to **Blaze Plan** (pay-as-you-go)
- [ ] Phone Authentication SMS requires Blaze plan
- [ ] Free Spark plan does NOT support production SMS

### 6. Test Phone Numbers (For Testing)
- [ ] Go to **Authentication** → **Sign-in method** → **Phone**
- [ ] Scroll to **Phone numbers for testing**
- [ ] Add test phone numbers (e.g., `+970123456789`)
- [ ] Add test verification codes (e.g., `123456`)
- [ ] Use these for testing without real SMS

## 🔍 Troubleshooting

### Issue: OTP SMS not received

1. **Check Firebase Console:**
   - Go to **Authentication** → **Usage** tab
   - Check for quota limits or errors
   - Verify Blaze plan is active

2. **Check Phone Number Format:**
   - Must include country code: `+970XXXXXXXXX`
   - No spaces, dashes, or special characters
   - Current default in code: `+970` (Palestine)

3. **Check App Logs:**
   - Look for: `📱 Attempting to send OTP to: +970XXXXXXXXX`
   - Look for: `✅ OTP code sent successfully` or error messages
   - Check Firebase error codes

4. **Common Firebase Error Codes:**
   - `invalid-phone-number`: Wrong format
   - `quota-exceeded`: Need Blaze plan
   - `app-not-authorized`: SHA-1/SHA-256 not configured
   - `too-many-requests`: Rate limit exceeded

### Issue: Backend generating OTP codes

If you see backend logs like `📱 OTP for +970...`, this is from:
- **Order OTP endpoint** (`/api/orders/send-otp`) - Different flow, not Firebase Auth
- **Email OTP** (for email verification) - Different flow

Firebase Phone Auth does NOT generate OTP in backend - it's handled by Firebase directly.

## 📱 Testing

### Test with Firebase Test Numbers:
1. Add test phone number in Firebase Console
2. Use test verification code (e.g., `123456`)
3. No real SMS will be sent

### Test with Real Phone:
1. Ensure Blaze plan is active
2. Use real phone number with country code
3. SMS will be sent automatically by Firebase
4. Check phone for 6-digit code

## 🔗 Useful Links

- [Firebase Phone Auth Documentation](https://firebase.google.com/docs/auth/android/phone-auth)
- [Firebase Pricing](https://firebase.google.com/pricing)
- [Firebase Console](https://console.firebase.google.com/)

## ⚡ Quick Fixes

### Change Default Country Code:
Edit `user-app/lib/services/firebase_auth_service.dart` line 55:
```dart
formattedPhone = '+970$formattedPhone'; // Change +970 to your country code
```

### Enable Test Mode:
Add test phone numbers in Firebase Console to avoid SMS costs during development.

