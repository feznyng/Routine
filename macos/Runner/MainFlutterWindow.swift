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
          
          // Extract binary data and filename if provided
          var binary: Data? = nil
          let binaryFilename = args["binaryFilename"] as? String
          
          // Check if binary data is provided and convert it to Data
          if let binaryList = args["binary"] as? [UInt8] {
            binary = Data(binaryList)
            NSLog("Received binary data: %d bytes", binary!.count)
          } else if let binaryData = args["binary"] as? FlutterStandardTypedData {
            binary = binaryData.data
            NSLog("Received binary data as FlutterStandardTypedData: %d bytes", binary!.count)
          }
          
          NSLog("Saving manifest with binary: %@", binary != nil ? "Yes" : "No")
          if let filename = binaryFilename {
            NSLog("Binary filename: %@", filename)
          }
          
          saveNativeMessagingHostManifest(content: manifestContent, binary: binary, binaryFilename: binaryFilename) { success, error in
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
          NSLog("[Routine] Error sending systemWake event: %@", error.message ?? "Unknown error")
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
  
  private func saveNativeMessagingHostManifest(content: String, binary: Data? = nil, binaryFilename: String? = nil, completion: @escaping (Bool, String) -> Void) {
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
        // If binary data is provided, also copy the binary to the same directory
        // var binaryPath = ""
        
        // if let binaryData = binary, let filename = binaryFilename {
        //   let binaryURL = selectedURL.appendingPathComponent(filename)
        //   binaryPath = binaryURL.path
        //   NSLog("Installing binary to: %@", binaryPath)
          
        //   do {
        //     // Check if binary already exists
        //     let fileExists = fileManager.fileExists(atPath: binaryURL.path)
        //     if fileExists {
        //       // If it exists, try to remove it first to avoid permission issues
        //       NSLog("Binary already exists, attempting to replace it")
        //       try fileManager.removeItem(at: binaryURL)
        //       NSLog("Successfully removed existing binary")
        //     }
            
        //     // Write the binary to the selected directory
        //     try binaryData.write(to: binaryURL)
        //     NSLog("Binary written to: %@, size: %d bytes", binaryURL.path, binaryData.count)
            
        //     // Make the binary executable
        //     let chmodProcess = Process()
        //     chmodProcess.executableURL = URL(fileURLWithPath: "/bin/chmod")
        //     chmodProcess.arguments = ["+x", binaryURL.path]
        //     try chmodProcess.run()
        //     chmodProcess.waitUntilExit()
        //     NSLog("Made binary executable with chmod +x")
            
        //     // Remove quarantine attribute to prevent Gatekeeper blocking
        //     do {
        //       // First check if the quarantine attribute exists
        //       let checkProcess = Process()
        //       checkProcess.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        //       checkProcess.arguments = ["-l", binaryURL.path]
              
        //       let checkPipe = Pipe()
        //       checkProcess.standardOutput = checkPipe
        //       try checkProcess.run()
        //       checkProcess.waitUntilExit()
              
        //       let checkData = checkPipe.fileHandleForReading.readDataToEndOfFile()
        //       let output = String(data: checkData, encoding: .utf8) ?? ""
              
        //       if output.contains("com.apple.quarantine") {
        //         let xattrProcess = Process()
        //         xattrProcess.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        //         xattrProcess.arguments = ["-d", "com.apple.quarantine", binaryURL.path]
        //         try xattrProcess.run()
        //         xattrProcess.waitUntilExit()
        //         NSLog("Removed quarantine attribute from binary")
        //       } else {
        //         NSLog("No quarantine attribute found on binary")
        //       }
        //     } catch {
        //       NSLog("Error handling quarantine attribute: %@", error.localizedDescription)
        //       // Continue anyway, as this is not critical
        //     }
            
        //     // Check if the binary was created successfully
        //     if !fileManager.fileExists(atPath: binaryURL.path) {
        //       NSLog("Failed to verify binary was created at: %@", binaryURL.path)
        //       completion(false, "Failed to install binary")
        //       return
        //     }
            
        //     NSLog("Binary installed successfully at: %@", binaryURL.path)
        //   } catch {
        //     NSLog("Error installing binary: %@", error.localizedDescription)
        //     completion(false, "Failed to install binary: \(error.localizedDescription)")
        //     return
        //   }
        // }
        
        // Create the file URL for the manifest
        let binaryUrl = selectedURL.appendingPathComponent("routine-nmh")
        let fileURL = selectedURL.appendingPathComponent("com.routine.native_messaging.json")
        
        do {
          // If we have a binary, update the manifest content with the correct path
          var updatedContent = content
          NSLog("Updating manifest with binary path: %@", binaryUrl.path)
          updatedContent = content.replacingOccurrences(of: "PLACEHOLDER_PATH", with: binaryUrl.path)
          
          // Write the content to the file
          try updatedContent.write(to: fileURL, atomically: true, encoding: .utf8)
          NSLog("Manifest written to: %@", fileURL.path)
          
          // Verify file was created
          let fileManager = FileManager.default
          if fileManager.fileExists(atPath: fileURL.path) {
            
            // Show a success notification using UserNotifications framework
          let notificationCenter = UNUserNotificationCenter.current()
          let notificationContent = UNMutableNotificationContent()
          notificationContent.title = "Browser Extension Setup Complete"
          notificationContent.body = "The browser extension has been successfully configured. You can now use Routine with your browser.\n\nNote: If you see a security warning about 'routine-nmh', you may need to go to System Preferences > Security & Privacy and click 'Allow Anyway'."
          
          // Create a request with the notification content
          let request = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: nil)
          
          // Add the request to the notification center
          notificationCenter.add(request) { error in }
          
          // Also log instructions for handling security warnings
          NSLog("IMPORTANT: If macOS blocks the binary due to security restrictions, the user may need to:")
          NSLog("1. Open System Preferences > Security & Privacy")
          NSLog("2. Look for a message about 'routine-nmh' being blocked")
          NSLog("3. Click 'Allow Anyway' or 'Open Anyway'")
          
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
