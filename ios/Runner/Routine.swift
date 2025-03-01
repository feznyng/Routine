//
//  Routine.swift
//  Runner
//
//  Created by Ajan on 2/28/25.
//

import ManagedSettings
import Foundation

class Routine: Codable {
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
    
    enum CodingKeys: String, CodingKey {
        case id, name, days, startTime, endTime, allDay, pausedUntil, snoozedUntil, apps, sites, categories, allow
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
        
        // Handle optional Date properties
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
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
                    print("failed to create site token")
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
        
        // Create a single formatter for date properties
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
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
