import SwiftUI
import UIKit
import Vision
import CoreImage

// Graph Line Detector for pattern-coding multi-color lines
class GraphLineDetector {
    
    struct DetectedLine {
        let path: [CGPoint]
        let color: UIColor
        let thickness: CGFloat
    }
    
    func detectLines(in image: UIImage) -> [DetectedLine] {
        guard let ciImage = CIImage(image: image) else { return [] }
        
        var detectedLines: [DetectedLine] = []
        
        // Use Vision framework to detect lines
        let request = VNDetectContoursRequest()
        request.contrastAdjustment = 1.5
        request.detectsDarkOnLight = true
        
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        do {
            try handler.perform([request])
            
            if let results = request.results {
                for observation in results {
                    let contour = observation.normalizedPath
                    let points = convertPathToPoints(contour, imageSize: image.size)
                    
                    if let color = sampleColorAlongPath(points, in: image) {
                        let line = DetectedLine(
                            path: points,
                            color: color,
                            thickness: estimateLineThickness(points)
                        )
                        detectedLines.append(line)
                    }
                }
            }
        } catch {
            print("Failed to detect lines: \(error)")
        }
        
        return groupSimilarLines(detectedLines)
    }
    
    func applyPatternCodingToGraph(image: UIImage, lines: [DetectedLine]) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            // Draw original image
            image.draw(at: .zero)
            
            let ctx = context.cgContext
            
            // Define different patterns for each line
            let patterns: [PatternStyle] = [.solid, .dashed, .dotted, .dashDot, .thickDashed]
            
            // Group lines by color
            let groupedLines = Dictionary(grouping: lines) { line in
                quantizeColor(line.color)
            }
            
            var patternIndex = 0
            
            for (_, colorLines) in groupedLines {
                let pattern = patterns[patternIndex % patterns.count]
                
                for line in colorLines {
                    drawPatternedLine(
                        path: line.path,
                        pattern: pattern,
                        thickness: line.thickness,
                        context: ctx
                    )
                }
                
                patternIndex += 1
            }
        }
    }
    
    private enum PatternStyle {
        case solid
        case dashed
        case dotted
        case dashDot
        case thickDashed
    }
    
    private func drawPatternedLine(path: [CGPoint], pattern: PatternStyle, thickness: CGFloat, context: CGContext) {
        guard path.count >= 2 else { return }
        
        context.saveGState()
        
        context.setLineWidth(thickness * 1.5) // Make patterns more visible
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        switch pattern {
        case .solid:
            context.setLineDash(phase: 0, lengths: [])
        case .dashed:
            context.setLineDash(phase: 0, lengths: [10, 5])
        case .dotted:
            context.setLineDash(phase: 0, lengths: [2, 3])
        case .dashDot:
            context.setLineDash(phase: 0, lengths: [10, 5, 2, 5])
        case .thickDashed:
            context.setLineDash(phase: 0, lengths: [15, 8])
        }
        
        // Draw the path
        context.beginPath()
        context.move(to: path[0])
        
        for i in 1..<path.count {
            context.addLine(to: path[i])
        }
        
        context.strokePath()
        context.restoreGState()
    }
    
    private func convertPathToPoints(_ path: CGPath, imageSize: CGSize) -> [CGPoint] {
        var points: [CGPoint] = []
        
        path.applyWithBlock { elementPointer in
            let element = elementPointer.pointee
            
            switch element.type {
            case .moveToPoint, .addLineToPoint:
                let point = element.points[0]
                // Convert from normalized coordinates
                let scaledPoint = CGPoint(
                    x: point.x * imageSize.width,
                    y: (1 - point.y) * imageSize.height
                )
                points.append(scaledPoint)
            case .addQuadCurveToPoint:
                let point = element.points[1]
                let scaledPoint = CGPoint(
                    x: point.x * imageSize.width,
                    y: (1 - point.y) * imageSize.height
                )
                points.append(scaledPoint)
            case .addCurveToPoint:
                let point = element.points[2]
                let scaledPoint = CGPoint(
                    x: point.x * imageSize.width,
                    y: (1 - point.y) * imageSize.height
                )
                points.append(scaledPoint)
            case .closeSubpath:
                break
            @unknown default:
                break
            }
        }
        
        return points
    }
    
    private func sampleColorAlongPath(_ points: [CGPoint], in image: UIImage) -> UIColor? {
        guard !points.isEmpty,
              let cgImage = image.cgImage,
              let pixelData = cgImage.dataProvider?.data,
              let data = CFDataGetBytePtr(pixelData) else {
            return nil
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        var sampleCount = 0
        
        // Sample color at multiple points along the path
        let samplePoints = stride(from: 0, to: points.count, by: max(1, points.count / 10))
        
        for index in samplePoints {
            let point = points[index]
            let x = Int(point.x)
            let y = Int(point.y)
            
            guard x >= 0, x < width, y >= 0, y < height else { continue }
            
            let pixelInfo = ((width * y) + x) * 4
            
            r += CGFloat(data[pixelInfo]) / 255.0
            g += CGFloat(data[pixelInfo + 1]) / 255.0
            b += CGFloat(data[pixelInfo + 2]) / 255.0
            sampleCount += 1
        }
        
        guard sampleCount > 0 else { return nil }
        
        return UIColor(
            red: r / CGFloat(sampleCount),
            green: g / CGFloat(sampleCount),
            blue: b / CGFloat(sampleCount),
            alpha: 1.0
        )
    }
    
    private func estimateLineThickness(_ points: [CGPoint]) -> CGFloat {
        // Estimate based on density of points
        guard points.count >= 2 else { return 2.0 }
        
        var totalDistance: CGFloat = 0
        for i in 0..<points.count-1 {
            let dx = points[i+1].x - points[i].x
            let dy = points[i+1].y - points[i].y
            totalDistance += sqrt(dx*dx + dy*dy)
        }
        
        let avgSegmentLength = totalDistance / CGFloat(points.count - 1)
        return max(2.0, min(8.0, avgSegmentLength / 10))
    }
    
    private func quantizeColor(_ color: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let red = Int(r * 255)
        let green = Int(g * 255)
        let blue = Int(b * 255)
        
        // Quantize to major color groups
        if red > 200 && green < 100 && blue < 100 { return "red" }
        if green > 200 && red < 100 && blue < 100 { return "green" }
        if blue > 200 && red < 100 && green < 100 { return "blue" }
        if red > 200 && green > 200 && blue < 100 { return "yellow" }
        if red < 100 && green < 100 && blue < 100 { return "black" }
        if red > 200 && green > 200 && blue > 200 { return "white" }
        
        return "color_\(red/50)_\(green/50)_\(blue/50)"
    }
    
    private func groupSimilarLines(_ lines: [DetectedLine]) -> [DetectedLine] {
        // Remove duplicate or very similar lines
        var uniqueLines: [DetectedLine] = []
        
        for line in lines {
            let isDuplicate = uniqueLines.contains { existingLine in
                areLinesSimiular(line, existingLine)
            }
            
            if !isDuplicate {
                uniqueLines.append(line)
            }
        }
        
        return uniqueLines
    }
    
    private func areLinesSimiular(_ line1: DetectedLine, _ line2: DetectedLine) -> Bool {
        guard line1.path.count > 0, line2.path.count > 0 else { return false }
        
        // Check if start and end points are close
        let start1 = line1.path.first!
        let start2 = line2.path.first!
        let end1 = line1.path.last!
        let end2 = line2.path.last!
        
        let threshold: CGFloat = 10
        
        let startDistance = sqrt(pow(start1.x - start2.x, 2) + pow(start1.y - start2.y, 2))
        let endDistance = sqrt(pow(end1.x - end2.x, 2) + pow(end1.y - end2.y, 2))
        
        return startDistance < threshold && endDistance < threshold
    }
}
