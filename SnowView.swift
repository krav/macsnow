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
    private var windPhase: CGFloat = 0
    private var windowDetector = WindowDetector()
    private var settledSnowManager = SettledSnowManager()
    private var lastUpdateTime: Date = Date()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startAnimation() {
        createParticles()
        lastUpdateTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updateParticles()
            self?.needsDisplay = true
        }
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
        
        windPhase += 0.02
        let windEffect = windEnabled ? sin(windPhase) * 0.5 : 0
        
        let visibleWindows = settlingEnabled ? windowDetector.getVisibleWindows() : []
        if settlingEnabled {
            settledSnowManager.update(deltaTime: deltaTime, visibleWindows: visibleWindows)
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
        
        for window in windows {
            let topEdge = window.frame.maxY
            let snowHeight = settledSnowManager.getSnowHeight(on: window.frame)
            let collisionY = topEdge + snowHeight
            
            if particle.y <= collisionY &&
               particle.y >= collisionY - particle.speed &&
               particle.x >= window.frame.minX &&
               particle.x <= window.frame.maxX {
                
                settledSnowManager.addSnowParticle(
                    at: particlePoint,
                    size: particle.size,
                    on: window.frame
                )
                return true
            }
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
    }
    
    private func drawSnowPiles(context: CGContext) {
        let piles = settledSnowManager.getAllSnowPiles()
        
        for pile in piles {
            let sortedColumns = pile.columns.sorted { $0.key < $1.key }
            guard !sortedColumns.isEmpty else { continue }
            
            let windowTop = pile.windowFrame.maxY
            let windowLeft = pile.windowFrame.minX
            
            for (columnX, column) in sortedColumns {
                let absoluteX = windowLeft + columnX
                let height = column.height
                let age = column.age
                let opacity = max(0.7, 1.0 - CGFloat(age / pile.maxAge))
                
                let path = CGMutablePath()
                let baseY = windowTop
                let topY = windowTop + height
                
                let leftX = absoluteX
                let rightX = absoluteX + pile.columnWidth
                
                path.move(to: CGPoint(x: leftX, y: baseY))
                
                let controlHeight = height * 0.7
                path.addCurve(
                    to: CGPoint(x: leftX + pile.columnWidth / 2, y: topY),
                    control1: CGPoint(x: leftX, y: baseY + controlHeight),
                    control2: CGPoint(x: leftX + pile.columnWidth * 0.3, y: topY - 2)
                )
                
                path.addCurve(
                    to: CGPoint(x: rightX, y: baseY),
                    control1: CGPoint(x: rightX - pile.columnWidth * 0.3, y: topY - 2),
                    control2: CGPoint(x: rightX, y: baseY + controlHeight)
                )
                
                path.closeSubpath()
                
                context.setAlpha(opacity)
                context.addPath(path)
                context.fillPath()
                
                context.setAlpha(opacity * 0.5)
                context.setStrokeColor(NSColor.white.cgColor)
                context.setLineWidth(0.5)
                context.addPath(path)
                context.strokePath()
            }
        }
    }
}
