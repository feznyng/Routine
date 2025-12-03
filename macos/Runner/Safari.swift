class Safari : Browser {
    init() {
        super.init(
        bundleId: "com.apple.Safari",
       queryScript: """
            tell application id "com.apple.Safari"
                if not running then return "error" -- Safari not running
                if (count of windows) is 0 then return "error" -- No windows open
                tell front window
                    if (count of tabs) is 0 then return "error" -- No tabs in front window
                    tell current tab
                        return URL
                    end tell
                end tell
            end tell
    """, redirectScript: """
        tell application id "com.apple.Safari"
            tell front window
                tell current tab
                    set URL to "%@"
                end tell
            end tell
        end tell
    """)
    }
    
}
