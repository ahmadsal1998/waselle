import { admin } from '../utils/firebase';
import User from '../models/User';
import { getOrderStatusMessage, getNotificationMessages } from '../utils/notificationMessages';
import Settings from '../models/Settings';
import City from '../models/City';
import { findCityForLocation, calculateDistance } from '../utils/distance';

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
  payload: NotificationPayload,
  options?: { skipLogging?: boolean }
): Promise<void> => {
  try {
    const user = await User.findById(userId);
    if (!user) {
      if (!options?.skipLogging) {
        console.log(`❌ User ${userId} not found, skipping notification`);
      }
      return;
    }
    
    if (!user.fcmToken || user.fcmToken.trim() === '') {
      // For customers, this is optional - don't log as error
      if (user.role === 'customer') {
        if (!options?.skipLogging) {
          console.log(`ℹ️  Customer ${userId} has no FCM token, skipping notification (optional for customers)`);
        }
      } else {
        console.log(`❌ User ${userId} has no FCM token, skipping notification`);
        console.log(`   User role: ${user.role}, isAvailable: ${user.isAvailable}, isActive: ${user.isActive}`);
      }
      return;
    }

    // Validate token format (FCM tokens are typically long strings)
    if (user.fcmToken.length < 50) {
      console.log(`❌ User ${userId} has invalid FCM token (too short: ${user.fcmToken.length} chars), skipping notification`);
      return;
    }

    console.log(`📤 Sending notification to user ${userId}`);
    console.log(`   Title: ${payload.title}`);
    console.log(`   Body: ${payload.body}`);
    console.log(`   Token: ${user.fcmToken.substring(0, 20)}... (${user.fcmToken.length} chars)`);

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
      console.log(`❌ Invalid FCM token for user ${userId}, removing token`);
      console.log(`   Error code: ${error.code}`);
      await User.findByIdAndUpdate(userId, { fcmToken: undefined });
    } else if (error.code === 'messaging/third-party-auth-error') {
      // APNS authentication error - Firebase cannot authenticate with Apple
      console.error(`❌ APNS Authentication Error for user ${userId}`);
      console.error(`   This means Firebase cannot authenticate with Apple's APNS Production service.`);
      console.error(`   Error code: ${error.code}`);
      console.error(`   Error message: ${error.message}`);
      console.error(`   ⚠️  ACTION REQUIRED: Configure APNS in Firebase Console:`);
      console.error(`   1. Go to Firebase Console → Project Settings → Cloud Messaging`);
      console.error(`   2. Under "Apple app configuration", upload your APNS Authentication Key (.p8)`);
      console.error(`   3. Or upload your APNS Production Certificate (.p12) if using certificate-based auth`);
      console.error(`   4. Make sure the bundle ID matches exactly:`);
      console.error(`      - User app: com.wassle.userapp`);
      console.error(`      - Driver app: com.wassle.driverapp`);
      console.error(`   5. For production, APNS Authentication Key is recommended (works for both dev & prod)`);
      console.error(`   6. This error occurs when app is from App Store/TestFlight (Production APNs)`);
      console.error(`   7. See IOS_PRODUCTION_APNS_FIX.md for detailed instructions`);
      console.error(`   Full error:`, error);
      
      // Don't remove the token - this is a configuration issue, not a token issue
      // The notification will fail, but the token is still valid
    } else {
      console.error(`❌ Error sending push notification to user ${userId}:`, error.message);
      console.error(`   Error code: ${error.code}`);
      console.error(`   Full error:`, error);
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

  // For customers, skip error logging if they don't have FCM token (it's optional)
  await sendNotificationToUser(customerId, {
    title: message.title,
    body: message.body,
    data: {
      type: 'order_status_update',
      orderId: orderId,
      status: status,
      ...(orderData && { orderData: JSON.stringify(orderData) }),
    },
  }, { skipLogging: true });
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

/**
 * Send new order notification to all relevant drivers
 * Drivers are filtered by vehicle type, availability, location, and radius
 */
export const sendNewOrderNotificationToDrivers = async (
  orderId: string,
  vehicleType: 'car' | 'bike' | 'cargo',
  deliveryType: 'internal' | 'external',
  customerLocation: { lat: number; lng: number },
  orderData?: any
): Promise<{ notified: number; skipped: number }> => {
  try {
    // Diagnostic: Check total drivers of this vehicle type
    const totalDriversOfType = await User.countDocuments({
      role: 'driver',
      vehicleType: vehicleType,
    });
    
    const activeDriversOfType = await User.countDocuments({
      role: 'driver',
      vehicleType: vehicleType,
      isActive: true,
    });
    
    const availableDriversOfType = await User.countDocuments({
      role: 'driver',
      vehicleType: vehicleType,
      isAvailable: true,
      isActive: true,
    });
    
    const driversWithLocation = await User.countDocuments({
      role: 'driver',
      vehicleType: vehicleType,
      isAvailable: true,
      isActive: true,
      location: { $exists: true, $ne: null },
    });
    
    const driversWithFCMToken = await User.countDocuments({
      role: 'driver',
      vehicleType: vehicleType,
      isAvailable: true,
      isActive: true,
      location: { $exists: true, $ne: null },
      fcmToken: { $exists: true, $ne: null, $type: 'string' },
    });
    
    console.log(`[sendNewOrderNotificationToDrivers] Diagnostic for vehicle type ${vehicleType}:`);
    console.log(`   Total drivers: ${totalDriversOfType}`);
    console.log(`   Active drivers: ${activeDriversOfType}`);
    console.log(`   Available & active: ${availableDriversOfType}`);
    console.log(`   With location: ${driversWithLocation}`);
    console.log(`   With FCM token: ${driversWithFCMToken}`);
    
    // Find all available drivers with matching vehicle type
    // CRITICAL: Only include drivers with valid FCM tokens (not empty strings)
    const allDrivers = await User.find({
      role: 'driver',
      vehicleType: vehicleType,
      isAvailable: true,
      isActive: true, // Only active drivers
      location: { $exists: true, $ne: null },
      fcmToken: { $exists: true, $ne: null, $type: 'string' }, // Only drivers with FCM tokens (string type)
    }).lean();
    
    // Additional validation: filter out drivers with invalid tokens
    const drivers = allDrivers.filter(driver => {
      const token = driver.fcmToken;
      return token && typeof token === 'string' && token.trim().length >= 50;
    });
    
    if (drivers.length !== allDrivers.length) {
      console.log(`⚠️ Filtered out ${allDrivers.length - drivers.length} drivers with invalid FCM tokens`);
    }

    if (drivers.length === 0) {
      console.log(`❌ No available drivers found for vehicle type ${vehicleType} with valid FCM tokens`);
      console.log(`   This could mean:`);
      console.log(`   - No drivers registered with vehicle type ${vehicleType}`);
      console.log(`   - Drivers are not marked as available (isAvailable=false)`);
      console.log(`   - Drivers are not active (isActive=false)`);
      console.log(`   - Drivers don't have location set`);
      console.log(`   - Drivers don't have valid FCM tokens registered`);
      return { notified: 0, skipped: 0 };
    }

    // Get settings for radius configuration
    const settings = await Settings.getSettings();

    // Get all active cities with service centers configured
    const citiesWithServiceCenters = await City.find({
      isActive: true,
      'serviceCenter.center.lat': { $exists: true, $ne: null },
      'serviceCenter.center.lng': { $exists: true, $ne: null },
    }).lean();

    // Determine radius based on delivery type and city/global settings
    let internalRadiusKm: number;
    let externalMinRadiusKm: number;
    let externalMaxRadiusKm: number;

    if (citiesWithServiceCenters.length > 0) {
      const cityServiceCenter = findCityForLocation(
        customerLocation,
        citiesWithServiceCenters as any
      );

      if (cityServiceCenter) {
        // Use city-specific radius
        internalRadiusKm = cityServiceCenter.internalOrderRadiusKm;
        externalMinRadiusKm = cityServiceCenter.externalOrderMinRadiusKm;
        externalMaxRadiusKm = cityServiceCenter.externalOrderMaxRadiusKm;
      } else {
        // Use global settings
        internalRadiusKm = settings.internalOrderRadiusKm;
        externalMinRadiusKm = settings.externalOrderMinRadiusKm;
        externalMaxRadiusKm = settings.externalOrderMaxRadiusKm;
      }
    } else {
      // Use global settings
      internalRadiusKm = settings.internalOrderRadiusKm;
      externalMinRadiusKm = settings.externalOrderMinRadiusKm;
      externalMaxRadiusKm = settings.externalOrderMaxRadiusKm;
    }

    // Filter drivers by distance and delivery type
    const relevantDrivers = drivers
      .map((driver) => {
        if (!driver.location) return null;

        const distance = calculateDistance(driver.location, customerLocation);

        // Apply radius logic based on delivery type
        let isWithinRadius: boolean;
        if (deliveryType === 'internal') {
          isWithinRadius = distance <= internalRadiusKm;
        } else {
          isWithinRadius =
            distance >= externalMinRadiusKm && distance <= externalMaxRadiusKm;
        }

        if (isWithinRadius) {
          return {
            driverId: driver._id.toString(),
            distance,
          };
        }

        return null;
      })
      .filter((driver) => driver !== null) as Array<{
      driverId: string;
      distance: number;
    }>;

    if (relevantDrivers.length === 0) {
      console.log(
        `No drivers found within radius for order ${orderId} (vehicleType: ${vehicleType}, deliveryType: ${deliveryType})`
      );
      return { notified: 0, skipped: drivers.length };
    }

    // Get notification messages (will use each driver's language preference)
    const messages = {
      ar: {
        title: 'طلب جديد متاح',
        body: 'تم وضع طلب توصيل جديد. اضغط لعرض الطلبات المتاحة.',
      },
      en: {
        title: 'New Order Available',
        body: 'A new delivery order has been placed. Tap to view.',
      },
    };

    // Send notifications to all relevant drivers
    let notified = 0;
    let skipped = 0;

    await Promise.all(
      relevantDrivers.map(async (driverInfo) => {
        try {
          const driver = await User.findById(driverInfo.driverId);
          if (!driver || !driver.fcmToken) {
            console.log(`[sendNewOrderNotificationToDrivers] ⚠️ Skipping driver ${driverInfo.driverId} - ${!driver ? 'driver not found' : 'no FCM token'}`);
            skipped++;
            return;
          }

          const language = (driver.preferredLanguage || 'ar') as 'ar' | 'en';
          const message = messages[language];

          await sendNotificationToUser(driver._id.toString(), {
            title: message.title,
            body: message.body,
            data: {
              type: 'new_order',
              orderId: orderId,
              ...(orderData && { orderData: JSON.stringify(orderData) }),
            },
          });

          console.log(`[sendNewOrderNotificationToDrivers] ✅ Notification sent to driver ${driverInfo.driverId} for order ${orderId} (distance: ${driverInfo.distance.toFixed(2)}km)`);
          notified++;
        } catch (error: any) {
          console.error(
            `Error sending notification to driver ${driverInfo.driverId}:`,
            error.message
          );
          skipped++;
        }
      })
    );

    console.log(
      `✅ New order notification sent: ${notified} drivers notified, ${skipped} skipped for order ${orderId}`
    );

    return { notified, skipped };
  } catch (error: any) {
    console.error(
      `❌ Error sending new order notifications:`,
      error.message
    );
    return { notified: 0, skipped: 0 };
  }
};


