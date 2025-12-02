import Cocoa

struct WindowInfo {
    let frame: CGRect
    let title: String
}

class WindowDetector {
    private var cachedWindows: [WindowInfo] = []
    private var lastUpdate: Date = Date.distantPast
    private let updateInterval: TimeInterval = 0.5
    
    func getVisibleWindows() -> [WindowInfo] {
        let now = Date()
        if now.timeIntervalSince(lastUpdate) < updateInterval {
            return cachedWindows
        }
        
        lastUpdate = now
        cachedWindows = detectWindows()
        return cachedWindows
    }
    
    private func detectWindows() -> [WindowInfo] {
        var windows: [WindowInfo] = []
        
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return windows
        }
        
        for windowDict in windowList {
            guard let bounds = windowDict[kCGWindowBounds as String] as? [String: CGFloat],
                  let layer = windowDict[kCGWindowLayer as String] as? Int,
                  let ownerName = windowDict[kCGWindowOwnerName as String] as? String else {
                continue
            }
            
            if layer == 0 && ownerName != "xSnow" {
                if let x = bounds["X"],
                   let y = bounds["Y"],
                   let width = bounds["Width"],
                   let height = bounds["Height"],
                   width > 50 && height > 50 {
                    
                    let screenHeight = NSScreen.main?.frame.height ?? 0
                    let flippedY = screenHeight - y - height
                    
                    let frame = CGRect(x: x, y: flippedY, width: width, height: height)
                    let title = windowDict[kCGWindowName as String] as? String ?? ownerName
                    
                    windows.append(WindowInfo(frame: frame, title: title))
                }
            }
        }
        
        return windows
    }
}
