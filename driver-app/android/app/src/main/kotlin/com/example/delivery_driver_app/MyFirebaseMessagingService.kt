package com.example.delivery_driver_app

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {
    private val TAG = "MyFirebaseMessaging"

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "✅ Refreshed FCM token: ${token.substring(0, minOf(20, token.length))}...")
        Log.d(TAG, "✅ Full FCM token: $token")
        // Token refresh is handled by Flutter Firebase Messaging plugin
        // This service ensures token refresh works even when app is in background
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        Log.d(TAG, "📨 Message received from: ${remoteMessage.from}")
        Log.d(TAG, "📨 Message ID: ${remoteMessage.messageId}")
        
        // Check if message contains data payload
        if (remoteMessage.data.isNotEmpty()) {
            Log.d(TAG, "📨 Message data payload: ${remoteMessage.data}")
        }

        // Check if message contains notification payload
        remoteMessage.notification?.let { notification ->
            Log.d(TAG, "📨 Notification title: ${notification.title}")
            Log.d(TAG, "📨 Notification body: ${notification.body}")
            Log.d(TAG, "📨 Notification channel: ${notification.channelId}")
        }
        
        // IMPORTANT: When app is in foreground, Flutter's onMessage handler receives the message
        // When app is in background/terminated, Android system automatically displays notifications
        // with notification payload, and Flutter's onMessageOpenedApp/getInitialMessage handles taps
        
        // For data-only messages (no notification payload), this method is called
        // and Flutter's onBackgroundMessage handles them
        // For notification messages, Android system handles display automatically
    }
}

