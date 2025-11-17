# Firebase Phone Auth Setup Guide

Complete step-by-step guide to set up and use Firebase Phone Auth for OTP verification in your delivery system.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Firebase Console Setup](#firebase-console-setup)
3. [Backend Setup](#backend-setup)
4. [Client Setup](#client-setup)
5. [Testing Checklist](#testing-checklist)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- ✅ Node.js backend running (Express/TypeScript)
- ✅ MongoDB database configured
- ✅ Client app (Flutter/React/Web) ready for Firebase integration
- ✅ Firebase account (create one at https://console.firebase.google.com)

---

## Part 1: Firebase Console Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **"Add project"** or select existing project
3. Enter project name (e.g., "Delivery System")
4. (Optional) Enable Google Analytics
5. Click **"Create project"**
6. Wait for project creation, then click **"Continue"**

### Step 2: Enable Phone Authentication

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Click on **Phone** provider
3. Toggle **Enable** to ON
4. Click **"Save"**
5. (For testing) Add test phone numbers if needed:
   - Click **"Phone numbers for testing"**
   - Add phone number and OTP code (e.g., +970501234567, code: 123456)

### Step 3: Get Service Account Credentials

1. In Firebase Console, click **Project Settings** (gear icon) → **Service Accounts**
2. Click **"Generate new private key"**
3. Click **"Generate key"** in the dialog
4. A JSON file will download - **SAVE THIS FILE SECURELY** (don't commit to git!)
5. Open the JSON file and note these values:
   - `project_id` → This is your `FIREBASE_PROJECT_ID`
   - `client_email` → This is your `FIREBASE_CLIENT_EMAIL`
   - `private_key` → This is your `FIREBASE_PRIVATE_KEY` (keep the quotes and \n)

### Step 4: Configure Firebase for Your Platforms

#### For Flutter Apps:

1. In Firebase Console, click **Project Overview** → **Add app** → **Flutter**
2. Follow the setup wizard:
   - Register app with package name (e.g., `com.yourcompany.deliveryapp`)
   - Download `google-services.json` (Android)
   - Download `GoogleService-Info.plist` (iOS)
3. Add these files to your Flutter project:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/` (open in Xcode)

#### For Web Apps:

1. In Firebase Console, click **Project Overview** → **Add app** → **Web** (</> icon)
2. Register app with a nickname
3. Copy the Firebase config object (you'll need this later):
   ```javascript
   const firebaseConfig = {
     apiKey: "AIza...",
     authDomain: "your-project.firebaseapp.com",
     projectId: "your-project-id",
     // ... other config
   };
   ```

---

## Part 2: Backend Setup

### Step 5: Install Firebase Admin SDK

```bash
cd backend
npm install firebase-admin
```

### Step 6: Configure Environment Variables

1. Open your `.env` file in the `backend/` directory
2. Add these Firebase credentials (from Step 3):

```env
# Firebase Admin SDK Credentials
FIREBASE_PROJECT_ID=your-project-id-from-json
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...\n-----END PRIVATE KEY-----\n"

# JWT Configuration (if not already set)
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRE=7d
```

**Important Notes:**
- Keep the quotes around `FIREBASE_PRIVATE_KEY`
- The private key must include `\n` for newlines (already in the JSON)
- Never commit `.env` to version control
- In production, use environment variables or secrets management

### Step 7: Verify Backend Setup

1. Start your backend server:
   ```bash
   cd backend
   npm run dev
   ```

2. Check console for Firebase initialization:
   - ✅ Should see: No Firebase warnings
   - ❌ If you see: `Missing Firebase service account env vars` → Check Step 6

3. Test the endpoints (optional):
   ```bash
   # Test check phone endpoint
   curl -X POST http://localhost:5000/api/auth/check-phone \
     -H "Content-Type: application/json" \
     -d '{"phone": "501234567", "countryCode": "+970"}'
   ```

---

## Part 3: Client Setup

### Step 8: Flutter Setup

#### Install Firebase Packages

1. Add to `pubspec.yaml`:
   ```yaml
   dependencies:
     firebase_core: ^2.24.2
     firebase_auth: ^4.15.3
   ```

2. Run:
   ```bash
   flutter pub get
   ```

#### Initialize Firebase

1. In `main.dart`, initialize Firebase:
   ```dart
   import 'package:firebase_core/firebase_core.dart';
   import 'firebase_options.dart'; // Generated file
   
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
     );
     runApp(MyApp());
   }
   ```

2. Generate Firebase options (if not exists):
   ```bash
   flutterfire configure
   ```
   This will create `lib/firebase_options.dart`

#### Implement Phone Auth Flow

Create a phone auth service (example in `lib/services/phone_auth_service.dart`):

```dart
import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  
  // Step 1: Send OTP
  Future<void> sendOTP(String phoneNumber) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        // Auto-verification (Android only)
        _signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        throw Exception('Verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }
  
  // Step 2: Verify OTP and get ID token
  Future<String> verifyOTP(String smsCode) async {
    if (_verificationId == null) {
      throw Exception('No verification ID. Call sendOTP first.');
    }
    
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );
    
    final userCredential = await _auth.signInWithCredential(credential);
    final idToken = await userCredential.user?.getIdToken();
    
    if (idToken == null) {
      throw Exception('Failed to get ID token');
    }
    
    return idToken;
  }
  
  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    await _auth.signInWithCredential(credential);
  }
}
```

### Step 9: Web/React Setup

#### Install Firebase Packages

```bash
npm install firebase
```

#### Initialize Firebase

1. Create `src/firebase/config.ts`:
   ```typescript
   import { initializeApp } from 'firebase/app';
   import { getAuth } from 'firebase/auth';
   
   const firebaseConfig = {
     apiKey: "AIza...", // From Step 4
     authDomain: "your-project.firebaseapp.com",
     projectId: "your-project-id",
     // ... other config from Firebase Console
   };
   
   const app = initializeApp(firebaseConfig);
   export const auth = getAuth(app);
   ```

#### Implement Phone Auth Flow

```typescript
import { signInWithPhoneNumber, RecaptchaVerifier } from 'firebase/auth';
import { auth } from './firebase/config';

// Step 1: Send OTP
export const sendOTP = async (phoneNumber: string) => {
  const appVerifier = new RecaptchaVerifier('recaptcha-container', {
    size: 'invisible',
  }, auth);
  
  const confirmationResult = await signInWithPhoneNumber(
    auth, 
    phoneNumber, 
    appVerifier
  );
  
  return confirmationResult;
};

// Step 2: Verify OTP
export const verifyOTP = async (
  confirmationResult: any,
  code: string
): Promise<string> => {
  const result = await confirmationResult.confirm(code);
  const idToken = await result.user.getIdToken();
  return idToken;
};
```

---

## Part 4: Integration Steps

### Step 10: Implement Complete Flow in Client

#### Flutter Example Flow

```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../services/phone_auth_service.dart';
import '../repositories/api_service.dart';

class OrderFlowController {
  final PhoneAuthService _phoneAuth = PhoneAuthService();
  
  // Step 1: User enters phone number
  Future<void> initiatePhoneAuth(String phoneNumber) async {
    try {
      await _phoneAuth.sendOTP(phoneNumber);
      // Show OTP input screen
    } catch (e) {
      // Handle error
    }
  }
  
  // Step 2: User enters OTP
  Future<void> verifyOTPAndLogin(String smsCode) async {
    try {
      // Get Firebase ID token
      final idToken = await _phoneAuth.verifyOTP(smsCode);
      
      // Send to backend to verify and get JWT
      final response = await ApiService.verifyPhoneAndLogin(
        idToken: idToken,
        countryCode: '+970', // Get from user input
      );
      
      // Store JWT token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response['token']);
      
      // User is now logged in - can place orders
      // Navigate to order creation screen
    } catch (e) {
      // Handle error
    }
  }
  
  // Step 3: Place order (if logged in)
  Future<void> placeOrder(Map<String, dynamic> orderData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null) {
      // User not logged in - require phone auth first
      throw Exception('Please verify your phone number first');
    }
    
    // Use authenticated endpoint (JWT token automatically sent in headers)
    await ApiService.createOrder(...orderData);
  }
  
  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    // Clear any other session data
  }
}
```

#### Web/React Example Flow

```typescript
import { verifyPhoneAndLogin, createOrder } from './services';
import { sendOTP, verifyOTP } from './firebase/phoneAuth';

// Step 1: Send OTP
const handleSendOTP = async (phoneNumber: string) => {
  const confirmationResult = await sendOTP(phoneNumber);
  setConfirmationResult(confirmationResult);
};

// Step 2: Verify OTP and login
const handleVerifyOTP = async (code: string) => {
  const idToken = await verifyOTP(confirmationResult, code);
  
  // Send to backend
  const { token } = await verifyPhoneAndLogin(idToken);
  
  // Store JWT
  localStorage.setItem('token', token);
  
  // User logged in
};

// Step 3: Place order
const handlePlaceOrder = async (orderData: any) => {
  const token = localStorage.getItem('token');
  
  if (!token) {
    throw new Error('Please verify your phone number first');
  }
  
  // Order API automatically includes token in headers
  await createOrder(orderData);
};
```

### Step 11: Update API Client to Include JWT

Make sure your API client automatically includes JWT token in headers:

#### Flutter Example

In `api_service.dart`, the `_getHeaders()` method should already include:
```dart
static Future<Map<String, String>> _getHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  return {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
}
```

#### Web/React Example

```typescript
// In your API client
axios.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});
```

---

## Part 5: Testing Checklist

### Backend Tests

- [ ] Backend starts without Firebase errors
- [ ] `POST /api/auth/check-phone` returns correct response
- [ ] `POST /api/auth/verify-phone` with valid Firebase ID token:
  - [ ] Creates new user if phone doesn't exist
  - [ ] Finds existing user if phone exists
  - [ ] Returns JWT token
- [ ] `POST /api/orders/` with JWT token creates order successfully
- [ ] `POST /api/orders/create-with-firebase` with Firebase ID token creates order

### Client Tests

#### First Time User Flow

- [ ] User enters phone number
- [ ] OTP is sent via Firebase (SMS received)
- [ ] User enters OTP
- [ ] Firebase verifies OTP
- [ ] Client gets Firebase ID token
- [ ] Client sends ID token to `/api/auth/verify-phone`
- [ ] Backend creates new user
- [ ] JWT token is received and stored
- [ ] User can place order without re-entering OTP

#### Returning User Flow (Logged In)

- [ ] User opens app (JWT token exists)
- [ ] User can place order directly (no OTP needed)
- [ ] Multiple orders can be placed without re-verification

#### Logged Out User Flow

- [ ] User logs out (JWT token cleared)
- [ ] User tries to place order
- [ ] System prompts for phone verification
- [ ] OTP flow is triggered again

### Edge Cases

- [ ] Invalid OTP shows error message
- [ ] Expired OTP token shows error
- [ ] Network errors are handled gracefully
- [ ] JWT token expiration is handled
- [ ] Phone number format validation works

---

## Part 6: Troubleshooting

### Issue: Firebase Admin not initialized

**Error:** `Firebase Admin is not initialized`

**Solution:**
1. Check `.env` file has all three Firebase variables
2. Verify `FIREBASE_PRIVATE_KEY` has quotes and `\n` characters
3. Restart backend server

### Issue: OTP not received

**Possible Causes:**
1. Phone number format incorrect (must be E.164: +970501234567)
2. Firebase Phone Auth not enabled in console
3. Test phone numbers not configured
4. Country/region restrictions

**Solution:**
1. Use correct format: `+[country code][number]`
2. Enable Phone Auth in Firebase Console → Authentication
3. Add test numbers for development
4. Check Firebase quotas/billing

### Issue: Invalid Firebase ID Token

**Error:** `Invalid or expired Firebase ID token`

**Solution:**
1. Token might be expired - get fresh token from Firebase
2. Verify Firebase project ID matches in client and backend
3. Check token is being sent correctly in request body

### Issue: JWT token not working

**Error:** `Authentication required` or `Invalid token`

**Solution:**
1. Verify JWT_SECRET is set in backend `.env`
2. Check token is stored correctly in client
3. Verify Authorization header format: `Bearer <token>`
4. Check token hasn't expired (default: 7 days)

### Issue: User not created

**Error:** User exists but can't login, or new user not created

**Solution:**
1. Check MongoDB connection
2. Verify User model schema
3. Check backend logs for errors
4. Ensure phone number is unique in database

---

## Quick Reference

### API Endpoints

```
POST /api/auth/check-phone
Body: { phone: string, countryCode?: string }
Response: { exists: boolean, phone: string, message: string }

POST /api/auth/verify-phone
Body: { idToken: string, countryCode?: string }
Response: { token: string, user: {...}, message: string }

POST /api/orders/
Headers: { Authorization: "Bearer <JWT_TOKEN>" }
Body: { ...orderData }
Response: { order: {...}, message: string }

POST /api/orders/create-with-firebase
Body: { idToken: string, ...orderData }
Response: { order: {...}, token: string, user: {...} }
```

### Environment Variables Checklist

Backend `.env`:
- [ ] `FIREBASE_PROJECT_ID`
- [ ] `FIREBASE_CLIENT_EMAIL`
- [ ] `FIREBASE_PRIVATE_KEY`
- [ ] `JWT_SECRET`
- [ ] `JWT_EXPIRE`

### Client Configuration Checklist

Flutter:
- [ ] `google-services.json` in `android/app/`
- [ ] `GoogleService-Info.plist` in `ios/Runner/`
- [ ] `firebase_core` and `firebase_auth` packages installed
- [ ] Firebase initialized in `main.dart`

Web/React:
- [ ] Firebase config object in client code
- [ ] `firebase` package installed
- [ ] Firebase initialized before use

---

## Security Best Practices

1. **Never commit** `.env` files or Firebase service account keys to git
2. **Use environment variables** or secrets management in production
3. **Validate phone numbers** on both client and server
4. **Set JWT expiration** appropriately (not too long)
5. **Use HTTPS** in production for all API calls
6. **Implement rate limiting** for OTP requests
7. **Monitor Firebase quotas** to prevent abuse

---

## Next Steps

1. ✅ Complete all setup steps above
2. ✅ Test the flow end-to-end
3. ✅ Handle edge cases and errors
4. ✅ Update UI/UX for phone auth flow
5. ✅ Deploy to staging environment
6. ✅ Test in production-like environment
7. ✅ Monitor logs and errors
8. ✅ Deploy to production

---

## Support

If you encounter issues:

1. Check Firebase Console for quotas/errors
2. Review backend logs for detailed error messages
3. Verify all environment variables are set correctly
4. Test with Firebase test phone numbers first
5. Check Firebase documentation: https://firebase.google.com/docs/auth

Good luck! 🚀

