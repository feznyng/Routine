package com.solidsoft.routine

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.routine.ios_channel"
    private val TAG = "RoutineAndroid"

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
                "checkFamilyControlsAuthorization" -> {
                    // This is iOS-specific, but we'll add a placeholder for Android
                    Log.d(TAG, "checkFamilyControlsAuthorization called (iOS-specific)")
                    result.success(false)
                }
                "requestFamilyControlsAuthorization" -> {
                    // This is iOS-specific, but we'll add a placeholder for Android
                    Log.d(TAG, "requestFamilyControlsAuthorization called (iOS-specific)")
                    result.success(false)
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
        
        // TODO: Implement actual handling of strict mode settings for Android
    }

    private fun handleUpdateRoutines(routines: List<Map<String, Any>>, immediate: Boolean) {
        // Placeholder implementation for handling routine updates
        Log.d(TAG, "Received ${routines.size} routines to update (immediate=$immediate)")
        
        for (routine in routines) {
            val id = routine["id"] as String
            val name = routine["name"] as String
            val strictMode = routine["strictMode"] as Boolean
            
            Log.d(TAG, "Routine: id=$id, name=$name, strictMode=$strictMode")
        }
        
        // TODO: Implement actual handling of routines for Android
    }
}
