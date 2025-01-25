import Cocoa
import FlutterMacOS
import UserNotifications
import os.log

class MainFlutterWindow: NSWindow {
  private var blockedApps: [String] = []
  private var isMonitoring = false
  private var lastNotificationTimes: [String: Date] = [:]
  private let notificationDebounceInterval: TimeInterval = 5.0 // 5 seconds
  private var methodChannel: FlutterMethodChannel?
  
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    RegisterGeneratedPlugins(registry: flutterViewController)
    
    // Set up method channel
    methodChannel = FlutterMethodChannel(
      name: "com.routine.blockedapps",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    
    methodChannel?.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      
      switch call.method {
      case "updateBlockedApps":
        if let args = call.arguments as? [String: Any],
           let apps = args["apps"] as? [String] {
          self.blockedApps = apps
          os_log("Updated blocked apps list: %{public}@", log: OSLog.default, type: .info, apps.description)
          result(nil)
        } else {
          os_log("Invalid arguments received for updateBlockedApps", log: OSLog.default, type: .error)
          result(FlutterError(code: "INVALID_ARGUMENTS",
                            message: "Invalid arguments for updateBlockedApps",
                            details: nil))
        }
      default:
        os_log("Method not implemented: %{public}@", log: OSLog.default, type: .info, call.method)
        result(FlutterMethodNotImplemented)
      }
    }
    
    super.awakeFromNib()
    
    // Request notification permissions
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
      if let error = error {
        os_log("Failed to request notification permission: %{public}@", log: OSLog.default, type: .error, error.localizedDescription)
      } else {
        os_log("Notification permission granted: %{public}@", log: OSLog.default, type: .info, String(granted))
      }
    }
    
    startMonitoring()
    
    // Check initial state
    checkActiveApplication(NSWorkspace.shared.frontmostApplication)
  }
  
  deinit {
    stopMonitoring()
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
    
    // Start periodic check
    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
      self?.checkAllBlockedApps()
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
  
  private func checkAllBlockedApps() {
    for appName in blockedApps {
      NSWorkspace.shared.runningApplications.forEach { app in
        if app.localizedName?.lowercased() == appName {
          checkActiveApplication(app)
        }
      }
    }
  }
  
  private func checkActiveApplication(_ app: NSRunningApplication?) {
    if let app = app, let appName = app.localizedName?.lowercased(), blockedApps.contains(appName) {
      app.hide()
      os_log("Hiding blocked application: %{public}@", log: OSLog.default, type: .debug, appName)
    }
  }
}
