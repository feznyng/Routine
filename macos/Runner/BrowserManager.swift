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
    
    static func hasAutomationPermission(for bundleId: String) -> Bool {
        let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let options = [trusted: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func requestAutomationPermission(for bundleId: String, openPrefsOnReject: Bool = false) -> Bool {
        let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        let options = [trusted: true] as CFDictionary
        let hasPermission = AXIsProcessTrustedWithOptions(options)
        
        if !hasPermission && openPrefsOnReject {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
        }
        
        return hasPermission
    }
    
    func checkBrowser(bundleId: String) {
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
