import Cocoa
import FlutterMacOS
import UserNotifications
import os.log
import ServiceManagement
import Sentry

class MainFlutterWindow: NSWindow {
    private var methodChannel: FlutterMethodChannel?
    private var isFlutterReady = false
    private var pendingMessages: [(String, Any)] = []
    private let routineManager = RoutineManager()
    
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)
        
        RegisterGeneratedPlugins(registry: flutterViewController)
        
        requestNotificationAuthorization()
        
        // Set up RoutineManager delegate
        routineManager.delegate = self
        
        methodChannel = FlutterMethodChannel(
            name: "com.solidsoft.routine",
            binaryMessenger: flutterViewController.engine.binaryMessenger
        )
        
        methodChannel?.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            
            switch call.method {
            case "engineReady":
                self.isFlutterReady = true
                // Process any pending messages
                self.processPendingMessages()
                result(true)
            case "updateAppList":
                if let args = call.arguments as? [String: Any],
                   let apps = args["apps"] as? [String],
                   let allowList = args["allowList"] as? Bool,
                   let sites = args["sites"] as? [String] {
                    routineManager.updateList(apps: apps, sites: sites, allow: allowList)
                    NSLog("[Routine] ✅ Successfully updated app and site lists")
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS",
                                        message: "Invalid arguments for updateappList",
                                        details: nil))
                }
            case "setStartOnLogin":
                if let allow = call.arguments as? Bool {
                    setStartOnLogin(enabled: allow)
                    result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected boolean", details: nil))
                }
            case "getStartOnLogin":
                let isEnabled = SMAppService.mainApp.status == .enabled
                result(isEnabled)
            case "hasAutomationPermission":
                if let bundleId = call.arguments as? String {
                    result(routineManager.browserManager.hasAutomationPermission(for: bundleId))
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS",
                                      message: "Expected bundle ID string",
                                      details: nil))
                }
            case "requestAutomationPermission":
                if let args = call.arguments as? [String: Any],
                   let bundleId = args["bundleId"] as? String,
                   let openPrefsOnReject = args["openPrefsOnReject"] as? Bool {
                    result(routineManager.browserManager.requestAutomationPermission(for: bundleId, openPrefsOnReject: openPrefsOnReject))
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS",
                                      message: "Expected bundleId and openPrefsOnReject arguments",
                                      details: nil))
                }
            default:
                NSLog("Method not implemented: %@", call.method)
                result(FlutterMethodNotImplemented)
            }
        }
        
        super.awakeFromNib()
        
        // Monitor for system wake
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    private func setStartOnLogin(enabled: Bool) {
        if enabled {
            do {
                try SMAppService.mainApp.register()
            } catch {
                NSLog("Failed to register app for launch at login: \(error)")
            }
        } else {
            do {
                try SMAppService.mainApp.unregister()
            } catch {
                NSLog("Failed to unregister app for launch at login: \(error)")
            }
        }
    }
    
    @objc private func systemDidWake(_ notification: Notification) {
        NSLog("[Routine] System wake event detected in macOS")
        
        // Get current timestamp for logging
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let timestamp = dateFormatter.string(from: Date())
        NSLog("[Routine] System wake at: %@", timestamp)
        
        // Notify Flutter that the system woke from sleep
        if isFlutterReady, let channel = methodChannel {
            NSLog("[Routine] Sending systemWake event to Flutter")
            channel.invokeMethod("systemWake", arguments: ["timestamp": timestamp]) { result in
                if let error = result as? FlutterError {
                    let errorCode = error.code
                    let errorMessage = error.message ?? "Unknown error"
                    let errorDetails = error.details as? String ?? "No details"
                    
                    NSLog("[Routine] Error sending systemWake event: code=%@, message=%@, details=%@", errorCode, errorMessage, errorDetails)
                    
                    // Track error with Sentry using error capture
                    if SentrySDK.isEnabled {
                        // Create a custom error object
                        let error = NSError(
                            domain: "com.routine.app.methodchannel",
                            code: Int(errorCode) ?? -1,
                            userInfo: [
                                NSLocalizedDescriptionKey: errorMessage,
                                "details": errorDetails,
                                "timestamp": timestamp,
                                "method": "systemWake"
                            ]
                        )
                        
                        // Capture the error with additional context
                        SentrySDK.capture(error: error) { scope in
                            scope.setTag(value: "MainFlutterWindow", key: "component")
                            scope.setTag(value: "systemWake", key: "method")
                            scope.setExtra(value: timestamp, key: "timestamp")
                        }
                    }
                } else {
                    NSLog("[Routine] Successfully sent systemWake event to Flutter")
                }
            }
        } else {
            // Queue the message if Flutter is not ready yet
            NSLog("[Routine] Flutter not ready, queueing systemWake event")
            pendingMessages.append(("systemWake", ["timestamp": timestamp]))
        }
    }
    
    private func processPendingMessages() {
        guard isFlutterReady, let channel = methodChannel else { return }
        
        for (method, arguments) in pendingMessages {
            channel.invokeMethod(method, arguments: arguments)
        }
        pendingMessages.removeAll()
    }
    
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                NSLog("Failed to request notification permission: %@", error.localizedDescription)
                SentrySDK.capture(error: error) { (scope) in
                    scope.setTag(value: "failed to request notification permission", key: "method")
                }
            } else {
                NSLog("Notification permission granted: %@", String(granted))
            }
        }
    }
}

// MARK: - RoutineManagerDelegate
extension MainFlutterWindow: RoutineManagerDelegate {
    func routineManager(_ manager: RoutineManager, didUpdateBrowserControllability bundleId: String, isControllable: Bool) {
        let message = [
            "bundleId": bundleId,
            "isControllable": isControllable
        ] as [String : Any]
        
        NSLog("[Routine] Sending browserControllabilityChanged event")
        
        if isFlutterReady, let channel = methodChannel {
            channel.invokeMethod("browserControllabilityChanged", arguments: message) { result in
                if let error = result as? FlutterError {
                    NSLog("[Routine] Error sending browserControllabilityChanged: %@", error.message ?? "Unknown error")
                }
            }
        }
    }
}
