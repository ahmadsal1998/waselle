import * as admin from 'firebase-admin';
import * as path from 'path';
import * as fs from 'fs';

// Initialize Firebase Admin SDK
let firebaseApp: admin.app.App | null = null;

export const initializeFirebase = (): void => {
  if (firebaseApp) {
    return; // Already initialized
  }

  try {
    // Priority 1: Check if service account credentials are provided via individual env vars
    // This is the preferred method for Render and other cloud platforms
    if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        }),
      });
      console.log('✅ Firebase Admin SDK initialized with service account credentials from environment variables');
      return;
    }

    // Priority 2: Check if service account key path is provided via env
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
    
    if (serviceAccountPath) {
      // Initialize with service account file from env
      const serviceAccount = require(path.resolve(serviceAccountPath));
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log('✅ Firebase Admin SDK initialized with service account file:', serviceAccountPath);
      return;
    }

    // Priority 3: Check if service account JSON string is provided via env
    if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
      // Initialize with service account JSON string from env
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log('✅ Firebase Admin SDK initialized with FIREBASE_SERVICE_ACCOUNT_KEY environment variable');
      return;
    }

    // Priority 4: Try to auto-discover service account file (for local development)
    const possiblePaths = [
      // In backend directory
      path.join(process.cwd(), 'wae-679cc-firebase-adminsdk.json'),
      // In parent directory (workspace root)
      path.join(process.cwd(), '..', 'wae-679cc-firebase-adminsdk.json'),
      // Absolute path from workspace root
      path.join(__dirname, '..', '..', 'wae-679cc-firebase-adminsdk.json'),
    ];

    let foundPath: string | null = null;
    for (const possiblePath of possiblePaths) {
      if (fs.existsSync(possiblePath)) {
        foundPath = possiblePath;
        break;
      }
    }

    // If still not found, try to find any firebase-adminsdk file
    if (!foundPath) {
      try {
        const backendDir = process.cwd();
        const files = fs.readdirSync(backendDir);
        const firebaseFile = files.find((file) => file.includes('firebase-adminsdk') && file.endsWith('.json'));
        if (firebaseFile) {
          foundPath = path.join(backendDir, firebaseFile);
        }
      } catch (error) {
        // Directory read failed, continue
      }
    }

    if (foundPath) {
      const serviceAccount = require(foundPath);
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log('✅ Firebase Admin SDK initialized with auto-discovered service account file:', foundPath);
      return;
    }

    // If we reach here, no valid configuration was found
    // DO NOT use applicationDefault() as it tries to access Google Cloud metadata
    // which fails on non-Google Cloud platforms like Render
    throw new Error(
      'Firebase configuration not found. Please set one of the following:\n' +
      '  - FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL (recommended for cloud platforms)\n' +
      '  - FIREBASE_SERVICE_ACCOUNT_PATH (path to service account JSON file)\n' +
      '  - FIREBASE_SERVICE_ACCOUNT_KEY (service account JSON as string)\n' +
      '  - Place a firebase-adminsdk JSON file in the backend directory (for local development)'
    );
  } catch (error: any) {
    console.error('❌ Error initializing Firebase Admin SDK:', error.message);
    throw error;
  }
};

export const verifyFirebaseToken = async (idToken: string): Promise<admin.auth.DecodedIdToken> => {
  if (!firebaseApp) {
    initializeFirebase();
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    return decodedToken;
  } catch (error: any) {
    console.error('❌ Error verifying Firebase token:', error.message);
    throw new Error('Invalid Firebase token');
  }
};

export { admin };

