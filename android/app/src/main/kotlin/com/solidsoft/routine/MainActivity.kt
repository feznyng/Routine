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
import androidx.core.content.edit
import io.sentry.Sentry;

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.solidsoft.routine"
    private val TAG = "RoutineAndroid"

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.d(TAG, "onCreate: Starting")
        try {
            super.onCreate(savedInstanceState)
            Log.d(TAG, "onCreate: Completed")
        } catch (e: Exception) {
            Log.e(TAG, "Error in onCreate: ${e.message}", e)
            Sentry.captureException(e)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        Log.d(TAG, "configureFlutterEngine: Starting")
        try {
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
                            Sentry.captureException(e)
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
                            Sentry.captureException(e)
                            result.error("ROUTINES_ERROR", "Failed to update routines", e.message)
                        }
                    }
                    "retrieveAllApps" -> {
                        try {
                            Log.d(TAG, "retrieveAllApps: Starting")
                            val allApps = retrieveAllApps()
                            result.success(allApps)
                            Log.d(TAG, "retrieveAllApps: Completed")
                        } catch (e: Exception) {
                            Log.e(TAG, "Error retrieving all apps: ${e.message}", e)
                            Sentry.captureException(e)
                            result.error("RETRIEVE_APPS_ERROR", "Failed to retrieve apps", e.message)
                        }
                    }
                    "checkOverlayPermission" -> {
                        try {
                            Log.d(TAG, "checkOverlayPermission: Starting")
                            val permissionResult = checkOverlayPermission()
                            result.success(permissionResult)
                            Log.d(TAG, "checkOverlayPermission: Completed")
                        } catch (e: Exception) {
                            Log.e(TAG, "Error checking overlay permission: ${e.message}", e)
                            Sentry.captureException(e)
                            result.error("PERMISSION_ERROR", "Failed to check overlay permission", e.message)
                        }
                    }
                    "requestOverlayPermission" -> {
                        try {
                            Log.d(TAG, "requestOverlayPermission: Starting")
                            requestOverlayPermission();
                            result.success(checkOverlayPermission())
                            Log.d(TAG, "requestOverlayPermission: Completed")
                        } catch (e: Exception) {
                            Log.e(TAG, "Error requesting overlay permission: ${e.message}", e)
                            Sentry.captureException(e)
                            result.error("PERMISSION_ERROR", "Failed to request overlay permission", e.message)
                        }
                    }
                    "checkAccessibilityPermission" -> {
                        try {
                            Log.d(TAG, "checkAccessibilityPermission: Starting")
                            val permissionResult = isAccessibilityServiceEnabled()
                            result.success(permissionResult)
                            Log.d(TAG, "checkAccessibilityPermission: Completed")
                        } catch (e: Exception) {
                            Log.e(TAG, "Error checking accessibility permission: ${e.message}", e)
                            Sentry.captureException(e)
                            result.error("PERMISSION_ERROR", "Failed to check accessibility permission", e.message)
                        }
                    }
                    "requestAccessibilityPermission" -> {
                        try {
                            Log.d(TAG, "requestAccessibilityPermission: Starting")
                            requestAccessibilityPermission()
                            result.success(true)
                            Log.d(TAG, "requestAccessibilityPermission: Completed")
                        } catch (e: Exception) {
                            Log.e(TAG, "Error requesting accessibility permission: ${e.message}", e)
                            Sentry.captureException(e)
                            result.error("PERMISSION_ERROR", "Failed to request accessibility permission", e.message)
                        }
                    }
                    else -> {
                        Log.d(TAG, "Unknown method call: ${call.method}")
                        result.notImplemented()
                    }
                }
            }
            Log.d(TAG, "configureFlutterEngine: Completed")
        } catch (e: Exception) {
            Log.e(TAG, "Error in configureFlutterEngine: ${e.message}", e)
            Sentry.captureException(e)
        }
    }

    private fun handleUpdateStrictModeSettings(settings: Map<String, Any>) {
        Log.d(TAG, "handleUpdateStrictModeSettings: Starting")
        try {
            // Extract strict mode settings
            val blockChangingTimeSettings = settings["blockChangingTimeSettings"] as Boolean
            val blockUninstallingApps = settings["blockUninstallingApps"] as Boolean
            val blockInstallingApps = settings["blockInstallingApps"] as Boolean
            val inStrictMode = settings["inStrictMode"] as Boolean
            
            Log.d(TAG, "Received strict mode settings: blockChangingTimeSettings=$blockChangingTimeSettings, " +
                    "blockUninstallingApps=$blockUninstallingApps, blockInstallingApps=$blockInstallingApps, " +
                    "inStrictMode=$inStrictMode")
            
            // Persist strict mode settings to shared preferences
            val sharedPreferences = getSharedPreferences("com.solidsoft.routine.preferences", Context.MODE_PRIVATE)
            sharedPreferences.edit {
                putBoolean("blockChangingTimeSettings", blockChangingTimeSettings)
                putBoolean("blockUninstallingApps", blockUninstallingApps)
                putBoolean("blockInstallingApps", blockInstallingApps)
                putBoolean("inStrictMode", inStrictMode)
            }

            RoutineManager.updateStrictMode()
            
            Log.d(TAG, "handleUpdateStrictModeSettings: Completed")
        } catch (e: Exception) {
            Log.e(TAG, "Error handling strict mode settings update: ${e.message}", e)
            Sentry.captureException(e)
            throw e
        }
    }

    private fun handleUpdateRoutines(routines: List<Map<String, Any>>) {
        Log.d(TAG, "handleUpdateRoutines: Starting")
        try {
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
        } catch (e: Exception) {
            Log.e(TAG, "Error handling routines update: ${e.message}", e)
            Sentry.captureException(e)
            throw e
        }
    }
    
    private fun checkOverlayPermission(): Boolean {
        Log.d(TAG, "checkOverlayPermission: Starting")
        try {
            val result = Settings.canDrawOverlays(this)
            Log.d(TAG, "checkOverlayPermission: Completed with result=$result")
            return result // On older versions, the permission is granted at install time
        } catch (e: Exception) {
            Log.e(TAG, "Error checking overlay permission: ${e.message}", e)
            Sentry.captureException(e)
            throw e
        }
    }
    
    private fun requestOverlayPermission() {
        Log.d(TAG, "requestOverlayPermission: Starting")
        try {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                "package:$packageName".toUri()
            )
            startActivity(intent)
            Log.d(TAG, "requestOverlayPermission: Completed")
        } catch (e: Exception) {
            Log.e(TAG, "Error requesting overlay permission: ${e.message}", e)
            Sentry.captureException(e)
            throw e
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        Log.d(TAG, "isAccessibilityServiceEnabled: Starting")
        try {
            val accessibilityManager = getSystemService(Context.ACCESSIBILITY_SERVICE) as android.view.accessibility.AccessibilityManager
            val enabledServices = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: return false
            
            val serviceName = packageName + "/" + RoutineManager::class.java.canonicalName
            val result = enabledServices.contains(serviceName)
            Log.d(TAG, "isAccessibilityServiceEnabled: Completed with result=$result")
            return result
        } catch (e: Exception) {
            Log.e(TAG, "Error checking accessibility service: ${e.message}", e)
            Sentry.captureException(e)
            throw e
        }
    }

    private fun retrieveAllApps(): List<Map<String, Any>> {
        Log.d(TAG, "retrieveAllApps: Starting")
        try {
            val packageManager = packageManager
            val installedApps = packageManager.getInstalledApplications(0)
            val appsList = mutableListOf<Map<String, Any>>()

            Log.d(TAG, "Retrieving all apps = ${installedApps.size}")

            for (appInfo in installedApps) {
                try {
                    if (!Util.isBlockable(appInfo)) {
                        continue
                    }

                    val appName = packageManager.getApplicationLabel(appInfo).toString()

                    val appMap = mapOf(
                        "filePath" to appInfo.packageName,
                        "name" to appName,
                        "isSystemApp" to ((appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0)
                    )
                    
                    appsList.add(appMap)
                } catch (e: Exception) {
                    Log.e(TAG, "Error processing app ${appInfo.packageName}: ${e.message}", e)
                    Sentry.captureException(e)
                    // Continue with next app
                }
            }
            
            Log.d(TAG, "retrieveAllApps: Completed with ${appsList.size} apps")
            return appsList
        } catch (e: Exception) {
            Log.e(TAG, "Error retrieving all apps: ${e.message}", e)
            Sentry.captureException(e)
            throw e
        }
    }

    private fun requestAccessibilityPermission() {
        Log.d(TAG, "requestAccessibilityPermission: Starting")
        try {
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
            
            // Show a toast to guide the user
            android.widget.Toast.makeText(
                this,
                "Please enable 'Routine' in the Accessibility settings",
                android.widget.Toast.LENGTH_LONG
            ).show()
            Log.d(TAG, "requestAccessibilityPermission: Completed")
        } catch (e: Exception) {
            Log.e(TAG, "Error requesting accessibility permission: ${e.message}", e)
            Sentry.captureException(e)
            throw e
        }
    }
}
