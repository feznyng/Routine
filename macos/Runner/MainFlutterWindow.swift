import Cocoa
import FlutterMacOS
import UserNotifications

class MainFlutterWindow: NSWindow {
  let blockedApps = ["discord"]
  private var isMonitoring = false
  private var lastNotificationTimes: [String: Date] = [:]
  private let notificationDebounceInterval: TimeInterval = 5.0 // 5 seconds
  
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    RegisterGeneratedPlugins(registry: flutterViewController)
    
    super.awakeFromNib()
    
    // Request notification permissions
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
      if let error = error {
        print("Error requesting notification permission: \(error)")
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
      showBlockNotificationIfNeeded(appName: app.localizedName ?? appName)
    }
  }
  
  private func showBlockNotificationIfNeeded(appName: String) {
    let now = Date()
    if let lastTime = lastNotificationTimes[appName] {
      let timeSinceLastNotification = now.timeIntervalSince(lastTime)
      if timeSinceLastNotification < notificationDebounceInterval {
        return // Skip notification if we're within the debounce interval
      }
    }
    
    // Update the last notification time
    lastNotificationTimes[appName] = now
    
    // Show the notification
    let content = UNMutableNotificationContent()
    content.title = "App Blocked"
    content.body = "\(appName) was blocked"
    content.sound = .default
    
    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("Error showing notification: \(error)")
      }
    }
  }
}
