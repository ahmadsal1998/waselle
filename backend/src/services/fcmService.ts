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

    // Determine channel ID based on notification type
    const channelId = data?.type === 'incoming_call' ? 'incoming_calls' : 'order_updates';

    // HTTP v1 API message format - ensures delivery in all app states
    const message: admin.messaging.Message = {
      token: user.fcmToken,
      // Include both notification and data for compatibility
      notification: {
        title,
        body,
      },
      // Data payload - always delivered regardless of app state
      data: data ? Object.fromEntries(
        Object.entries(data).map(([key, value]) => [key, String(value)])
      ) : undefined,
      // Android-specific configuration for HTTP v1
      android: {
        priority: 'high' as const,
        notification: {
          sound: 'default',
          channelId: channelId, // Must match channel ID in Android app
          priority: 'high' as const,
          visibility: 'public' as const,
          defaultSound: true,
          defaultVibrateTimings: true,
          notificationCount: 1,
        },
      },
      // iOS (APNS) configuration for HTTP v1
      apns: {
        headers: {
          'apns-priority': '10', // High priority for immediate delivery
          'apns-push-type': 'alert', // Alert type for user-visible notifications
        },
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            contentAvailable: true, // Enable background notification processing
            mutableContent: true, // Allow notification modification
            alert: {
              title,
              body,
            },
            'thread-id': channelId,
          },
        },
      },
      // Web push configuration
      webpush: {
        notification: {
          title,
          body,
          icon: '/icon.png',
          badge: '/badge.png',
        },
        data: data || {},
      },
    };

    // Use HTTP v1 API explicitly (default in Firebase Admin SDK v12+)
    const response = await admin.messaging().send(message);
    console.log(`✅ Push notification sent successfully to user ${userId} via HTTP v1 API:`, response);
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

