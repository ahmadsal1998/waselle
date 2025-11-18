import admin from 'firebase-admin';
import * as path from 'path';

// Initialize Firebase Admin SDK
try {
  const fs = require('fs');
  let serviceAccountPath: string | null = null;
  
  // Try multiple possible locations for the service account file
  const possiblePaths = [
    // In backend directory
    path.join(process.cwd(), 'wae-60069-firebase-adminsdk-fbsvc-b9d3a1e951.json'),
    // In parent directory (workspace root)
    path.join(process.cwd(), '..', 'wae-60069-firebase-adminsdk-fbsvc-b9d3a1e951.json'),
    // Absolute path from workspace root
    path.join(__dirname, '..', '..', 'wae-60069-firebase-adminsdk-fbsvc-b9d3a1e951.json'),
  ];

  // Find the first existing path
  for (const possiblePath of possiblePaths) {
    if (fs.existsSync(possiblePath)) {
      serviceAccountPath = possiblePath;
      break;
    }
  }

  if (serviceAccountPath) {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    console.log('✅ Firebase Admin SDK initialized with service account file:', serviceAccountPath);
  } else {
    // Try environment variables as fallback
    if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        }),
      });
      console.log('✅ Firebase Admin SDK initialized with environment variables');
    } else {
      throw new Error('Firebase configuration not found. Please ensure the service account key file exists or set environment variables.');
    }
  }
} catch (error: any) {
  console.error('❌ Error initializing Firebase Admin SDK:', error.message);
  console.warn('⚠️  Firebase Phone Authentication will not work without proper configuration');
  console.warn('💡 Place the service account key file in the backend directory or set FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, and FIREBASE_CLIENT_EMAIL environment variables');
}

export default admin;

