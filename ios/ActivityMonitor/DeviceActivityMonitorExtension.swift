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

        // store.shield.applicationCategories = .all()
        
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
    
    func eval() {
        let routines: [Routine] = []
        let allow = routines.contains(where: { $0.allow })
        
        if (allow) {
            var apps = [ApplicationToken: Int]()
            var sites = [WebDomainToken: Int]()
            var categories = [ActivityCategoryToken: Int]()
            
            for routine in routines {
                for app in routine.apps {
                    apps[app, default: 0] += 1
                }
                for site in routine.sites {
                    sites[site, default: 0] += 1
                }
                for category in routine.categories {
                    categories[category, default: 0] += 1
                }
            }
            
            for (tok, cnt) in apps {
                if routines.count != cnt {
                    apps.removeValue(forKey: tok)
                }
            }
            
            for (tok, cnt) in sites {
                if routines.count != cnt {
                    sites.removeValue(forKey: tok)
                }
            }
            
            for (tok, cnt) in categories {
                if routines.count != cnt {
                    categories.removeValue(forKey: tok)
                }
            }
                        
            store.shield.applicationCategories = .all(except: Set(apps.map { $0.0 }))
            store.shield.webDomainCategories = .all(except: Set(sites.map { $0.0 }))
        } else {
            var apps: [ApplicationToken] = []
            var sites: [WebDomainToken] = []
            var categories: [ActivityCategoryToken] = []
            
            for routine in routines {
                if routine.isActive() {
                    apps.append(contentsOf: routine.apps)
                    sites.append(contentsOf: routine.sites)
                    categories.append(contentsOf: routine.categories)
                }
            }
            
            print("Blocking \(apps.count) apps, \(sites.count) sites, \(categories.count) categories")
            
            store.shield.applications = Set(apps)
            store.shield.webDomains = Set(sites)
            store.shield.applicationCategories = .specific(Set(categories))
            store.shield.webDomainCategories = .specific(Set(categories))
        }
    }
}
