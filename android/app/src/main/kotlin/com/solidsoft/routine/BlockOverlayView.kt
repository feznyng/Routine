package com.solidsoft.routine

import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView

/**
 * A view that displays over other apps to block interaction with blocked apps.
 * Uses SYSTEM_ALERT_WINDOW permission to show a blocking overlay.
 */
class BlockOverlayView(private val context: Context) {
    private val TAG = "BlockOverlayView"
    private var overlayView: View? = null
    private val windowManager: WindowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private var isShowing = false
    
    /**
     * Shows the blocking overlay for a specific package
     */
    fun show(packageName: String) {
        if (isShowing) {
            // Already showing, just update the text
            updateBlockedAppInfo(packageName)
            return
        }
        
        try {
            // Inflate the overlay layout
            val inflater = LayoutInflater.from(context)
            overlayView = inflater.inflate(R.layout.view_block_overlay, null)
            
            // Set the app name in the message
            updateBlockedAppInfo(packageName)
            
            // Set up the close button
            val closeButton = overlayView?.findViewById<Button>(R.id.closeButton)
            closeButton?.setOnClickListener {
                hide()
                goToHomeScreen()
            }
            
            // Create layout parameters for the overlay window
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                getOverlayType(),
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                        WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            )
            
            params.gravity = Gravity.CENTER
            
            // Add the view to the window
            windowManager.addView(overlayView, params)
            isShowing = true
            
            Log.d(TAG, "Block overlay shown for $packageName")
        } catch (e: Exception) {
            Log.e(TAG, "Error showing block overlay: ${e.message}", e)
        }
    }
    
    /**
     * Updates the blocked app information in the overlay
     */
    private fun updateBlockedAppInfo(packageName: String) {
        try {
            val appName = getAppNameFromPackage(packageName)
            val messageTextView = overlayView?.findViewById<TextView>(R.id.blockMessageTextView)
            messageTextView?.text = "This app ($appName) is currently blocked by Routine"
        } catch (e: Exception) {
            Log.e(TAG, "Error updating blocked app info: ${e.message}", e)
        }
    }
    
    /**
     * Hides the blocking overlay
     */
    fun hide() {
        if (!isShowing || overlayView == null) return
        
        try {
            windowManager.removeView(overlayView)
            overlayView = null
            isShowing = false
            Log.d(TAG, "Block overlay hidden")
        } catch (e: Exception) {
            Log.e(TAG, "Error hiding block overlay: ${e.message}", e)
        }
    }
    
    /**
     * Gets the appropriate overlay window type based on Android version
     */
    private fun getOverlayType(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
        }
    }
    
    /**
     * Gets the app name from its package name
     */
    private fun getAppNameFromPackage(packageName: String): String {
        return try {
            val packageManager = context.packageManager
            val applicationInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(applicationInfo).toString()
        } catch (e: Exception) {
            packageName
        }
    }
    
    /**
     * Navigates to the home screen
     */
    private fun goToHomeScreen() {
        val homeIntent = Intent(Intent.ACTION_MAIN)
        homeIntent.addCategory(Intent.CATEGORY_HOME)
        homeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(homeIntent)
    }
    
    /**
     * Checks if the overlay is currently being displayed
     */
    fun isShowing(): Boolean {
        return isShowing
    }
}
