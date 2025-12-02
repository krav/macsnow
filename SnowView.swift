import Cocoa

enum SnowIntensity {
    case light
    case medium
    case heavy
    
    var particleCount: Int {
        switch self {
        case .light: return 100
        case .medium: return 250
        case .heavy: return 500
        }
    }
}

struct SnowParticle {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var speed: CGFloat
    var drift: CGFloat
    var opacity: CGFloat
    var isFalling: Bool
}

class SnowView: NSView {
    private var particles: [SnowParticle] = []
    private var timer: Timer?
    private var intensity: SnowIntensity = .medium
    private var windEnabled: Bool = true
    private var settlingEnabled: Bool = true
    private var santaEnabled: Bool = true
    private var windPhase: CGFloat = 0
    private var windowDetector = WindowDetector()
    private var settledSnowManager = SettledSnowManager()
    private var lastUpdateTime: Date = Date()
    private var santa: SantaSleigh?
    private var nextSantaTime: TimeInterval = 0
    private var timeSinceStart: TimeInterval = 0
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        santa = SantaSleigh(screenBounds: frameRect)
        scheduleNextSanta()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startAnimation() {
        createParticles()
        lastUpdateTime = Date()
        timeSinceStart = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updateParticles()
            self?.needsDisplay = true
        }
    }
    
    private func scheduleNextSanta() {
        nextSantaTime = TimeInterval.random(in: 30...120)
    }
    
    func setIntensity(_ intensity: SnowIntensity) {
        self.intensity = intensity
        createParticles()
    }
    
    func setWindEnabled(_ enabled: Bool) {
        self.windEnabled = enabled
    }
    
    func setSettlingEnabled(_ enabled: Bool) {
        self.settlingEnabled = enabled
        if !enabled {
            settledSnowManager.clear()
        }
    }
    
    func setSantaEnabled(_ enabled: Bool) {
        self.santaEnabled = enabled
    }
    
    private func createParticles() {
        particles.removeAll()
        
        for _ in 0..<intensity.particleCount {
            let particle = createRandomParticle()
            particles.append(particle)
        }
    }
    
    private func createRandomParticle(atTop: Bool = false) -> SnowParticle {
        let x = CGFloat.random(in: 0...bounds.width)
        let y = atTop ? bounds.height : CGFloat.random(in: 0...bounds.height)
        let size = CGFloat.random(in: 2...6)
        let speed = CGFloat.random(in: 1...3) * (size / 6.0)
        let drift = CGFloat.random(in: -0.5...0.5)
        let opacity = CGFloat.random(in: 0.6...1.0)
        
        return SnowParticle(x: x, y: y, size: size, speed: speed, drift: drift, opacity: opacity, isFalling: true)
    }
    
    private func updateParticles() {
        let now = Date()
        let deltaTime = now.timeIntervalSince(lastUpdateTime)
        lastUpdateTime = now
        
        if santaEnabled {
            timeSinceStart += deltaTime
            
            if timeSinceStart >= nextSantaTime {
                santa?.startFlight()
                timeSinceStart = 0
                scheduleNextSanta()
            }
            
            santa?.update()
        }
        
        windPhase += 0.02
        let windEffect = windEnabled ? sin(windPhase) * 0.5 : 0
        
        let visibleWindows = settlingEnabled ? windowDetector.getVisibleWindows() : []
        if settlingEnabled {
            settledSnowManager.update(deltaTime: deltaTime, visibleWindows: visibleWindows)
            settledSnowManager.removeOccludedSnow(windowDetector: windowDetector, allWindows: visibleWindows)
        }
        
        for i in 0..<particles.count {
            guard particles[i].isFalling else { continue }
            
            particles[i].y -= particles[i].speed
            particles[i].x += particles[i].drift + windEffect
            
            if settlingEnabled && checkCollisionWithWindows(particle: particles[i], windows: visibleWindows) {
                particles[i] = createRandomParticle(atTop: true)
                continue
            }
            
            if particles[i].y < -10 {
                particles[i] = createRandomParticle(atTop: true)
            }
            
            if particles[i].x < -10 {
                particles[i].x = bounds.width + 10
            } else if particles[i].x > bounds.width + 10 {
                particles[i].x = -10
            }
        }
    }
    
    private func checkCollisionWithWindows(particle: SnowParticle, windows: [WindowInfo]) -> Bool {
        let particlePoint = CGPoint(x: particle.x, y: particle.y)
        
        guard let topmostWindow = windowDetector.getTopmostWindow(at: particlePoint, from: windows) else {
            return false
        }
        
        let topEdge = topmostWindow.frame.maxY
        let snowHeight = settledSnowManager.getSnowHeight(on: topmostWindow.windowID)
        let collisionY = topEdge + snowHeight
        
        if particle.y <= collisionY &&
           particle.y >= collisionY - particle.speed * 2 {
            
            let landingPoint = CGPoint(x: particle.x, y: topEdge + snowHeight)
            if !windowDetector.isPointOccluded(point: landingPoint, byWindowsInFrontOf: topmostWindow, allWindows: windows) {
                settledSnowManager.addSnowParticle(
                    at: particlePoint,
                    size: particle.size,
                    on: topmostWindow
                )
            }
            return true
        }
        
        return false
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        context.setFillColor(NSColor.white.cgColor)
        
        for particle in particles where particle.isFalling {
            context.setAlpha(particle.opacity)
            let rect = CGRect(
                x: particle.x - particle.size / 2,
                y: particle.y - particle.size / 2,
                width: particle.size,
                height: particle.size
            )
            context.fillEllipse(in: rect)
        }
        
        if settlingEnabled {
            drawSnowPiles(context: context)
        }
        
        if santaEnabled {
            santa?.draw(context: context)
        }
    }
    
    private func drawSnowPiles(context: CGContext) {
        let piles = settledSnowManager.getAllSnowPiles()
        
        for pile in piles {
            let sortedColumns = pile.columns.sorted { $0.key < $1.key }
            guard !sortedColumns.isEmpty else { continue }
            
            let windowTop = pile.windowFrame.maxY
            let windowLeft = pile.windowFrame.minX
            let windowRight = pile.windowFrame.maxX
            let cornerRadius: CGFloat = 10.0
            
            let avgAge = pile.getAverageAge()
            let fadeStartAge: TimeInterval = 240.0
            let opacity: CGFloat
            if avgAge < fadeStartAge {
                opacity = 0.95
            } else {
                let fadeProgress = (avgAge - fadeStartAge) / (pile.maxAge - fadeStartAge)
                opacity = max(0.3, 0.95 - CGFloat(fadeProgress) * 0.65)
            }
            
            let path = CGMutablePath()
            
            var points: [(x: CGFloat, y: CGFloat)] = []
            for (columnX, column) in sortedColumns {
                let absoluteX = windowLeft + columnX + pile.columnWidth / 2
                let topY = windowTop + column.height
                points.append((x: absoluteX, y: topY))
            }
            
            guard !points.isEmpty else { continue }
            
            let leftBound = windowLeft + cornerRadius
            let rightBound = windowRight - cornerRadius
            
            let firstPoint = points[0]
            let lastPoint = points[points.count - 1]
            
            let startX = min(max(firstPoint.x, leftBound), rightBound)
            path.move(to: CGPoint(x: startX, y: windowTop))
            
            if points.count == 1 {
                let p = points[0]
                path.addLine(to: CGPoint(x: startX, y: p.y))
                path.addLine(to: CGPoint(x: startX, y: windowTop))
            } else {
                for i in 0..<points.count {
                    let p = points[i]
                    let clampedX = min(max(p.x, leftBound), rightBound)
                    let point = CGPoint(x: clampedX, y: p.y)
                    
                    if i == 0 {
                        path.addLine(to: point)
                    } else {
                        let prevP = points[i - 1]
                        let prevClampedX = min(max(prevP.x, leftBound), rightBound)
                        let controlX = (prevClampedX + clampedX) / 2
                        let controlY = (prevP.y + p.y) / 2 + abs(prevP.y - p.y) * 0.2
                        path.addQuadCurve(to: point, control: CGPoint(x: controlX, y: controlY))
                    }
                }
                
                let endX = min(max(lastPoint.x, leftBound), rightBound)
                path.addLine(to: CGPoint(x: endX, y: windowTop))
            }
            
            path.closeSubpath()
            
            context.saveGState()
            context.setAlpha(opacity)
            context.addPath(path)
            context.setFillColor(NSColor.white.cgColor)
            context.fillPath()
            
            context.setAlpha(opacity * 0.7)
            context.addPath(path)
            context.setStrokeColor(NSColor.white.withAlphaComponent(0.8).cgColor)
            context.setLineWidth(1.0)
            context.strokePath()
            context.restoreGState()
        }
    }
}
