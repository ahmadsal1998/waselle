# Order Status Notifications Setup Guide

This document explains the order status notification system that has been implemented to notify users about order status changes in real-time, regardless of app state (foreground, background, or terminated).

## Overview

The notification system uses Firebase Cloud Messaging (FCM) to send push notifications to users when order status changes occur. Notifications work in all app states:
- **Foreground**: Shows local notifications
- **Background**: Shows system notifications
- **Terminated**: Shows system notifications and navigates to order tracking when tapped

## Backend Implementation

### 1. User Model Updates
- Added `fcmToken` field to store Firebase Cloud Messaging tokens for each user
- Location: `backend/src/models/User.ts`

### 2. Notification Service
- Created `backend/src/services/notificationService.ts` with functions to:
  - Send push notifications to users by user ID
  - Send order status notifications to customers
  - Send order status notifications to drivers
  - Handle invalid FCM tokens gracefully

### 3. FCM Token Registration Endpoint
- Added `POST /api/users/fcm-token` endpoint to register/update FCM tokens
- Location: `backend/src/controllers/userController.ts` and `backend/src/routes/userRoutes.ts`

### 4. Order Status Change Notifications
- Updated order controller to send notifications when:
  - Order is created (pending status)
  - Order is accepted by driver
  - Order status is updated (on_the_way, delivered, cancelled)
- Location: `backend/src/controllers/orderController.ts`

## Flutter App Implementation

### 1. Dependencies Added
- `firebase_messaging: ^15.1.3` - For FCM integration
- `flutter_local_notifications: ^17.2.2` - For foreground notifications
- Updated `user-app/pubspec.yaml`

### 2. Notification Service
- Created `user-app/lib/services/notification_service.dart` with:
  - FCM token management and registration
  - Foreground message handling (shows local notifications)
  - Background message handling
  - Notification tap handling
  - Navigation to order tracking screen

### 3. Main App Initialization
- Updated `user-app/lib/main.dart` to:
  - Initialize Firebase
  - Initialize notification service on app startup
  - Request notification permissions

### 4. Navigation Handling
- Updated `user-app/lib/screens/home/home_screen.dart` to:
  - Check for pending navigation from notifications
  - Navigate to order tracking tab when notification is tapped

### 5. API Service
- Added `registerFCMToken()` method to `user-app/lib/repositories/api_service.dart`
- Automatically registers FCM token with backend when received

### 6. Android Configuration
- Updated `android/app/src/main/AndroidManifest.xml` to:
  - Add notification permissions (`POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`)
  - Configure Firebase Messaging service
  - Set default notification channel

## Notification Flow

### When Order Status Changes:

1. **Backend** (`orderController.ts`):
   - Order status is updated in database
   - Socket event is emitted for real-time updates (existing functionality)
   - Push notification is sent via FCM to customer and/or driver

2. **Flutter App** receives notification:
   - **Foreground**: Shows local notification banner
   - **Background**: Shows system notification
   - **Terminated**: Shows system notification

3. **User Taps Notification**:
   - App opens (if terminated)
   - Navigates to order tracking screen
   - Shows updated order status

## Notification Messages

### Customer Notifications:
- **Pending**: "Order Placed - Your order has been placed and is waiting for a driver."
- **Accepted**: "Order Accepted - A driver has accepted your order and will be on their way soon!"
- **On The Way**: "Driver On The Way - Your driver is on the way to pick up your order."
- **Delivered**: "Order Delivered - Your order has been delivered successfully!"
- **Cancelled**: "Order Cancelled - Your order has been cancelled."

### Driver Notifications:
- Similar messages tailored for driver perspective

## Setup Requirements

### Backend:
1. Ensure Firebase Admin SDK is properly configured (already done)
2. Firebase project must have Cloud Messaging enabled
3. No additional environment variables needed

### Flutter App:
1. Run `flutter pub get` to install new dependencies
2. For Android: Ensure `google-services.json` is in `android/app/` directory
3. For iOS: Ensure `GoogleService-Info.plist` is in `ios/Runner/` directory
4. Build and run the app

## Testing

### Test Notification Flow:
1. Create an order (should receive "Order Placed" notification)
2. Have a driver accept the order (should receive "Order Accepted" notification)
3. Update order status to "on_the_way" (should receive "Driver On The Way" notification)
4. Update order status to "delivered" (should receive "Order Delivered" notification)

### Test App States:
1. **Foreground**: App open, notification appears as banner
2. **Background**: App minimized, notification appears in system tray
3. **Terminated**: App closed, notification appears in system tray, tapping opens app and navigates to order tracking

## Troubleshooting

### Notifications Not Appearing:
1. Check that notification permissions are granted
2. Verify FCM token is registered (check backend logs)
3. Ensure Firebase is properly initialized
4. Check device notification settings

### Navigation Not Working:
1. Verify `NotificationService.getPendingNavigation()` is called in HomeScreen
2. Check that order tracking tab index is correct (index 1)

### FCM Token Issues:
1. Check backend logs for token registration errors
2. Verify Firebase configuration files are present
3. Ensure internet connection is available

## Future Enhancements

- Add notification preferences/settings
- Support for notification actions (e.g., "Call Driver" button)
- Rich notifications with order details
- Notification history/settings screen
- Batch notifications for multiple orders

