//
//  CameraService.swift
//  Colourblind Camera
//
//  Created by Alex Au on 2/12/2024.
//
import SwiftUI
import Foundation
import AVFoundation
import CoreImage

extension UIImage {
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x,
                                  y: inputImage.extent.origin.y,
                                  z: inputImage.extent.size.width,
                                  w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage",
                                  parameters: [kCIInputImageKey: inputImage,
                                             kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage,
                      toBitmap: &bitmap,
                      rowBytes: 4,
                      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                      format: .RGBA8,
                      colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255,
                      green: CGFloat(bitmap[1]) / 255,
                      blue: CGFloat(bitmap[2]) / 255,
                      alpha: CGFloat(bitmap[3]) / 255)
    }
}

extension UIColor {
    func closestColorName() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        // Apply lighting compensation - normalize based on perceived brightness
        let (normR, normG, normB) = normalizeForLighting(r: r, g: g, b: b)
        
        // Convert normalized RGB to HSL for better color detection
        let (hue, saturation, lightness) = rgbToHSL(r: normR, g: normG, b: normB)
        
        // Also get original HSB for comparison
        var h: CGFloat = 0, s: CGFloat = 0, br: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &br, alpha: &a)
        
        let hueAngle = hue * 360
        let sat = saturation * 100
        let light = lightness * 100
        let originalBrightness = br * 100
        
        // Use chroma to detect true grayscale vs colored under bad lighting
        let chroma = max(normR, normG, normB) - min(normR, normG, normB)
        let isGrayscale = chroma < 0.08 || sat < 8
        
        // Handle grayscale/neutral colors
        if isGrayscale {
            if light > 85 || originalBrightness > 90 { return "White" }
            if light > 65 { return "Light Gray" }
            if light > 35 { return "Gray" }
            if light > 15 { return "Dark Gray" }
            return "Black"
        }
        
        // Handle very dark colors - check if it's truly black or just dark colored
        if light < 12 && sat < 20 {
            return "Black"
        }
        
        // Classify by lightness level
        let isVeryLight = light > 75
        let isLight = light > 55
        let isDark = light < 30
        let isVeryDark = light < 18
        let isPale = sat < 30
        let isVivid = sat > 70
        
        // Determine color based on hue with lighting-aware thresholds
        var colorName: String
        
        // Red range (wraps around 0/360)
        if hueAngle < 12 || hueAngle >= 350 {
            if isVeryLight && isPale { colorName = "Pink" }
            else if isVeryLight { colorName = "Light Red" }
            else if isVeryDark { colorName = "Dark Red" }
            else if isDark && sat < 50 { colorName = "Maroon" }
            else if isPale && isLight { colorName = "Salmon" }
            else { colorName = "Red" }
        }
        // Red-Orange range
        else if hueAngle < 22 {
            if isDark { colorName = "Brown" }
            else if isVeryLight { colorName = "Peach" }
            else { colorName = "Red-Orange" }
        }
        // Orange range
        else if hueAngle < 40 {
            if isVeryDark || (isDark && sat < 50) { colorName = "Brown" }
            else if isVeryLight && isPale { colorName = "Peach" }
            else if isPale { colorName = "Tan" }
            else { colorName = "Orange" }
        }
        // Yellow-Orange range
        else if hueAngle < 50 {
            if isDark { colorName = "Brown" }
            else if isLight && isPale { colorName = "Cream" }
            else { colorName = "Gold" }
        }
        // Yellow range
        else if hueAngle < 70 {
            if isVeryDark { colorName = "Olive" }
            else if isDark { colorName = "Dark Yellow" }
            else if isPale && isLight { colorName = "Cream" }
            else if isPale { colorName = "Beige" }
            else { colorName = "Yellow" }
        }
        // Yellow-Green range
        else if hueAngle < 85 {
            if isDark { colorName = "Olive" }
            else if isPale { colorName = "Light Olive" }
            else { colorName = "Yellow-Green" }
        }
        // Green range
        else if hueAngle < 150 {
            if isVeryLight && isPale { colorName = "Mint" }
            else if isVeryLight { colorName = "Light Green" }
            else if isVeryDark { colorName = "Dark Green" }
            else if isDark { colorName = "Forest Green" }
            else if isPale { colorName = "Sage" }
            else if isVivid { colorName = "Bright Green" }
            else { colorName = "Green" }
        }
        // Cyan-Green range
        else if hueAngle < 170 {
            if isLight { colorName = "Aqua" }
            else if isDark { colorName = "Teal" }
            else { colorName = "Cyan-Green" }
        }
        // Cyan range
        else if hueAngle < 195 {
            if isVeryLight { colorName = "Light Cyan" }
            else if isDark { colorName = "Dark Cyan" }
            else { colorName = "Cyan" }
        }
        // Light Blue range
        else if hueAngle < 220 {
            if isVeryLight && isPale { colorName = "Powder Blue" }
            else if isVeryLight { colorName = "Sky Blue" }
            else if isDark { colorName = "Steel Blue" }
            else { colorName = "Light Blue" }
        }
        // Blue range
        else if hueAngle < 255 {
            if isVeryLight && isPale { colorName = "Periwinkle" }
            else if isVeryDark { colorName = "Navy" }
            else if isDark { colorName = "Dark Blue" }
            else if isVivid { colorName = "Bright Blue" }
            else { colorName = "Blue" }
        }
        // Blue-Purple range
        else if hueAngle < 275 {
            if isVeryLight { colorName = "Lavender" }
            else if isDark { colorName = "Indigo" }
            else { colorName = "Violet" }
        }
        // Purple range
        else if hueAngle < 310 {
            if isVeryLight && isPale { colorName = "Lavender" }
            else if isVeryLight { colorName = "Light Purple" }
            else if isVeryDark { colorName = "Dark Purple" }
            else if isPale { colorName = "Mauve" }
            else { colorName = "Purple" }
        }
        // Magenta/Pink range
        else if hueAngle < 335 {
            if isVeryLight { colorName = "Pink" }
            else if isDark { colorName = "Magenta" }
            else if isPale { colorName = "Rose" }
            else { colorName = "Hot Pink" }
        }
        // Pink-Red range
        else {
            if isVeryLight { colorName = "Light Pink" }
            else if isDark { colorName = "Maroon" }
            else if isPale { colorName = "Dusty Rose" }
            else { colorName = "Pink" }
        }
        
        return colorName
    }
    
    // Normalize RGB values to compensate for lighting conditions
    private func normalizeForLighting(r: CGFloat, g: CGFloat, b: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
        // Calculate perceived luminance
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        
        // If image is very dark or very bright, normalize
        if luminance < 0.01 {
            return (r, g, b) // Too dark to normalize
        }
        
        // Gray world assumption - assume average should be neutral gray
        let avgColor = (r + g + b) / 3.0
        
        // Only normalize if there's significant color cast from lighting
        if avgColor > 0.05 {
            // Calculate scaling factors to normalize toward gray
            let scaleR = avgColor / max(r, 0.01)
            let scaleG = avgColor / max(g, 0.01)
            let scaleB = avgColor / max(b, 0.01)
            
            // Blend between original and normalized (50% blend to preserve some original)
            let blendFactor: CGFloat = 0.4
            let normR = min(1.0, r * (1 + (scaleR - 1) * blendFactor))
            let normG = min(1.0, g * (1 + (scaleG - 1) * blendFactor))
            let normB = min(1.0, b * (1 + (scaleB - 1) * blendFactor))
            
            return (normR, normG, normB)
        }
        
        return (r, g, b)
    }
    
    // Convert RGB to HSL (Hue, Saturation, Lightness) - better for color perception
    private func rgbToHSL(r: CGFloat, g: CGFloat, b: CGFloat) -> (h: CGFloat, s: CGFloat, l: CGFloat) {
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC
        
        // Lightness
        let l = (maxC + minC) / 2.0
        
        // Saturation
        var s: CGFloat = 0
        if delta > 0 {
            s = delta / (1 - abs(2 * l - 1))
        }
        
        // Hue
        var h: CGFloat = 0
        if delta > 0 {
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
        
        return (h, min(1, max(0, s)), l)
    }
}

class CameraService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {
    @Published var session: AVCaptureSession?
    var delegate: AVCapturePhotoCaptureDelegate?
    
    let output = AVCapturePhotoOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()
    let videoOutput = AVCaptureVideoDataOutput()
    let processingQueue = DispatchQueue(label: "com.colourblind.processing")
    
    @Published var dominantColor: String = "Unknown"
    @Published var colorBlindnessType: ColorBlindnessType = .normal
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera { _ in }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setupCamera { _ in }
                    }
                }
            }
        case .denied, .restricted:
            print("Camera access denied")
        @unknown default:
            break
        }
    }
    
    func start(delegate: AVCapturePhotoCaptureDelegate, completion: @escaping (Error?)->()) {
        self.delegate = delegate
        checkPermission(completion: completion)
    }
    
    private func checkPermission(completion: @escaping(Error?)->()) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    guard granted else { return }
                    DispatchQueue.main.async {
                        self?.setupCamera(completion: completion)
                    }
                }
            case .restricted:
                break
            case .denied:
                break
            case .authorized:
                setupCamera(completion: completion)
            @unknown default:
                break
        }
    }
    
    private func setupCamera(completion: @escaping(Error?)->()) {
        let session = AVCaptureSession()
        if let device = AVCaptureDevice.default(for: .video) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                
                if session.canAddOutput(output) {
                    session.addOutput(output)
                }
                
                videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
                if session.canAddOutput(videoOutput) {
                    session.addOutput(videoOutput)
                }
                
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session
                
                DispatchQueue.global(qos: .userInitiated).async {
                    session.startRunning()
                    DispatchQueue.main.async {
                        self.session = session
                        completion(nil)
                    }
                }
            } catch {
                completion(error)
            }
        }
    }
    
    func capturePhoto(with settings: AVCapturePhotoSettings = AVCapturePhotoSettings()) {
        output.capturePhoto(with: settings, delegate: delegate!)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        if let processedBuffer = DaltonizationFilter.shared.processBuffer(pixelBuffer, type: colorBlindnessType) {
            let ciImage = CIImage(cvPixelBuffer: processedBuffer)
            let context = CIContext()
            
            let centerRect = CGRect(x: ciImage.extent.width/2 - 50,
                                  y: ciImage.extent.height/2 - 50,
                                  width: 100,
                                  height: 100)
            
            guard let centerImage = context.createCGImage(ciImage, from: centerRect) else { return }
            
            let uiImage = UIImage(cgImage: centerImage)
            
            if let color = uiImage.averageColor {
                DispatchQueue.main.async {
                    self.dominantColor = color.closestColorName()
                }
            }
        }
    }
}