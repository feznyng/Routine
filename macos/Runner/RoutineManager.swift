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
    
    private let redirectUrl = "https://www.routineblocker.com/blocked.html"
    private let browsers: Dictionary<String, Browser>;
    
    init() {
        var browsers: Dictionary<String, Browser> = Dictionary(uniqueKeysWithValues: [
            "com.google.Chrome",
            "com.microsoft.edgemac",
            "com.brave.Browser",
            "com.operasoftware.Opera"
        ].map { ($0, Chromium(bundleId: $0)) })
        
        browsers["com.apple.Safari"] = Safari()
        
        self.browsers = browsers
        
        startMonitoring()
    }
    
    private func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        let workspace = NSWorkspace.shared
        let notificationCenter = workspace.notificationCenter
        
        notificationCenter.addObserver(
            self,
            selector: #selector(activeAppDidChange),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        
        notificationCenter.addObserver(
            self,
            selector: #selector(appDidUnhide),
            name: NSWorkspace.didUnhideApplicationNotification,
            object: nil
        )
        
        notificationCenter.addObserver(
            self,
            selector: #selector(appDidLaunch),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
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
        self.siteList = sites.map { $0.lowercased() };
        self.allowList = allow
        self.checkFrontmostApp()
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
    
    private func checkActiveApplication(_ app: NSRunningApplication?) {
        guard let app = app,
              let appPath = app.bundleURL?.path.lowercased() else { return }
        
        if let executablePath = Bundle.main.executablePath {
            if (executablePath.lowercased().contains(appPath.lowercased())) {
                return
            }
        }
        
        let bundleId = app.bundleIdentifier ?? ""
        let blocked = appList.contains(appPath) != allowList
        
        if blocked && !isHiding && bundleId != "com.apple.finder" {
            hideApplication(app)
            return
        }
        
        checkBrowser(bundleId: bundleId)
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
    
    private func checkBrowser(bundleId: String) {
        guard let browser = browsers[bundleId], let activeUrl = browser.getUrl() else {
            return
        }
        
        NSLog("[Routine] Active URL: %@ ", activeUrl)
        NSLog("[Routine] Site List URL: %@ ", siteList)

        if (siteList.contains { activeUrl.contains($0) } != allowList) {
            browser.redirect(url: redirectUrl)
        }
    }
}
