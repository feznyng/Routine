// Prints the CGWindowID of an app's largest on-screen window, for
// `screencapture -l`.
//
// screencapture cannot target an application by name, and its rectangular -R
// mode would square off the window's rounded corners. Capturing by window id
// keeps the corners transparent, which is what the download page wants.
//
//     swift scripts/window_id.swift Routine
import CoreGraphics
import Foundation

let owner = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Routine"

// Panels, tray popovers and the like are small; the app window is not.
let minHeight = 200.0

let windows = CGWindowListCopyWindowInfo(
  [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
) as? [[String: Any]] ?? []

var best: (id: Int, area: Double)?

for window in windows {
  guard let name = window[kCGWindowOwnerName as String] as? String, name == owner,
        let id = window[kCGWindowNumber as String] as? Int,
        let bounds = window[kCGWindowBounds as String] as? [String: Any],
        let width = bounds["Width"] as? Double,
        let height = bounds["Height"] as? Double,
        height >= minHeight
  else { continue }

  // Largest wins, so a leftover window from an earlier `flutter run` at the
  // default 800x600 loses to the 1280x800 one demo mode opens.
  let area = width * height
  if best == nil || area > best!.area {
    best = (id, area)
  }
}

guard let window = best else {
  FileHandle.standardError.write(
    "error: no on-screen '\(owner)' window found\n".data(using: .utf8)!)
  exit(1)
}

print(window.id)
