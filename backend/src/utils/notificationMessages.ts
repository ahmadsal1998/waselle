/**
 * Language-specific notification message templates
 */

export interface NotificationMessages {
  orderPlaced: { title: string; body: string };
  orderAccepted: { title: string; body: string };
  driverOnTheWay: { title: string; body: string };
  orderDelivered: { title: string; body: string };
  orderCancelled: { title: string; body: string };
  driverOrderAccepted: { title: string; body: string };
  driverStatusUpdated: { title: string; body: string };
  driverOrderDelivered: { title: string; body: string };
  driverOrderCancelled: { title: string; body: string };
  incomingCall: { title: string; body: (callerName: string) => string };
}

const messages: Record<'ar' | 'en', NotificationMessages> = {
  en: {
    orderPlaced: {
      title: 'Order Placed',
      body: 'Your order has been placed and is waiting for a driver.',
    },
    orderAccepted: {
      title: 'Order Accepted',
      body: 'A driver has accepted your order and will be on their way soon!',
    },
    driverOnTheWay: {
      title: 'Driver On The Way',
      body: 'Your driver is on the way to pick up your order.',
    },
    orderDelivered: {
      title: 'Order Delivered',
      body: 'Your order has been delivered successfully!',
    },
    orderCancelled: {
      title: 'Order Cancelled',
      body: 'Your order has been cancelled.',
    },
    driverOrderAccepted: {
      title: 'Order Accepted',
      body: 'You have successfully accepted the order.',
    },
    driverStatusUpdated: {
      title: 'Status Updated',
      body: 'Order status updated to "On The Way".',
    },
    driverOrderDelivered: {
      title: 'Order Delivered',
      body: 'Order marked as delivered successfully!',
    },
    driverOrderCancelled: {
      title: 'Order Cancelled',
      body: 'The order has been cancelled.',
    },
    incomingCall: {
      title: 'Incoming Call',
      body: (callerName: string) => `${callerName} is calling you`,
    },
  },
  ar: {
    orderPlaced: {
      title: 'تم تقديم الطلب',
      body: 'تم تقديم طلبك وهو في انتظار سائق.',
    },
    orderAccepted: {
      title: 'تم قبول الطلب',
      body: 'لقد قبل سائق طلبك وسيكون في طريقه قريباً!',
    },
    driverOnTheWay: {
      title: 'السائق في الطريق',
      body: 'سائقك في طريقه لاستلام طلبك.',
    },
    orderDelivered: {
      title: 'تم تسليم الطلب',
      body: 'تم تسليم طلبك بنجاح!',
    },
    orderCancelled: {
      title: 'تم إلغاء الطلب',
      body: 'تم إلغاء طلبك.',
    },
    driverOrderAccepted: {
      title: 'تم قبول الطلب',
      body: 'لقد قبلت الطلب بنجاح.',
    },
    driverStatusUpdated: {
      title: 'تم تحديث الحالة',
      body: 'تم تحديث حالة الطلب إلى "في الطريق".',
    },
    driverOrderDelivered: {
      title: 'تم تسليم الطلب',
      body: 'تم تسليم الطلب بنجاح!',
    },
    driverOrderCancelled: {
      title: 'تم إلغاء الطلب',
      body: 'تم إلغاء الطلب.',
    },
    incomingCall: {
      title: 'مكالمة واردة',
      body: (callerName: string) => `${callerName} يتصل بك`,
    },
  },
};

/**
 * Get notification messages for a specific language
 * @param language - Language code ('ar' or 'en')
 * @returns Notification messages object for the specified language
 */
export const getNotificationMessages = (language: 'ar' | 'en' = 'ar'): NotificationMessages => {
  return messages[language] || messages.ar;
};

/**
 * Get notification message for a specific order status
 * @param status - Order status
 * @param language - Language code ('ar' or 'en')
 * @param isDriver - Whether this is a driver notification
 * @returns Notification message object
 */
export const getOrderStatusMessage = (
  status: string,
  language: 'ar' | 'en' = 'ar',
  isDriver: boolean = false
): { title: string; body: string } => {
  const msgs = getNotificationMessages(language);

  if (isDriver) {
    switch (status) {
      case 'accepted':
        return msgs.driverOrderAccepted;
      case 'on_the_way':
        return msgs.driverStatusUpdated;
      case 'delivered':
        return msgs.driverOrderDelivered;
      case 'cancelled':
        return msgs.driverOrderCancelled;
      default:
        return {
          title: language === 'ar' ? 'تحديث الطلب' : 'Order Update',
          body: language === 'ar' 
            ? `تم تحديث حالة الطلب إلى ${status}.`
            : `Order status updated to ${status}.`,
        };
    }
  } else {
    switch (status) {
      case 'pending':
        return msgs.orderPlaced;
      case 'accepted':
        return msgs.orderAccepted;
      case 'on_the_way':
        return msgs.driverOnTheWay;
      case 'delivered':
        return msgs.orderDelivered;
      case 'cancelled':
        return msgs.orderCancelled;
      default:
        return {
          title: language === 'ar' ? 'تحديث الطلب' : 'Order Update',
          body: language === 'ar'
            ? `تم تحديث حالة الطلب إلى ${status}.`
            : `Order status updated to ${status}.`,
        };
    }
  }
};

