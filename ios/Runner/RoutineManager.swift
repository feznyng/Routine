//
//  RoutineManager.swift
//  Runner
//
//  Created by Ajan on 2/28/25.
//

import Foundation
import ManagedSettings
import DeviceActivity
import Sentry

class RoutineManager {
    private let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("routineBlockerRestrictions"))
    private let center = DeviceActivityCenter()
    var routines: [Routine] = []
    
    func update(routines: [Routine]) {
        // Start timing the update function
        let updateStartTime = Date()
        
        SentrySDK.capture(message: "updateRoutines: internal start")
        
        // Store routines immediately on main thread since it's just an array assignment
        self.routines = routines
        
        self.store.clearAllSettings()
        self.center.stopMonitoring()
        
        let now = Date()
        let hasAllDay = routines.contains { $0.allDay }
        
        // Arrays to accumulate all evaluation times
        var regularEvalTimes: [(id: String, startTime: Int?, endTime: Int?)] = []
        var oneTimeEvalTimes: [(id: String, type: String, startTime: Date, endTime: Date)] = []

        // always schedule for midnight to handle all day routines
        if hasAllDay {
            do {
                let intervalStart = self.minutesOfDayToDateComponents(0)
                let intervalEnd = self.minutesOfDayToDateComponents(15)

                let name = DeviceActivityName("midnight-eval")
                let schedule = DeviceActivitySchedule(intervalStart: intervalStart, intervalEnd: intervalEnd, repeats: true)

                try self.center.startMonitoring(name, during: schedule)
                
                // Add midnight eval to the list
                regularEvalTimes.append((id: "midnight-eval", startTime: 0, endTime: 15))
            } catch {
                print("failed to register device activity \(error.localizedDescription)")
                SentrySDK.capture(message: "failed to register all day routine")
            }
        }
        
        for routine in routines {
            if routine.startTime != nil && routine.endTime != nil && !routine.allDay {
                let startTime = routine.startTime!
                let endTime = routine.endTime!
                
                let intervalStart = self.minutesOfDayToDateComponents(startTime)
                let intervalEnd = self.minutesOfDayToDateComponents(endTime)

                let name = DeviceActivityName(routine.id)
                let schedule = DeviceActivitySchedule(intervalStart: intervalStart, intervalEnd: intervalEnd, repeats: true)
                
                do {
                    try self.center.startMonitoring(name, during: schedule)
                    
                    // Add regular routine eval times to the list
                    regularEvalTimes.append((id: routine.id, startTime: startTime, endTime: endTime))
                } catch {
                    print("failed to register routine schedule \(error.localizedDescription)")
                    SentrySDK.capture(error: error)
                }
            }
            
            if let snoozedUntil = routine.snoozedUntil, now.compare(snoozedUntil) == .orderedAscending {
                let (scheduled, startTime, endTime) = self.scheduleOneTimeActivity(for: routine, startDate: snoozedUntil, activityType: "snoozed")
                if scheduled {
                    oneTimeEvalTimes.append((id: routine.id, type: "snoozed", startTime: startTime, endTime: endTime))
                }
            } else if let pausedUntil = routine.pausedUntil, now.compare(pausedUntil) == .orderedAscending {
                let (scheduled, startTime, endTime) = self.scheduleOneTimeActivity(for: routine, startDate: pausedUntil, activityType: "paused")
                if scheduled {
                    oneTimeEvalTimes.append((id: routine.id, type: "paused", startTime: startTime, endTime: endTime))
                }
            }
        }
        
        // Prepare the evaluation times summary for the Sentry log
        var evalTimesSummary = "Regular Evals: ["
        
        // Create a date formatter for HH:mm format
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        // Function to convert minutes of day to HH:mm format
        func formatMinutesOfDay(_ minutes: Int?) -> String {
            guard let mins = minutes else { return "00:00" }
            let hours = mins / 60
            let remainingMins = mins % 60
            return String(format: "%02d:%02d", hours, remainingMins)
        }
        
        for (index, evalTime) in regularEvalTimes.enumerated() {
            let startFormatted = formatMinutesOfDay(evalTime.startTime)
            let endFormatted = formatMinutesOfDay(evalTime.endTime)
            evalTimesSummary += "\(evalTime.id)(\(startFormatted)-\(endFormatted))"
            if index < regularEvalTimes.count - 1 {
                evalTimesSummary += ", "
            }
        }
        evalTimesSummary += "] OneTime Evals: ["
        
        for (index, evalTime) in oneTimeEvalTimes.enumerated() {
            let startTimeString = dateFormatter.string(from: evalTime.startTime)
            let endTimeString = dateFormatter.string(from: evalTime.endTime)
            evalTimesSummary += "\(evalTime.id)(\(evalTime.type)-\(startTimeString)-\(endTimeString))"
            if index < oneTimeEvalTimes.count - 1 {
                evalTimesSummary += ", "
            }
        }
        evalTimesSummary += "]"
        
        // Calculate elapsed time for the entire update function
        let updateElapsedTime = Date().timeIntervalSince(updateStartTime)
        
        print("finished updating routines")
        SentrySDK.capture(message: "updateRoutines: internal done - \(evalTimesSummary) - Total Duration: \(String(format: "%.3f", updateElapsedTime)) seconds")
        SentrySDK.flush(timeout: 1000)
    }
    
    private func scheduleOneTimeActivity(for routine: Routine, startDate: Date, activityType: String) -> (scheduled: Bool, startTime: Date, endTime: Date) {
        let uniqueId = "\(activityType)_\(routine.id)"
        let name = DeviceActivityName(uniqueId)
        
        // add a slight delay to avoid timing issues
        let delayedStartDate = startDate.addingTimeInterval(30)
        
        let endDate = delayedStartDate.addingTimeInterval(15 * 60) // 15 minutes in seconds
        
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: delayedStartDate)
        let endComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: endDate)
        
        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )
        
        do {
            try center.startMonitoring(name, during: schedule)
            return (true, delayedStartDate, endDate)
        } catch {
            // Create a date formatter for detailed time logging
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            let errorMessage = "\(error.localizedDescription) - Start: \(formatter.string(from: delayedStartDate)), End: \(formatter.string(from: endDate))"
            SentrySDK.capture(message: errorMessage)
            return (false, delayedStartDate, endDate)
        }
    }
    
    private func minutesOfDayToDateComponents(_ minutes: Int) -> DateComponents {
        var dateComponents = DateComponents()
        dateComponents.hour = minutes / 60
        dateComponents.minute = minutes % 60
        return dateComponents
    }
}
