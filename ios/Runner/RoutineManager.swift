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
        var seenTimes: Set<Int> = []
        var usedNames: Set<String> = []
        
        for routine in routines {

            if routine.startTime != nil && routine.endTime != nil && !routine.allDay {
                let startTime = routine.startTime!
                let endTime = routine.endTime!
                
                if !(seenTimes.contains(startTime) && seenTimes.contains(endTime)) {
                    let intervalStart = minutesOfDayToDateComponents(startTime)
                    let intervalEnd = minutesOfDayToDateComponents(endTime)

                    let name = DeviceActivityName(routine.id)
                    let schedule = DeviceActivitySchedule(intervalStart: intervalStart, intervalEnd: intervalEnd, repeats: true)
                    
                    do {
                        try center.startMonitoring(name, during: schedule)
                        print("scheduled \(routine.name) for \(schedule.nextInterval!)")
                        
                        seenTimes.insert(startTime)
                        seenTimes.insert(endTime)
                        usedNames.insert(routine.id)
                        
                    } catch {
                        print("failed to register device activity \(error.localizedDescription)")
                    }
                }
            }
            
            if let pausedUntil = routine.pausedUntil, pausedUntil > now {
                scheduleOneTimeActivity(for: routine, startDate: pausedUntil, activityType: "paused")
            }
            
            if let snoozedUntil = routine.snoozedUntil, snoozedUntil > now {
                scheduleOneTimeActivity(for: routine, startDate: snoozedUntil, activityType: "snoozed")
            }
        }

        self.routines = routines
        
        print("Center Activities: \(center.activities)")
    }
    
    private func scheduleOneTimeActivity(for routine: Routine, startDate: Date, activityType: String) {
        // Create a unique name for this one-time activity
        let uniqueId = "\(activityType)_\(routine.id)"
        let name = DeviceActivityName(uniqueId)
        
        let delayedStartDate = startDate.addingTimeInterval(30)
        
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
            print("scheduled one-time \(activityType) activity for \(routine.name) at \(startDate) until \(endDate)")
        } catch {
            print("failed to register one-time \(activityType) activity: \(error.localizedDescription)")
        }
    }
    
    private func minutesOfDayToDateComponents(_ minutes: Int) -> DateComponents {
        var dateComponents = DateComponents()
        dateComponents.hour = minutes / 60
        dateComponents.minute = minutes % 60
        dateComponents.second = 30
        return dateComponents
    }
}
