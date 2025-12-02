import Cocoa

class SantaSleigh {
    var x: CGFloat
    var y: CGFloat
    var speed: CGFloat
    var isActive: Bool
    let screenBounds: CGRect
    
    private var santaImages: [NSImage] = []
    private var currentFrame: Int = 0
    private var frameCounter: Int = 0
    
    init(screenBounds: CGRect) {
        self.screenBounds = screenBounds
        self.x = -200
        self.y = screenBounds.height * 0.7
        self.speed = 3.0
        self.isActive = false
        
        loadSantaImages()
    }
    
    private func loadSantaImages() {
        let santaFiles = ["RegularSantaRudolf1", "RegularSantaRudolf2", "RegularSantaRudolf3", "RegularSantaRudolf4"]
        
        for filename in santaFiles {
            if let xpmImage = XPMLoader.loadXPM(filename: filename) {
                let image = XPMLoader.createNSImage(from: xpmImage, scale: 2.0)
                santaImages.append(image)
            }
        }
        
        if santaImages.isEmpty {
            print("Warning: No Santa XPM images loaded")
        }
    }
    
    func startFlight() {
        x = -200
        y = CGFloat.random(in: screenBounds.height * 0.3...screenBounds.height * 0.7)
        speed = CGFloat.random(in: 2.5...4.5)
        isActive = true
    }
    
    func update() {
        if isActive {
            x += speed
            
            frameCounter += 1
            if frameCounter >= 8 {
                frameCounter = 0
                currentFrame = (currentFrame + 1) % max(1, santaImages.count)
            }
            
            if x > screenBounds.width + 200 {
                isActive = false
            }
        }
    }
    
    func draw(context: CGContext) {
        guard isActive, !santaImages.isEmpty else { return }
        
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.current = nsContext
        
        let santa = santaImages[currentFrame]
        let santaRect = NSRect(origin: NSPoint(x: x, y: y), size: santa.size)
        santa.draw(in: santaRect)
    }
}
