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
    
    // Log an error to shared UserDefaults for the main app to report to Sentry
    private func logError(_ context: String, _ error: Error?) {
        if let sharedDefaults = UserDefaults(suiteName: "group.routineblocker") {
            // Create error entry
            let errorEntry: [String: Any] = [
                "timestamp": Date().timeIntervalSince1970,
                "context": context,
                "error": error?.localizedDescription ?? ""
            ]
            
            // Convert to JSON
            if let errorData = try? JSONSerialization.data(withJSONObject: errorEntry),
               let errorString = String(data: errorData, encoding: .utf8) {
                
                // Get existing errors array or create new one
                var errorsArray: [String] = []
                if let existingErrors = sharedDefaults.array(forKey: "extensionErrors") as? [String] {
                    errorsArray = existingErrors
                }
                
                // Add new error and limit array size to prevent excessive storage
                errorsArray.append(errorString)
                if errorsArray.count > 10 {
                    errorsArray.removeFirst(errorsArray.count - 10)
                }
                
                // Save back to shared UserDefaults
                sharedDefaults.set(errorsArray, forKey: "extensionErrors")
                sharedDefaults.synchronize()
                
                os_log("DeviceActivityMonitorExtension: Error logged to shared UserDefaults: %{public}s", context)
            } else {
                os_log("DeviceActivityMonitorExtension: Failed to serialize error for logging")
            }
        } else {
            os_log("DeviceActivityMonitorExtension: Failed to access shared UserDefaults for error logging")
        }
    }
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        os_log("DeviceActivityMonitorExtension: intervalDidStart %{public}s", activity.rawValue)
        
        eval(id: activity.rawValue, type: "start")
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        os_log("DeviceActivityMonitorExtension: intervalDidEnd %{public}s", activity.rawValue)
        
        eval(id: activity.rawValue, type: "end")
    }
    
    private func eval(id: String, type: String) {
        // Start timing the eval function
        let startTime = Date()
        
        os_log("DeviceActivityMonitorExtension: Evaluating [ID: %{public}s]", id)
        //logError("DeviceActivityMonitorExtension: Start Eval [ID: \(evalId)]", nil)

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
                logError("Failed to decode routines from shared UserDefaults", error)
            }
        } else {
            os_log("DeviceActivityMonitorExtension: No routines data found in shared UserDefaults")
        }
        
        routines = routines.filter { $0.isActive() && !$0.areConditionsMet() }
        os_log("DeviceActivityMonitorExtension: filtered routine count = %d", routines.count)

        let allow = routines.contains(where: { $0.allow })

        var excludeApps = Set<ApplicationToken>();
        var excludeSites = Set<WebDomainToken>();
        var excludeDomains = Set<String>();
        var excludeCategories = Set<ActivityCategoryToken>();

        if allow {
            for routine in (routines.filter { !$0.allow }) {
                excludeApps.formUnion(routine.apps)
                excludeSites.formUnion(routine.sites)
                excludeDomains.formUnion(routine.domains)
                excludeCategories.formUnion(routine.categories)
            }

            routines = routines.filter { $0.allow }
        }
        
        var apps = Set<ApplicationToken>();
        var sites = Set<WebDomainToken>();
        var domains = Set<String>();
        var categories = Set<ActivityCategoryToken>();
        
        for routine in routines {
            apps.formUnion(routine.apps.filter { !excludeApps.contains($0) })
            sites.formUnion(routine.sites.filter { !excludeSites.contains($0) })
            domains.formUnion(routine.domains.filter { !excludeDomains.contains($0) })
            categories.formUnion(routine.categories.filter { !excludeCategories.contains($0) })
        }
        
        var webDomains: Set<WebDomain> = []
        
        for tok in sites {
            webDomains.insert(WebDomain(token: tok))
        }
        
        for domain in domains {
            webDomains.insert(WebDomain(domain: domain))
        }
        
        if (allow) {
            store.shield.applications = nil
            store.shield.applicationCategories = .all(except: Set(apps))
            store.shield.webDomainCategories = .all(except: Set(sites))
            store.webContent.blockedByFilter = .all(except: webDomains)
        } else {
            store.shield.applications = apps
            store.shield.applicationCategories = .specific(categories)
            store.shield.webDomainCategories = nil
            store.webContent.blockedByFilter = .specific(webDomains)
        }

        let strictMode = routines.contains(where: { $0.isActive() && $0.strictMode ?? false })
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
                    logError("Failed to parse strict mode settings", error)
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
        
        // Calculate elapsed time
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        os_log("DeviceActivityMonitorExtension: Eval completed [ID: %{public}s] in %.3f seconds", String(id), elapsedTime)
        logError("DeviceActivityMonitorExtension: End Eval [ID: \(id)] - Duration: \(String(format: "%.3f", elapsedTime)) seconds", nil)
    }
}
