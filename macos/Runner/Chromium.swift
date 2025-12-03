class Chromium : Browser {
    init(bundleId: String) {
        super.init(
        bundleId: bundleId,
       queryScript: """
        tell application id "\(bundleId)"
            if not running then return "error"
            if (count of windows) is 0 then return "error"
            tell active tab of front window
                return URL
            end tell
        end tell
    """, redirectScript: """
    tell application id "\(bundleId)"
        tell active tab of front window
            set URL to "%@"
        end tell
    end tell
    """)
    }
}
