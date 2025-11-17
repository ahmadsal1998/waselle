# Firebase Phone Auth Setup Checklist

Quick checklist to track your setup progress.

## 📋 Firebase Console Setup

- [ ] Create Firebase project
- [ ] Enable Phone Authentication in Firebase Console
- [ ] Generate Service Account Key (JSON file)
- [ ] Note down:
  - [ ] `FIREBASE_PROJECT_ID` (from JSON file)
  - [ ] `FIREBASE_CLIENT_EMAIL` (from JSON file)
  - [ ] `FIREBASE_PRIVATE_KEY` (from JSON file - keep quotes and \n)

### For Flutter Apps:
- [ ] Add Flutter app to Firebase project
- [ ] Download `google-services.json` → Place in `android/app/`
- [ ] Download `GoogleService-Info.plist` → Place in `ios/Runner/`
- [ ] Run `flutterfire configure` (generates firebase_options.dart)

### For Web Apps:
- [ ] Add Web app to Firebase project
- [ ] Copy Firebase config object (apiKey, authDomain, projectId, etc.)
- [ ] Create `src/firebase/config.ts` with config

---

## 🔧 Backend Setup

- [ ] Install Firebase Admin SDK: `npm install firebase-admin`
- [ ] Update `.env` file with:
  - [ ] `FIREBASE_PROJECT_ID=...`
  - [ ] `FIREBASE_CLIENT_EMAIL=...`
  - [ ] `FIREBASE_PRIVATE_KEY="..."` (with quotes!)
  - [ ] `JWT_SECRET=...` (if not already set)
  - [ ] `JWT_EXPIRE=7d` (if not already set)
- [ ] Restart backend server
- [ ] Verify no Firebase initialization errors in console

---

## 📱 Client Setup

### Flutter:
- [ ] Install packages: `firebase_core`, `firebase_auth`
- [ ] Run `flutter pub get`
- [ ] Initialize Firebase in `main.dart`
- [ ] Implement phone auth service (use guide examples)
- [ ] Update order flow to use new endpoints

### Web/React:
- [ ] Install Firebase: `npm install firebase`
- [ ] Create Firebase config file
- [ ] Implement phone auth functions (use guide examples)
- [ ] Update order flow to use new endpoints

---

## 🔌 API Integration

- [ ] Update API client to send JWT token in headers automatically
- [ ] Implement `/api/auth/verify-phone` endpoint call
- [ ] Implement `/api/auth/check-phone` endpoint call (optional)
- [ ] Store JWT token after verification
- [ ] Use JWT token for authenticated order creation
- [ ] Implement logout (clear JWT token)

---

## ✅ Testing

### Backend Tests:
- [ ] `POST /api/auth/check-phone` works
- [ ] `POST /api/auth/verify-phone` creates new user
- [ ] `POST /api/auth/verify-phone` finds existing user
- [ ] Returns JWT token after verification
- [ ] `POST /api/orders/` works with JWT token
- [ ] `POST /api/orders/create-with-firebase` works with Firebase ID token

### Client Tests:
- [ ] Phone number input works
- [ ] OTP is sent (SMS received)
- [ ] OTP verification works
- [ ] Firebase ID token obtained
- [ ] Backend verification successful
- [ ] JWT token stored
- [ ] Order creation works without OTP (logged in)
- [ ] Logout clears token
- [ ] After logout, OTP required again

---

## 🐛 Troubleshooting

If something doesn't work:

1. [ ] Check Firebase Console → Authentication → Phone is enabled
2. [ ] Verify all environment variables are set correctly
3. [ ] Check backend logs for detailed errors
4. [ ] Verify phone number format: `+[country][number]` (e.g., `+970501234567`)
5. [ ] Test with Firebase test phone numbers first
6. [ ] Check Firebase quotas/billing status
7. [ ] Verify JWT token is being sent in Authorization header

---

## 📝 Quick Reference

### Required Endpoints:
- `POST /api/auth/check-phone` - Check if phone exists (optional)
- `POST /api/auth/verify-phone` - Verify Firebase token, get JWT
- `POST /api/orders/` - Create order (requires JWT token)
- `POST /api/orders/create-with-firebase` - Create order with Firebase token

### Client Flow:
1. User enters phone → Firebase sends OTP
2. User enters OTP → Firebase verifies → Get ID token
3. Send ID token to `/api/auth/verify-phone` → Get JWT
4. Store JWT → User logged in
5. Create orders using JWT (no OTP needed)
6. Logout → Clear JWT → OTP required next time

---

## 🎯 Ready for Production?

- [ ] All tests pass
- [ ] Error handling implemented
- [ ] Environment variables secured (not in git)
- [ ] HTTPS configured
- [ ] Rate limiting implemented
- [ ] Firebase quotas monitored
- [ ] Logs are being monitored
- [ ] User experience is smooth

---

**Status:** ⬜ Not Started | 🟡 In Progress | ✅ Complete

---

*For detailed instructions, see `FIREBASE_PHONE_AUTH_SETUP_GUIDE.md`*

