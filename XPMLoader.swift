import Cocoa

class XPMLoader {
    struct XPMImage {
        let width: Int
        let height: Int
        let pixels: [[NSColor]]
    }
    
    static func loadXPM(filename: String) -> XPMImage? {
        guard let path = Bundle.main.path(forResource: filename, ofType: "XPM", inDirectory: "pixmaps"),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return nil
        }
        
        return parseXPM(content)
    }
    
    static func parseXPM(_ content: String) -> XPMImage? {
        let lines = content.components(separatedBy: .newlines)
        var dataLines: [String] = []
        
        for line in lines {
            if line.contains("\"") {
                if let start = line.firstIndex(of: "\""),
                   let end = line.lastIndex(of: "\""),
                   start != end {
                    let dataLine = String(line[line.index(after: start)..<end])
                    dataLines.append(dataLine)
                }
            }
        }
        
        guard dataLines.count > 1 else { return nil }
        
        let headerParts = dataLines[0].trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard headerParts.count >= 4,
              let width = Int(headerParts[0]),
              let height = Int(headerParts[1]),
              let numColors = Int(headerParts[2]) else {
            return nil
        }
        
        var colorMap: [Character: NSColor] = [:]
        
        for i in 1...numColors {
            guard i < dataLines.count else { break }
            let colorLine = dataLines[i]
            guard let charIndex = colorLine.first else { continue }
            
            if colorLine.contains("none") {
                colorMap[charIndex] = NSColor.clear
            } else if let colorStart = colorLine.range(of: "#"),
                      colorStart.lowerBound < colorLine.endIndex {
                let colorStartIndex = colorLine.index(after: colorStart.lowerBound)
                let colorEndIndex = colorLine.index(colorStartIndex, offsetBy: min(6, colorLine.distance(from: colorStartIndex, to: colorLine.endIndex)))
                let colorHex = String(colorLine[colorStartIndex..<colorEndIndex])
                colorMap[charIndex] = parseColor(hex: colorHex)
            }
        }
        
        var pixels: [[NSColor]] = []
        let pixelStartIndex = 1 + numColors
        
        for i in 0..<height {
            let lineIndex = pixelStartIndex + i
            guard lineIndex < dataLines.count else { break }
            
            let pixelLine = dataLines[lineIndex]
            var row: [NSColor] = []
            
            for char in pixelLine {
                if let color = colorMap[char] {
                    row.append(color)
                } else {
                    row.append(NSColor.clear)
                }
            }
            
            pixels.append(row)
        }
        
        return XPMImage(width: width, height: height, pixels: pixels)
    }
    
    static func parseColor(hex: String) -> NSColor {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    static func createNSImage(from xpmImage: XPMImage, scale: CGFloat = 1.0) -> NSImage {
        let scaledWidth = Int(CGFloat(xpmImage.width) * scale)
        let scaledHeight = Int(CGFloat(xpmImage.height) * scale)
        
        let image = NSImage(size: NSSize(width: scaledWidth, height: scaledHeight))
        image.lockFocus()
        
        for y in 0..<xpmImage.height {
            for x in 0..<xpmImage.width {
                let color = xpmImage.pixels[y][x]
                if color != NSColor.clear {
                    color.setFill()
                    let rect = NSRect(
                        x: CGFloat(x) * scale,
                        y: CGFloat(xpmImage.height - y - 1) * scale,
                        width: scale,
                        height: scale
                    )
                    NSBezierPath(rect: rect).fill()
                }
            }
        }
        
        image.unlockFocus()
        return image
    }
}
