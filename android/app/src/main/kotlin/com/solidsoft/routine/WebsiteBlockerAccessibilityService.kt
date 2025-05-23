package com.solidsoft.routine

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.inputmethod.InputMethodManager
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
    
    // Flag to track if user is currently typing
    private var isUserTyping = false
    
    // Last detected URL to avoid repeated checks
    private var lastCheckedUrl: String? = null
    
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
            // We're only interested in specific event types
            if (event.eventType == AccessibilityEvent.TYPE_VIEW_FOCUSED ||
                event.eventType == AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED ||
                event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED ||
                event.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
                
                // Check if user is typing in a text field
                checkIfUserIsTyping(event)
            } else {
                return
            }
            
            val nodeInfo = event.source ?: return
            
            // Check if we're in a browser
            val packageName = event.packageName?.toString() ?: ""
            if (isBrowser(packageName)) {
                // Check for blocked URLs
                checkForBlockedUrls(nodeInfo, packageName)
            }
            
            nodeInfo.recycle()
        } catch (e: Exception) {
            Log.e(TAG, "Error processing accessibility event: ${e.message}", e)
        }
    }
    
    private fun checkForBlockedUrls(nodeInfo: AccessibilityNodeInfo, packageName: String) {
        // Extract URL from address bar based on browser type
        Log.d(TAG, "Checking for blocked URLs in $packageName")

        val url = when {
            packageName.contains("chrome") -> extractChromeUrl(nodeInfo)
            packageName.contains("firefox") -> extractFirefoxUrl(nodeInfo)
            packageName.contains("samsung") -> extractSamsungBrowserUrl(nodeInfo)
            else -> extractGenericBrowserUrl(nodeInfo)
        }
        
        // If we found a URL, check if it's blocked
        if (url != null && url.isNotEmpty()) {
            // Skip if it's the same URL we just checked
            if (url == lastCheckedUrl) {
                return
            }
            
            lastCheckedUrl = url
            Log.d(TAG, "Detected URL: $url in $packageName, user typing: $isUserTyping")
            
            // Only check and redirect if the user is NOT typing
            if (!isUserTyping && isBlockedUrl(url)) {
                Log.d(TAG, "Blocked URL detected: $url, redirecting...")
                redirectToBrowser(redirectUrl)
            }
        } else {
            Log.d(TAG, "No URL found in $packageName")
        }
    }
    
    private fun extractChromeUrl(nodeInfo: AccessibilityNodeInfo): String? {
        Log.d(TAG, "Extracting Chrome URL")
        
        // Method 1: Try to find by specific resource IDs
        val chromeUrlIds = listOf(
            "url_bar", 
            "search_box", 
            "location_bar_edit_text", 
            "address_bar_edit",
            "omnibox_text_field",
            "url_field",
            "address_bar"
        )
        
        for (id in chromeUrlIds) {
            val urlNode = findNodeByResourceId(nodeInfo, id)
            if (urlNode != null && !urlNode.text.isNullOrEmpty()) {
                Log.d(TAG, "Found Chrome URL by resource ID: $id")
                return urlNode.text.toString()
            }
        }
        
        // Method 2: Try to find by content description containing URL
        try {
            val allNodes = nodeInfo.findAccessibilityNodeInfosByText("http")
            for (node in allNodes) {
                val desc = node.contentDescription?.toString()
                if (desc != null && (desc.startsWith("http://") || desc.startsWith("https://"))) {
                    Log.d(TAG, "Found Chrome URL in content description")
                    return desc
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error finding URL in content descriptions: ${e.message}")
        }
        
        // Method 3: Try to find EditText nodes that contain URL-like text
        try {
            val allEditTexts = findAllEditTexts(nodeInfo)
            for (editText in allEditTexts) {
                val text = editText.text?.toString()
                if (text != null && (text.contains("http://") || text.contains("https://") || 
                                    text.contains("www.") || text.contains(".com"))) {
                    Log.d(TAG, "Found Chrome URL in EditText: $text")
                    return text
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error finding URL in EditTexts: ${e.message}")
        }
        
        // Method 4: Try to find by traversing all nodes and looking for URL patterns
        try {
            val urlText = findUrlInNodeTree(nodeInfo)
            if (urlText != null) {
                Log.d(TAG, "Found Chrome URL by traversing node tree: $urlText")
                return urlText
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error finding URL in node tree: ${e.message}")
        }
        
        Log.d(TAG, "No Chrome URL found")
        return null
    }
    
    /**
     * Finds all EditText nodes in the hierarchy
     */
    private fun findAllEditTexts(rootNode: AccessibilityNodeInfo): List<AccessibilityNodeInfo> {
        val results = mutableListOf<AccessibilityNodeInfo>()
        findAllEditTextsRecursive(rootNode, results)
        return results
    }
    
    private fun findAllEditTextsRecursive(node: AccessibilityNodeInfo, results: MutableList<AccessibilityNodeInfo>) {
        // Check if this node is an EditText
        if (node.className?.contains("EditText") == true || node.isEditable) {
            results.add(node)
        }
        
        // Check children
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            findAllEditTextsRecursive(child, results)
        }
    }
    
    /**
     * Recursively searches the node tree for text that looks like a URL
     */
    private fun findUrlInNodeTree(rootNode: AccessibilityNodeInfo): String? {
        // Check if this node's text is a URL
        val text = rootNode.text?.toString()
        if (text != null && isLikelyUrl(text)) {
            return text
        }
        
        // Check content description
        val desc = rootNode.contentDescription?.toString()
        if (desc != null && isLikelyUrl(desc)) {
            return desc
        }
        
        // Check children recursively
        for (i in 0 until rootNode.childCount) {
            val child = rootNode.getChild(i) ?: continue
            val result = findUrlInNodeTree(child)
            if (result != null) {
                return result
            }
            child.recycle()
        }
        
        return null
    }
    
    /**
     * Checks if a string is likely to be a URL
     */
    private fun isLikelyUrl(text: String): Boolean {
        val lowerText = text.lowercase()
        return lowerText.startsWith("http://") || 
               lowerText.startsWith("https://") || 
               lowerText.startsWith("www.") || 
               (lowerText.contains(".") && 
                (lowerText.contains(".com") || 
                 lowerText.contains(".org") || 
                 lowerText.contains(".net") || 
                 lowerText.contains(".io") || 
                 lowerText.contains(".app")))
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
        try {
            // Try to find nodes by viewIdResourceName directly
            val nodes = nodeInfo.findAccessibilityNodeInfosByViewId("*:id/$resourceIdPart")
            if (nodes.isNotEmpty()) {
                return nodes[0]
            }
            
            // If that fails, try to find by traversing the view hierarchy
            return findNodeByResourceIdRecursive(nodeInfo, resourceIdPart)
        } catch (e: Exception) {
            Log.e(TAG, "Error finding node by resource ID: ${e.message}", e)
            return null
        }
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
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Website blocker accessibility service destroyed")
    }
    
    /**
     * Checks if the user is currently typing in a text field
     */
    private fun checkIfUserIsTyping(event: AccessibilityEvent) {
        try {
            val nodeInfo = event.source ?: return
            
            // Check if the focused node is an editable text field
            val isTyping = when (event.eventType) {
                AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED -> {
                    // Text is actively being changed
                    true
                }
                AccessibilityEvent.TYPE_VIEW_FOCUSED -> {
                    // Check if the focused element is editable
                    nodeInfo.isEditable || 
                    (nodeInfo.className?.contains("EditText") == true) ||
                    isAddressBarNode(nodeInfo)
                }
                else -> {
                    // For other events, check the focused node
                    val focused = findFocusedEditableNode(nodeInfo)
                    focused != null
                }
            }
            
            if (isTyping != isUserTyping) {
                isUserTyping = isTyping
                Log.d(TAG, "User typing state changed: $isUserTyping")

                // Reset the last checked URL when typing state changes
                if (isUserTyping) {
                    lastCheckedUrl = null
                }
            }
            
            nodeInfo.recycle()
        } catch (e: Exception) {
            Log.e(TAG, "Error checking if user is typing: ${e.message}", e)
        }
    }
    
    /**
     * Checks if the node is likely an address bar
     */
    private fun isAddressBarNode(nodeInfo: AccessibilityNodeInfo): Boolean {
        val resourceId = nodeInfo.viewIdResourceName ?: return false
        val commonAddressBarIds = listOf("url_bar", "search_box", "url_edit_text", 
                                        "location_bar", "address_bar")
        
        return commonAddressBarIds.any { resourceId.contains(it) }
    }
    
    /**
     * Finds a focused editable node in the view hierarchy
     */
    private fun findFocusedEditableNode(rootNode: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        // Check if this node is focused and editable
        if (rootNode.isFocused && (rootNode.isEditable || 
            rootNode.className?.contains("EditText") == true ||
            isAddressBarNode(rootNode))) {
            return rootNode
        }
        
        // Check children recursively
        for (i in 0 until rootNode.childCount) {
            val child = rootNode.getChild(i) ?: continue
            val result = findFocusedEditableNode(child)
            if (result != null) {
                return result
            }
            child.recycle()
        }
        
        return null
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
