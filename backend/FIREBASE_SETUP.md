# Firebase Admin SDK Configuration

This guide explains how to configure Firebase Admin SDK for FCM push notifications.

## Configuration Methods

The backend supports multiple methods for configuring Firebase Admin SDK, in order of priority:

### Method 1: Environment Variables (Recommended for Cloud Deployment)

Set these environment variables in your deployment platform (Render, Heroku, etc.):

```bash
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYour private key here\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=your-service-account@your-project-id.iam.gserviceaccount.com
```

**How to get these values:**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** → **Service Accounts**
4. Click **Generate New Private Key**
5. Download the JSON file
6. Extract the following values:
   - `project_id` → `FIREBASE_PROJECT_ID`
   - `private_key` → `FIREBASE_PRIVATE_KEY` (keep the `\n` characters)
   - `client_email` → `FIREBASE_CLIENT_EMAIL`

**Important Notes:**
- The `FIREBASE_PRIVATE_KEY` should include the full private key with `\n` characters preserved
- On some platforms, you may need to escape the newlines as `\\n`
- The private key should be wrapped in quotes if it contains special characters

### Method 2: Service Account File Path (For Local Development)

Set the path to your service account JSON file:

```bash
FIREBASE_SERVICE_ACCOUNT_PATH=./wae-679cc-firebase-adminsdk.json
```

Place the service account JSON file in the backend directory.

### Method 3: Service Account JSON String

Provide the entire service account JSON as a string:

```bash
FIREBASE_SERVICE_ACCOUNT_KEY='{"type":"service_account","project_id":"...","private_key":"...","client_email":"..."}'
```

### Method 4: Auto-Discovery (For Local Development)

If no environment variables are set, the backend will automatically look for service account files:
- `wae-679cc-firebase-adminsdk.json` in the backend directory
- `wae-679cc-firebase-adminsdk.json` in the parent directory
- Any file matching `*-firebase-adminsdk-*.json` pattern

## Local Development Setup

1. **Download Service Account Key:**
   - Go to Firebase Console → Project Settings → Service Accounts
   - Click "Generate New Private Key"
   - Save the JSON file as `wae-679cc-firebase-adminsdk.json` in the `backend/` directory

2. **Or use environment variables:**
   - Create a `.env` file in the `backend/` directory
   - Add the Firebase environment variables (see Method 1 above)

## Cloud Deployment Setup

For cloud platforms like Render, Heroku, or Railway:

1. **Set Environment Variables:**
   - Go to your platform's environment variables settings
   - Add `FIREBASE_PROJECT_ID`, `FIREBASE_PRIVATE_KEY`, and `FIREBASE_CLIENT_EMAIL`
   - Make sure to properly escape the private key if needed

2. **Verify Configuration:**
   - Check server logs on startup
   - You should see: `✅ Firebase Admin SDK initialized with service account credentials from environment variables`

## Verification

After configuration, verify Firebase is working:

1. Start the backend server
2. Check the console logs for Firebase initialization message
3. Test FCM push notifications by making a call

## Troubleshooting

### Error: "Firebase configuration not found"

- Make sure at least one configuration method is set up
- Check that environment variables are properly set
- Verify the service account file exists (if using file-based method)
- Check that the JSON file is valid

### Error: "Invalid credentials"

- Verify the `FIREBASE_PRIVATE_KEY` includes the full key with proper formatting
- Check that `FIREBASE_CLIENT_EMAIL` matches the service account email
- Ensure `FIREBASE_PROJECT_ID` is correct
- Try regenerating the service account key

### Error: "Permission denied"

- Make sure the service account has the necessary permissions:
  - Firebase Cloud Messaging API Admin
  - Firebase Authentication Admin

## Security Notes

- **Never commit** service account JSON files to version control
- The `.gitignore` file already excludes `*-firebase-adminsdk-*.json` files
- Use environment variables for production deployments
- Rotate service account keys periodically

