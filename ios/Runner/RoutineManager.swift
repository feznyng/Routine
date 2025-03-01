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
    
    func update(routines: [Routine]) {
        store.shield.applications = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
        store.shield.applicationCategories = nil
        
        let deviceActivityCenter = DeviceActivityCenter()
        let activityName = DeviceActivityName("lunchBreak")

        let now = Date()
        let components: Set<Calendar.Component> = [.hour, .minute, .second]
        let calendar = Calendar.current
        let startDate = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now)!
        let endDate = calendar.date(bySettingHour: 20, minute: 30, second: 0, of: now)!
        let intervalStart = calendar.dateComponents(components, from: startDate)
        let intervalEnd = calendar.dateComponents(components, from: endDate)

        let schedule = DeviceActivitySchedule(intervalStart: intervalStart, intervalEnd: intervalEnd, repeats: true)
        // you can also provide a warningTime to DeviceActivitySchedule.

        let thresholdDate = calendar.date(bySettingHour: 2, minute: 0, second: 0, of: now)!
        let thresholdTime = calendar.dateComponents(components, from: thresholdDate)
        let event = DeviceActivityEvent(threshold: thresholdTime)
        let eventName = DeviceActivityEvent.Name("lunchBreakEvent")

        do {
            try deviceActivityCenter.startMonitoring(activityName, during: schedule, events: [eventName: event])
            print("successfully scheduled for \(schedule.nextInterval!)")
        } catch {
            print("Error scheduling \(error)")
        }
    }
    
    func eval(routines: [Routine]) {
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
