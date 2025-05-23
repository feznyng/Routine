package com.solidsoft.routine

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import java.util.Timer
import java.util.TimerTask

class BlockOverlayActivity : Activity() {
    private val TAG = "BlockOverlay"
    private var blockedPackage: String? = null
    private var timer: Timer? = null
    private var secondsRemaining = 0
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Set window flags to show on top of other apps
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )
        
        setContentView(R.layout.activity_block_overlay)
        
        blockedPackage = intent.getStringExtra("blockedPackage")
        Log.d(TAG, "Blocking package: $blockedPackage")
        
        // Set app name in message
        val appName = getAppNameFromPackage(blockedPackage)
        val messageTextView = findViewById<TextView>(R.id.blockMessageTextView)
        messageTextView.text = "This app ($appName) is currently blocked by Routine"
        
        // Setup close button
        val closeButton = findViewById<Button>(R.id.closeButton)
        closeButton.setOnClickListener {
            goToHomeScreen()
        }
        
        // Setup countdown if provided
        val countdownTextView = findViewById<TextView>(R.id.countdownTextView)
        if (intent.hasExtra("countdownSeconds")) {
            secondsRemaining = intent.getIntExtra("countdownSeconds", 0)
            countdownTextView.visibility = View.VISIBLE
            startCountdown(countdownTextView)
        } else {
            countdownTextView.visibility = View.GONE
        }
    }
    
    private fun getAppNameFromPackage(packageName: String?): String {
        return try {
            val packageManager = applicationContext.packageManager
            val applicationInfo = packageName?.let { 
                packageManager.getApplicationInfo(it, 0) 
            }
            // Handle nullable applicationInfo
            if (applicationInfo != null) {
                packageManager.getApplicationLabel(applicationInfo).toString()
            } else {
                packageName ?: "Unknown"
            }
        } catch (e: Exception) {
            packageName ?: "Unknown"
        }
    }
    
    private fun startCountdown(textView: TextView) {
        timer = Timer()
        timer?.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                runOnUiThread {
                    if (secondsRemaining <= 0) {
                        finish()
                    } else {
                        textView.text = "Time remaining: $secondsRemaining seconds"
                        secondsRemaining--
                    }
                }
            }
        }, 0, 1000)
    }
    
    private fun goToHomeScreen() {
        val homeIntent = Intent(Intent.ACTION_MAIN)
        homeIntent.addCategory(Intent.CATEGORY_HOME)
        homeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(homeIntent)
        finish()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        timer?.cancel()
        timer = null
    }
    
    // Prevent user from using back button to bypass
    override fun onBackPressed() {
        goToHomeScreen()
    }
}
