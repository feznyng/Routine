//
//  RoutineManager.swift
//  Runner
//
//  Created by Ajan on 2/28/25.
//

import ManagedSettings

class RoutineManager {
    private let store = ManagedSettingsStore()
    
    func update(routines: [Routine]) {
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
