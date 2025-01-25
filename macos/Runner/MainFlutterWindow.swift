import Cocoa
import FlutterMacOS
import UserNotifications
import os.log

class MainFlutterWindow: NSWindow {
  private var blockedApps: Set<String> = []
  private var isMonitoring = false
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
            self.blockedApps = Set(apps.map { $0.lowercased() })  // Store lowercase for case-insensitive comparison
            result(nil)
          } else {
            NSLog("Invalid arguments received for updateBlockedApps")
            result(FlutterError(code: "INVALID_ARGUMENTS",
                              message: "Invalid arguments for updateBlockedApps",
                              details: nil))
          }
        default:
          NSLog("Method not implemented: %@", call.method)
          result(FlutterMethodNotImplemented)
        }
    }
    
    super.awakeFromNib()
    
    // Request notification permissions
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
      if let error = error {
        NSLog("Failed to request notification permission: %@", error.localizedDescription)
      } else {
        NSLog("Notification permission granted: %@", String(granted))
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
    Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
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
    NSWorkspace.shared.runningApplications.forEach { app in
      if let appName = app.localizedName?.lowercased(), blockedApps.contains(appName) {
        checkActiveApplication(app)
      }
    }
  }
  
  private func checkActiveApplication(_ app: NSRunningApplication?) {
    if let app = app,
       let appName = app.localizedName?.lowercased(),
       blockedApps.contains(appName) {
      app.hide()
    }
  }
}
