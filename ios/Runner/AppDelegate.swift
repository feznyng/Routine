import Flutter
import UIKit

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
          
          var routines: [Routine] = []
          for routineJson in routinesJson {
              routines.append(Routine(entity: routineJson))
          }
          
          self?.manager.update(routines: routines)
          
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
