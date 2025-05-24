package com.solidsoft.routine

/**
 * Constants used throughout the application
 */
object Constants {
    // Package names for essential apps that shouldn't be blocked
    val ESSENTIAL_PACKAGES = setOf(
        "com.solidsoft.routine",
    )

    val ALLOWED_SYSTEM_PACKAGES = setOf(
        "com.google.android.apps.youtube.music",
        "com.google.android.youtube",
    )
    
    // Essential app categories that should never be blocked
    val ESSENTIAL_CATEGORIES = setOf(
        android.content.pm.ApplicationInfo.CATEGORY_ACCESSIBILITY,  // Accessibility services
        android.content.pm.ApplicationInfo.CATEGORY_PRODUCTIVITY    // Productivity apps like calendar, email
    )
    
    // Essential app types based on their intent actions
    val ESSENTIAL_INTENT_ACTIONS = setOf(
        android.content.Intent.ACTION_DIAL,           // Phone dialer
        android.content.Intent.ACTION_CALL,           // Phone call
        android.content.Intent.ACTION_SEND,           // Sharing
        android.content.Intent.ACTION_SENDTO,         // Email/messaging
        android.content.Intent.ACTION_ANSWER          // Answer calls
    )
}
