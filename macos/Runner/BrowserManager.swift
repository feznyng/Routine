import Cocoa

class BrowserManager {
    private let redirectUrl = "https://www.routineblocker.com/blocked.html"
    private let browsers: Dictionary<String, Browser>;
    var siteList: [String] = []
    var allowList = false

    init() {
        var browsers: Dictionary<String, Browser> = Dictionary(uniqueKeysWithValues: [
            "com.google.Chrome",
            "com.microsoft.edgemac",
            "com.brave.Browser",
            "com.operasoftware.Opera"
        ].map { ($0, Chromium(bundleId: $0)) })
        
        browsers["com.apple.Safari"] = Safari()
        
        self.browsers = browsers
    }
    
    func hasAutomationPermission(for bundleId: String) -> Bool {
        guard let browser = browsers[bundleId] else {
            NSLog("[Routine] hasAutomationPermission - could not find browser %@ ", bundleId)
            return false
        }
        
        let canControl = browser.canControl()
        
        NSLog("[Routine] hasAutomationPermission - browser %@ is controllable = %d ", bundleId, canControl)
        
        return canControl
    }

    func requestAutomationPermission(for bundleId: String, openPrefsOnReject: Bool = false) -> Bool {
        guard let browser = browsers[bundleId] else {
            return false
        }
        
        let hasPermission = browser.canControl()

        if !hasPermission && openPrefsOnReject {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
        }
        
        return hasPermission
    }
    
    func isBrowser(bundleId: String) -> Bool {
        return browsers[bundleId] != nil
    }
    
    func checkBrowser(bundleId: String) -> Bool {
        guard let browser = browsers[bundleId], let activeUrl = browser.getUrl() else {
            return false
        }
        
        NSLog("[Routine] Active URL: %@ ", activeUrl)
        NSLog("[Routine] Site List URL: %@ ", siteList)
        
        if activeUrl == "error" {
            return false
        }

        if (siteList.contains { activeUrl.contains($0) } != allowList) {
            browser.redirect(url: redirectUrl)
        }
        
        return true
    }
}
