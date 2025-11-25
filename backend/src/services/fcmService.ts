import { admin } from '../utils/firebase';
import User from '../models/User';

interface CallNotificationData {
  orderId: string;
  roomId: string;
  callerId: string;
  callerName: string;
  type: 'incoming_call';
}

/**
 * Send FCM push notification to a user
 */
export const sendPushNotification = async (
  userId: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<boolean> => {
  try {
    // Get user's FCM token
    const user = await User.findById(userId);
    if (!user || !user.fcmToken) {
      console.log(`⚠️  User ${userId} has no FCM token, skipping push notification`);
      return false;
    }

    const message: admin.messaging.Message = {
      token: user.fcmToken,
      notification: {
        title,
        body,
      },
      data: data ? Object.fromEntries(
        Object.entries(data).map(([key, value]) => [key, String(value)])
      ) : undefined,
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'incoming_calls',
          priority: 'high' as const,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            contentAvailable: true,
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log(`✅ Push notification sent successfully to user ${userId}:`, response);
    return true;
  } catch (error: any) {
    console.error(`❌ Error sending push notification to user ${userId}:`, error.message);
    
    // If token is invalid, remove it from user
    if (error.code === 'messaging/invalid-registration-token' || 
        error.code === 'messaging/registration-token-not-registered') {
      console.log(`🗑️  Removing invalid FCM token for user ${userId}`);
      await User.findByIdAndUpdate(userId, { $unset: { fcmToken: 1 } });
    }
    
    return false;
  }
};

/**
 * Send incoming call notification via FCM
 */
export const sendIncomingCallNotification = async (
  receiverId: string,
  callData: CallNotificationData
): Promise<boolean> => {
  const callerName = callData.callerName || 'Someone';
  
  return sendPushNotification(
    receiverId,
    'Incoming Call',
    `${callerName} is calling you`,
    {
      type: 'incoming_call',
      orderId: callData.orderId,
      roomId: callData.roomId,
      callerId: callData.callerId,
      callerName: callData.callerName,
    }
  );
};

/**
 * Send notification to multiple users
 */
export const sendPushNotificationToMultiple = async (
  userIds: string[],
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<{ success: number; failed: number }> => {
  let success = 0;
  let failed = 0;

  await Promise.all(
    userIds.map(async (userId) => {
      const result = await sendPushNotification(userId, title, body, data);
      if (result) {
        success++;
      } else {
        failed++;
      }
    })
  );

  return { success, failed };
};

