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
import kotlin.apply
import androidx.core.content.edit

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.routine.ios_channel"
    private val TAG = "RoutineAndroid"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
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
                        handleUpdateRoutines(routines)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Error updating routines: ${e.message}", e)
                        result.error("ROUTINES_ERROR", "Failed to update routines", e.message)
                    }
                }
                "retrieveAllApps" -> {
                    val allApps = retrieveAllApps()
                    Log.d(TAG, "Retrieved ${allApps.size} apps")
                    result.success(allApps)
                }
                "checkOverlayPermission" -> {
                    Log.d(TAG, "Check overlay permission")
                    result.success(checkOverlayPermission())
                }
                "requestOverlayPermission" -> {
                    Log.d(TAG, "Request overlay permission")
                    requestOverlayPermission();
                    result.success(checkOverlayPermission())
                }
                "checkAccessibilityPermission" -> {
                    Log.d(TAG, "Check accessibility permission")
                    result.success(isAccessibilityServiceEnabled())
                }
                "requestAccessibilityPermission" -> {
                    Log.d(TAG, "Request accessibility permission")
                    requestAccessibilityPermission()
                    result.success(true)
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

    private fun handleUpdateRoutines(routines: List<Map<String, Any>>) {
        // Placeholder implementation for handling routine updates
        Log.d(TAG, "Received ${routines.size} routines to update")

        val sharedPreferences = getSharedPreferences("com.solidsoft.routine.preferences", Context.MODE_PRIVATE)
        sharedPreferences.edit {
            // Convert routines to JSON array
            val routinesJsonArray = JSONArray()
            for (routine in routines) {
                routinesJsonArray.put(routine)
            }

            // Save JSON array as string
            putString("routines", routinesJsonArray.toString())
        }

        RoutineManager.updateRoutines()
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
                    "package:$packageName".toUri()
                )
                startActivity(intent)
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val accessibilityManager = getSystemService(Context.ACCESSIBILITY_SERVICE) as android.view.accessibility.AccessibilityManager
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        
        val serviceName = packageName + "/" + RoutineManager::class.java.canonicalName
        return enabledServices.contains(serviceName)
    }

    private fun retrieveAllApps(): List<Map<String, Any>> {
        val packageManager = packageManager
        val installedApps = packageManager.getInstalledApplications(0)
        val appsList = mutableListOf<Map<String, Any>>()

        Log.d(TAG, "Retrieving all apps = ${installedApps.size}")

        for (appInfo in installedApps) {
            try {
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

        Log.d(TAG, "Finished retrieving all apps = ${appsList.size}")

        // Sort apps by name
        return appsList.sortedBy { it["name"].toString().lowercase() }
    }

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
}
