package com.solidsoft.routine

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.net.Uri
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
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
    
    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Website blocker accessibility service connected")
        
        // Add YouTube as a blocked domain by default for testing
        if (!blockedDomains.contains("reddit.com")) {
            blockedDomains.add("reddit.com")
        }
        if (!blockedDomains.contains("m.reddit.com")) {
            blockedDomains.add("m.reddit.com")
        }
    }
    
    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        try {
            // We're only interested in window state changes and content changes
            if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED && 
                event.eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
                return
            }
            
            val nodeInfo = event.source ?: return
            
            // Check if we're in a browser
            val packageName = event.packageName?.toString() ?: ""
            if (isBrowser(packageName)) {
                checkForBlockedUrls(nodeInfo, packageName)
            }
            
            nodeInfo.recycle()
        } catch (e: Exception) {
            Log.e(TAG, "Error processing accessibility event: ${e.message}", e)
        }
    }
    
    private fun checkForBlockedUrls(nodeInfo: AccessibilityNodeInfo, packageName: String) {
        // Extract URL from address bar based on browser type
        val url = when {
            packageName.contains("chrome") -> extractChromeUrl(nodeInfo)
            packageName.contains("firefox") -> extractFirefoxUrl(nodeInfo)
            packageName.contains("samsung") -> extractSamsungBrowserUrl(nodeInfo)
            else -> extractGenericBrowserUrl(nodeInfo)
        }
        
        // If we found a URL, check if it's blocked
        if (url != null && url.isNotEmpty()) {
            Log.d(TAG, "Detected URL: $url in $packageName")
            
            // Check if the URL contains any blocked domain
            if (isBlockedUrl(url)) {
                Log.d(TAG, "Blocked URL detected: $url, redirecting...")
                redirectToBrowser(redirectUrl)
            }
        }
    }
    
    private fun extractChromeUrl(nodeInfo: AccessibilityNodeInfo): String? {
        // Chrome's address bar has a resource ID that contains "url_bar" or "search_box"
        val urlNode = findNodeByResourceId(nodeInfo, "url_bar") 
            ?: findNodeByResourceId(nodeInfo, "search_box")
        return urlNode?.text?.toString()
    }
    
    private fun extractFirefoxUrl(nodeInfo: AccessibilityNodeInfo): String? {
        // Firefox's address bar has a resource ID that contains "url_bar" or "url_edit_text"
        val urlNode = findNodeByResourceId(nodeInfo, "url_bar") 
            ?: findNodeByResourceId(nodeInfo, "url_edit_text")
        return urlNode?.text?.toString()
    }
    
    private fun extractSamsungBrowserUrl(nodeInfo: AccessibilityNodeInfo): String? {
        // Samsung browser's address bar has a resource ID that contains "location_bar" or "url_bar"
        val urlNode = findNodeByResourceId(nodeInfo, "location_bar") 
            ?: findNodeByResourceId(nodeInfo, "url_bar")
        return urlNode?.text?.toString()
    }
    
    private fun extractGenericBrowserUrl(nodeInfo: AccessibilityNodeInfo): String? {
        // Try common resource IDs for URL bars
        val commonIds = listOf("url_bar", "search_box", "url_edit_text", "location_bar", "address_bar")
        for (id in commonIds) {
            val urlNode = findNodeByResourceId(nodeInfo, id)
            if (urlNode != null && urlNode.text != null) {
                return urlNode.text.toString()
            }
        }
        return null
    }
    
    private fun findNodeByResourceId(nodeInfo: AccessibilityNodeInfo, resourceIdPart: String): AccessibilityNodeInfo? {
        // Find nodes that match the resource ID pattern
        val nodes = nodeInfo.findAccessibilityNodeInfosByText(resourceIdPart)
        if (nodes.isEmpty()) {
            // Try to find by traversing the view hierarchy
            return findNodeByResourceIdRecursive(nodeInfo, resourceIdPart)
        }
        return nodes[0]
    }
    
    private fun findNodeByResourceIdRecursive(nodeInfo: AccessibilityNodeInfo, resourceIdPart: String): AccessibilityNodeInfo? {
        // Check if current node's resource ID contains the target string
        val resourceId = nodeInfo.viewIdResourceName
        if (resourceId != null && resourceId.contains(resourceIdPart)) {
            return nodeInfo
        }
        
        // Check children
        for (i in 0 until nodeInfo.childCount) {
            val child = nodeInfo.getChild(i) ?: continue
            val result = findNodeByResourceIdRecursive(child, resourceIdPart)
            if (result != null) {
                return result
            }
            child.recycle()
        }
        
        return null
    }
    
    private fun isBlockedUrl(url: String): Boolean {
        val lowerUrl = url.lowercase()
        for (domain in blockedDomains) {
            if (lowerUrl.contains(domain)) {
                return true
            }
        }
        return false
    }
    
    private fun isBrowser(packageName: String): Boolean {
        return packageName.contains("chrome") ||
               packageName.contains("firefox") ||
               packageName.contains("browser") ||
               packageName.contains("opera") ||
               packageName.contains("brave") ||
               packageName.contains("duckduckgo") ||
               packageName.contains("samsung.internet")
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
