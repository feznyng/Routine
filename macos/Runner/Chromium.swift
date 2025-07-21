class Chromium : Browser {
    init(bundleId: String) {
        super.init(
        bundleId: bundleId,
       queryScript: """
        tell application id "\(bundleId)"
            if not running then return "error"
            try
                if (count of windows) is 0 then return ""
                tell active tab of front window
                    return URL
                end tell
            on error errMsg number errNum
                return "error" -- Error occurred
            end try
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
