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

protocol Browser {
    func getUrl() -> String?
    func redirect(url: String)
}

