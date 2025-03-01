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
        store.shield.applications = nil
        store.shield.webDomains = nil
        store.shield.webDomainCategories = nil
        store.shield.applicationCategories = nil
        
        
    }
}
