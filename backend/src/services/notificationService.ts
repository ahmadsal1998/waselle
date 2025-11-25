import { admin } from '../utils/firebase';
import User from '../models/User';

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

    const message = {
      token: user.fcmToken,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data || {},
      android: {
        priority: 'high' as const,
        notification: {
          sound: 'default',
          channelId: 'order_updates',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log(`✅ Push notification sent to user ${userId}: ${response}`);
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
  const statusMessages: Record<string, { title: string; body: string }> = {
    pending: {
      title: 'Order Placed',
      body: 'Your order has been placed and is waiting for a driver.',
    },
    accepted: {
      title: 'Order Accepted',
      body: 'A driver has accepted your order and will be on their way soon!',
    },
    on_the_way: {
      title: 'Driver On The Way',
      body: 'Your driver is on the way to pick up your order.',
    },
    delivered: {
      title: 'Order Delivered',
      body: 'Your order has been delivered successfully!',
    },
    cancelled: {
      title: 'Order Cancelled',
      body: 'Your order has been cancelled.',
    },
  };

  const message = statusMessages[status] || {
    title: 'Order Update',
    body: `Your order status has been updated to ${status}.`,
  };

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
  const statusMessages: Record<string, { title: string; body: string }> = {
    accepted: {
      title: 'Order Accepted',
      body: 'You have successfully accepted the order.',
    },
    on_the_way: {
      title: 'Status Updated',
      body: 'Order status updated to "On The Way".',
    },
    delivered: {
      title: 'Order Delivered',
      body: 'Order marked as delivered successfully!',
    },
    cancelled: {
      title: 'Order Cancelled',
      body: 'The order has been cancelled.',
    },
  };

  const message = statusMessages[status] || {
    title: 'Order Update',
    body: `Order status updated to ${status}.`,
  };

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

