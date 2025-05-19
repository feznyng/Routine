import Flutter
import UIKit
import Foundation
import FamilyControls
import ManagedSettings
import os.log
import Sentry

@main
@objc class AppDelegate: FlutterAppDelegate {
    let manager = RoutineManager()
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        let factory = AppSiteSelectorFactory(messenger: controller.binaryMessenger)
        registrar(forPlugin: "AppSiteSelectorPlugin")?.register(
            factory,
            withId: "app_site_selector"
        )
        
        // Setup iOS routine channel
        let routineChannel = FlutterMethodChannel(name: "com.routine.ios_channel",
                                                  binaryMessenger: controller.binaryMessenger)
        routineChannel.setMethodCallHandler { [weak self] (call, result) in
            os_log("AppDelegate: %{public}s", call.method)
            switch call.method {
            case "immediateUpdateRoutines":
                os_log("updateRoutines: immediate start")
                if let args = call.arguments as? [String: Any],
                   let routinesJson = args["routines"] as? [[String: Any]] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: routinesJson)
                        let jsonString = String(data: jsonData, encoding: .utf8)!
                        
                        if let sharedDefaults = UserDefaults(suiteName: "group.routineblocker") {
                            sharedDefaults.set(jsonString, forKey: "routinesData")
                            sharedDefaults.synchronize()
                        } else {
                            print("Failed to access shared UserDefaults")
                        }
                        
                        let decoder = JSONDecoder()
                        let routines = try decoder.decode([Routine].self, from: jsonString.data(using: .utf8)!)
                        
                        self?.manager.update(routines: routines)
                        
                        os_log("updateRoutines: immediate done")
                        result(true)
                    } catch {
                        // Return error on main thread
                        os_log("updateRoutines: immediate failed - \(error)")
                        SentrySDK.capture(error: error) { (scope) in
                            scope.setTag(value: "failed to immediately update routines", key: "context")
                        }
                        result(FlutterError(code: "JSON_DECODE_ERROR",
                                            message: "Failed to deserialize: \(error.localizedDescription)",
                                            details: nil))
                    }

                }
                return;
            case "updateRoutines":
                if let args = call.arguments as? [String: Any],
                   let routinesJson = args["routines"] as? [[String: Any]] {
                    
                    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                        os_log("updateRoutines: start")
                        
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: routinesJson)
                            let jsonString = String(data: jsonData, encoding: .utf8)!
                            
                            if let sharedDefaults = UserDefaults(suiteName: "group.routineblocker") {
                                sharedDefaults.set(jsonString, forKey: "routinesData")
                                sharedDefaults.synchronize()
                            } else {
                                print("Failed to access shared UserDefaults")
                            }
                            
                            let decoder = JSONDecoder()
                            let routines = try decoder.decode([Routine].self, from: jsonString.data(using: .utf8)!)
                            
                            self?.manager.update(routines: routines)
                            
                            // Return success on main thread
                            DispatchQueue.main.async {
                                os_log("updateRoutines: done")
                                result(true)
                            }
                            
                        } catch {
                            // Return error on main thread
                            SentrySDK.capture(error: error) { (scope) in
                                scope.setTag(value: "failed to background update routines", key: "context")
                            }
                            DispatchQueue.main.async {
                                os_log("updateRoutines: failed - \(error)")
                                result(FlutterError(code: "JSON_DECODE_ERROR",
                                                    message: "Failed to deserialize: \(error.localizedDescription)",
                                                    details: nil))
                            }
                        }
                    }
                } else {
                    print("Error: Invalid arguments for updateRoutines")
                    result(FlutterError(code: "INVALID_ARGUMENTS",
                                      message: "Invalid arguments for updateRoutines",
                                      details: nil))
                }
                
            case "checkFamilyControlsAuthorization":
                Task {
                    let status = AuthorizationCenter.shared.authorizationStatus
                    DispatchQueue.main.async {
                        switch status {
                        case .approved:
                            result(true)
                        case .denied, .notDetermined:
                            result(false)
                        @unknown default:
                            result(false)
                        }
                    }
                }
                
            case "requestFamilyControlsAuthorization":
                Task {
                    do {
                        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                        DispatchQueue.main.async {
                            result(true)
                        }
                    } catch {
                        print("Failed to request authorization: \(error)")
                        DispatchQueue.main.async {
                            result(FlutterError(code: "AUTHORIZATION_ERROR",
                                                message: "Failed to request authorization: \(error.localizedDescription)",
                                                details: nil))
                        }
                    }
                }
                
            case "updateStrictModeSettings":
                if let args = call.arguments as? [String: Any] {
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: args)
                        let jsonString = String(data: jsonData, encoding: .utf8)!
                        
                        if let sharedDefaults = UserDefaults(suiteName: "group.routineblocker") {
                            sharedDefaults.set(jsonString, forKey: "strictModeData")
                            sharedDefaults.synchronize()
                        } else {
                            print("Failed to access shared UserDefaults")
                        }

                        // Get routines from the manager to check if any active routine has strict mode enabled
                        let manager = (UIApplication.shared.delegate as! AppDelegate).manager
                        let strictMode = manager.routines.contains(where: { $0.isActive() && $0.strictMode ?? false })
                                                
                        // Apply settings to managed settings store immediately
                        let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("routineBlockerRestrictions"))
                        
                        // Apply strict mode settings
                        if strictMode || (args["inStrictMode"] as? Bool == true) {
                            // Block installing apps if setting is enabled
                            if let blockInstallingApps = args["blockInstallingApps"] as? Bool, blockInstallingApps {
                                store.application.denyAppInstallation = true
                            } else {
                                store.application.denyAppInstallation = false
                            }
                            
                            // Block uninstalling apps if setting is enabled
                            if let blockUninstallingApps = args["blockUninstallingApps"] as? Bool, blockUninstallingApps {
                                store.application.denyAppRemoval = true
                            } else {
                                store.application.denyAppRemoval = false
                            }
                            
                            // Block changing time settings if setting is enabled
                            if let blockChangingTimeSettings = args["blockChangingTimeSettings"] as? Bool, blockChangingTimeSettings {
                                store.dateAndTime.requireAutomaticDateAndTime = true
                            } else {
                                store.dateAndTime.requireAutomaticDateAndTime = false
                            }
                        } else {
                            // If strict mode is not enabled, make sure restrictions are removed
                            store.application.denyAppInstallation = false
                            store.application.denyAppRemoval = false
                            store.dateAndTime.requireAutomaticDateAndTime = false
                        }

                        result(true)
                    } catch {
                        print("Failed to serialize strict mode settings: \(error)")
                        return result(FlutterError(code: "JSON_ENCODE_ERROR",
                                                  message: "Failed to serialize: \(error.localizedDescription)",
                                                  details: nil))
                    }
                } else {
                    print("Error: Invalid arguments for updateStrictModeSettings")
                    result(FlutterError(code: "INVALID_ARGUMENTS",
                                        message: "Invalid arguments for updateStrictModeSettings",
                                        details: nil))
                }
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
