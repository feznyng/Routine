import Cocoa
import FlutterMacOS
import UserNotifications
import os.log
import ServiceManagement


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

    // Set up method channel
    methodChannel = FlutterMethodChannel(
      name: "com.routine.applist",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    methodChannel?.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }

      switch call.method {
      case "updateAppList":
        if let args = call.arguments as? [String: Any],
          let apps = args["apps"] as? [String], let allowList = args["allowList"] as? Bool {
          NSLog("updating app list to: \(apps), allowList: \(allowList)")
          self.appList = Set(apps.map { $0.lowercased() })  // Store lowercase for case-insensitive comparison
          self.allowList = allowList
          result(nil)
        } else {
          NSLog("Invalid arguments received for updateappList")
          result(FlutterError(code: "INVALID_ARGUMENTS",
                              message: "Invalid arguments for updateappList",
                              details: nil))
        }
      case "setappList":
        if let apps = call.arguments as? [String] {
          self.appList = Set(apps.map { $0.lowercased() })
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected array of strings", details: nil))
        }
      case "setAllowList":
        if let allow = call.arguments as? Bool {
          self.allowList = allow
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected boolean", details: nil))
        }
      case "engineReady":
        self.isFlutterReady = true
        // Process any pending messages
        self.processPendingMessages()

        let isEnabled = SMAppService.mainApp.status == .enabled
        NSLog("App starts at login = \(isEnabled)")

        result(true)
          
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
      
      let isEnabled = SMAppService.mainApp.status == .enabled
      NSLog("App starts at login = \(isEnabled)")
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

  private func checkActiveApplication(_ app: NSRunningApplication?) {
    if let app = app,
       let appName = app.localizedName?.lowercased() {
      
      let isAllowed = allowList ? appList.contains(appName) : !appList.contains(appName)
      
      if !isAllowed && !isHiding && appName != "finder" {
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

      // Queue or send the message depending on Flutter readiness
      let message = (method: "activeApplication", arguments: appName as Any)
      if isFlutterReady, let channel = methodChannel {
        channel.invokeMethod(message.method, arguments: message.arguments)
      } else {
        pendingMessages.append(message)
      }
    }
  }
}
