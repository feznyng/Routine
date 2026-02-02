package com.solidsoft.routine

import android.content.Context
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView

class ReasonOverlayView(private val context: Context) {
    private val TAG = "ReasonOverlayView"

    private var overlayView: View? = null
    private val windowManager: WindowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val handler = Handler(Looper.getMainLooper())

    private var isShowing = false
    private var hideRunnable: Runnable? = null

    fun show(message: String, durationMs: Long = 2500L) {
        try {
            if (isShowing && overlayView != null) {
                updateMessage(message)
                scheduleHide(durationMs)
                return
            }

            val inflater = LayoutInflater.from(context)
            overlayView = inflater.inflate(R.layout.view_reason_overlay, null)

            updateMessage(message)

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                getOverlayType(),
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            )

            params.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            params.y = 140

            windowManager.addView(overlayView, params)
            isShowing = true

            scheduleHide(durationMs)

            Log.d(TAG, "Reason overlay shown: $message")
        } catch (e: Exception) {
            Log.e(TAG, "Error showing reason overlay: ${e.message}", e)
        }
    }

    fun hide() {
        if (!isShowing || overlayView == null) return

        try {
            hideRunnable?.let { handler.removeCallbacks(it) }
            hideRunnable = null

            windowManager.removeView(overlayView)
            overlayView = null
            isShowing = false

            Log.d(TAG, "Reason overlay hidden")
        } catch (e: Exception) {
            Log.e(TAG, "Error hiding reason overlay: ${e.message}", e)
        }
    }

    fun isShowing(): Boolean = isShowing

    private fun updateMessage(message: String) {
        try {
            val tv = overlayView?.findViewById<TextView>(R.id.reasonTextView)
            tv?.text = message
        } catch (e: Exception) {
            Log.e(TAG, "Error updating reason overlay message: ${e.message}", e)
        }
    }

    private fun scheduleHide(durationMs: Long) {
        hideRunnable?.let { handler.removeCallbacks(it) }
        hideRunnable = Runnable { hide() }
        handler.postDelayed(hideRunnable!!, durationMs)
    }

    private fun getOverlayType(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
        }
    }
}
