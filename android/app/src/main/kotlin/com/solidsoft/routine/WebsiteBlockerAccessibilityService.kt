package com.solidsoft.routine

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.net.Uri
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
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
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        val eventType = event.eventType
        
        // Only process relevant event types
        when (eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            AccessibilityEvent.TYPE_WINDOWS_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                val parentNodeInfo = event.source ?: return
                
                val packageName = event.packageName?.toString() ?: return
                
                // Check if this is a supported browser
                val browserConfig = getSupportedBrowsers().find { it.packageName == packageName }
                    ?: return
                
                // Capture URL from the browser
                val capturedUrl = captureUrl(parentNodeInfo, browserConfig)
                parentNodeInfo.recycle()
                
                if (capturedUrl == null) {
                    return
                }
                
                // Process the captured URL
                processUrl(packageName, capturedUrl)
            }
        }
    }
    
    /**
     * Process a captured URL from a browser
     */
    private fun processUrl(packageName: String, capturedUrl: String) {
        // Check if this is a new browser app
        if (packageName != currentBrowserApp) {
            if (android.util.Patterns.WEB_URL.matcher(capturedUrl).matches()) {
                Log.d(TAG, "New browser detected: $packageName with URL: $capturedUrl")
                currentBrowserApp = packageName
                currentBrowserUrl = capturedUrl
                
                // Check if URL is blocked
                if (isBlockedUrl(capturedUrl)) {
                    Log.d(TAG, "Blocked URL detected: $capturedUrl, redirecting...")
                    redirectToBrowser(redirectUrl)
                }
            }
        } else {
            // Same browser, check if URL changed
            if (capturedUrl != currentBrowserUrl) {
                if (android.util.Patterns.WEB_URL.matcher(capturedUrl).matches()) {
                    currentBrowserUrl = capturedUrl
                    Log.d(TAG, "URL changed in $packageName to: $capturedUrl")
                    
                    // Check if URL is blocked
                    if (isBlockedUrl(capturedUrl)) {
                        Log.d(TAG, "Blocked URL detected: $capturedUrl, redirecting...")
                        redirectToBrowser(redirectUrl)
                    }
                }
            }
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
        val nodes = info.findAccessibilityNodeInfosByViewId(config.addressBarId)
        if (nodes.isEmpty()) {
            return null
        }
        
        val addressBarNodeInfo = nodes[0]
        val url = addressBarNodeInfo.text?.toString()
        addressBarNodeInfo.recycle()
        
        return url
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
        instance = null
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
