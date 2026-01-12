//
//  ColorRecognizer.swift
//  Colourblind Camera
//
//  Fast and accurate color recognition
//

import Foundation

class ColorRecognizer {
    private var colorHistory: [String] = []
    private let historySize = 3
    
    func recognize(r: Double, g: Double, b: Double) -> String {
        // Convert to HSL
        let (h, s, l) = rgbToHSL(r: r, g: g, b: b)
        
        let hue = h * 360
        let sat = s * 100
        let light = l * 100
        
        // Detect neutral colors
        if sat < 12 {
            return classifyGray(light)
        }
        
        // Classify chromatic colors
        let color = classifyColor(hue: hue, sat: sat, light: light)
        
        // Apply smoothing
        return applySmoothing(color)
    }
    
    private func rgbToHSL(r: Double, g: Double, b: Double) -> (h: Double, s: Double, l: Double) {
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC
        
        let l = (maxC + minC) / 2.0
        
        var s: Double = 0
        if delta > 0.001 {
            s = delta / (1 - abs(2 * l - 1))
            s = min(1.0, max(0, s))
        }
        
        var h: Double = 0
        if delta > 0.001 {
            if maxC == r {
                h = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
            } else if maxC == g {
                h = (b - r) / delta + 2
            } else {
                h = (r - g) / delta + 4
            }
            h /= 6
            if h < 0 { h += 1 }
        }
        
        return (h, s, l)
    }
    
    private func classifyGray(_ light: Double) -> String {
        if light > 90 { return "White" }
        if light > 70 { return "Light Gray" }
        if light > 45 { return "Gray" }
        if light > 25 { return "Dark Gray" }
        return "Black"
    }
    
    private func classifyColor(hue: Double, sat: Double, light: Double) -> String {
        let veryLight = light > 75
        let isLight = light > 55
        let dark = light < 35
        let pale = sat < 35
        let vivid = sat > 70
        
        // Red
        if hue >= 345 || hue < 15 {
            if veryLight && pale { return "Pink" }
            if veryLight { return "Light Pink" }
            if dark { return "Dark Red" }
            if vivid { return "Red" }
            return "Red"
        }
        
        // Orange
        if hue < 45 {
            if dark && sat < 50 { return "Brown" }
            if veryLight { return "Peach" }
            if vivid { return "Orange" }
            return "Orange"
        }
        
        // Yellow
        if hue < 70 {
            if dark { return "Olive" }
            if veryLight && pale { return "Cream" }
            if pale { return "Beige" }
            if vivid { return "Yellow" }
            return "Yellow"
        }
        
        // Green
        if hue < 160 {
            if veryLight && pale { return "Mint" }
            if veryLight { return "Light Green" }
            if dark { return "Dark Green" }
            if hue > 145 { return "Teal" }
            if vivid { return "Green" }
            return "Green"
        }
        
        // Cyan/Blue
        if hue < 220 {
            if veryLight { return "Light Blue" }
            if dark { return "Navy" }
            if hue < 190 { return "Cyan" }
            if vivid { return "Blue" }
            return "Blue"
        }
        
        // Blue/Purple
        if hue < 260 {
            if veryLight { return "Lavender" }
            if dark { return "Indigo" }
            return "Blue"
        }
        
        // Purple
        if hue < 310 {
            if veryLight { return "Light Purple" }
            if dark { return "Plum" }
            if vivid { return "Purple" }
            return "Purple"
        }
        
        // Magenta/Pink
        if veryLight { return "Pink" }
        if dark { return "Magenta" }
        return "Magenta"
    }
    
    private func applySmoothing(_ color: String) -> String {
        colorHistory.append(color)
        if colorHistory.count > historySize {
            colorHistory.removeFirst()
        }
        
        if colorHistory.count >= 2 {
            let counts = colorHistory.reduce(into: [:]) { $0[$1, default: 0] += 1 }
            if let most = counts.max(by: { $0.value < $1.value }), most.value >= 2 {
                return most.key
            }
        }
        
        return color
    }
}
