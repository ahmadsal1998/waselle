package com.example.delivery_driver_app

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {
    private val TAG = "MyFirebaseMessaging"

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "Refreshed FCM token: $token")
        // Token refresh is handled by Flutter Firebase Messaging plugin
        // This service ensures token refresh works even when app is in background
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        Log.d(TAG, "Message received from: ${remoteMessage.from}")
        
        // Check if message contains data payload
        if (remoteMessage.data.isNotEmpty()) {
            Log.d(TAG, "Message data payload: ${remoteMessage.data}")
        }

        // Check if message contains notification payload
        remoteMessage.notification?.let {
            Log.d(TAG, "Message notification body: ${it.body}")
        }
        
        // Note: For data-only messages, Flutter handles them via onBackgroundMessage
        // For notification messages, Android system handles them automatically
        // This service is mainly for logging and ensuring token refresh works
    }
}

