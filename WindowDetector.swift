import Cocoa

struct WindowInfo {
    let frame: CGRect
    let title: String
    let zOrder: Int
    let windowID: CGWindowID
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
    
    func getTopmostWindow(at point: CGPoint, from windows: [WindowInfo]) -> WindowInfo? {
        let windowsAtPoint = windows.filter { window in
            let topEdge = window.frame.maxY
            let tolerance: CGFloat = 5.0
            
            return point.y >= topEdge - tolerance &&
                   point.y <= topEdge + tolerance &&
                   point.x >= window.frame.minX &&
                   point.x <= window.frame.maxX
        }
        
        return windowsAtPoint.min(by: { $0.zOrder < $1.zOrder })
    }
    
    func isPointOccluded(point: CGPoint, byWindowsInFrontOf targetWindow: WindowInfo, allWindows: [WindowInfo]) -> Bool {
        for window in allWindows {
            if window.zOrder < targetWindow.zOrder {
                if point.x >= window.frame.minX &&
                   point.x <= window.frame.maxX &&
                   point.y >= window.frame.minY &&
                   point.y <= window.frame.maxY {
                    return true
                }
            }
        }
        return false
    }
    
    private func detectWindows() -> [WindowInfo] {
        var windows: [WindowInfo] = []
        
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return windows
        }
        
        var zOrder = 0
        for windowDict in windowList {
            guard let bounds = windowDict[kCGWindowBounds as String] as? [String: CGFloat],
                  let layer = windowDict[kCGWindowLayer as String] as? Int,
                  let ownerName = windowDict[kCGWindowOwnerName as String] as? String,
                  let windowID = windowDict[kCGWindowNumber as String] as? CGWindowID else {
                continue
            }
            
            if layer == 0 && ownerName != "MacSnow" {
                if let x = bounds["X"],
                   let y = bounds["Y"],
                   let width = bounds["Width"],
                   let height = bounds["Height"],
                   width > 50 && height > 50 {
                    
                    let screenHeight = NSScreen.main?.frame.height ?? 0
                    let flippedY = screenHeight - y - height
                    
                    let frame = CGRect(x: x, y: flippedY, width: width, height: height)
                    let title = windowDict[kCGWindowName as String] as? String ?? ownerName
                    
                    windows.append(WindowInfo(frame: frame, title: title, zOrder: zOrder, windowID: windowID))
                    zOrder += 1
                }
            }
        }
        
        return windows
    }
}
