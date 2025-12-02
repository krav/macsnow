import Cocoa

struct SnowColumn {
    var height: CGFloat
    var age: TimeInterval
}

struct SnowPile {
    var windowID: CGWindowID
    var windowFrame: CGRect
    var columns: [CGFloat: SnowColumn]
    var columnWidth: CGFloat = 8.0
    var totalAge: TimeInterval = 0
    let maxAge: TimeInterval = 30000.0
    
    init(windowID: CGWindowID, windowFrame: CGRect) {
        self.windowID = windowID
        self.windowFrame = windowFrame
        self.columns = [:]
    }
    
    func getMaxHeight() -> CGFloat {
        return columns.values.map { $0.height }.max() ?? 0
    }
    
    func getAverageAge() -> TimeInterval {
        guard !columns.isEmpty else { return 0 }
        return columns.values.reduce(0.0) { $0 + $1.age } / Double(columns.count)
    }
}

class SettledSnowManager {
    private var snowPiles: [CGWindowID: SnowPile] = [:]
    private let maxSnowHeight: CGFloat = 500.0
    private let meltRate: CGFloat = 0.000005
    
    func addSnowParticle(at point: CGPoint, size: CGFloat, on window: WindowInfo) {
        var pile = snowPiles[window.windowID] ?? SnowPile(windowID: window.windowID, windowFrame: window.frame)
        pile.windowFrame = window.frame
        
        let relativeX = point.x - window.frame.minX
        let cornerRadius: CGFloat = 10.0
        
        guard relativeX >= cornerRadius && relativeX <= window.frame.width - cornerRadius else {
            return
        }
        
        let columnX = floor(relativeX / pile.columnWidth) * pile.columnWidth
        addSnowToColumn(pile: &pile, columnX: columnX, amount: size * 0.5)
        
        snowPiles[window.windowID] = pile
    }
    
    private func addSnowToColumn(pile: inout SnowPile, columnX: CGFloat, amount: CGFloat) {
        let currentHeight = pile.columns[columnX]?.height ?? 0
        
        guard currentHeight < maxSnowHeight else { return }
        
        let amountToAdd = min(amount, maxSnowHeight - currentHeight)
        
        if pile.columns[columnX] != nil {
            pile.columns[columnX]?.height += amountToAdd
            pile.columns[columnX]?.age = 0
        } else {
            pile.columns[columnX] = SnowColumn(height: amountToAdd, age: 0)
        }
        
        redistributeSnow(pile: &pile, centerColumn: columnX, gentle: false)
    }
    
    private func redistributeSnow(pile: inout SnowPile, centerColumn: CGFloat, gentle: Bool = false) {
        let baseAngleOfRepose: CGFloat = 1.2
        let angleVariation: CGFloat = gentle ? 0.3 : 0.4
        let maxAngleOfRepose = baseAngleOfRepose + CGFloat.random(in: -angleVariation...angleVariation)
        
        var changed = true
        var iterations = 0
        let maxIterations = gentle ? 2 : 3
        
        while changed && iterations < maxIterations {
            changed = false
            iterations += 1
            
            let sortedColumns = pile.columns.sorted { $0.key < $1.key }
            
            for (x, column) in sortedColumns {
                let neighbors = [-pile.columnWidth, pile.columnWidth].shuffled()
                
                for neighborOffset in neighbors {
                    let neighborX = x + neighborOffset
                    let neighborHeight = pile.columns[neighborX]?.height ?? 0
                    let heightDiff = column.height - neighborHeight
                    
                    guard heightDiff > maxAngleOfRepose else { continue }
                    
                    let transferRate = gentle ? 0.15 : 0.5
                    let randomness = CGFloat.random(in: 0.9...1.1)
                    let transfer = (heightDiff - maxAngleOfRepose) * transferRate * randomness
                    
                    guard transfer > 0.01 else { continue }
                    
                    pile.columns[x]?.height -= transfer
                    
                    if pile.columns[neighborX] != nil {
                        pile.columns[neighborX]?.height += transfer
                    } else {
                        pile.columns[neighborX] = SnowColumn(height: transfer, age: pile.columns[x]?.age ?? 0)
                    }
                    changed = true
                }
            }
        }
    }
    
    func update(deltaTime: TimeInterval, visibleWindows: [WindowInfo]) {
        let visibleWindowIDs = Set(visibleWindows.map { $0.windowID })
        let windowFrames = Dictionary(uniqueKeysWithValues: visibleWindows.map { ($0.windowID, $0.frame) })
        
        snowPiles = snowPiles.filter { visibleWindowIDs.contains($0.key) }
        
        for (windowID, var pile) in snowPiles {
            if let updatedFrame = windowFrames[windowID] {
                pile.windowFrame = updatedFrame
            }
            
            pile.totalAge += deltaTime
            
            for (x, var column) in pile.columns {
                column.age += deltaTime
                
                if column.age > 24000 {
                    column.height = max(0, column.height - meltRate)
                }
                
                if column.age > 30 && column.height > 0.5 {
                    let compressionRate: CGFloat = 0.0005
                    column.height = max(0.1, column.height - compressionRate)
                }
                
                pile.columns[x] = column
            }
            
            pile.columns = pile.columns.filter { column in 
                column.value.height > 0.1 && column.value.age <= pile.maxAge 
            }
            
            if !pile.columns.isEmpty {
                redistributeSnow(pile: &pile, centerColumn: pile.columns.keys.first ?? 0, gentle: true)
                snowPiles[windowID] = pile
            }
        }
        
        snowPiles = snowPiles.filter { !$0.value.columns.isEmpty }
    }
    
    func getAllSnowPiles() -> [SnowPile] {
        return Array(snowPiles.values)
    }
    
    func getSnowPile(for windowID: CGWindowID) -> SnowPile? {
        return snowPiles[windowID]
    }
    
    func getSnowHeight(on windowID: CGWindowID) -> CGFloat {
        return snowPiles[windowID]?.getMaxHeight() ?? 0
    }
    
    func removeOccludedSnow(windowDetector: WindowDetector, allWindows: [WindowInfo]) {
        for (windowID, var pile) in snowPiles {
            guard let targetWindow = allWindows.first(where: { $0.windowID == windowID }) else {
                continue
            }
            
            pile.columns = pile.columns.filter { columnX, column in
                let checkPoints = [
                    CGPoint(x: pile.windowFrame.minX + columnX, y: pile.windowFrame.maxY + column.height),
                    CGPoint(x: pile.windowFrame.minX + columnX + pile.columnWidth / 2, y: pile.windowFrame.maxY + column.height),
                    CGPoint(x: pile.windowFrame.minX + columnX + pile.columnWidth, y: pile.windowFrame.maxY + column.height),
                    CGPoint(x: pile.windowFrame.minX + columnX + pile.columnWidth / 2, y: pile.windowFrame.maxY + column.height / 2)
                ]
                
                for point in checkPoints {
                    if windowDetector.isPointOccluded(
                        point: point,
                        byWindowsInFrontOf: targetWindow,
                        allWindows: allWindows
                    ) {
                        return false
                    }
                }
                
                return true
            }
            
            if !pile.columns.isEmpty {
                snowPiles[windowID] = pile
            }
        }
        
        snowPiles = snowPiles.filter { !$0.value.columns.isEmpty }
    }
    
    func clear() {
        snowPiles.removeAll()
    }
}
