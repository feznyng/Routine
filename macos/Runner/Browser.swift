import Cocoa

class Browser {
    private let bundleId: String
    private let queryScript: String
    private let redirectScript: String
    
    init(bundleId: String, queryScript: String, redirectScript: String) {
        self.bundleId = bundleId
        self.queryScript = queryScript
        self.redirectScript = redirectScript
    }
    
    func canControl() -> Bool {
        let url = getUrl()
        return url != "error" && url != nil;
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
            
            NSLog("[Routine] retrieved url \(output.stringValue)")
            
            return output.stringValue
        } else {
            NSLog("[Routine] failed to create apple script")
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

