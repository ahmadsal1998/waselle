import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import crypto from 'crypto';

// Helper function to get Zego credentials dynamically (reads from env each time)
function getZegoCredentials() {
  const zegoAppID = parseInt(process.env.ZEGO_APP_ID || '0', 10);
  const zegoServerSecret = process.env.ZEGO_SERVER_SECRET || '';
  return { zegoAppID, zegoServerSecret };
}

// Check credentials on module load (after dotenv.config() has been called)
// Use setTimeout to ensure dotenv.config() has run
setTimeout(() => {
  const { zegoAppID, zegoServerSecret } = getZegoCredentials();
  if (!zegoAppID || !zegoServerSecret) {
    console.warn('⚠️  Zego credentials not configured. Voice call feature will not work.');
    console.warn('⚠️  Please set ZEGO_APP_ID and ZEGO_SERVER_SECRET in .env');
    console.warn(`   Current ZEGO_APP_ID: ${process.env.ZEGO_APP_ID ? 'SET (value hidden)' : 'NOT SET'}`);
    console.warn(`   Current ZEGO_SERVER_SECRET: ${process.env.ZEGO_SERVER_SECRET ? 'SET (value hidden)' : 'NOT SET'}`);
    console.warn('   Make sure:');
    console.warn('   1. .env file exists in the backend/ directory');
    console.warn('   2. Variables are formatted as: ZEGO_APP_ID=1234567890');
    console.warn('   3. No spaces around the = sign');
    console.warn('   4. Server was restarted after adding variables');
  } else {
    console.log('✅ Zego credentials loaded successfully');
    console.log(`   App ID: ${zegoAppID}`);
    console.log(`   Server Secret: ${zegoServerSecret.substring(0, 10)}... (hidden)`);
  }
}, 100);

/**
 * Generate Zego token for voice call
 * Token generation algorithm based on Zego documentation
 * POST /api/zego/token
 */
export const generateZegoToken = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ message: 'Authentication required' });
      return;
    }

    const { userId, userName, roomId } = req.body;

    if (!userId || !userName || !roomId) {
      res.status(400).json({ 
        message: 'Missing required fields: userId, userName, roomId' 
      });
      return;
    }

    // Get credentials dynamically
    const { zegoAppID, zegoServerSecret } = getZegoCredentials();

    if (!zegoAppID || !zegoServerSecret) {
      res.status(500).json({ 
        message: 'Zego service not configured. Please contact administrator.' 
      });
      return;
    }

    // Token expiration time (2 hours from now)
    const expireTime = Math.floor(Date.now() / 1000) + 7200;

    // Create token payload
    const payload = {
      app_id: zegoAppID,
      user_id: userId,
      nonce: Math.floor(Math.random() * 2147483647),
      ctime: Math.floor(Date.now() / 1000),
      expire: expireTime,
      payload: JSON.stringify({
        room_id: roomId,
        privilege: {
          1: 1, // Login room
          2: 1, // Publish stream
        },
      }),
    };

    // Create token string
    const tokenString = JSON.stringify(payload);

    // Generate signature using HMAC-SHA256
    const signature = crypto
      .createHmac('sha256', zegoServerSecret)
      .update(tokenString)
      .digest('hex');

    // Combine token string and signature
    const token = Buffer.from(tokenString).toString('base64') + '.' + signature;

    res.status(200).json({
      token,
      expireTime,
      appID: zegoAppID,
      roomID: roomId,
      userID: userId,
    });
  } catch (error: any) {
    console.error('Error generating Zego token:', error);
    res.status(500).json({ 
      message: error.message || 'Failed to generate token' 
    });
  }
};

