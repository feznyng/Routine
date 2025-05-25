package com.solidsoft.routine

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import java.util.ArrayList
import java.util.Calendar
import java.util.HashSet
import org.json.JSONArray
import java.util.Date

private const val SYSTEM_UI_PACKAGE = "com.android.systemui"

class RoutineManager : AccessibilityService() {
    private val TAG = "RoutineManager"

    private var blockOverlayView: BlockOverlayView? = null

    private var routines = ArrayList<Routine>();

    private var sites = ArrayList<String>()
    private var apps = HashSet<String>()
    private var allow = false
    
    // Strict mode settings
    private var strictModeEnabled = false
    private var blockChangingTimeSettings = false
    private var blockUninstallingApps = false
    private var blockInstallingApps = false

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
    
    // Handler for scheduling evaluations
    private val handler = Handler(Looper.getMainLooper())
    private var evaluationRunnable: Runnable? = null
    
    // List of evaluation times sorted by timestamp
    private var evaluationTimes = ArrayList<EvaluationTime>()
    private var currentEvaluationIndex = 0

    // Add these properties at the class level
    private var lastBackPressTime = 0L
    private val BACK_PRESS_DEBOUNCE_MS = 1000L // 1 second debounce

    override fun onCreate() {
        Log.d(TAG, "RoutineManager service onCreate")
        super.onCreate()
        blockOverlayView = BlockOverlayView(this)
        
        // Restore state from shared preferences when service is created
        updateRoutines()
        updateStrictMode()
    }
    
    override fun onServiceConnected() {
        Log.d(TAG, "RoutineManager accessibility service connected")
        super.onServiceConnected()

        instance = this
        isEditableFieldFocused = false
    }
    
    /**
     * Updates routines from shared preferences and evaluates them
     * This is used both when routines are updated from the Flutter app
     * and when the service is restarted
     */
    fun updateRoutines() {
        Log.d(TAG, "Updating routines from shared preferences")
        // Use applicationContext instead of appContext
        val sharedPreferences = applicationContext.getSharedPreferences("com.solidsoft.routine.preferences", Context.MODE_PRIVATE)
        
        // Get the JSON string from shared preferences
        val routinesJsonString = sharedPreferences.getString("routines", null)
        if (routinesJsonString == null) {
            Log.d(TAG, "No routines found in shared preferences")
            return
        }
        
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
            Log.e(TAG, "Error updating routines from shared preferences: ${e.message}", e)
        }
    }
    
    /**
     * Updates strict mode settings from shared preferences
     * This is used both when strict mode settings are updated from the Flutter app
     * and when the service is restarted
     */
    fun updateStrictMode() {
        Log.d(TAG, "Updating strict mode settings from shared preferences")
        // Use applicationContext instead of appContext
        val sharedPreferences = applicationContext.getSharedPreferences("com.solidsoft.routine.preferences", Context.MODE_PRIVATE)
        
        // Get the strict mode settings from shared preferences
        blockChangingTimeSettings = sharedPreferences.getBoolean("blockChangingTimeSettings", false)
        blockUninstallingApps = sharedPreferences.getBoolean("blockUninstallingApps", false)
        blockInstallingApps = sharedPreferences.getBoolean("blockInstallingApps", false)

        Log.d(TAG, "Updated strict mode settings: blockChangingTimeSettings=$blockChangingTimeSettings, " +
                "blockUninstallingApps=$blockUninstallingApps, blockInstallingApps=$blockInstallingApps")

        evaluate()
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        val eventType = event.eventType
        val currentTime = System.currentTimeMillis()
        val packageName = event.packageName?.toString() ?: return
        val changeType = event.contentChangeTypes;

        if (changeType != AccessibilityEvent.CONTENT_CHANGE_TYPE_PANE_DISAPPEARED &&
            packageName != SYSTEM_UI_PACKAGE) {
            lastSeenApp = packageName
            lastSeenTimestamp = currentTime
        }

        // Check strict mode restrictions
        if (strictModeEnabled) {
            // Block uninstalling apps
            if (blockUninstallingApps && isAppInfoOrAccessibilitySettingsForRoutine(event)) {
                Log.d(TAG, "Blocking access to app info or accessibility settings for Routine")
                goBack()
                return
            }
            
            // Block installing apps
            if (blockInstallingApps && isAppStore(packageName)) {
                Log.d(TAG, "Blocking access to app store: $packageName")
                goBack()
                return
            }
            
            // Block changing time settings
            if (blockChangingTimeSettings && isTimeSettingsPage(event)) {
                Log.d(TAG, "Blocking access to time settings")
                goBack()
                return
            }
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
            if (!isEditableFieldFocused) {
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
        for (site in sites) {
            if (site == lowerUrl || lowerUrl.contains(site)) {
                return true
            }
        }
        return false
    }

    private fun isBlockedUrl(url: String): Boolean {
        val inList = isUrlInList(url)
        return url != redirectUrl && (allow && !inList) || (!allow && inList)
    }

    private fun isBlockedApp(packageName: String): Boolean {
        if (!Util.isBlockable(packageManager, packageName)) {
            return false
        }

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
        Log.d(TAG, "RoutineManager service interrupted")
    }
    
    /**
     * Navigates back using the global back action
     */
    private fun goBack() {
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastBackPressTime > BACK_PRESS_DEBOUNCE_MS) {
            Log.d(TAG, "Navigating back")
            performGlobalAction(GLOBAL_ACTION_BACK)
            lastBackPressTime = currentTime
        } else {
            Log.d(TAG, "Ignoring back press due to debounce (last press was ${currentTime - lastBackPressTime}ms ago)")
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

    /**
     * Represents a scheduled evaluation time
     */
    private data class EvaluationTime(
        val timestamp: Long,
        val reason: String,
        val routineId: String
    ) : Comparable<EvaluationTime> {
        override fun compareTo(other: EvaluationTime): Int {
            return timestamp.compareTo(other.timestamp)
        }
    }

    private fun scheduleEvaluations() {
        // Cancel any existing scheduled evaluations
        cancelScheduledEvaluations()

        val now = System.currentTimeMillis()

        // Create a set to store unique evaluation times
        val evaluationTimeSet = HashSet<Long>()
        val newEvaluationTimes = ArrayList<EvaluationTime>()

        val allDayRoutine = routines.find { it.allDay }

        if (allDayRoutine != null) {
            // Add all day evaluation time
            val midnight = convertMinutesToTimestamp(now, 1)
            newEvaluationTimes.add(EvaluationTime(midnight, "all_day", allDayRoutine.id))
            Log.d(TAG, "Added evaluation time for all day")
        }
        
        // For each routine, collect evaluation times
        for (routine in routines.filter { !it.allDay }) {
            // Add pausedUntil time if it's in the future
            val now = System.currentTimeMillis()
            
            routine.pausedUntil?.let { pausedUntil ->
                val pausedUntilTime = pausedUntil.time
                if (pausedUntilTime > now && !evaluationTimeSet.contains(pausedUntilTime)) {
                    evaluationTimeSet.add(pausedUntilTime)
                    newEvaluationTimes.add(
                        EvaluationTime(
                            pausedUntilTime,
                            "paused_until_expired",
                            routine.id
                        )
                    )
                    Log.d(TAG, "Added evaluation time for routine ${routine.name} when pause expires at ${pausedUntil}")
                }
            }
            
            // Add snoozedUntil time if it's in the future
            routine.snoozedUntil?.let { snoozedUntil ->
                val snoozedUntilTime = snoozedUntil.time
                if (snoozedUntilTime > now && !evaluationTimeSet.contains(snoozedUntilTime)) {
                    evaluationTimeSet.add(snoozedUntilTime)
                    newEvaluationTimes.add(
                        EvaluationTime(
                            snoozedUntilTime,
                            "snoozed_until_expired",
                            routine.id
                        )
                    )
                    Log.d(TAG, "Added evaluation time for routine ${routine.name} when snooze expires at ${snoozedUntil}")
                }
            }
            
            // Skip if routine doesn't have time constraints
            if (routine.startTime == null && routine.endTime == null) {
                continue
            }
            
            // Add start time if defined
            routine.startTime?.let { startTime ->
                val startTimeMillis = convertMinutesToTimestamp(now, startTime)
                if (!evaluationTimeSet.contains(startTimeMillis)) {
                    evaluationTimeSet.add(startTimeMillis)
                    newEvaluationTimes.add(
                        EvaluationTime(
                            startTimeMillis,
                            "daily_start_time",
                            routine.id
                        )
                    )
                    Log.d(TAG, "Added evaluation time for routine ${routine.name} at start time: ${startTime / 60}:${startTime % 60}")
                }
            }
            
            // Add end time if defined
            routine.endTime?.let { endTime ->
                val endTimeMillis = convertMinutesToTimestamp(now, endTime)
                if (!evaluationTimeSet.contains(endTimeMillis)) {
                    evaluationTimeSet.add(endTimeMillis)
                    newEvaluationTimes.add(
                        EvaluationTime(
                            endTimeMillis,
                            "daily_end_time",
                            routine.id
                        )
                    )
                    Log.d(TAG, "Added evaluation time for routine ${routine.name} at end time: ${endTime / 60}:${endTime % 60}")
                }
            }
        }

        newEvaluationTimes.sort()
        
        evaluationTimes = newEvaluationTimes
        
        // Log the sorted evaluation times
        if (evaluationTimes.isNotEmpty()) {
            Log.d(TAG, "Sorted evaluation times:")
            for (i in evaluationTimes.indices) {
                val evalTime = evaluationTimes[i]
                val routine = routines.find { it.id == evalTime.routineId }
                val routineName = routine?.name ?: evalTime.routineId
                Log.d(TAG, "$i: ${Date(evalTime.timestamp)} - ${evalTime.reason} - $routineName")
            }
        }

        // Schedule the first evaluation if there are any
        if (evaluationTimes.isNotEmpty()) {
            currentEvaluationIndex = 0
            scheduleNextEvaluation()
        }
    }

    private fun convertMinutesToTimestamp(now: Long, minutes: Int): Long {
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, minutes / 60)
        calendar.set(Calendar.MINUTE, minutes % 60)
        calendar.set(Calendar.SECOND, 0)

        if (calendar.timeInMillis < now) {
            calendar.add(Calendar.DAY_OF_MONTH, 1)
        } else {
            Log.d(TAG, "Did not add a day: " +
                    "minutes: $minutes, now: $now, timestamp: ${calendar.timeInMillis}")
        }

        return calendar.timeInMillis
    }
    
    private fun scheduleNextEvaluation() {
        // Cancel any existing evaluation
        evaluationRunnable?.let {
            handler.removeCallbacks(it)
        }
        
        if (evaluationTimes.isEmpty() || currentEvaluationIndex >= evaluationTimes.size) {
            Log.d(TAG, "No more evaluations to schedule")
            return
        }
        
        val nextEval = evaluationTimes[currentEvaluationIndex]
        val now = System.currentTimeMillis()
        val delay = Math.max(0, (nextEval.timestamp + 10000) - now) // add 10s to avoid timing issues
        
        Log.d(TAG, "Scheduling next evaluation in ${delay/1000} seconds (${Date(nextEval.timestamp)}), reason: ${nextEval.reason}")
        
        evaluationRunnable = Runnable {
            Log.d(TAG, "Running scheduled evaluation. Reason: ${nextEval.reason}, RoutineId: ${nextEval.routineId}")

            val routine = routines.find { it.id == nextEval.routineId }
            if (routine != null) {
                Log.d(TAG, "Re-evaluating after ${nextEval.reason} expired for routine: ${routine.name}")
            }
            
            evaluate()

            currentEvaluationIndex++

            if (currentEvaluationIndex >= evaluationTimes.size) {
                Log.d(TAG, "All evaluations completed for today, rescheduling for tomorrow")
                scheduleEvaluations()
            } else {
                scheduleNextEvaluation()
            }
        }
        
        handler.postDelayed(evaluationRunnable!!, delay)
    }

    private fun cancelScheduledEvaluations() {
        // Remove any pending evaluation callbacks
        evaluationRunnable?.let {
            handler.removeCallbacks(it)
            evaluationRunnable = null
        }
        
        // Clear the evaluation times list
        evaluationTimes.clear()
        currentEvaluationIndex = 0
    }

    private fun evaluate() {
        // Start timing the eval function
        val startTime = System.currentTimeMillis()
        
        Log.d(TAG, "Evaluating routines")
        
        // Filter routines: active and conditions not met
        val activeRoutines = routines.filter { it.isActive() && !it.areConditionsMet() }
        Log.d(TAG, "Filtered routine count = ${activeRoutines.size}")
        
        // Check if any routine is an allow list
        allow = activeRoutines.any { it.allow }
        
        // Sets to hold excluded items (for allow list mode)
        val excludeApps = HashSet<String>()
        val excludeSites = HashSet<String>()
        
        // If in allow list mode, collect all items from block lists to exclude
        if (allow) {
            for (routine in activeRoutines.filter { !it.allow }) {
                excludeApps.addAll(routine.getApps())
                excludeSites.addAll(routine.getSites())
            }
            
            // Only keep allow list routines
            val allowRoutines = activeRoutines.filter { it.allow }
            
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
            for (routine in activeRoutines) {
                apps.addAll(routine.getApps())
                sites.addAll(routine.getSites())
            }
        }

        // Check if any active routine has strict mode enabled
        strictModeEnabled = activeRoutines.any { it.strictMode }

        Log.d(TAG, "Strict mode enabled: $strictModeEnabled")

        checkLastSeenForBlocking()

        // Calculate elapsed time
        val elapsedTime = System.currentTimeMillis() - startTime
        
        Log.d(TAG, "Eval completed in ${elapsedTime}ms, blocked apps: ${apps.size}, " +
                "blocked domains: ${sites.size}")
    }

    private fun checkLastSeenForBlocking() {
        if (lastSeenApp.isNotEmpty() && isBlockedApp(lastSeenApp)) {
            Log.d(TAG, "Last seen app is now blocked: $lastSeenApp")
            showBlockOverlay(lastSeenApp)
        }
        
        if (getSupportedBrowsers().find { it.packageName == lastSeenApp } != null &&
            lastSeenSite.isNotEmpty() && isBlockedUrl(lastSeenSite)) {
            Log.d(TAG, "Last seen site on current browser is now blocked: $lastSeenSite")
            redirectTo(redirectUrl)
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "RoutineManager service destroyed")
        instance = null
        blockOverlayView?.hide()
        blockOverlayView = null
        
        // Cancel any scheduled evaluations
        cancelScheduledEvaluations()
    }

    /**
     * Navigates to the home screen
     */
    private fun goToHomeScreen() {
        val homeIntent = Intent(Intent.ACTION_MAIN)
        homeIntent.addCategory(Intent.CATEGORY_HOME)
        homeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(homeIntent)
    }
    
    /**
     * Checks if the current screen is the app info or accessibility settings page for Routine
     */
    private fun isAppInfoOrAccessibilitySettingsForRoutine(event: AccessibilityEvent): Boolean {
        val packageName = event.packageName?.toString() ?: return false
        val eventType = event.eventType
        
        // Check if we're in the Settings app
        if (packageName != "com.android.settings") {
            return false
        }

        // Get the root node to examine the content
        val rootNode = event.source ?: return false

        try {
            Log.d(TAG, "Checking if current screen is app info or accessibility settings for Routine")
            
            // Dump node hierarchy for debugging
            dumpNodeHierarchy(rootNode, 0)
            
            // Check for app info page by traversing the node hierarchy
            if (isAppInfoPageByNodePattern(rootNode)) {
                Log.d(TAG, "Detected Routine app info page by node pattern")
                return true
            }
            
            // Check for uninstall dialog by traversing the node hierarchy
            if (isUninstallDialogByNodePattern(rootNode)) {
                Log.d(TAG, "Detected uninstall dialog by node pattern")
                return true
            }
            
            // Check for accessibility settings page - using original working logic
            val accessibilityTexts = rootNode.findAccessibilityNodeInfosByText("Accessibility")
            val routineServiceTexts = rootNode.findAccessibilityNodeInfosByText("Routine")
            
            // Original working logic for accessibility settings detection
            if (accessibilityTexts.isNotEmpty() && routineServiceTexts.isNotEmpty()) {
                Log.d(TAG, "Detected Routine accessibility settings page")
                return true
            }
            
            return false
        } catch (e: Exception) {
            Log.e(TAG, "Error checking app info page: ${e.message}", e)
        }
        
        return false
    }
    
    /**
     * Dumps the node hierarchy to the log for debugging
     */
    private fun dumpNodeHierarchy(node: AccessibilityNodeInfo?, depth: Int) {
        if (node == null) return
        
        val indent = "  ".repeat(depth)
        val className = node.className ?: "null"
        val text = node.text ?: "null"
        val contentDesc = node.contentDescription ?: "null"
        val viewId = node.viewIdResourceName ?: "null"
        
        Log.d(TAG, "$indent Node: class=$className, text=$text, contentDesc=$contentDesc, id=$viewId")
        
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                dumpNodeHierarchy(child, depth + 1)
                child.recycle()
            }
        }
    }
    
    /**
     * Checks if the current screen is an app info page by looking for specific node patterns
     */
    private fun isAppInfoPageByNodePattern(rootNode: AccessibilityNodeInfo): Boolean {
        try {
            // Look for switches and buttons that are typically on app info pages
            var hasForceStopButton = false
            var hasUninstallButton = false
            var hasRoutineReference = false
            
            // Traverse the node hierarchy to look for specific patterns
            traverseNodes(rootNode) { node ->
                val className = node.className?.toString() ?: ""
                val text = node.text?.toString() ?: ""
                val contentDesc = node.contentDescription?.toString() ?: ""
                
                // Check for force stop button
                if ((text.contains("Force stop", ignoreCase = true) || 
                     contentDesc.contains("Force stop", ignoreCase = true)) &&
                    (className.contains("Button") || className.contains("TextView"))) {
                    hasForceStopButton = true
                    Log.d(TAG, "Found Force Stop button")
                }
                
                // Check for uninstall button
                if ((text.contains("Uninstall", ignoreCase = true) || 
                     contentDesc.contains("Uninstall", ignoreCase = true)) &&
                    (className.contains("Button") || className.contains("TextView"))) {
                    hasUninstallButton = true
                    Log.d(TAG, "Found Uninstall button")
                }
                
                // Check for Routine reference
                if (text.contains("Routine") || contentDesc.contains("Routine") || 
                    text.contains(this.packageName) || contentDesc.contains(this.packageName)) {
                    hasRoutineReference = true
                    Log.d(TAG, "Found Routine reference")
                }
                
                !hasUninstallButton || !hasForceStopButton || !hasRoutineReference
            }
            
            return hasForceStopButton && hasUninstallButton && hasRoutineReference
        } catch (e: Exception) {
            Log.e(TAG, "Error in isAppInfoPageByNodePattern: ${e.message}", e)
        }
        
        return false
    }
    
    /**
     * Checks if the current screen is an uninstall dialog by looking for specific node patterns
     */
    private fun isUninstallDialogByNodePattern(rootNode: AccessibilityNodeInfo): Boolean {
        try {
            var hasUninstallText = false
            var hasRoutineReference = false
            var hasOkButton = false
            var hasCancelButton = false
            
            // Traverse the node hierarchy to look for specific patterns
            traverseNodes(rootNode) { node ->
                val className = node.className?.toString() ?: ""
                val text = node.text?.toString() ?: ""
                val contentDesc = node.contentDescription?.toString() ?: ""
                
                // Check for uninstall text
                if (text.contains("Uninstall", ignoreCase = true) || 
                    contentDesc.contains("Uninstall", ignoreCase = true)) {
                    hasUninstallText = true
                    Log.d(TAG, "Found Uninstall text")
                }
                
                // Check for Routine reference
                if (text.contains("Routine") || contentDesc.contains("Routine") || 
                    text.contains(this.packageName) || contentDesc.contains(this.packageName)) {
                    hasRoutineReference = true
                    Log.d(TAG, "Found Routine reference in dialog")
                }
                
                // Check for OK button
                if ((text.equals("OK", ignoreCase = true) || 
                     text.equals("Yes", ignoreCase = true) ||
                     contentDesc.equals("OK", ignoreCase = true) ||
                     contentDesc.equals("Yes", ignoreCase = true)) &&
                    className.contains("Button")) {
                    hasOkButton = true
                    Log.d(TAG, "Found OK/Yes button")
                }
                
                // Check for Cancel button
                if ((text.equals("Cancel", ignoreCase = true) || 
                     text.equals("No", ignoreCase = true) ||
                     contentDesc.equals("Cancel", ignoreCase = true) ||
                     contentDesc.equals("No", ignoreCase = true)) &&
                    className.contains("Button")) {
                    hasCancelButton = true
                    Log.d(TAG, "Found Cancel/No button")
                }
                
                // Continue traversal
                true
            }
            
            // If we found uninstall text, Routine reference, and at least one button, it's likely an uninstall dialog
            return hasUninstallText && hasRoutineReference && (hasOkButton || hasCancelButton)
        } catch (e: Exception) {
            Log.e(TAG, "Error in isUninstallDialogByNodePattern: ${e.message}", e)
        }
        
        return false
    }
    
    /**
     * Traverses the node hierarchy and calls the provided function for each node
     * Returns early if the function returns false
     */
    private fun traverseNodes(node: AccessibilityNodeInfo?, action: (AccessibilityNodeInfo) -> Boolean): Boolean {
        if (node == null) return true
        
        // Process this node
        if (!action(node)) {
            return false
        }
        
        // Process children
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val shouldContinue = traverseNodes(child, action)
            child.recycle()
            if (!shouldContinue) {
                return false
            }
        }
        
        return true
    }

    /**
     * Checks if the current app is an app store (Play Store or F-Droid)
     */
    private fun isAppStore(packageName: String): Boolean {
        return packageName == "com.android.vending" || // Google Play Store
               packageName == "org.fdroid.fdroid"      // F-Droid
    }
    
    /**
     * Checks if the current screen is the date/time settings page
     */
    private fun isTimeSettingsPage(event: AccessibilityEvent): Boolean {
        val packageName = event.packageName?.toString() ?: return false
        
        // Check if we're in the Settings app
        if (packageName != "com.android.settings") {
            return false
        }
        
        // Get the root node to examine the content
        val rootNode = event.source ?: return false
        
        try {
            // Look for indicators of the date & time settings page
            val dateTimeTexts = rootNode.findAccessibilityNodeInfosByText("Date & time")
            val timeTexts = rootNode.findAccessibilityNodeInfosByText("Set time")
            val dateTexts = rootNode.findAccessibilityNodeInfosByText("Set date")
            val timezoneTexts = rootNode.findAccessibilityNodeInfosByText("Select time zone")
            val automaticTexts = rootNode.findAccessibilityNodeInfosByText("Automatic date & time")
            
            return dateTimeTexts.isNotEmpty() || 
                   timeTexts.isNotEmpty() || 
                   dateTexts.isNotEmpty() || 
                   timezoneTexts.isNotEmpty() || 
                   automaticTexts.isNotEmpty()
        } catch (e: Exception) {
            Log.e(TAG, "Error checking time settings page: ${e.message}", e)
        }
        
        return false
    }

    companion object {
        // Static reference to the active service instance
        private var instance: RoutineManager? = null
        
        fun updateRoutines() {
            instance?.updateRoutines()
        }

        fun updateStrictMode() {
            instance?.updateStrictMode()
        }
    }
}
