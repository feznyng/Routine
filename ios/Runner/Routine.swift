//
//  Routine.swift
//  Runner
//
//  Created by Ajan on 2/28/25.
//

import ManagedSettings
import Foundation
import os.log

class Routine: Codable {
    let id: String
    let name: String
    let days: [Bool]
    let startTime: Int?
    let endTime: Int?
    let allDay: Bool
    let pausedUntil: Date?
    let snoozedUntil: Date?
    let conditionsLastMet: Date?
    let strictMode: Bool?
    private(set) var apps: [ApplicationToken]
    private(set) var sites: [WebDomainToken]
    private(set) var domains: [String]
    private(set) var categories: [ActivityCategoryToken]
    
    enum CodingKeys: String, CodingKey {
        case id, name, days, startTime, endTime, allDay, pausedUntil, snoozedUntil, apps, sites, categories, allow, conditionsMet, conditionsLastMet, strictMode
    }
    let allow: Bool
    
    // Required initializer for Decodable protocol
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.days = try container.decode([Bool].self, forKey: .days)
        self.startTime = try container.decodeIfPresent(Int.self, forKey: .startTime)
        self.endTime = try container.decodeIfPresent(Int.self, forKey: .endTime)
        self.allDay = try container.decode(Bool.self, forKey: .allDay)
        self.allow = try container.decode(Bool.self, forKey: .allow)
        self.strictMode = try container.decodeIfPresent(Bool.self, forKey: .strictMode)

        // Handle conditionsLastMet as an optional Date
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let conditionsLastMetString = try container.decodeIfPresent(String.self, forKey: .conditionsLastMet) {
            self.conditionsLastMet = formatter.date(from: conditionsLastMetString)
        } else {
            self.conditionsLastMet = nil
        }

        // Handle optional Date properties
        
        if let pausedUntilString = try container.decodeIfPresent(String.self, forKey: .pausedUntil) {
            self.pausedUntil = formatter.date(from: pausedUntilString)
        } else {
            self.pausedUntil = nil
        }

        if let snoozedUntilString = try container.decodeIfPresent(String.self, forKey: .snoozedUntil) {
            self.snoozedUntil = formatter.date(from: snoozedUntilString)
        } else {
            self.snoozedUntil = nil
        }
        
        // Process tokens directly
        self.apps = [ApplicationToken]()
        self.sites = [WebDomainToken]()
        self.categories = [ActivityCategoryToken]()
        self.domains = [String]()
        
        // Since the tokens are stored as JSON strings, we need to decode them separately
        // We'll use a single JSONDecoder instance for all token types
        let jsonDecoder = JSONDecoder()
        
        if let appsData = try container.decodeIfPresent([String].self, forKey: .apps) {
            for appString in appsData {
                if let data = appString.data(using: .utf8),
                   let token = try? jsonDecoder.decode(ApplicationToken.self, from: data) {
                    self.apps.append(token)
                } else {
                    print("failed to create app token")
                }
            }
        }
        
        if let sitesData = try container.decodeIfPresent([String].self, forKey: .sites) {
            for siteString in sitesData {
                if let data = siteString.data(using: .utf8),
                   let token = try? jsonDecoder.decode(WebDomainToken.self, from: data) {
                    self.sites.append(token)
                } else {
                    self.domains.append(siteString)
                }
            }
        }
        
        if let categoriesData = try container.decodeIfPresent([String].self, forKey: .categories) {
            for categoryString in categoriesData {
                if let data = categoryString.data(using: .utf8),
                   let token = try? jsonDecoder.decode(ActivityCategoryToken.self, from: data) {
                    self.categories.append(token)
                } else {
                    print("failed to create category token")
                }
            }
        }
    }
    
    func isActive() -> Bool {
        let now = Date().addingTimeInterval(45)
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
            let dateFormatter = DateFormatter()

            // Set the date format you want
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            // Convert the Date to String
            let dateString = dateFormatter.string(from: pausedUntil)
            let nowString = dateFormatter.string(from: now)
            os_log("DeviceActivityMonitorExtension: routine is paused - %{public}s < %{public}s", nowString, dateString)
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
    
    func areConditionsMet() -> Bool {
        // If conditionsLastMet is nil, return false
        guard let lastMet = conditionsLastMet else {
            return false
        }
        
        // Get the current date and extract the time components
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        
        // Use startTime if defined, otherwise use 0 (midnight)
        // This assumes all-day routines start at midnight
        let effectiveStartTime = startTime ?? 0
        
        let startHour = effectiveStartTime / 60
        let startMinute = effectiveStartTime % 60
        
        var startComponents = components
        startComponents.hour = startHour
        startComponents.minute = startMinute
        startComponents.second = 0
        
        guard let todayAtStartTime = calendar.date(from: startComponents) else {
            return false
        }
        
        // Return true if conditionsLastMet is after today's start time (completed during routine)
        return todayAtStartTime.compare(lastMet) == .orderedAscending
    }
}

// MARK: - Encodable Implementation
extension Routine {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(days, forKey: .days)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(allDay, forKey: .allDay)
        try container.encode(allow, forKey: .allow)
        try container.encode(strictMode, forKey: .strictMode)

        // Create a single formatter for date properties
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Handle conditionsLastMet
        if let conditionsLastMet = conditionsLastMet {
            try container.encode(formatter.string(from: conditionsLastMet), forKey: .conditionsLastMet)
        } else {
            try container.encodeNil(forKey: .conditionsLastMet)
        }
        
        // Handle optional Date properties
        if let pausedUntil = pausedUntil {
            try container.encode(formatter.string(from: pausedUntil), forKey: .pausedUntil)
        } else {
            try container.encodeNil(forKey: .pausedUntil)
        }
        
        if let snoozedUntil = snoozedUntil {
            try container.encode(formatter.string(from: snoozedUntil), forKey: .snoozedUntil)
        } else {
            try container.encodeNil(forKey: .snoozedUntil)
        }
        
        // Create a single JSONEncoder for token encoding
        let jsonEncoder = JSONEncoder()
        
        // Encode tokens as strings
        let appsData = try apps.map { try String(data: jsonEncoder.encode($0), encoding: .utf8) ?? "" }
        try container.encode(appsData, forKey: .apps)
        
        let sitesData = try sites.map { try String(data: jsonEncoder.encode($0), encoding: .utf8) ?? "" }
        try container.encode(sitesData, forKey: .sites)
        
        let categoriesData = try categories.map { try String(data: jsonEncoder.encode($0), encoding: .utf8) ?? "" }
        try container.encode(categoriesData, forKey: .categories)
    }
}
