import { admin } from '../utils/firebase';
import User from '../models/User';
import { getOrderStatusMessage, getNotificationMessages } from '../utils/notificationMessages';

export interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Send push notification to a user by their user ID
 */
export const sendNotificationToUser = async (
  userId: string,
  payload: NotificationPayload
): Promise<void> => {
  try {
    const user = await User.findById(userId);
    if (!user || !user.fcmToken) {
      console.log(`User ${userId} has no FCM token, skipping notification`);
      return;
    }

    // HTTP v1 API message format - ensures delivery in all app states
    const message: admin.messaging.Message = {
      token: user.fcmToken,
      // Include both notification and data for compatibility
      // notification: shown when app is in background/terminated
      // data: always delivered, can be handled when app is in foreground
      notification: {
        title: payload.title,
        body: payload.body,
      },
      // Data payload - always delivered regardless of app state
      data: Object.fromEntries(
        Object.entries(payload.data || {}).map(([key, value]) => [
          key,
          typeof value === 'string' ? value : String(value),
        ])
      ),
      // Android-specific configuration for HTTP v1
      android: {
        priority: 'high' as const,
        // Notification configuration for Android
        notification: {
          sound: 'default',
          channelId: 'order_updates', // Must match channel ID in Android app
          priority: 'high' as const,
          visibility: 'public' as const,
          defaultSound: true,
          defaultVibrateTimings: true,
          // Ensure notification is shown even when app is in foreground
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
              title: payload.title,
              body: payload.body,
            },
            // Ensure notification is shown even when app is in foreground
            'thread-id': 'order_updates',
          },
        },
      },
      // Web push configuration
      webpush: {
        notification: {
          title: payload.title,
          body: payload.body,
          icon: '/icon.png',
          badge: '/badge.png',
        },
        data: payload.data || {},
      },
    };

    // Use HTTP v1 API explicitly (default in Firebase Admin SDK v12+)
    const response = await admin.messaging().send(message);
    console.log(`✅ Push notification sent to user ${userId} via HTTP v1 API: ${response}`);
  } catch (error: any) {
    // Handle invalid token errors gracefully
    if (error.code === 'messaging/invalid-registration-token' || 
        error.code === 'messaging/registration-token-not-registered') {
      console.log(`Invalid FCM token for user ${userId}, removing token`);
      await User.findByIdAndUpdate(userId, { fcmToken: undefined });
    } else {
      console.error(`❌ Error sending push notification to user ${userId}:`, error.message);
    }
  }
};

/**
 * Send order status notification to customer
 */
export const sendOrderStatusNotification = async (
  orderId: string,
  customerId: string,
  status: string,
  orderData?: any
): Promise<void> => {
  // Get user to retrieve their preferred language
  const user = await User.findById(customerId);
  const language = (user?.preferredLanguage || 'ar') as 'ar' | 'en';
  
  // Get language-specific message
  const message = getOrderStatusMessage(status, language, false);

  await sendNotificationToUser(customerId, {
    title: message.title,
    body: message.body,
    data: {
      type: 'order_status_update',
      orderId: orderId,
      status: status,
      ...(orderData && { orderData: JSON.stringify(orderData) }),
    },
  });
};

/**
 * Send order status notification to driver
 */
export const sendDriverOrderStatusNotification = async (
  orderId: string,
  driverId: string,
  status: string,
  orderData?: any
): Promise<void> => {
  // Get user to retrieve their preferred language
  const user = await User.findById(driverId);
  const language = (user?.preferredLanguage || 'ar') as 'ar' | 'en';
  
  // Get language-specific message
  const message = getOrderStatusMessage(status, language, true);

  await sendNotificationToUser(driverId, {
    title: message.title,
    body: message.body,
    data: {
      type: 'order_status_update',
      orderId: orderId,
      status: status,
      ...(orderData && { orderData: JSON.stringify(orderData) }),
    },
  });
};


