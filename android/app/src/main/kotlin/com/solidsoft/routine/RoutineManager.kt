package com.solidsoft.routine

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import java.util.ArrayList
import org.json.JSONArray
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.IntentFilter
import androidx.core.content.ContextCompat
import java.util.Calendar
import java.util.HashSet

/**
 * Accessibility service that monitors web browsing activity and blocks access to specific websites.
 */
class RoutineManager : AccessibilityService() {
    private val TAG = "RoutineManager"

    private var blockOverlayView: BlockOverlayView? = null

    private var routines = ArrayList<Routine>();

    private var sites = ArrayList<String>()
    private var apps = HashSet<String>()
    private var allow = false

    // Default redirect URL
    private val redirectUrl = "https://www.google.com"

    // Track current browser app and URL to avoid redundant processing
    private var currentBrowserUrl = ""
    
    // Cache the last seen app and site to handle block sessions that come into effect
    private var lastSeenApp = ""
    private var lastSeenSite = ""
    private var lastSeenTimestamp = 0L

    // Flag to track if an editable text field is focused
    private var isEditableFieldFocused = false
    
    // Track the last processed URL timestamp to avoid rapid redirects
    private var lastProcessedTime = 0L
    private val MIN_PROCESS_INTERVAL = 1000L

    override fun onCreate() {
        super.onCreate()
        blockOverlayView = BlockOverlayView(this)
        registerEvaluateReceiver()
    }
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Website blocker accessibility service connected")

        instance = this
        isEditableFieldFocused = false
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        val eventType = event.eventType
        val currentTime = System.currentTimeMillis()
        val packageName = event.packageName?.toString() ?: return
        val changeType = event.contentChangeTypes;

        Log.d(TAG, "Accessibility event: " +
                "$eventType, package: $packageName, action: ${event.contentChangeTypes}")

        // Update last seen app
        if (packageName != this.packageName) {
            lastSeenApp = packageName
            lastSeenTimestamp = currentTime
        }

        // block apps
        if (isBlockedApp(packageName) &&
            changeType != AccessibilityEvent.CONTENT_CHANGE_TYPE_PANE_DISAPPEARED) {
            showBlockOverlay(packageName)
            return
        } else if (blockOverlayView?.isShowing() == true) {
            if (packageName != this.packageName) {
                hideBlockOverlay()
            }
        }
        
        // block sites
        val browserConfig = getSupportedBrowsers().find { it.packageName == packageName }
            ?: return
        
        // Handle focus changes to detect when user is editing text
        if (eventType == AccessibilityEvent.TYPE_VIEW_FOCUSED || 
            eventType == AccessibilityEvent.TYPE_VIEW_CLICKED) {
            val source = event.source
            if (source != null) {
                // Check if the focused element is editable
                val isFocused = source.isFocused
                val isEditable = source.isEditable || source.className?.contains("EditText") == true
                val isAddressBar = isAddressBarNode(source, browserConfig)
                
                isEditableFieldFocused = isFocused && (isEditable || isAddressBar)
                
                if (isEditableFieldFocused) {
                    Log.d(TAG, "Editable field focused: $isEditableFieldFocused (address bar: $isAddressBar)")
                }
                
                return
            }
        }
        
        // Check for typing events
        if (eventType == AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED) {
            // User is typing, update focus state
            isEditableFieldFocused = true
            Log.d(TAG, "Text changed event detected, marking editable field as focused")
            return
        }
        
        // Only process content and window change events
        if (eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED ||
            eventType == AccessibilityEvent.TYPE_WINDOWS_CHANGED ||
            eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
            
            val parentNodeInfo = event.source ?: return
            
            // Check for focus state in the current view hierarchy
            updateFocusState(parentNodeInfo, browserConfig)
            
            // Capture URL from the browser
            val capturedUrl = captureUrl(parentNodeInfo, browserConfig)
            parentNodeInfo.recycle()
            
            if (capturedUrl == null || !android.util.Patterns.WEB_URL.matcher(capturedUrl).matches()) {
                return
            }
            
            // Only process URL if no editable field is focused and it passes validation
            if (!isEditableFieldFocused && shouldProcessUrl(capturedUrl, currentTime)) {
                processUrl(packageName, capturedUrl)
            }
        }
    }
    
    /**
     * Updates the focus state by checking the view hierarchy
     */
    private fun updateFocusState(rootNode: AccessibilityNodeInfo, browserConfig: SupportedBrowserConfig) {
        try {
            // Check if any editable field is focused in the hierarchy
            val focusedNode = findFocusedEditableNode(rootNode, browserConfig)
            isEditableFieldFocused = focusedNode != null
            
            if (isEditableFieldFocused) {
                Log.d(TAG, "Found focused editable node in view hierarchy")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error updating focus state: ${e.message}")
        }
    }

    private fun findFocusedEditableNode(rootNode: AccessibilityNodeInfo, browserConfig: SupportedBrowserConfig): AccessibilityNodeInfo? {
        // Check if this node is focused and editable
        if (rootNode.isFocused && (rootNode.isEditable || 
                                  rootNode.className?.contains("EditText") == true ||
                                  isAddressBarNode(rootNode, browserConfig))) {
            return rootNode
        }
        
        // Check children recursively
        for (i in 0 until rootNode.childCount) {
            val child = rootNode.getChild(i) ?: continue
            val result = findFocusedEditableNode(child, browserConfig)
            if (result != null) {
                return result
            }
            child.recycle()
        }
        
        return null
    }

    private fun isAddressBarNode(node: AccessibilityNodeInfo, browserConfig: SupportedBrowserConfig): Boolean {
        val nodeId = node.viewIdResourceName ?: return false
        return nodeId.contains(browserConfig.addressBarId.substringAfterLast("/"))
    }

    private fun shouldProcessUrl(url: String, currentTime: Long): Boolean {
        // Don't process the same URL too frequently
        if (url == currentBrowserUrl && (currentTime - lastProcessedTime) < MIN_PROCESS_INTERVAL) {
            return false
        }
        
        // Don't process very short URLs that might be incomplete
        if (url.length < 5) {
            return false
        }
        
        // Don't process URLs that look like they're being edited
        if (url.endsWith("|") || url.contains("|")) {
            return false
        }
        
        return true
    }

    private fun processUrl(packageName: String, capturedUrl: String) {
        val currentTime = System.currentTimeMillis()
        
        // Update tracking variables
        lastProcessedTime = currentTime
        currentBrowserUrl = capturedUrl
        
        // Update last seen site
        lastSeenSite = capturedUrl
        lastSeenTimestamp = currentTime
        
        Log.d(TAG, "Processing URL: $capturedUrl in $packageName")
        
        // Check if URL is blocked
        if (isBlockedUrl(capturedUrl)) {
            Log.d(TAG, "Blocked URL detected: $capturedUrl, redirecting...")
            redirectTo(redirectUrl)
        }
    }

    private data class SupportedBrowserConfig(
        val packageName: String, 
        val addressBarId: String
    )

    private fun getSupportedBrowsers(): List<SupportedBrowserConfig> {
        val browsers = ArrayList<SupportedBrowserConfig>()
        
        // Chrome
        browsers.add(SupportedBrowserConfig("com.android.chrome", "com.android.chrome:id/url_bar"))
        
        // Firefox
        browsers.add(SupportedBrowserConfig("org.mozilla.firefox", "org.mozilla.firefox:id/mozac_browser_toolbar_url_view"))
        browsers.add(SupportedBrowserConfig("org.mozilla.firefox", "org.mozilla.firefox:id/url_bar_title"))
        
        // Samsung Internet Browser
        browsers.add(SupportedBrowserConfig("com.sec.android.app.sbrowser", "com.sec.android.app.sbrowser:id/location_bar"))
        
        // Opera
        browsers.add(SupportedBrowserConfig("com.opera.browser", "com.opera.browser:id/url_field"))
        browsers.add(SupportedBrowserConfig("com.opera.mini.native", "com.opera.mini.native:id/url_field"))
        
        // Edge
        browsers.add(SupportedBrowserConfig("com.microsoft.emmx", "com.microsoft.emmx:id/url_bar"))
        
        // DuckDuckGo
        browsers.add(SupportedBrowserConfig("com.duckduckgo.mobile.android", "com.duckduckgo.mobile.android:id/omnibarTextInput"))
        
        // Brave
        browsers.add(SupportedBrowserConfig("com.brave.browser", "com.brave.browser:id/url_bar"))
        
        // UC Browser
        browsers.add(SupportedBrowserConfig("com.UCMobile.intl", "com.UCMobile.intl:id/url_bar"))
        
        // Vivaldi
        browsers.add(SupportedBrowserConfig("com.vivaldi.browser", "com.vivaldi.browser:id/url_bar"))
        
        return browsers
    }

    private fun captureUrl(info: AccessibilityNodeInfo, config: SupportedBrowserConfig): String? {
        try {
            val nodes = info.findAccessibilityNodeInfosByViewId(config.addressBarId)
            if (nodes.isEmpty()) {
                return null
            }
            
            val addressBarNodeInfo = nodes[0]
            val url = addressBarNodeInfo.text?.toString()
            
            // Check if the address bar is focused - this could indicate editing
            if (addressBarNodeInfo.isFocused) {
                isEditableFieldFocused = true
            }
            
            addressBarNodeInfo.recycle()
            
            // Clean up the URL if needed
            if (url != null) {
                // Remove any editing indicators or cursor markers
                return url.replace("|", "").trim()
            }
            
            return url
        } catch (e: Exception) {
            Log.e(TAG, "Error capturing URL: ${e.message}")
            return null
        }
    }

    private fun isUrlInList(url: String): Boolean {
        val lowerUrl = url.lowercase()
        Log.d(TAG, "lowerUrl: $lowerUrl sites: $sites")
        for (site in sites) {
            if (site == lowerUrl || lowerUrl.contains(site)) {
                return true
            }
        }
        return false
    }

    private fun isBlockedUrl(url: String): Boolean {
        val inList = isUrlInList(url)
        return (allow && !inList) || (!allow && inList)
    }

    private fun isBlockedApp(packageName: String): Boolean {
        val inList = apps.contains(packageName)
        return (allow && !inList) || (!allow && inList)
    }

    private fun redirectTo(url: String) {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error redirecting to browser: ${e.message}", e)
        }
    }
    
    override fun onInterrupt() {
        Log.d(TAG, "Website blocker accessibility service interrupted")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Website blocker accessibility service destroyed")
        instance = null
        blockOverlayView?.hide()
        blockOverlayView = null
        
        // Unregister the broadcast receiver
        try {
            applicationContext.unregisterReceiver(evaluateReceiver)
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering evaluate receiver: ${e.message}")
        }
    }

    private fun showBlockOverlay(packageName: String) {
        try {
            // Update notification to inform the user that an app is being blocked
            Log.d(TAG, "App blocked: $packageName")

            // Show the overlay window using SYSTEM_ALERT_WINDOW permission
            blockOverlayView?.show(packageName)

        } catch (e: Exception) {
            Log.e(TAG, "Error handling blocked app: ${e.message}", e)
        }
    }

    private fun hideBlockOverlay() {
        try {
            blockOverlayView?.hide()
        } catch (e: Exception) {
            Log.e(TAG, "Error hiding block overlay: ${e.message}", e)
        }
    }

    fun updateRoutines() {
        // Use applicationContext instead of appContext
        val sharedPreferences = applicationContext.getSharedPreferences("com.solidsoft.routine.preferences", Context.MODE_PRIVATE)
        
        // Get the JSON string from shared preferences
        val routinesJsonString = sharedPreferences.getString("routines", null) ?: return
        
        try {
            // Parse the JSON array string
            val routinesJsonArray = JSONArray(routinesJsonString)
            val routinesList = mutableListOf<Routine>()
            
            // Convert each JSON object to a Routine
            for (i in 0 until routinesJsonArray.length()) {
                val routineJson = routinesJsonArray.getJSONObject(i)
                val routine = Routine(routineJson)
                routinesList.add(routine)
            }
            
            // Update the routines list
            routines.clear()
            routines.addAll(routinesList)

            // Immediately evaluate routines
            evaluate()
            
            // Schedule evaluations at start and end times
            scheduleEvaluations()
            
            Log.d(TAG, "Updated ${routines.size} routines from shared preferences")
        } catch (e: Exception) {
            Log.e(TAG, "Error updating routines from shared preferences: ${e.message}")
        }
    }

    private fun scheduleEvaluations() {
        // Cancel any existing alarms
        cancelScheduledEvaluations()
        
        // Get the alarm manager
        val alarmManager = applicationContext.getSystemService(ALARM_SERVICE) as AlarmManager
        
        // Set of minutes of day to schedule evaluations (to avoid duplicates)
        val scheduledMinutes = HashSet<Int>()
        
        // Current calendar instance
        val calendar = Calendar.getInstance()
        
        // Get today's date components
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH)
        val day = calendar.get(Calendar.DAY_OF_MONTH)
        
        // For each routine, schedule evaluations at start and end times
        for (routine in routines) {
            // Schedule for paused and snoozed times
            val now = System.currentTimeMillis()
            
            // Schedule for pausedUntil if it's in the future
            routine.pausedUntil?.let { pausedUntil ->
                val pausedUntilTime = pausedUntil.time
                if (pausedUntilTime > now) {
                    scheduleEvaluationAtExactTime(
                        alarmManager,
                        pausedUntilTime,
                        "paused_${routine.id}".hashCode(),
                        "paused_until_expired",
                        routine.id
                    )
                    Log.d(TAG, "Scheduled evaluation for routine ${routine.name} when pause expires at ${pausedUntil}")
                }
            }
            
            // Schedule for snoozedUntil if it's in the future
            routine.snoozedUntil?.let { snoozedUntil ->
                val snoozedUntilTime = snoozedUntil.time
                if (snoozedUntilTime > now) {
                    scheduleEvaluationAtExactTime(
                        alarmManager,
                        snoozedUntilTime,
                        "snoozed_${routine.id}".hashCode(),
                        "snoozed_until_expired",
                        routine.id
                    )
                    Log.d(TAG, "Scheduled evaluation for routine ${routine.name} when snooze expires at ${snoozedUntil}")
                }
            }
            
            // Skip if routine doesn't have time constraints
            if (routine.allDay || (routine.startTime == null && routine.endTime == null)) {
                continue
            }
            
            // Schedule evaluation at start time if defined
            routine.startTime?.let { startTime ->
                scheduleEvaluationAtTime(alarmManager, startTime, scheduledMinutes, year, month, day)
            }
            
            // Schedule evaluation at end time if defined
            routine.endTime?.let { endTime ->
                scheduleEvaluationAtTime(alarmManager, endTime, scheduledMinutes, year, month, day)
            }
        }
    }
    
    /**
     * Schedules an evaluation at a specific time (in minutes of day)
     */
    private fun scheduleEvaluationAtTime(
        alarmManager: AlarmManager,
        timeInMinutes: Int,
        scheduledMinutes: HashSet<Int>,
        year: Int,
        month: Int,
        day: Int
    ) {
        // Only schedule if this time hasn't been scheduled yet
        if (!scheduledMinutes.contains(timeInMinutes)) {
            // Add to set of scheduled minutes
            scheduledMinutes.add(timeInMinutes)
            
            // Create calendar for the specified time
            val calendar = Calendar.getInstance()
            
            // Set calendar to today at the specified time
            calendar.set(year, month, day, timeInMinutes / 60, timeInMinutes % 60, 0)
            
            // If the time has already passed today, schedule for tomorrow
            if (calendar.timeInMillis < System.currentTimeMillis()) {
                calendar.add(Calendar.DAY_OF_YEAR, 1)
            }
            
            // Schedule at the calculated time
            scheduleEvaluationAtExactTime(
                alarmManager,
                calendar.timeInMillis,
                timeInMinutes,
                "daily_schedule",
                null
            )
            
            Log.d(TAG, "Scheduled evaluation at time: ${timeInMinutes / 60}:${timeInMinutes % 60}")
        }
    }
    
    /**
     * Schedules an evaluation at an exact timestamp
     */
    private fun scheduleEvaluationAtExactTime(
        alarmManager: AlarmManager,
        triggerTimeMillis: Long,
        requestCode: Int,
        reason: String,
        routineId: String?
    ) {
        // Create intent for the alarm
        val intent = Intent(EVALUATE_ACTION)
        if (reason.isNotEmpty()) {
            intent.putExtra("reason", reason)
        }
        if (routineId != null) {
            intent.putExtra("routineId", routineId)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            applicationContext,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Schedule the alarm based on Android version and permissions
        scheduleAlarm(alarmManager, triggerTimeMillis, pendingIntent)
    }

    private fun cancelScheduledEvaluations() {
        val alarmManager = applicationContext.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        // Cancel all possible alarms (for all minutes of the day)
        for (minute in 0 until 24 * 60) {
            val intent = Intent(EVALUATE_ACTION)
            val pendingIntent = PendingIntent.getBroadcast(
                applicationContext,
                minute,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            
            // If the pending intent exists, cancel it
            pendingIntent?.let {
                alarmManager.cancel(it)
                it.cancel()
            }
        }
    }

    private fun registerEvaluateReceiver() {
        // Create and register the broadcast receiver
        val filter = IntentFilter(EVALUATE_ACTION)
        ContextCompat.registerReceiver(
            applicationContext,
            evaluateReceiver,
            filter,
            ContextCompat.RECEIVER_NOT_EXPORTED
        )
    }
    
    private val evaluateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == EVALUATE_ACTION) {
                val reason = intent.getStringExtra("reason") ?: "scheduled_time"
                val routineId = intent.getStringExtra("routineId")
                
                Log.d(TAG, "Received scheduled evaluation broadcast. Reason: $reason, RoutineId: $routineId")
                
                // If this is for a specific routine that was paused/snoozed, log it
                if (routineId != null) {
                    val routine = routines.find { it.id == routineId }
                    if (routine != null) {
                        Log.d(TAG, "Re-evaluating after ${reason} expired for routine: ${routine.name}")
                    }
                }
                
                // Evaluate all routines
                evaluate()
            }
        }
    }

    private fun evaluate() {
        // Start timing the eval function
        val startTime = System.currentTimeMillis()
        
        Log.d(TAG, "Evaluating routines")
        
        // Filter routines: active and conditions not met
        val filteredRoutines = routines.filter { it.isActive() && !it.areConditionsMet() }
        Log.d(TAG, "Filtered routine count = ${filteredRoutines.size}")
        
        // Check if any routine is an allow list
        allow = filteredRoutines.any { it.allow }
        
        // Sets to hold excluded items (for allow list mode)
        val excludeApps = HashSet<String>()
        val excludeSites = HashSet<String>()
        
        // If in allow list mode, collect all items from block lists to exclude
        if (allow) {
            for (routine in filteredRoutines.filter { !it.allow }) {
                excludeApps.addAll(routine.getApps())
                excludeSites.addAll(routine.getSites())
            }
            
            // Only keep allow list routines
            val allowRoutines = filteredRoutines.filter { it.allow }
            
            // Process allow lists
            apps.clear()
            sites.clear()
            
            // In allow list mode, everything is blocked except what's in the allow lists
            // and not in any block list
            for (routine in allowRoutines) {
                apps.addAll(routine.getApps().filter { it !in excludeApps })
                sites.addAll(routine.getSites().filter { it !in excludeSites })
            }
        } else {
            // Process block lists
            apps.clear()
            sites.clear()
            
            // Collect all apps and domains to block
            for (routine in filteredRoutines) {
                apps.addAll(routine.getApps())
                sites.addAll(routine.getSites())
            }
        }

        // Check if the last seen app or site is now blocked
        checkLastSeenForBlocking()

        // Calculate elapsed time
        val elapsedTime = System.currentTimeMillis() - startTime
        
        Log.d(TAG, "Eval completed in ${elapsedTime}ms, blocked apps: ${apps.size}, blocked domains: ${sites.size}")
    }
    
    /**
     * Checks if the last seen app or site is now blocked and takes appropriate action
     */
    private fun checkLastSeenForBlocking() {
        // Only check if we have a recently seen app or site (within last 5 minutes)
        val currentTime = System.currentTimeMillis()
        val maxAge = 5 * 60 * 1000L // 5 minutes
        
        if (currentTime - lastSeenTimestamp > maxAge) {
            return
        }
        
        // Check if the last seen app is now blocked
        if (lastSeenApp.isNotEmpty() && isBlockedApp(lastSeenApp)) {
            Log.d(TAG, "Last seen app is now blocked: $lastSeenApp")
            showBlockOverlay(lastSeenApp)
        }
        
        // Check if the last seen site is now blocked
        if (lastSeenSite.isNotEmpty() && isBlockedUrl(lastSeenSite)) {
            if (getSupportedBrowsers().find { it.packageName == lastSeenApp } != null) {
                Log.d(TAG, "Last seen site is now blocked: $lastSeenSite")
                redirectTo(redirectUrl)
            }
        }
    }

    /**
     * Schedules an alarm using the appropriate method based on Android version and permissions
     */
    private fun scheduleAlarm(alarmManager: AlarmManager, triggerTime: Long, pendingIntent: PendingIntent) {
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                // Android 12 (API 31) and above requires SCHEDULE_EXACT_ALARM permission
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerTime,
                        pendingIntent
                    )
                } else {
                    // Fall back to inexact alarm if we don't have permission
                    Log.w(TAG, "Cannot schedule exact alarms. Using inexact alarm instead.")
                    alarmManager.set(
                        AlarmManager.RTC_WAKEUP,
                        triggerTime,
                        pendingIntent
                    )
                }
            } else if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                // Android 6.0 (API 23) to Android 11 (API 30)
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            } else {
                // Below Android 6.0
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling alarm: ${e.message}")
            // Fall back to inexact alarm as a last resort
            alarmManager.set(
                AlarmManager.RTC_WAKEUP,
                triggerTime,
                pendingIntent
            )
        }
    }

    companion object {
        // Static reference to the active service instance
        private var instance: RoutineManager? = null
        
        // Action for the broadcast receiver
        private const val EVALUATE_ACTION = "com.solidsoft.routine.EVALUATE_ACTION"
        
        fun updateRoutines() {
            instance?.updateRoutines()
        }
    }
}
