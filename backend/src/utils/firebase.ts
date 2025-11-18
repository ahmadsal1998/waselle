import * as admin from 'firebase-admin';
import * as path from 'path';

// Initialize Firebase Admin SDK
let firebaseApp: admin.app.App | null = null;

export const initializeFirebase = (): void => {
  if (firebaseApp) {
    return; // Already initialized
  }

  try {
    // Check if service account key path is provided
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
    
    if (serviceAccountPath) {
      // Initialize with service account file
      const serviceAccount = require(path.resolve(serviceAccountPath));
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    } else if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
      // Initialize with service account JSON string from env
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
      firebaseApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    } else {
      // Try to use default credentials (for Google Cloud environments)
      firebaseApp = admin.initializeApp({
        credential: admin.credential.applicationDefault(),
      });
    }

    console.log('✅ Firebase Admin SDK initialized successfully');
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

