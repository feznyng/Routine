//
//  Routine.swift
//  Runner
//
//  Created by Ajan on 2/28/25.
//

import ManagedSettings

class Routine {
    let id: String
    let name: String
    let days: [Bool]
    let startTime: Int?
    let endTime: Int?
    let allDay: Bool
    let pausedUntil: Date?
    let snoozedUntil: Date?
    private(set) var apps: [ApplicationToken]
    private(set) var sites: [WebDomainToken]
    private(set) var categories: [ActivityCategoryToken]
    let allow: Bool
    
    init(entity: [String: Any]) {
        self.id = entity["id"] as? String ?? ""
        self.name = entity["name"] as? String ?? ""
        self.days = entity["days"] as? [Bool] ?? Array(repeating: false, count: 7)
        self.startTime = entity["startTime"] as? Int
        self.endTime = entity["endTime"] as? Int
        self.allDay = entity["allDay"] as? Bool ?? false
        
        let formatter = ISO8601DateFormatter()
        
        // Convert ISO8601 strings to Date objects if they exist
        if let pausedUntilString = entity["pausedUntil"] as? String {
            self.pausedUntil = formatter.date(from: pausedUntilString)
        } else {
            self.pausedUntil = nil
        }
        
        if let snoozedUntilString = entity["snoozedUntil"] as? String {
            self.snoozedUntil = formatter.date(from: snoozedUntilString)
        } else {
            self.snoozedUntil = nil
        }
        
        // Process application tokens
        let decoder = JSONDecoder()
        self.apps = [ApplicationToken]()
        if let apps = entity["apps"] as? [String] {
            for appId in apps {
                if let data = appId.data(using: .utf8),
                   let token = try? decoder.decode(ApplicationToken.self, from: data) {
                    self.apps.append(token)
                }
            }
        }
        
        // Process web domain tokens
        self.sites = [WebDomainToken]()
        if let sites = entity["sites"] as? [String] {
            for siteId in sites {
                if let data = siteId.data(using: .utf8),
                   let token = try? decoder.decode(WebDomainToken.self, from: data) {
                    self.sites.append(token)
                }
            }
        }
        
        // Process category tokens
        self.categories = [ActivityCategoryToken]()
        if let categories = entity["categories"] as? [String] {
            for categoryId in categories {
                if let data = categoryId.data(using: .utf8),
                   let token = try? decoder.decode(ActivityCategoryToken.self, from: data) {
                    self.categories.append(token)
                }
            }
        }
        
        self.allow = entity["allow"] as? Bool ?? false
    }
    
    func isActive() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        
        // Get day of week (0-6, where 0 is Sunday in Swift)
        // Convert to 0-6 where 0 is Monday to match Dart implementation
        var dayOfWeek = calendar.component(.weekday, from: now) - 1 // 1-7 (Sunday is 1) -> 0-6
        dayOfWeek = (dayOfWeek + 6) % 7 // Convert to 0-6 where 0 is Monday
        
        // Check if routine is active on current day
        if dayOfWeek < days.count && !days[dayOfWeek] {
            return false
        }
        
        // Check if routine is snoozed
        if let snoozedUntil = snoozedUntil, now < snoozedUntil {
            return false
        }
        
        // Check if routine is paused
        if let pausedUntil = pausedUntil, now < pausedUntil {
            return false
        }
        
        // If allDay or no time restrictions, just check the day
        if allDay || (startTime == nil && endTime == nil) {
            return dayOfWeek < days.count && days[dayOfWeek]
        }
        
        // Get current time in minutes since midnight
        let components = calendar.dateComponents([.hour, .minute], from: now)
        let currMins = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        
        // Unwrap optional startTime and endTime with defaults
        if (startTime == nil || endTime == nil) {
            return true;
        }
        
        let start = startTime ?? -1
        let end = endTime ?? -1
        
        // If start time is after end time (crosses midnight)
        if end < start {
            return (currMins >= start || currMins < end)
        }
        
        // Normal case: start time is before end time
        return (currMins >= start && currMins < end)
    }
}
