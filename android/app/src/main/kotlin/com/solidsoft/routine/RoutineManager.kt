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

/**
 * Accessibility service that monitors web browsing activity and blocks access to specific websites.
 */
class RoutineManager : AccessibilityService() {
    private val TAG = "RoutineManager"

    private var blockOverlayView: BlockOverlayView? = null

    private var routines = ArrayList<Routine>();

    private var sites = HashSet<String>()
    private var apps = HashSet<String>()
    private var allow = false

    // Default redirect URL
    private val redirectUrl = "https://www.google.com"

    // Track current browser app and URL to avoid redundant processing
    private var currentBrowserUrl = ""

    // Flag to track if an editable text field is focused
    private var isEditableFieldFocused = false
    
    // Track the last processed URL timestamp to avoid rapid redirects
    private var lastProcessedTime = 0L
    private val MIN_PROCESS_INTERVAL = 1000L

    override fun onCreate() {
        super.onCreate()
        blockOverlayView = BlockOverlayView(this)
    }
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Website blocker accessibility service connected")
        
        // TODO: remove after testing
        sites.add("reddit.com")
        sites.add("m.reddit.com")
        apps.add("com.google.android.youtube")

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

        // block apps
        if (isBlockedApp(packageName) &&
            changeType == AccessibilityEvent.CONTENT_CHANGE_TYPE_UNDEFINED) {
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
        
        Log.d(TAG, "Processing URL: $capturedUrl in $packageName")
        
        // Check if URL is blocked
        if (isBlockedUrl(capturedUrl)) {
            Log.d(TAG, "Blocked URL detected: $capturedUrl, redirecting...")
            redirectToBrowser(redirectUrl)
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
        for (domain in sites) {
            if (lowerUrl.contains(domain)) {
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

    private fun redirectToBrowser(url: String) {
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
            val routinesJsonArray: JSONArray = JSONArray(routinesJsonString)
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

            evaluate()
            
            Log.d(TAG, "Updated ${routines.size} routines from shared preferences")
        } catch (e: Exception) {
            Log.e(TAG, "Error updating routines from shared preferences: ${e.message}")
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

        // Calculate elapsed time
        val elapsedTime = System.currentTimeMillis() - startTime
        
        Log.d(TAG, "Eval completed in ${elapsedTime}ms, blocked apps: ${apps.size}, blocked domains: ${sites.size}")
    }
    
    companion object {
        // Static reference to the active service instance
        private var instance: RoutineManager? = null
        
        fun updateRoutines() {
            instance?.updateRoutines()
        }
    }
}
