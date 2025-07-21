class Safari : Browser {
    init() {
        super.init(
        bundleId: "com.apple.Safari",
       queryScript: """
            tell application id "com.apple.Safari"
                if not running then return "error" -- Safari not running
                try
                    if (count of windows) is 0 then return "error" -- No windows open
                    tell front window
                        if (count of tabs) is 0 then return "error" -- No tabs in front window
                        tell current tab
                            return URL
                        end tell
                    end tell
                on error errMsg number errNum
                    return "error" -- Error occurred
                end try
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
