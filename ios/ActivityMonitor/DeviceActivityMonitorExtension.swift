//
//  DeviceActivityMonitorExtension.swift
//  ActivityMonitor
//
//  Created by Ajan on 2/28/25.
//

import DeviceActivity
import ManagedSettings
import os.log
import Foundation

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("routineBlockerRestrictions"))
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        os_log("DeviceActivityMonitorExtension: intervalDidStart %{public}s", activity.rawValue)
        
        eval()
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        os_log("DeviceActivityMonitorExtension: intervalDidEnd %{public}s", activity.rawValue)
        
        let name = activity.rawValue
        if name.starts(with: "paused") || name.starts(with: "snoozed") {
            os_log("DeviceActivityMonitorExtension: skipping due to non-standard schedule")
            return
        }
        
        eval()
    }
    
    private func eval() {
        os_log("DeviceActivityMonitorExtension: Evaluating")
        // Read routines from shared UserDefaults
        var routines: [Routine] = []
        
        if let sharedDefaults = UserDefaults(suiteName: "group.routineblocker"),
           let jsonString = sharedDefaults.string(forKey: "routinesData") {
            do {
                let decoder = JSONDecoder()
                if let data = jsonString.data(using: .utf8) {
                    routines = try decoder.decode([Routine].self, from: data)
                    os_log("DeviceActivityMonitorExtension: Successfully loaded %d routines from shared UserDefaults", routines.count)
                }
            } catch {
                os_log("DeviceActivityMonitorExtension: Failed to decode routines from shared UserDefaults: %{public}s", error.localizedDescription)
            }
        } else {
            os_log("DeviceActivityMonitorExtension: No routines data found in shared UserDefaults")
        }
        
        routines = routines.filter { $0.isActive() && !$0.areConditionsMet() }
        os_log("DeviceActivityMonitorExtension: filtered routine count = %d", routines.count)

        let allow = routines.contains(where: { $0.allow })
        
        if (allow) {
            var apps = [ApplicationToken: Int]()
            var sites = [WebDomainToken: Int]()
            var domains = [String: Int]()
            var categories = [ActivityCategoryToken: Int]()
            
            for routine in routines {
                for app in routine.apps {
                    apps[app, default: 0] += 1
                }
                for site in routine.sites {
                    sites[site, default: 0] += 1
                }
                for domain in routine.domains {
                    domains[domain, default: 0] += 1
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
            
            for (tok, cnt) in categories {
                if routines.count != cnt {
                    categories.removeValue(forKey: tok)
                }
            }
            
            var webDomains: Set<WebDomain> = []
            
            for (tok, cnt) in sites {
                if routines.count == cnt {
                    webDomains.insert(WebDomain(token: tok))
                }
            }
            
            for (domain, cnt) in domains {
                if routines.count == cnt {
                    webDomains.insert(WebDomain(domain: domain))
                }
            }
                        
            store.shield.applicationCategories = .all(except: Set(apps.map { $0.0 }))
            store.shield.webDomainCategories = .all(except: Set(sites.map { $0.0 }))
            store.webContent.blockedByFilter = .all(except: webDomains)
        } else {
            var apps: [ApplicationToken] = []
            var sites: [WebDomain] = []
            var categories: [ActivityCategoryToken] = []
            
            for routine in routines {
                apps.append(contentsOf: routine.apps)
                sites.append(contentsOf: routine.sites.map { WebDomain(token: $0) })
                sites.append(contentsOf: routine.domains.map { WebDomain(domain: $0) })
                categories.append(contentsOf: routine.categories)
            }
            
            os_log("DeviceActivityMonitorExtension: Blocking \(apps.count) apps, \(sites.count) sites, \(categories.count) categories")
            
            store.shield.applications = Set(apps)
            store.shield.applicationCategories = .specific(Set(categories))
            store.webContent.blockedByFilter = .specific(Set(sites.map { $0 }))
        }

        let strictMode = routines.contains(where: { $0.strictMode ?? false })
        if strictMode {
            os_log("DeviceActivityMonitorExtension: Strict mode enabled")
            
            // Retrieve strict mode settings from shared preferences
            if let sharedDefaults = UserDefaults(suiteName: "group.routineblocker"),
               let strictModeDataString = sharedDefaults.string(forKey: "strictModeData") {
                do {
                    // Parse the JSON string
                    if let strictModeData = strictModeDataString.data(using: .utf8),
                       let strictModeSettings = try JSONSerialization.jsonObject(with: strictModeData) as? [String: Any] {
                        
                        os_log("DeviceActivityMonitorExtension: Successfully loaded strict mode settings from shared UserDefaults")
                        
                        // Apply the settings to ManagedSettingsStore
                        if let blockInstallingApps = strictModeSettings["blockInstallingApps"] as? Bool, blockInstallingApps {
                            os_log("DeviceActivityMonitorExtension: Blocking app installation")
                            store.application.denyAppInstallation = true
                        } else {
                            store.application.denyAppInstallation = false
                        }
                        
                        if let blockUninstallingApps = strictModeSettings["blockUninstallingApps"] as? Bool, blockUninstallingApps {
                            os_log("DeviceActivityMonitorExtension: Blocking app removal")
                            store.application.denyAppRemoval = true
                        } else {
                            store.application.denyAppRemoval = false
                        }
                        
                        if let blockChangingTimeSettings = strictModeSettings["blockChangingTimeSettings"] as? Bool, blockChangingTimeSettings {
                            os_log("DeviceActivityMonitorExtension: Requiring automatic date and time")
                            store.dateAndTime.requireAutomaticDateAndTime = true
                        } else {
                            store.dateAndTime.requireAutomaticDateAndTime = false
                        }
                    }
                } catch {
                    os_log("DeviceActivityMonitorExtension: Failed to parse strict mode settings: %{public}s", error.localizedDescription)
                }
            } else {
                os_log("DeviceActivityMonitorExtension: No strict mode data found in shared UserDefaults")
            }
        } else {
            // If strict mode is not enabled, make sure restrictions are removed
            store.application.denyAppInstallation = false
            store.application.denyAppRemoval = false
            store.dateAndTime.requireAutomaticDateAndTime = false
            os_log("DeviceActivityMonitorExtension: Strict mode disabled, removing restrictions")
        }
    }
}
