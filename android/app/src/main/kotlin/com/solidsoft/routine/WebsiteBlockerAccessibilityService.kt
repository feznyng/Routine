package com.solidsoft.routine

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.net.Uri
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.os.Handler
import android.os.Looper
import java.util.ArrayList
import java.util.concurrent.CopyOnWriteArrayList

/**
 * Accessibility service that monitors web browsing activity and blocks access to specific websites.
 */
class WebsiteBlockerAccessibilityService : AccessibilityService() {
    private val TAG = "WebsiteBlocker"
    
    // List of blocked domains
    private var blockedDomains = CopyOnWriteArrayList<String>()
    
    // Default redirect URL
    private val redirectUrl = "https://www.google.com"
    
    // Track current browser app and URL to avoid redundant processing
    private var currentBrowserApp = ""
    private var currentBrowserUrl = ""
    
    // Flag to track if user is currently typing
    private var isUserTyping = false
    
    // Track the last time user was typing
    private var lastTypingTime = 0L
    
    // Handler for delayed URL checking
    private val handler = Handler(Looper.getMainLooper())
    private var pendingUrlCheck: Runnable? = null
    
    // Delay in milliseconds before checking a URL after typing stops
    private val URL_CHECK_DELAY = 2500L
    
    // Minimum time to consider between typing and URL check
    private val MIN_TYPING_COOLDOWN = 5000L
    
    // Track if we're in an address bar
    private var isInAddressBar = false
    
    // Track the last processed URL timestamp to avoid rapid redirects
    private var lastProcessedTime = 0L
    private val MIN_PROCESS_INTERVAL = 1000L
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Website blocker accessibility service connected")
        
        // Add default blocked domains for testing
        if (!blockedDomains.contains("reddit.com")) {
            blockedDomains.add("reddit.com")
        }
        if (!blockedDomains.contains("m.reddit.com")) {
            blockedDomains.add("m.reddit.com")
        }
        
        // Set the instance for companion object access
        instance = this
        
        // Initialize typing state
        isUserTyping = false
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        val eventType = event.eventType
        val currentTime = System.currentTimeMillis()
        val packageName = event.packageName?.toString() ?: return
        
        // Check if this is a supported browser first
        val browserConfig = getSupportedBrowsers().find { it.packageName == packageName }
        
        // Only proceed with browser-related processing if this is a supported browser
        if (browserConfig != null) {
            // Handle typing detection
            if (eventType == AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED) {
                // Update typing state and timestamp
                isUserTyping = true
                lastTypingTime = currentTime
                cancelPendingUrlCheck()
                
                // Check if we're in an address bar
                val source = event.source
                if (source != null) {
                    val nodeId = source.viewIdResourceName
                    isInAddressBar = nodeId != null && browserConfig.addressBarId.contains(nodeId)
                    source.recycle()
                }
                
                Log.d(TAG, "User typing detected in address bar: $isInAddressBar")
                return
            }
            
            // Check if enough time has passed since last typing
            if (isUserTyping && (currentTime - lastTypingTime) > MIN_TYPING_COOLDOWN) {
                Log.d(TAG, "Typing cooldown period expired after ${currentTime - lastTypingTime}ms")
                isUserTyping = false
            }
            
            // Only process relevant event types
            when (eventType) {
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
                AccessibilityEvent.TYPE_WINDOWS_CHANGED,
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                    val parentNodeInfo = event.source ?: return
                    
                    // Capture URL from the browser
                    val capturedUrl = captureUrl(parentNodeInfo, browserConfig)
                    parentNodeInfo.recycle()
                    
                    if (capturedUrl == null || !android.util.Patterns.WEB_URL.matcher(capturedUrl).matches()) {
                        return
                    }
                    
                    // Check if we should process this URL
                    if (shouldProcessUrl(capturedUrl, currentTime)) {
                        // If user was typing recently or we're in an address bar, schedule a delayed check
                        if (isUserTyping || isInAddressBar || (currentTime - lastTypingTime < MIN_TYPING_COOLDOWN * 2)) {
                            Log.d(TAG, "Scheduling delayed URL check for: $capturedUrl")
                            scheduleUrlCheck(packageName, capturedUrl)
                        } else {
                            // Process the URL immediately if user is not typing
                            processUrl(packageName, capturedUrl)
                        }
                    }
                }
            }
        }
    }
    
    /**
     * Determines if a URL should be processed based on various heuristics
     */
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
    
    /**
     * Process a captured URL from a browser
     */
    private fun processUrl(packageName: String, capturedUrl: String) {
        val currentTime = System.currentTimeMillis()
        
        // Reset typing flag since we're now processing a URL
        isUserTyping = false
        isInAddressBar = false
        lastProcessedTime = currentTime
        
        // Skip processing if URL doesn't look valid
        if (!android.util.Patterns.WEB_URL.matcher(capturedUrl).matches()) {
            return
        }

        if (isBlockedUrl(capturedUrl)) {
            Log.d(TAG, "Blocked URL detected: $capturedUrl, redirecting...")
            redirectToBrowser(redirectUrl)
        }
    }
    
    /**
     * Defines a supported browser configuration with package name and address bar ID
     */
    private data class SupportedBrowserConfig(
        val packageName: String, 
        val addressBarId: String
    )
    
    /**
     * Returns a list of supported browsers with their address bar IDs
     */
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
    
    /**
     * Captures the URL from a browser's address bar
     */
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
                isInAddressBar = true
                lastTypingTime = System.currentTimeMillis() // Reset typing timer when address bar is focused
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
    
    /**
     * Checks if a URL contains any of the blocked domains
     */
    private fun isBlockedUrl(url: String): Boolean {
        val lowerUrl = url.lowercase()
        for (domain in blockedDomains) {
            if (lowerUrl.contains(domain)) {
                return true
            }
        }
        return false
    }
    
    /**
     * Redirects to a different URL by opening a new browser intent
     */
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
        cancelPendingUrlCheck()
        instance = null
    }
    
    /**
     * Schedules a delayed URL check after typing has stopped
     */
    private fun scheduleUrlCheck(packageName: String, capturedUrl: String) {
        // Cancel any existing scheduled checks
        cancelPendingUrlCheck()
        
        // Create a new runnable for delayed processing
        pendingUrlCheck = Runnable {
            // Double-check that enough time has passed since typing
            val currentTime = System.currentTimeMillis()
            if (currentTime - lastTypingTime >= MIN_TYPING_COOLDOWN) {
                Log.d(TAG, "Processing URL after typing delay: $capturedUrl")
                processUrl(packageName, capturedUrl)
            } else {
                Log.d(TAG, "Skipping URL check, user typed too recently")
            }
        }
        
        // Schedule the check after the delay
        handler.postDelayed(pendingUrlCheck!!, URL_CHECK_DELAY)
    }
    
    /**
     * Cancels any pending URL checks
     */
    private fun cancelPendingUrlCheck() {
        pendingUrlCheck?.let {
            handler.removeCallbacks(it)
            pendingUrlCheck = null
        }
    }
    
    /**
     * Updates the list of blocked domains
     */
    fun updateBlockedDomains(domains: List<String>) {
        blockedDomains.clear()
        blockedDomains.addAll(domains)
        Log.d(TAG, "Updated blocked domains: $blockedDomains")
    }
    
    companion object {
        // Static reference to the active service instance
        private var instance: WebsiteBlockerAccessibilityService? = null
        
        fun getInstance(): WebsiteBlockerAccessibilityService? {
            return instance
        }
        
        fun updateBlockedDomains(domains: List<String>) {
            instance?.updateBlockedDomains(domains)
        }
    }
}
