import Cocoa
import FlutterMacOS
import UserNotifications
import os.log
import ServiceManagement
import Sentry

class MainFlutterWindow: NSWindow {
  private var appList: Set<String> = []
  private var isMonitoring = false
  private var methodChannel: FlutterMethodChannel?
  private var allowList = false
  private var isFlutterReady = false
  private var pendingMessages: [(String, Any)] = []
  private var isHiding = false

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    
    requestNotificationAuthorization()

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
          let apps = args["apps"] as? [String], let allowList = args["allowList"] as? Bool {
          self.appList = Set(apps.map { $0.lowercased() })  // Store lowercase for case-insensitive comparison
          self.allowList = allowList
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
      default:
        NSLog("Method not implemented: %@", call.method)
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()

    startMonitoring()

    // Check initial state
    checkActiveApplication(NSWorkspace.shared.frontmostApplication)
  }

  deinit {
    stopMonitoring()
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

  private func startMonitoring() {
    guard !isMonitoring else { return }
    isMonitoring = true

    let workspace = NSWorkspace.shared
    let notificationCenter = workspace.notificationCenter

    // Monitor for application activation
    notificationCenter.addObserver(
      self,
      selector: #selector(activeAppDidChange),
      name: NSWorkspace.didActivateApplicationNotification,
      object: nil
    )

    // Monitor for application unhiding
    notificationCenter.addObserver(
      self,
      selector: #selector(appDidUnhide),
      name: NSWorkspace.didUnhideApplicationNotification,
      object: nil
    )

    // Monitor for application launching
    notificationCenter.addObserver(
      self,
      selector: #selector(appDidLaunch),
      name: NSWorkspace.didLaunchApplicationNotification,
      object: nil
    )
    
    // Monitor for system wake
    NSWorkspace.shared.notificationCenter.addObserver(
      self,
      selector: #selector(systemDidWake),
      name: NSWorkspace.didWakeNotification,
      object: nil
    )

    // Start periodic check
    Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
      self?.checkFrontmostApp()
    }
  }

  private func stopMonitoring() {
    guard isMonitoring else { return }
    isMonitoring = false
    NSWorkspace.shared.notificationCenter.removeObserver(self)
  }

  @objc private func activeAppDidChange(_ notification: Notification) {
    if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
      checkActiveApplication(app)
    }
  }

  @objc private func appDidUnhide(_ notification: Notification) {
    if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
      checkActiveApplication(app)
    }
  }

  @objc private func appDidLaunch(_ notification: Notification) {
    if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
      checkActiveApplication(app)
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

  private func checkFrontmostApp() {
    if let frontmostApp = NSWorkspace.shared.frontmostApplication {
      checkActiveApplication(frontmostApp)
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

  private func checkActiveApplication(_ app: NSRunningApplication?) {
    if let app = app,
       let appPath = app.bundleURL?.path.lowercased() {

      if let executablePath = Bundle.main.executablePath {
        if (executablePath.lowercased().contains(appPath.lowercased())) {
          return
        }
      }
      
      let isAllowed = allowList ? appList.contains(appPath) : !appList.contains(appPath)

      if !isAllowed && !isHiding && app.localizedName?.lowercased() != "finder" {
        isHiding = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
          // Find and activate Finder
          if let finder = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName?.lowercased() == "finder" }) {
            finder.activate(options: .activateIgnoringOtherApps)
          }
          app.hide()
          self?.isHiding = false
        }
      }
    }
  }
}
