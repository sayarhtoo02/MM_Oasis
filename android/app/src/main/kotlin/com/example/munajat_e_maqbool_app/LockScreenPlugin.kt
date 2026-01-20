package com.example.munajat_e_maqbool_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class LockScreenPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var notificationManager: NotificationManager
    
    companion object {
        private const val CHANNEL_ID = "dua_lockscreen"
        private const val NOTIFICATION_ID = 1001
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.munajat.lockscreen")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
        notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initializeLockScreen" -> {
                createNotificationChannel()
                result.success("Initialized")
            }
            "showLockScreenDua" -> {
                val arabicText = call.argument<String>("arabicText") ?: ""
                showLockScreenNotification(arabicText)
                result.success("Notification shown")
            }
            else -> result.notImplemented()
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Daily Dua",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows daily dua on lock screen"
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showLockScreenNotification(arabicText: String) {
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle("Daily Dua Reminder")
            .setContentText(arabicText)
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText(arabicText)
                .setBigContentTitle("مناجات مقبول - Today's Dua")
                .setSummaryText("Tap to open app"))
            .setSmallIcon(R.mipmap.launcher_icon)
            .setOngoing(true)
            .setAutoCancel(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .build()

        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}