import Cocoa

/// Check if we have automation permission for a specific app
/// - Parameter bundleId: The bundle identifier of the target app (e.g. "com.apple.Safari")
/// - Returns: true if we have permission, false otherwise
func hasAutomationPermission(for bundleId: String) -> Bool {
    let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
    let options = [trusted: false] as CFDictionary
    return AXIsProcessTrustedWithOptions(options)
}

/// Request automation permission for a specific app
/// - Parameters:
///   - bundleId: The bundle identifier of the target app (e.g. "com.apple.Safari")
///   - openPrefsOnReject: If true, opens System Settings > Privacy & Security > Automation when permission is rejected
/// - Returns: true if permission was granted, false otherwise
func requestAutomationPermission(for bundleId: String, openPrefsOnReject: Bool = false) -> Bool {
    let trusted = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
    let options = [trusted: true] as CFDictionary
    let hasPermission = AXIsProcessTrustedWithOptions(options)
    
    if !hasPermission && openPrefsOnReject {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
    }
    
    return hasPermission
}

class Browser {
    private let bundleId: String
    private let queryScript: String
    private let redirectScript: String
    
    init(bundleId: String, queryScript: String, redirectScript: String) {
        self.bundleId = bundleId
        self.queryScript = queryScript
        self.redirectScript = redirectScript
    }
    
    func getUrl() -> String? {
        var error: NSDictionary?
        if let script = NSAppleScript(source: queryScript) {
            NSLog("[Routine] Executing AppleScript to get \(bundleId) URL...")
            let output = script.executeAndReturnError(&error)
            
            if let errorDict = error {
                let errorMessage = errorDict[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error"
                let errorNumber = errorDict[NSAppleScript.errorNumber] as? NSNumber ?? -1
                NSLog("[Routine] ❌ Error executing AppleScript for \(bundleId) URL: %@ (Number: %@)", errorMessage, errorNumber)
                return nil
            }
            
            return output.stringValue
        }
        
        return nil
    }
    
    func redirect(url: String) {
        if let redirectAppleScript = NSAppleScript(source: String(format: redirectScript, url)) {
            NSLog("[Routine] Executing redirect AppleScript...")
            var error: NSDictionary?
            redirectAppleScript.executeAndReturnError(&error)
            
            if let errorDict = error {
                NSLog("[Routine] ❌ Error redirecting \(bundleId): %@", errorDict[NSAppleScript.errorMessage] as? String ?? "Unknown error")
            } else {
                NSLog("[Routine] ✅ Successfully redirected to: %@", url)
            }
        }
    }
}

