# Firebase Configuration Setup

## ✅ Flutter Apps Configuration (COMPLETED)

Both `user-app` and `driver-app` have been configured with the new Firebase project:
- **Project ID**: `wae-679cc`
- **API Key**: `AIzaSyASIXUzzjt5BE_pGmtIw2Dw2ZU6kjevkOM`
- Configuration files created:
  - `user-app/lib/firebase_options.dart`
  - `driver-app/lib/firebase_options.dart`

## 🔧 Backend Configuration (REQUIRED)

The backend needs a Firebase Admin SDK service account JSON file to verify Firebase tokens.

### Steps to Configure Backend:

1. **Download Firebase Service Account JSON**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select project: `wae-679cc`
   - Go to Project Settings → Service Accounts
   - Click "Generate New Private Key"
   - Save the JSON file

2. **Replace the Template File**:
   - A template file has been created at: `backend/wae-679cc-firebase-adminsdk.json`
   - **IMPORTANT**: Replace the template content with the actual JSON file downloaded from Firebase Console
   - The template file contains placeholder values that must be replaced with real credentials

3. **Update Backend `.env` file**:
   Create or update `backend/.env` with:
   ```env
   FIREBASE_SERVICE_ACCOUNT_PATH=./wae-679cc-firebase-adminsdk.json
   ```

   Or alternatively, you can use the JSON content directly:
   ```env
   FIREBASE_SERVICE_ACCOUNT_KEY={"type":"service_account","project_id":"wae-679cc",...}
   ```

### ⚠️ Security Note:
- The service account JSON file contains sensitive credentials
- **DO NOT** commit this file to version control (it should be in `.gitignore`)
- Keep it secure and never share it publicly

### Important Notes:

- The Flutter apps use **Firebase Client SDK** (configured via `firebase_options.dart`)
- The backend uses **Firebase Admin SDK** (requires service account JSON)
- These are different configurations for different purposes:
  - **Client SDK**: For sending OTP and verifying codes in mobile apps
  - **Admin SDK**: For verifying Firebase tokens on the backend server

### Verify Configuration:

1. **Flutter Apps**: Run the apps and check Firebase initialization logs
2. **Backend**: Start the server and check for:
   ```
   ✅ Firebase Admin SDK initialized successfully
   ```

If you see this message, Firebase is properly configured!

