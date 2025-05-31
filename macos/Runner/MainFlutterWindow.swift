import Cocoa
import FlutterMacOS
import UserNotifications
import os.log
import ServiceManagement
import Sentry

class MainFlutterWindow: NSWindow {
  private var appList: Set<String> = []
  private var siteList: [String] = []
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
        NSLog("[Routine] Received updateAppList call")
        if let args = call.arguments as? [String: Any],
          let apps = args["apps"] as? [String], 
          let allowList = args["allowList"] as? Bool,
          let sites = args["sites"] as? [String] {
          NSLog("[Routine] 📱 Apps to monitor: %@", apps)
          NSLog("[Routine] 🌐 Sites to monitor: %@", sites)
          NSLog("[Routine] 🔄 Mode: %@", allowList ? "Allow List" : "Block List")
          
          self.appList = Set(apps.map { $0.lowercased() })  // Store lowercase for case-insensitive comparison
          self.siteList = sites;
          self.allowList = allowList
          
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
    guard let app = app,
          let appPath = app.bundleURL?.path.lowercased() else { return }

    if let executablePath = Bundle.main.executablePath {
      if (executablePath.lowercased().contains(appPath.lowercased())) {
        return
      }
    }
    
    let bundleId = app.bundleIdentifier ?? ""
    let isAllowed = allowList ? appList.contains(appPath) : !appList.contains(appPath)

    if !isAllowed && !isHiding && bundleId != "com.apple.finder" {
      hideApplication(app)
      return
    }

    if bundleId == "com.apple.Safari" {
      checkSafariURL()
    }
  }

  private func hideApplication(_ app: NSRunningApplication) {
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

  private func checkSafariURL() {
    NSLog("[Routine] Starting Safari URL poll...")
    NSLog("[Routine] Current siteList: %@", siteList)
    NSLog("[Routine] Allow List Mode: %@", allowList ? "true" : "false")
    
    let getUrlScript = """
    tell application id "com.apple.Safari"
        if not running then return "" -- Safari not running
        try
            if (count of windows) is 0 then return "" -- No windows open
            tell front window
                if (count of tabs) is 0 then return "" -- No tabs in front window
                tell current tab
                    return URL
                end tell
            end tell
        on error errMsg number errNum
            return "" -- Error occurred
        end try
    end tell
    """
    
    var error: NSDictionary?
    if let script = NSAppleScript(source: getUrlScript) {
        NSLog("[Routine] Executing AppleScript to get Safari URL...")
        let output = script.executeAndReturnError(&error)
        
        if let errorDict = error {
            let errorMessage = errorDict[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error"
            let errorNumber = errorDict[NSAppleScript.errorNumber] as? NSNumber ?? -1
            NSLog("[Routine] ❌ Error executing AppleScript for Safari URL: %@ (Number: %@)", errorMessage, errorNumber)
            return
        }
        
        guard let currentUrl = output.stringValue, !currentUrl.isEmpty else {
            NSLog("[Routine] No valid URL found (empty or Safari not active)")
            return
        }
        
        NSLog("[Routine] Current Safari URL: %@", currentUrl)
        
        // Check if the current URL matches any site in the siteList
        var matchedSite: String? = nil
        let shouldBlock = siteList.contains { site in
            let matches = currentUrl.lowercased().contains(site.lowercased())
            if matches {
                matchedSite = site
                NSLog("[Routine] 🎯 URL matched site in list: %@", site)
            }
            return matches
        }
        
        NSLog("[Routine] URL check result - Should Block: %@", shouldBlock ? "true" : "false")
        
        // Block if: (allowList is false AND site is in list) OR (allowList is true AND site is NOT in list)
        if shouldBlock != allowList {
            NSLog("[Routine] 🚫 Blocking required. Matched site: %@, Allow List: %@", matchedSite ?? "N/A", allowList ? "true" : "false")
            
            // Redirect to a blocking page
            let redirectScript = """
            tell application id "com.apple.Safari"
                tell front window
                    tell current tab
                        set URL to "https://www.routineblocker.com/blocked.html"
                    end tell
                end tell
            end tell
            """
            
            if let redirectAppleScript = NSAppleScript(source: redirectScript) {
                NSLog("[Routine] Executing redirect AppleScript...")
                redirectAppleScript.executeAndReturnError(&error)
                
                if let errorDict = error {
                    NSLog("[Routine] ❌ Error redirecting Safari: %@", errorDict[NSAppleScript.errorMessage] as? String ?? "Unknown error")
                } else {
                    NSLog("[Routine] ✅ Successfully blocked access to: %@", currentUrl)
                }
            }
        } else {
            NSLog("[Routine] ✅ Access allowed to: %@", currentUrl)
        }
    } else {
        NSLog("[Routine] ❌ Failed to initialize AppleScript for Safari URL.")
    }
    
    NSLog("[Routine] Safari URL poll completed.")
  }
}
