package com.wassle.driverapp

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)
            
            // Create order_updates channel
            val orderUpdatesChannelId = "order_updates"
            val orderUpdatesChannelName = "Order Updates"
            val orderUpdatesChannelDescription = "Notifications for order status updates"
            val orderUpdatesChannel = NotificationChannel(
                orderUpdatesChannelId,
                orderUpdatesChannelName,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = orderUpdatesChannelDescription
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
            }
            notificationManager.createNotificationChannel(orderUpdatesChannel)
            
            // Create incoming_calls channel
            val incomingCallsChannelId = "incoming_calls"
            val incomingCallsChannelName = "Incoming Calls"
            val incomingCallsChannelDescription = "Notifications for incoming voice calls"
            val incomingCallsChannel = NotificationChannel(
                incomingCallsChannelId,
                incomingCallsChannelName,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = incomingCallsChannelDescription
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
            }
            notificationManager.createNotificationChannel(incomingCallsChannel)
        }
    }
}

