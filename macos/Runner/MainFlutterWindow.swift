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
    
    // Request notification authorization
    requestNotificationAuthorization()

    // Set up method channel
    methodChannel = FlutterMethodChannel(
      name: "com.routine.applist",
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
      case "saveNativeMessagingHostManifest":
        if let args = call.arguments as? [String: Any],
           let manifestContent = args["content"] as? String {
          saveNativeMessagingHostManifest(content: manifestContent) { success, error in
            if success {
              result(true)
            } else {
              result(FlutterError(code: "SAVE_FAILED", message: error, details: nil))
            }
          }
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected manifest content", details: nil))
        }
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
  
  private func requestNotificationAuthorization() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
      if let error = error {
        NSLog("Failed to request notification permission: %@", error.localizedDescription)
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

      // Queue or send the message depending on Flutter readiness
      let message = (method: "activeApplication", arguments: appPath as Any)
      if isFlutterReady, let channel = methodChannel {
        channel.invokeMethod(message.method, arguments: message.arguments)
      } else {
        pendingMessages.append(message)
      }
    }
  }
  
  private func saveNativeMessagingHostManifest(content: String, completion: @escaping (Bool, String) -> Void) {
    // Create an NSOpenPanel for selecting the save location
    let savePanel = NSOpenPanel()
    savePanel.title = "Browser Extension Setup"
    savePanel.message = "Click 'Save' to install the browser extension. The recommended directory is already selected."
    savePanel.prompt = "Save"
    savePanel.canCreateDirectories = true
    savePanel.canChooseFiles = false
    savePanel.canChooseDirectories = true
    savePanel.allowsMultipleSelection = false
    
    // Set the initial directory to the recommended location
    let homeDir = FileManager.default.homeDirectoryForCurrentUser
    let recommendedPath = homeDir.appendingPathComponent("Library/Application Support/Mozilla/NativeMessagingHosts")
    
    // Check permissions and set up directories
    let fileManager = FileManager.default
    
    if fileManager.fileExists(atPath: recommendedPath.path) {
      savePanel.directoryURL = recommendedPath
    } else {
      // Try to create the directory structure
      do {
        try fileManager.createDirectory(at: recommendedPath, withIntermediateDirectories: true, attributes: nil)
        savePanel.directoryURL = recommendedPath
      } catch {
        // If we can't create it, just start at the home directory
        savePanel.directoryURL = homeDir
      }
    }
    
    // Show the save panel
    savePanel.begin { response in
      if response == .OK, let selectedURL = savePanel.url {
        // Create the file URL
        let fileURL = selectedURL.appendingPathComponent("com.routine.native_messaging.json")
        
        do {
          // Write the content to the file
          try content.write(to: fileURL, atomically: true, encoding: .utf8)
          
          // Verify file was created
          let fileManager = FileManager.default
          if fileManager.fileExists(atPath: fileURL.path) {
            
            // Show a success notification using UserNotifications framework
          let notificationCenter = UNUserNotificationCenter.current()
          let notificationContent = UNMutableNotificationContent()
          notificationContent.title = "Browser Extension Setup Complete"
          notificationContent.body = "The browser extension has been successfully configured. You can now use Routine with your browser."
          
          // Create a request with the notification content
          let request = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: nil)
          
          // Add the request to the notification center
          notificationCenter.add(request) { error in }
          
            completion(true, "")
          } else {
            completion(false, "Failed to verify file was created")
          }
        } catch {
          completion(false, error.localizedDescription)
        }
      } else {
        completion(false, "User cancelled the operation")
      }
    }
  }
}
