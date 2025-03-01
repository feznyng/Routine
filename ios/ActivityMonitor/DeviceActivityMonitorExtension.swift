//
//  DeviceActivityMonitorExtension.swift
//  ActivityMonitor
//
//  Created by Ajan on 2/28/25.
//

import DeviceActivity
import ManagedSettings
import os.log

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("routineBlockerRestrictions"))
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        os_log("DeviceActivityMonitorExtension: intervalDidStart")

        store.shield.applicationCategories = .all()
        
        // Handle the start of the interval.
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        os_log("DeviceActivityMonitorExtension: intervalDidEnd")

        // Handle the end of the interval.
        
        store.shield.applications = nil

    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        os_log("DeviceActivityMonitorExtension: eventDidReachThreshold")

        // Handle the event reaching its threshold.
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        os_log("DeviceActivityMonitorExtension: intervalWillStartWarning")

        // Handle the warning before the interval starts.
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        os_log("DeviceActivityMonitorExtension: intervalWillEndWarning")

        // Handle the warning before the interval ends.
    }
    
    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        os_log("DeviceActivityMonitorExtension: eventWillReachThresholdWarning")

        // Handle the warning before the event reaches its threshold.
    }
}
