//
//  RoutineManager.swift
//  Runner
//
//  Created by Ajan on 2/28/25.
//

import ManagedSettings
import DeviceActivity

class RoutineManager {
    private let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("routineBlockerRestrictions"))
    private let center = DeviceActivityCenter()
    var routines: [Routine] = []
    
    func update(routines: [Routine]) {
        store.clearAllSettings()
        center.stopMonitoring()
        
        let now = Date()
        let hasAllDay = routines.contains { $0.allDay }

        // always schedule for midnight to handle all day routines
        if hasAllDay {
            do {
                let intervalStart = minutesOfDayToDateComponents(0)
                let intervalEnd = minutesOfDayToDateComponents(15)

                let name = DeviceActivityName("midnight-eval")
                let schedule = DeviceActivitySchedule(intervalStart: intervalStart, intervalEnd: intervalEnd, repeats: true)

                try center.startMonitoring(name, during: schedule)
            } catch {
                print("failed to register device activity \(error.localizedDescription)")
            }
        }
        
        for routine in routines {
            if routine.startTime != nil && routine.endTime != nil && !routine.allDay {
                let startTime = routine.startTime!
                let endTime = routine.endTime!
                
                let intervalStart = minutesOfDayToDateComponents(startTime)
                let intervalEnd = minutesOfDayToDateComponents(endTime)

                let name = DeviceActivityName(routine.id)
                let schedule = DeviceActivitySchedule(intervalStart: intervalStart, intervalEnd: intervalEnd, repeats: true)
                
                do {
                    try center.startMonitoring(name, during: schedule)
                    
                } catch {
                    print("failed to register device activity \(error.localizedDescription)")
                }
            }
            
            if let snoozedUntil = routine.snoozedUntil, snoozedUntil > now {
                scheduleOneTimeActivity(for: routine, startDate: snoozedUntil, activityType: "snoozed")
            } else if let pausedUntil = routine.pausedUntil, pausedUntil > now {
                scheduleOneTimeActivity(for: routine, startDate: pausedUntil, activityType: "paused")
            }
        }

        self.routines = routines
    }
    
    private func scheduleOneTimeActivity(for routine: Routine, startDate: Date, activityType: String) {
        // Create a unique name for this one-time activity
        let uniqueId = "\(activityType)_\(routine.id)"
        let name = DeviceActivityName(uniqueId)
        
        let delayedStartDate = startDate.addingTimeInterval(45)
        
        // Calculate end date (15 minutes after start date)
        let endDate = delayedStartDate.addingTimeInterval(15 * 60) // 15 minutes in seconds
        
        // Create date components for start and end dates
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: delayedStartDate)
        let endComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: endDate)
        
        // Create non-repeating schedule
        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )
        
        do {
            try center.startMonitoring(name, during: schedule)
        } catch {
            print("failed to register one-time \(activityType) activity: \(error.localizedDescription)")
        }
    }
    
    private func minutesOfDayToDateComponents(_ minutes: Int) -> DateComponents {
        var dateComponents = DateComponents()
        dateComponents.hour = minutes / 60
        dateComponents.minute = minutes % 60
        return dateComponents
    }
}
