import Cocoa
import FlutterMacOS
import UserNotifications
import os.log
import ServiceManagement
import Sentry

protocol RoutineManagerDelegate: AnyObject {
    func routineManager(_ manager: RoutineManager, didUpdateBrowserControllability bundleId: String, isControllable: Bool)
}

class RoutineManager {
    let browserManager = BrowserManager()
    private var appList: Set<String> = []
    private var allowList = false
    private var isHiding = false
    private var isMonitoring = false
    weak var delegate: RoutineManagerDelegate?
    
    private var lastApp: NSRunningApplication? = nil
    
    init() {
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
        self.appList = Set(apps.map { $0.lowercased() })
        self.allowList = allow
        
        browserManager.siteList = sites.map { $0.lowercased() };
        browserManager.allowList = allow;
        
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
            lastApp = frontmostApp
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
        let blocked = appList.contains(where: { appPath.hasSuffix($0) }) != allowList
        
        
        if lastApp != app && browserManager.isBrowser(bundleId: bundleId) {
            let isControllable = browserManager.checkBrowser(bundleId: bundleId)
            delegate?.routineManager(self, didUpdateBrowserControllability: bundleId, isControllable: isControllable)
        }
        
        if blocked && !isHiding && bundleId != "com.apple.finder" {
            hideApplication(app)
            return
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
}
