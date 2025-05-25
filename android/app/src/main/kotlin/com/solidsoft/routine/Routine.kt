package com.solidsoft.routine

import android.util.Log
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class Routine(
    val id: String,
    val name: String,
    val days: List<Boolean>,
    val startTime: Int?,
    val endTime: Int?,
    val allDay: Boolean,
    val pausedUntil: Date?,
    val snoozedUntil: Date?,
    val conditionsLastMet: Date?,
    val allow: Boolean,
    val strictMode: Boolean = false,
    private val apps: MutableList<String> = mutableListOf(),
    private val sites: MutableList<String> = mutableListOf()
) {
    companion object {
        private const val TAG = "Routine"
        
        // JSON keys matching Swift implementation
        const val KEY_ID = "id"
        const val KEY_NAME = "name"
        const val KEY_DAYS = "days"
        const val KEY_START_TIME = "startTime"
        const val KEY_END_TIME = "endTime"
        const val KEY_ALL_DAY = "allDay"
        const val KEY_PAUSED_UNTIL = "pausedUntil"
        const val KEY_SNOOZED_UNTIL = "snoozedUntil"
        const val KEY_CONDITIONS_LAST_MET = "conditionsLastMet"
        const val KEY_STRICT_MODE = "strictMode"
        const val KEY_ALLOW = "allow"
        const val KEY_APPS = "apps"
        const val KEY_SITES = "sites"
        const val KEY_CATEGORIES = "categories"
        
        // Date formatter matching Swift's ISO8601DateFormatter with fractional seconds
        val iso8601Formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }
        
        fun fromJson(jsonString: String): Routine? {
            return try {
                val json = JSONObject(jsonString)
                Routine(json)
            } catch (e: Exception) {
                Log.e(TAG, "Error parsing routine JSON: ${e.message}")
                null
            }
        }
    }
    
    /**
     * Secondary constructor that creates a Routine from a JSONObject
     */
    constructor(json: JSONObject) : this(
        id = json.getString(KEY_ID),
        name = json.getString(KEY_NAME),
        days = List(json.getJSONArray(KEY_DAYS).length()) { i -> json.getJSONArray(KEY_DAYS).getBoolean(i) },
        startTime = if (json.has(KEY_START_TIME) && !json.isNull(KEY_START_TIME)) json.getInt(KEY_START_TIME) else null,
        endTime = if (json.has(KEY_END_TIME) && !json.isNull(KEY_END_TIME)) json.getInt(KEY_END_TIME) else null,
        allDay = json.getBoolean(KEY_ALL_DAY),
        pausedUntil = if (json.has(KEY_PAUSED_UNTIL) && !json.isNull(KEY_PAUSED_UNTIL)) 
            iso8601Formatter.parse(json.getString(KEY_PAUSED_UNTIL)) else null,
        snoozedUntil = if (json.has(KEY_SNOOZED_UNTIL) && !json.isNull(KEY_SNOOZED_UNTIL)) 
            iso8601Formatter.parse(json.getString(KEY_SNOOZED_UNTIL)) else null,
        conditionsLastMet = if (json.has(KEY_CONDITIONS_LAST_MET) && !json.isNull(KEY_CONDITIONS_LAST_MET)) 
            iso8601Formatter.parse(json.getString(KEY_CONDITIONS_LAST_MET)) else null,
        allow = json.getBoolean(KEY_ALLOW),
        strictMode = if (json.has(KEY_STRICT_MODE) && !json.isNull(KEY_STRICT_MODE)) json.getBoolean(KEY_STRICT_MODE) else false
    ) {
        // Parse apps array
        if (json.has(KEY_APPS) && !json.isNull(KEY_APPS)) {
            val appsArray = json.getJSONArray(KEY_APPS)
            for (i in 0 until appsArray.length()) {
                apps.add(appsArray.getString(i))
            }
        }

        if (json.has(KEY_SITES) && !json.isNull(KEY_SITES)) {
            val sitesArray = json.getJSONArray(KEY_SITES)
            for (i in 0 until sitesArray.length()) {
                sites.add(sitesArray.getString(i))
            }
        }
    }

    fun isActive(): Boolean {
        // Add 45 seconds buffer to match Swift implementation
        val now = Date(System.currentTimeMillis() + 45000)
        val calendar = Calendar.getInstance()
        calendar.time = now
        
        // Get day of week (0-6, where 0 is Monday to match Swift implementation)
        var dayOfWeek = (calendar.get(Calendar.DAY_OF_WEEK) + 5) % 7 // Convert from Calendar.DAY_OF_WEEK (1-7, Sunday is 1) to 0-6 where 0 is Monday
        
        // Check if routine is snoozed
        if (snoozedUntil != null && now.before(snoozedUntil)) {
            return false
        }
        
        // Check if routine is paused
        if (pausedUntil != null && now.before(pausedUntil)) {
            val dateFormatter = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US)
            val dateString = dateFormatter.format(pausedUntil)
            val nowString = dateFormatter.format(now)
            Log.d(TAG, "Routine is paused - $nowString < $dateString")
            return false
        }
        
        // If allDay or no time restrictions, just check the day
        if (allDay || (startTime == null && endTime == null)) {
            return dayOfWeek < days.size && days[dayOfWeek]
        }
        
        // Get current time in minutes since midnight
        val currMins = calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE)
        
        // Unwrap optional startTime and endTime with defaults
        if (startTime == null || endTime == null) {
            return true
        }
        
        val start = startTime ?: -1
        val end = endTime ?: -1
        
        // If start time is after end time (crosses midnight)
        if (end < start) {
            if (currMins >= start) {
                // Current time is after start time but before midnight
                // Only need to check if current day is enabled
                return dayOfWeek < days.size && days[dayOfWeek]
            } else if (currMins < end) {
                // Current time is after midnight but before end time
                // Check if yesterday was enabled (routine started yesterday)
                val yesterdayOfWeek = (dayOfWeek + 6) % 7 // Previous day, wrapping from 0 back to 6
                return yesterdayOfWeek < days.size && days[yesterdayOfWeek]
            }
            return false
        }
        
        // Normal case: start time is before end time
        return dayOfWeek < days.size && days[dayOfWeek] && (currMins >= start && currMins < end)
    }
    
    fun areConditionsMet(): Boolean {
        // If conditionsLastMet is null, return false
        val lastMet = conditionsLastMet ?: return false
        
        // Get the current date and extract the time components
        val now = Date()
        val calendar = Calendar.getInstance()
        
        // Reset calendar to today at midnight
        calendar.time = now
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        
        // Use startTime if defined, otherwise use 0 (midnight)
        val effectiveStartTime = startTime ?: 0
        
        val startHour = effectiveStartTime / 60
        val startMinute = effectiveStartTime % 60
        
        // Set calendar to today at start time
        calendar.set(Calendar.HOUR_OF_DAY, startHour)
        calendar.set(Calendar.MINUTE, startMinute)
        
        val todayAtStartTime = calendar.time
        
        // Return true if conditionsLastMet is after today's start time (completed during routine)
        return lastMet.after(todayAtStartTime)
    }
    
    // Getter methods for collections
    fun getApps(): List<String> = apps.toList()
    
    fun getSites(): List<String> = sites.toList()
}
