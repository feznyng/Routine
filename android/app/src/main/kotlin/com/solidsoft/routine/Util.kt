package com.solidsoft.routine

import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager

object Util {
    private val BLOCKABLE_CATEGORIES = setOf(
        ApplicationInfo.CATEGORY_PRODUCTIVITY,
        ApplicationInfo.CATEGORY_AUDIO,
        ApplicationInfo.CATEGORY_IMAGE,
        ApplicationInfo.CATEGORY_VIDEO,
        ApplicationInfo.CATEGORY_NEWS,
        ApplicationInfo.CATEGORY_SOCIAL,
        ApplicationInfo.CATEGORY_GAME
    )

    private val PACKAGE_INSTALLER_PACKAGES = setOf(
        "com.google.android.packageinstaller",
        "com.android.packageinstaller"
    )

    fun isBlockable(appInfo: ApplicationInfo): Boolean {
        if (appInfo.packageName == "com.solidsoft.routine") {
            return false
        }

        return appInfo.category in BLOCKABLE_CATEGORIES
    }

    fun isPackageInstaller(packageName: String): Boolean {
        return packageName in PACKAGE_INSTALLER_PACKAGES
    }

    fun isBlockable(packageManager: PackageManager, packageName: String): Boolean {
        try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            return isBlockable(appInfo)
        } catch (_: Exception) {
            return false
        }
    }
}
