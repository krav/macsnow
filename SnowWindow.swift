import Cocoa

class SnowWindow: NSWindow {
    private var snowView: SnowView?
    
    init(screen: NSScreen) {
        let screenRect = screen.frame
        
        super.init(
            contentRect: screenRect,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        self.level = .floating
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        snowView = SnowView(frame: screenRect)
        self.contentView = snowView
    }
    
    func startSnowing() {
        snowView?.startAnimation()
    }
    
    func setSnowIntensity(_ intensity: SnowIntensity) {
        snowView?.setIntensity(intensity)
    }
    
    func setWindEnabled(_ enabled: Bool) {
        snowView?.setWindEnabled(enabled)
    }
    
    func setSettlingEnabled(_ enabled: Bool) {
        snowView?.setSettlingEnabled(enabled)
    }
    
    func setSantaEnabled(_ enabled: Bool) {
        snowView?.setSantaEnabled(enabled)
    }
}
