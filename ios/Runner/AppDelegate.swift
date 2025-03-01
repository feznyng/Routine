import Flutter
import UIKit
import Foundation

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
            guard call.method == "updateRoutines" else {
                result(FlutterMethodNotImplemented)
                return
            }
            
            if let args = call.arguments as? [String: Any],
               let routinesJson = args["routines"] as? [[String: Any]] {
                print("Received routines from Dart:")
                print(routinesJson)
                
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: routinesJson)
                    let jsonString = String(data: jsonData, encoding: .utf8)!
                    
                    // Save to UserDefaults in shared app group
                    if let sharedDefaults = UserDefaults(suiteName: "group.routineblocker") {
                        sharedDefaults.set(jsonString, forKey: "routinesData")
                        sharedDefaults.synchronize()
                        print("Saved routines data to shared UserDefaults")
                    } else {
                        print("Failed to access shared UserDefaults")
                    }

                    let decoder = JSONDecoder()
                    let routines = try decoder.decode([Routine].self, from: jsonString.data(using: .utf8)!)
                    
                    print("Created Routines: ")
                    for routine in routines {
                        print("Routine: \(routine.id) \(routine.name) \(routine.apps.count) \(routine.sites.count) \(routine.categories.count)")
                    }
                    
                    self?.manager.update(routines: routines)
                } catch {
                    print("Failed to deserialize: \(error)")
                    return result(FlutterError(code: "JSON_DECODE_ERROR",
                                               message: "Failed to deserialize: \(error.localizedDescription)",
                                               details: nil))
                    
                }
                
                result(true)
            } else {
                print("Error: Invalid arguments for updateRoutines")
                result(FlutterError(code: "INVALID_ARGUMENTS",
                                    message: "Invalid arguments for updateRoutines",
                                    details: nil))
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
