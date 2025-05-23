package com.solidsoft.routine

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.os.Build
import android.provider.Settings

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.routine.ios_channel"
    private val TAG = "RoutineAndroid"
    
    // YouTube package name
    private val YOUTUBE_PACKAGE = "com.google.android.youtube"
    private var blockedApps = mutableListOf<String>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        checkUsageStatsPermission()
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateStrictModeSettings" -> {
                    try {
                        val settings = call.arguments as Map<String, Any>
                        handleUpdateStrictModeSettings(settings)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error updating strict mode settings: ${e.message}", e)
                        result.error("STRICT_MODE_ERROR", "Failed to update strict mode settings", e.message)
                    }
                }
                "updateRoutines" -> {
                    try {
                        val arguments = call.arguments as Map<String, Any>
                        val routines = arguments["routines"] as List<Map<String, Any>>
                        handleUpdateRoutines(routines, false)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error updating routines: ${e.message}", e)
                        result.error("ROUTINES_ERROR", "Failed to update routines", e.message)
                    }
                }
                "immediateUpdateRoutines" -> {
                    try {
                        val arguments = call.arguments as Map<String, Any>
                        val routines = arguments["routines"] as List<Map<String, Any>>
                        handleUpdateRoutines(routines, true)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error immediately updating routines: ${e.message}", e)
                        result.error("IMMEDIATE_ROUTINES_ERROR", "Failed to immediately update routines", e.message)
                    }
                }
                "checkOverlayPermission" -> {
                    result.success(checkOverlayPermission())
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission();
                    result.success(checkOverlayPermission())
                }
                "checkAccessibilityPermission" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "requestAccessibilityPermission" -> {
                    requestAccessibilityPermission()
                    result.success(true)
                }
                "updateBlockedWebsites" -> {
                    try {
                        val arguments = call.arguments as Map<String, Any>
                        val websites = arguments["websites"] as? List<String> ?: listOf()
                        updateBlockedWebsites(websites)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error updating blocked websites: ${e.message}", e)
                        result.error("WEBSITE_BLOCK_ERROR", "Failed to update blocked websites", e.message)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun handleUpdateStrictModeSettings(settings: Map<String, Any>) {
        // Placeholder implementation for handling strict mode settings
        val blockChangingTimeSettings = settings["blockChangingTimeSettings"] as Boolean
        val blockUninstallingApps = settings["blockUninstallingApps"] as Boolean
        val blockInstallingApps = settings["blockInstallingApps"] as Boolean
        val inStrictMode = settings["inStrictMode"] as Boolean
        
        Log.d(TAG, "Received strict mode settings: blockChangingTimeSettings=$blockChangingTimeSettings, " +
                "blockUninstallingApps=$blockUninstallingApps, blockInstallingApps=$blockInstallingApps, " +
                "inStrictMode=$inStrictMode")
        
        // TODO: Implement actual handling of strict mode settings for Android using DevicePolicyManager
    }

    private fun handleUpdateRoutines(routines: List<Map<String, Any>>, immediate: Boolean) {
        // Placeholder implementation for handling routine updates
        Log.d(TAG, "Received ${routines.size} routines to update (immediate=$immediate)")
        
        // Update blocked apps list based on routines
        val newBlockedApps = mutableListOf<String>()
        
        for (routine in routines) {
            val id = routine["id"] as String
            val name = routine["name"] as String
            val strictMode = routine["strictMode"] as Boolean
            val apps = routine["apps"] as? List<String> ?: emptyList()
            val allow = routine["allow"] as Boolean
            
            Log.d(TAG, "Routine: id=$id, name=$name, strictMode=$strictMode, apps=$apps, allow=$allow")
        }
        
        // Update blocked apps and service
        blockedApps = newBlockedApps

        if (!blockedApps.contains(YOUTUBE_PACKAGE)) {
            blockedApps.add(YOUTUBE_PACKAGE)
        }

        updateBlockedApps()
    }
    
    private fun checkUsageStatsPermission() {
        val appOpsManager = getSystemService(Context.APP_OPS_SERVICE) as android.app.AppOpsManager
        val mode = appOpsManager.checkOpNoThrow(
            android.app.AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            packageName
        )
        
        if (mode != android.app.AppOpsManager.MODE_ALLOWED) {
            // Need to request permission
            Log.d(TAG, "Usage stats permission not granted, requesting...")
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            startActivity(intent)
        }
    }
    
    private fun checkOverlayPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return Settings.canDrawOverlays(this)
        }
        return true // On older versions, the permission is granted at install time
    }
    
    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                Log.d(TAG, "Overlay permission not granted, requesting...")
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:$packageName")
                )
                startActivity(intent)
            }
        }
    }

    private fun updateBlockedApps() {
        ForegroundAppDetectionService.updateBlockedPackages(this, blockedApps)
    }
    
    /**
     * Checks if the accessibility service is enabled
     */
    private fun isAccessibilityServiceEnabled(): Boolean {
        val accessibilityManager = getSystemService(Context.ACCESSIBILITY_SERVICE) as android.view.accessibility.AccessibilityManager
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        
        val serviceName = packageName + "/" + WebsiteBlockerAccessibilityService::class.java.canonicalName
        return enabledServices.contains(serviceName)
    }
    
    /**
     * Opens the accessibility settings screen for the user to enable the service
     */
    private fun requestAccessibilityPermission() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
        
        // Show a toast to guide the user
        android.widget.Toast.makeText(
            this,
            "Please enable 'Website Blocker' in the Accessibility settings",
            android.widget.Toast.LENGTH_LONG
        ).show()
    }
    
    /**
     * Updates the list of blocked websites in the accessibility service
     */
    private fun updateBlockedWebsites(websites: List<String>) {
        Log.d(TAG, "Updating blocked websites: $websites")
        WebsiteBlockerAccessibilityService.updateBlockedDomains(websites)
    }
}
