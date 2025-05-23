package com.solidsoft.routine

import android.app.ActivityManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

class ForegroundAppDetectionService : Service() {
    private val TAG = "ForegroundDetection"
    private val handler = Handler(Looper.getMainLooper())
    private val CHECK_INTERVAL_MS = 1000L // Check more frequently (every 500ms)
    private var isRunning = false
    private var blockedPackages = listOf<String>()
    private var currentlyBlockedApp: String? = null
    private var overlayShowing = false
    private var wakeLock: PowerManager.WakeLock? = null
    
    // YouTube package name
    private val YOUTUBE_PACKAGE = "com.google.android.youtube"
    
    private val checkForegroundRunnable = object : Runnable {
        override fun run() {
            try {
                val foregroundApp = getForegroundApp()
                
                // Log less frequently to avoid log spam
                if (foregroundApp != null && foregroundApp != currentlyBlockedApp) {
                    Log.d(TAG, "Current foreground app: $foregroundApp")
                }
                
                // Check if we need to show or hide the overlay
                if (foregroundApp != null && blockedPackages.contains(foregroundApp)) {
                    // Only show if not already showing for this app
                    if (currentlyBlockedApp != foregroundApp || !overlayShowing) {
                        Log.d(TAG, "Blocked app detected: $foregroundApp")
                        showBlockOverlay(foregroundApp)
                        currentlyBlockedApp = foregroundApp
                        overlayShowing = true
                    }
                } else {
                    // App is no longer in foreground or not blocked
                    currentlyBlockedApp = null
                    overlayShowing = false
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error in foreground check: ${e.message}", e)
            }
            
            if (isRunning) {
                handler.postDelayed(this, CHECK_INTERVAL_MS)
            }
        }
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        
        // For Android 14+ (API 34+), we need to specify a foreground service type
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, createNotification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(NOTIFICATION_ID, createNotification())
        }
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started")
        
        if (intent?.hasExtra("blockedPackages") == true) {
            val packages = intent.getStringArrayListExtra("blockedPackages")
            blockedPackages = packages ?: listOf()
            Log.d(TAG, "Blocked packages updated: $blockedPackages")
            
            // Update notification with current blocked apps
            updateNotification()
        }
        
        if (!isRunning) {
            isRunning = true
            
            // Acquire wake lock to keep service running reliably
            acquireWakeLock()
            
            // Start checking for foreground apps
            handler.post(checkForegroundRunnable)
        }
        
        return START_STICKY
    }
    
    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        handler.removeCallbacks(checkForegroundRunnable)
        releaseWakeLock()
        Log.d(TAG, "Service destroyed")
    }
    
    private fun getForegroundApp(): String? {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                // Modern approach using UsageStatsManager
                val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                val endTime = System.currentTimeMillis()
                val beginTime = endTime - 10000 // Look at last 10 seconds for more reliable detection
                
                // First try with UsageEvents for most accurate results
                val events = usageStatsManager.queryEvents(beginTime, endTime)
                val event = UsageEvents.Event()
                var lastForegroundApp: String? = null
                
                while (events.hasNextEvent()) {
                    events.getNextEvent(event)
                    if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                        lastForegroundApp = event.packageName
                    }
                }
                
                if (lastForegroundApp != null) {
                    return lastForegroundApp
                }
                
                // Fallback to usage stats if events didn't work
                val usageStats = usageStatsManager.queryUsageStats(
                    UsageStatsManager.INTERVAL_DAILY, beginTime, endTime)
                
                if (usageStats != null && usageStats.isNotEmpty()) {
                    var recentStats = usageStats.maxByOrNull { it.lastTimeUsed }
                    if (recentStats != null) {
                        return recentStats.packageName
                    }
                }
                
                // If all else fails, try ActivityManager (less reliable on newer Android versions)
                val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                val appProcess = activityManager.runningAppProcesses
                if (appProcess != null && appProcess.isNotEmpty()) {
                    for (process in appProcess) {
                        if (process.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND) {
                            return process.processName
                        }
                    }
                }
            } else {
                // Fallback for very old devices
                val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                return activityManager.runningAppProcesses?.firstOrNull { 
                    it.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND 
                }?.processName
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting foreground app: ${e.message}", e)
        }
        
        return null
    }
    
    private fun showBlockOverlay(packageName: String) {
        try {
            // Instead of starting an activity directly, update the notification
            // to inform the user that an app is being blocked
            Log.d(TAG, "App blocked: $packageName")
            
            // Get app name for better user experience
            val appName = getAppNameFromPackage(packageName)
            
            // Update notification to show blocked app
            updateNotification("Blocking $appName")
            
            // Send the user back to home screen
            val homeIntent = Intent(Intent.ACTION_MAIN)
            homeIntent.addCategory(Intent.CATEGORY_HOME)
            homeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(homeIntent)
            
        } catch (e: Exception) {
            Log.e(TAG, "Error handling blocked app: ${e.message}", e)
        }
    }
    
    private fun getAppNameFromPackage(packageName: String): String {
        return try {
            val packageManager = applicationContext.packageManager
            val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(applicationInfo).toString()
        } catch (e: Exception) {
            packageName
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "App Blocking Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows when Routine is monitoring and blocking apps"
                enableLights(false)
                lightColor = Color.BLUE
                enableVibration(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(contentText: String = "Monitoring for blocked apps"): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Routine App Blocker")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }
    
    private fun updateNotification(contentText: String = "Monitoring for blocked apps") {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, createNotification(contentText))
    }
    
    private fun acquireWakeLock() {
        try {
            if (wakeLock == null) {
                val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                wakeLock = powerManager.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "Routine:ForegroundDetectionWakeLock"
                )
                wakeLock?.acquire(10*60*1000L) // 10 minutes max
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error acquiring wake lock: ${e.message}", e)
        }
    }
    
    private fun releaseWakeLock() {
        try {
            if (wakeLock != null && wakeLock?.isHeld == true) {
                wakeLock?.release()
                wakeLock = null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing wake lock: ${e.message}", e)
        }
    }
    
    companion object {
        private const val CHANNEL_ID = "AppBlockingChannel"
        private const val NOTIFICATION_ID = 1001
        
        fun updateBlockedPackages(context: Context, packages: List<String>) {
            val intent = Intent(context, ForegroundAppDetectionService::class.java).apply {
                putStringArrayListExtra("blockedPackages", ArrayList(packages))
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun startService(context: Context) {
            val intent = Intent(context, ForegroundAppDetectionService::class.java)
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stopService(context: Context) {
            val intent = Intent(context, ForegroundAppDetectionService::class.java)
            context.stopService(intent)
        }
    }
}
