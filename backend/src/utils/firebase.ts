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
    // Check if service account key path is provided via env
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
    
    if (serviceAccountPath) {
      // Initialize with service account file from env
      const serviceAccount = require(path.resolve(serviceAccountPath));
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log('✅ Firebase Admin SDK initialized with service account file:', serviceAccountPath);
    } else if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
      // Initialize with service account JSON string from env
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
      console.log('✅ Firebase Admin SDK initialized with environment variable');
    } else {
      // Try to auto-discover service account file
      const possiblePaths = [
        // In backend directory
        path.join(process.cwd(), 'wae-679cc-firebase-adminsdk.json'),
        // In parent directory (workspace root)
        path.join(process.cwd(), '..', 'wae-679cc-firebase-adminsdk.json'),
        // Absolute path from workspace root
        path.join(__dirname, '..', '..', 'wae-679cc-firebase-adminsdk.json'),
        // Also try generic pattern
        path.join(process.cwd(), '*-firebase-adminsdk-*.json'),
      ];

      let foundPath: string | null = null;
      for (const possiblePath of possiblePaths) {
        // Skip glob patterns for now, check exact paths
        if (!possiblePath.includes('*') && fs.existsSync(possiblePath)) {
          foundPath = possiblePath;
          break;
        }
      }

      // If still not found, try to find any firebase-adminsdk file
      if (!foundPath) {
        const backendDir = process.cwd();
        const files = fs.readdirSync(backendDir);
        const firebaseFile = files.find((file) => file.includes('firebase-adminsdk') && file.endsWith('.json'));
        if (firebaseFile) {
          foundPath = path.join(backendDir, firebaseFile);
        }
      }

      if (foundPath) {
        const serviceAccount = require(foundPath);
        firebaseApp = admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
        });
        console.log('✅ Firebase Admin SDK initialized with auto-discovered service account file:', foundPath);
      } else if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY) {
        // Try environment variables as fallback
        firebaseApp = admin.initializeApp({
          credential: admin.credential.cert({
            projectId: process.env.FIREBASE_PROJECT_ID,
            privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
            clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          }),
        });
        console.log('✅ Firebase Admin SDK initialized with environment variables');
      } else {
        // Try to use default credentials (for Google Cloud environments)
        try {
          firebaseApp = admin.initializeApp({
            credential: admin.credential.applicationDefault(),
          });
          console.log('✅ Firebase Admin SDK initialized with application default credentials');
        } catch (defaultError: any) {
          throw new Error('Firebase configuration not found. Please ensure the service account key file exists or set environment variables (FIREBASE_SERVICE_ACCOUNT_PATH, FIREBASE_SERVICE_ACCOUNT_KEY, or FIREBASE_PROJECT_ID/FIREBASE_PRIVATE_KEY/FIREBASE_CLIENT_EMAIL).');
        }
      }
    }
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

