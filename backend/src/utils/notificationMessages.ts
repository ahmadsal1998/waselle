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
  // Price negotiation messages
  priceProposed: { title: string; body: string };
  priceAccepted: { title: string; body: string };
  priceRejected: { title: string; body: string };
  driverPriceAccepted: { title: string; body: string };
  driverPriceRejected: { title: string; body: string };
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
    // Price negotiation messages (for customer)
    priceProposed: {
      title: 'Price Proposal Received',
      body: 'The driver has proposed a delivery price. Please accept or reject.',
    },
    priceAccepted: {
      title: 'Price Confirmed',
      body: 'You have accepted the delivery price. The driver will start soon.',
    },
    priceRejected: {
      title: 'Price Rejected',
      body: 'You have rejected the delivery price. The driver will propose a new price.',
    },
    // Price negotiation messages (for driver)
    driverPriceAccepted: {
      title: 'Price Accepted',
      body: 'The customer has accepted your price. You can start the delivery now!',
    },
    driverPriceRejected: {
      title: 'Price Rejected',
      body: 'The customer has rejected your price. Please propose a new price.',
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
    // رسائل التفاوض على السعر (للعميل)
    priceProposed: {
      title: 'تم استلام عرض السعر',
      body: 'اقترح السائق سعر التوصيل. الرجاء القبول أو الرفض.',
    },
    priceAccepted: {
      title: 'تم تأكيد السعر',
      body: 'لقد قبلت سعر التوصيل. سيبدأ السائق قريباً.',
    },
    priceRejected: {
      title: 'تم رفض السعر',
      body: 'لقد رفضت سعر التوصيل. سيقترح السائق سعراً جديداً.',
    },
    // رسائل التفاوض على السعر (للسائق)
    driverPriceAccepted: {
      title: 'تم قبول السعر',
      body: 'العميل قبل السعر المقترح. يمكنك البدء في التوصيل الآن!',
    },
    driverPriceRejected: {
      title: 'تم رفض السعر',
      body: 'العميل رفض السعر المقترح. الرجاء اقتراح سعر جديد.',
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
      case 'price_accepted':
        return msgs.driverPriceAccepted;
      case 'price_rejected':
        return msgs.driverPriceRejected;
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
      case 'price_proposed':
        return msgs.priceProposed;
      case 'price_accepted':
        return msgs.priceAccepted;
      case 'price_rejected':
        return msgs.priceRejected;
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

