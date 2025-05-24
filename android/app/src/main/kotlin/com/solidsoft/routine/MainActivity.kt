package com.solidsoft.routine

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.os.Build
import android.provider.Settings
import androidx.core.net.toUri
import org.json.JSONArray
import org.json.JSONObject
import kotlin.apply
import androidx.core.content.edit

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.solidsoft.routine"
    private val TAG = "RoutineAndroid"

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.d(TAG, "onCreate: Starting")
        super.onCreate(savedInstanceState)
        Log.d(TAG, "onCreate: Completed")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        Log.d(TAG, "configureFlutterEngine: Starting")
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateStrictModeSettings" -> {
                    try {
                        Log.d(TAG, "updateStrictModeSettings: Starting")
                        val settings = call.arguments as Map<String, Any>
                        handleUpdateStrictModeSettings(settings)
                        result.success(true)
                        Log.d(TAG, "updateStrictModeSettings: Completed")
                    } catch (e: Exception) {
                        Log.e(TAG, "Error updating strict mode settings: ${e.message}", e)
                        result.error("STRICT_MODE_ERROR", "Failed to update strict mode settings", e.message)
                    }
                }
                "updateRoutines" -> {
                    try {
                        Log.d(TAG, "updateRoutines: Starting")
                        val arguments = call.arguments as Map<String, Any>
                        val routines = arguments["routines"] as List<Map<String, Any>>
                        handleUpdateRoutines(routines)
                        result.success(true)
                        Log.d(TAG, "updateRoutines: Completed")
                    } catch (e: Exception) {
                        Log.e(TAG, "Error updating routines: ${e.message}", e)
                        result.error("ROUTINES_ERROR", "Failed to update routines", e.message)
                    }
                }
                "retrieveAllApps" -> {
                    Log.d(TAG, "retrieveAllApps: Starting")
                    val allApps = retrieveAllApps()
                    result.success(allApps)
                    Log.d(TAG, "retrieveAllApps: Completed")
                }
                "checkOverlayPermission" -> {
                    Log.d(TAG, "checkOverlayPermission: Starting")
                    val permissionResult = checkOverlayPermission()
                    result.success(permissionResult)
                    Log.d(TAG, "checkOverlayPermission: Completed")
                }
                "requestOverlayPermission" -> {
                    Log.d(TAG, "requestOverlayPermission: Starting")
                    requestOverlayPermission();
                    result.success(checkOverlayPermission())
                    Log.d(TAG, "requestOverlayPermission: Completed")
                }
                "checkAccessibilityPermission" -> {
                    Log.d(TAG, "checkAccessibilityPermission: Starting")
                    val permissionResult = isAccessibilityServiceEnabled()
                    result.success(permissionResult)
                    Log.d(TAG, "checkAccessibilityPermission: Completed")
                }
                "requestAccessibilityPermission" -> {
                    Log.d(TAG, "requestAccessibilityPermission: Starting")
                    requestAccessibilityPermission()
                    result.success(true)
                    Log.d(TAG, "requestAccessibilityPermission: Completed")
                }
                else -> {
                    Log.d(TAG, "Unknown method call: ${call.method}")
                    result.notImplemented()
                }
            }
        }
        Log.d(TAG, "configureFlutterEngine: Completed")
    }

    private fun handleUpdateStrictModeSettings(settings: Map<String, Any>) {
        Log.d(TAG, "handleUpdateStrictModeSettings: Starting")
        // Placeholder implementation for handling strict mode settings
        val blockChangingTimeSettings = settings["blockChangingTimeSettings"] as Boolean
        val blockUninstallingApps = settings["blockUninstallingApps"] as Boolean
        val blockInstallingApps = settings["blockInstallingApps"] as Boolean
        val inStrictMode = settings["inStrictMode"] as Boolean
        
        Log.d(TAG, "Received strict mode settings: blockChangingTimeSettings=$blockChangingTimeSettings, " +
                "blockUninstallingApps=$blockUninstallingApps, blockInstallingApps=$blockInstallingApps, " +
                "inStrictMode=$inStrictMode")
        
        // TODO: Implement actual handling of strict mode settings for Android using DevicePolicyManager
        Log.d(TAG, "handleUpdateStrictModeSettings: Completed")
    }

    private fun handleUpdateRoutines(routines: List<Map<String, Any>>) {
        Log.d(TAG, "handleUpdateRoutines: Starting")
        // Placeholder implementation for handling routine updates
        Log.d(TAG, "Received ${routines.size} routines to update")

        val sharedPreferences = getSharedPreferences("com.solidsoft.routine.preferences", Context.MODE_PRIVATE)
        sharedPreferences.edit {
            // Convert routines to JSON array
            val routinesJsonArray = JSONArray()
            for (routine in routines) {
                // Convert each routine map to a JSONObject before adding to the array
                routinesJsonArray.put(JSONObject(routine))
            }

            // Save JSON array as string
            putString("routines", routinesJsonArray.toString())
        }

        RoutineManager.updateRoutines()
        Log.d(TAG, "handleUpdateRoutines: Completed")
    }
    
    private fun checkOverlayPermission(): Boolean {
        Log.d(TAG, "checkOverlayPermission: Starting")
        var result = true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            result = Settings.canDrawOverlays(this)
        }
        Log.d(TAG, "checkOverlayPermission: Completed with result=$result")
        return result // On older versions, the permission is granted at install time
    }
    
    private fun requestOverlayPermission() {
        Log.d(TAG, "requestOverlayPermission: Starting")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                Log.d(TAG, "Overlay permission not granted, requesting...")
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    "package:$packageName".toUri()
                )
                startActivity(intent)
            }
        }
        Log.d(TAG, "requestOverlayPermission: Completed")
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        Log.d(TAG, "isAccessibilityServiceEnabled: Starting")
        val accessibilityManager = getSystemService(Context.ACCESSIBILITY_SERVICE) as android.view.accessibility.AccessibilityManager
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        
        val serviceName = packageName + "/" + RoutineManager::class.java.canonicalName
        val result = enabledServices.contains(serviceName)
        Log.d(TAG, "isAccessibilityServiceEnabled: Completed with result=$result")
        return result
    }

    private fun retrieveAllApps(): List<Map<String, Any>> {
        Log.d(TAG, "retrieveAllApps: Starting")
        val packageManager = packageManager
        val installedApps = packageManager.getInstalledApplications(0)
        val appsList = mutableListOf<Map<String, Any>>()

        Log.d(TAG, "Retrieving all apps = ${installedApps.size}")

        for (appInfo in installedApps) {
            try {
                if (appInfo.packageName == this.packageName) {
                    continue
                }

                // Skip system apps if they don't have a launcher
                val intent = packageManager.getLaunchIntentForPackage(appInfo.packageName)
                if (intent == null && (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0) {
                    continue
                }
                
                // Get app name
                val appName = packageManager.getApplicationLabel(appInfo).toString()
                
                // Create app info map
                val appMap = mapOf(
                    "filePath" to appInfo.packageName,
                    "name" to appName,
                )
                
                appsList.add(appMap)
            } catch (e: Exception) {
                Log.e(TAG, "Error retrieving app info for ${appInfo.packageName}: ${e.message}")
            }
        }
        
        // Sort apps by name
        val result = appsList.sortedBy { it["appName"].toString().lowercase() }
        Log.d(TAG, "retrieveAllApps: Completed with ${result.size} apps")
        return result
    }

    private fun requestAccessibilityPermission() {
        Log.d(TAG, "requestAccessibilityPermission: Starting")
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(intent)
        
        // Show a toast to guide the user
        android.widget.Toast.makeText(
            this,
            "Please enable 'Website Blocker' in the Accessibility settings",
            android.widget.Toast.LENGTH_LONG
        ).show()
        Log.d(TAG, "requestAccessibilityPermission: Completed")
    }
}
