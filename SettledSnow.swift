import Cocoa

struct SnowColumn {
    var height: CGFloat
    var age: TimeInterval
}

struct SnowPile {
    var windowFrame: CGRect
    var columns: [CGFloat: SnowColumn]
    var columnWidth: CGFloat = 8.0
    var totalAge: TimeInterval = 0
    let maxAge: TimeInterval = 60.0
    
    init(windowFrame: CGRect) {
        self.windowFrame = windowFrame
        self.columns = [:]
    }
    
    func getMaxHeight() -> CGFloat {
        return columns.values.map { $0.height }.max() ?? 0
    }
    
    func getAverageAge() -> TimeInterval {
        guard !columns.isEmpty else { return 0 }
        let totalAge = columns.values.map { $0.age }.reduce(0, +)
        return totalAge / Double(columns.count)
    }
}

class SettledSnowManager {
    private var snowPiles: [CGRect: SnowPile] = [:]
    private let maxSnowHeight: CGFloat = 80.0
    private let meltRate: CGFloat = 0.005
    
    func addSnowParticle(at point: CGPoint, size: CGFloat, on windowFrame: CGRect) {
        if snowPiles[windowFrame] == nil {
            snowPiles[windowFrame] = SnowPile(windowFrame: windowFrame)
        }
        
        guard var pile = snowPiles[windowFrame] else { return }
        
        let relativeX = point.x - windowFrame.minX
        let columnX = floor(relativeX / pile.columnWidth) * pile.columnWidth
        
        if var column = pile.columns[columnX] {
            if column.height < maxSnowHeight {
                column.height += size * 0.5
                column.age = 0
                pile.columns[columnX] = column
            }
        } else {
            pile.columns[columnX] = SnowColumn(height: size * 0.5, age: 0)
        }
        
        snowPiles[windowFrame] = pile
    }
    
    func update(deltaTime: TimeInterval, visibleWindows: [WindowInfo]) {
        let visibleFrames = Set(visibleWindows.map { $0.frame })
        
        var keysToRemove: [CGRect] = []
        
        for (frame, var pile) in snowPiles {
            if !visibleFrames.contains(frame) {
                keysToRemove.append(frame)
                continue
            }
            
            pile.totalAge += deltaTime
            
            var columnsToRemove: [CGFloat] = []
            for (x, var column) in pile.columns {
                column.age += deltaTime
                column.height = max(0, column.height - meltRate)
                
                if column.height <= 0.1 || column.age > pile.maxAge {
                    columnsToRemove.append(x)
                } else {
                    pile.columns[x] = column
                }
            }
            
            for x in columnsToRemove {
                pile.columns.removeValue(forKey: x)
            }
            
            if pile.columns.isEmpty {
                keysToRemove.append(frame)
            } else {
                snowPiles[frame] = pile
            }
        }
        
        for key in keysToRemove {
            snowPiles.removeValue(forKey: key)
        }
    }
    
    func getAllSnowPiles() -> [SnowPile] {
        return Array(snowPiles.values)
    }
    
    func getSnowHeight(on windowFrame: CGRect) -> CGFloat {
        return snowPiles[windowFrame]?.getMaxHeight() ?? 0
    }
    
    func clear() {
        snowPiles.removeAll()
    }
}
