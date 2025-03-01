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
    
    func update(routines: [Routine]) {
        store.clearAllSettings()
        
        center.stopMonitoring()
        
        var seenTimes: Set<Int> = []
        var usedNames: Set<String> = []
        let now = Date()
        
        for routine in routines {
            if routine.startTime == nil || routine.endTime == nil || routine.allDay { continue }
          
            let startTime = routine.startTime!
            let endTime = routine.endTime!
            
            if (seenTimes.contains(startTime) && seenTimes.contains(endTime)) { continue }
            
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
        
        print("Center Activities: \(center.activities)")
    }
    
    func minutesOfDayToDateComponents(_ minutes: Int) -> DateComponents {
        var dateComponents = DateComponents()
        dateComponents.hour = minutes / 60
        dateComponents.minute = minutes % 60
        return dateComponents
    }
}
