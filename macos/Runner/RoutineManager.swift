import Cocoa
import FlutterMacOS
import UserNotifications
import os.log
import ServiceManagement
import Sentry

class RoutineManager {
    private var appList: Set<String> = []
    private var siteList: [String] = []
    private var allowList = false
    private var isHiding = false
    private var isMonitoring = false
    
    private let chromiumBundleIds = [
        "com.google.Chrome",
        "com.microsoft.edgemac",
        "com.brave.Browser",
        "com.operasoftware.Opera"
    ]
    
    init() {
        startMonitoring()
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
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkFrontmostApp()
        }
    }
    
    private func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    func updateList(apps: [String], sites: [String], allow: Bool) {
        self.appList = Set(apps.map { $0.lowercased() })  // Store lowercase for case-insensitive comparison
        self.siteList = sites;
        self.allowList = allow
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
        } else if chromiumBundleIds.contains(bundleId) {
            checkChromiumURL(bundleId: bundleId)
        }
    }
    
    private func checkFrontmostApp() {
        if let frontmostApp = NSWorkspace.shared.frontmostApplication {
            checkActiveApplication(frontmostApp)
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
        let getUrlScript = """
    tell application id "com.apple.Safari"
        if not running then return "not running" -- Safari not running
        try
            if (count of windows) is 0 then return "no windows" -- No windows open
            tell front window
                if (count of tabs) is 0 then return "no tabs" -- No tabs in front window
                tell current tab
                    return URL
                end tell
            end tell
        on error errMsg number errNum
            return errMsg -- Error occurred
        end try
    end tell
    """
        
        var error: NSDictionary?
        if let script = NSAppleScript(source: getUrlScript) {
            NSLog("[Routine] Executing AppleScript to get Safari URL...")
            let output = script.executeAndReturnError(&error)
            NSLog("[Routine] Raw output = %@", output)

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
    
    private func checkChromiumURL(bundleId: String) {
        NSLog("[Routine] Starting Chromium URL poll for %@...", bundleId)
        NSLog("[Routine] Current siteList: %@", siteList)
        NSLog("[Routine] Allow List Mode: %@", allowList ? "true" : "false")
        
        let getUrlScript = """
    tell application id "\(bundleId)"
        if not running then return ""
        try
            if (count of windows) is 0 then return ""
            tell active tab of front window
                return URL
            end tell
        on error errMsg number errNum
            return "" -- Error occurred
        end try
    end tell
    """
        
        var error: NSDictionary?
        if let script = NSAppleScript(source: getUrlScript) {
            NSLog("[Routine] Executing AppleScript to get Chromium URL for %@...", bundleId)
            let output = script.executeAndReturnError(&error)
            
            if let errorDict = error {
                let errorMessage = errorDict[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error"
                let errorNumber = errorDict[NSAppleScript.errorNumber] as? NSNumber ?? -1
                NSLog("[Routine] ❌ Error executing AppleScript for %@ URL: %@ (Number: %@)", bundleId, errorMessage, errorNumber)
                return
            }
            
            guard let currentUrl = output.stringValue, !currentUrl.isEmpty else {
                NSLog("[Routine] No valid URL found for %@ (empty or browser not active/no tabs)", bundleId)
                return
            }
            
            NSLog("[Routine] Current %@ URL: %@", bundleId, currentUrl)
            
            var matchedSite: String? = nil
            let shouldBlock = siteList.contains { site in
                let matches = currentUrl.lowercased().contains(site.lowercased())
                if matches {
                    matchedSite = site
                    NSLog("[Routine] 🎯 URL matched site in list for %@: %@", bundleId, site)
                }
                return matches
            }
            
            NSLog("[Routine] URL check result for %@ - Should Block: %@", bundleId, shouldBlock ? "true" : "false")
            
            if shouldBlock != allowList {
                NSLog("[Routine] 🚫 Blocking required for %@. Matched site: %@, Allow List: %@", bundleId, matchedSite ?? "N/A", allowList ? "true" : "false")
                
                let redirectScript = """
            tell application id "\(bundleId)"
                tell active tab of front window
                    set URL to "https://www.routineblocker.com/blocked.html"
                end tell
            end tell
            """
                
                if let redirectAppleScript = NSAppleScript(source: redirectScript) {
                    NSLog("[Routine] Executing redirect AppleScript for %@...", bundleId)
                    redirectAppleScript.executeAndReturnError(&error)
                    
                    if let errorDict = error {
                        NSLog("[Routine] ❌ Error redirecting %@: %@", bundleId, errorDict[NSAppleScript.errorMessage] as? String ?? "Unknown error")
                    } else {
                        NSLog("[Routine] ✅ Successfully blocked access for %@ to: %@", bundleId, currentUrl)
                    }
                }
            } else {
                NSLog("[Routine] ✅ Access allowed for %@ to: %@", bundleId, currentUrl)
            }
        } else {
            NSLog("[Routine] ❌ Failed to initialize AppleScript for %@ URL.", bundleId)
        }
        
        NSLog("[Routine] Chromium URL poll for %@ completed.", bundleId)
    }
    
}
