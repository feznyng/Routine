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
import android.app.admin.DevicePolicyManager
import android.content.ComponentName

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
                "checkDeviceManagerPolicyPermission" -> {
                    Log.d(TAG, "checkDeviceManagerPolicyPermission: Starting")
                    val permissionResult = isDeviceAdminActive()
                    result.success(permissionResult)
                    Log.d(TAG, "checkDeviceManagerPolicyPermission: Completed")
                }
                "requestDeviceManagerPolicyPermission" -> {
                    Log.d(TAG, "requestDeviceManagerPolicyPermission: Starting")
                    requestDeviceAdminPrivileges()
                    result.success(true)
                    Log.d(TAG, "requestDeviceManagerPolicyPermission: Completed")
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


        // If strict mode is enabled, request device admin privileges
        if (inStrictMode) {
            requestDeviceAdminPrivileges()
        }
        
        // Update strict mode settings in RoutineManager
        RoutineManager.updateStrictMode()
        
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
                Log.e(TAG, "Error retrieving app info for ${appInfo.packageName}: ${e.message}")
            }
        }
        
        // Sort apps by name (fixed to use the correct key)
        val result = appsList.sortedBy { it["name"].toString().lowercase() }
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
            "Please enable 'Routine' in the Accessibility settings",
            android.widget.Toast.LENGTH_LONG
        ).show()
        Log.d(TAG, "requestAccessibilityPermission: Completed")
    }

    /**
     * Requests device admin privileges if not already granted
     */
    private fun requestDeviceAdminPrivileges() {
        val devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponentName = ComponentName(this, DeviceAdminReceiver::class.java)
        
        // Check if the app is already a device admin
        if (!devicePolicyManager.isAdminActive(adminComponentName)) {
            Log.d(TAG, "Requesting device admin privileges")
            
            // Create intent to launch the add device admin activity
            val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponentName)
                putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, getString(R.string.device_admin_description))
            }
            
            // Start the activity to request device admin privileges
            startActivity(intent)
        } else {
            Log.d(TAG, "Device admin privileges already granted")
        }
    }

    /**
     * Checks if the app has active device admin privileges
     * @return Boolean indicating if the app is an active device admin
     */
    private fun isDeviceAdminActive(): Boolean {
        val devicePolicyManager = getSystemService(DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponentName = ComponentName(this, DeviceAdminReceiver::class.java)
        
        val isAdmin = devicePolicyManager.isAdminActive(adminComponentName)
        Log.d(TAG, "Device admin active: $isAdmin")
        return isAdmin
    }
}
