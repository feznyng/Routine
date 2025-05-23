package com.solidsoft.routine

import android.app.ActivityManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import java.util.concurrent.TimeUnit

class ForegroundAppDetectionService : Service() {
    private val TAG = "ForegroundDetection"
    private val handler = Handler(Looper.getMainLooper())
    private val CHECK_INTERVAL_MS = 1000L // Check every second
    private var isRunning = false
    private var blockedPackages = listOf<String>()
    
    // YouTube package name
    private val YOUTUBE_PACKAGE = "com.google.android.youtube"
    
    private val checkForegroundRunnable = object : Runnable {
        override fun run() {
            val foregroundApp = getForegroundApp()
            foregroundApp?.let {
                Log.d(TAG, "Current foreground app: $it")
                
                if (blockedPackages.contains(it)) {
                    Log.d(TAG, "Blocked app detected: $it")
                    showBlockOverlay(it)
                }
            }
            
            if (isRunning) {
                handler.postDelayed(this, CHECK_INTERVAL_MS)
            }
        }
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started")
        
        if (intent?.hasExtra("blockedPackages") == true) {
            val packages = intent.getStringArrayListExtra("blockedPackages")
            blockedPackages = packages ?: listOf()
            Log.d(TAG, "Blocked packages updated: $blockedPackages")
        }
        
        if (!isRunning) {
            isRunning = true
            handler.post(checkForegroundRunnable)
        }
        
        return START_STICKY
    }
    
    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        handler.removeCallbacks(checkForegroundRunnable)
        Log.d(TAG, "Service destroyed")
    }
    
    private fun getForegroundApp(): String? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            // Modern approach using UsageStatsManager
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val time = System.currentTimeMillis()
            val events = usageStatsManager.queryEvents(time - 1000 * 60, time)
            val event = UsageEvents.Event()
            var lastForegroundApp: String? = null
            
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                    lastForegroundApp = event.packageName
                }
            }
            
            lastForegroundApp
        } else {
            ""
        }
    }
    
    private fun showBlockOverlay(packageName: String) {
        // Start the overlay activity
        Log.d(TAG, "Showing block overlay");

        val intent = Intent(this, BlockOverlayActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            putExtra("blockedPackage", packageName)
        }
        startActivity(intent)
    }
    
    companion object {
        fun updateBlockedPackages(context: Context, packages: List<String>) {
            val intent = Intent(context, ForegroundAppDetectionService::class.java).apply {
                putStringArrayListExtra("blockedPackages", ArrayList(packages))
            }
            context.startService(intent)
        }
        
        fun startService(context: Context) {
            val intent = Intent(context, ForegroundAppDetectionService::class.java)
            context.startService(intent)
        }
        
        fun stopService(context: Context) {
            val intent = Intent(context, ForegroundAppDetectionService::class.java)
            context.stopService(intent)
        }
    }
}
