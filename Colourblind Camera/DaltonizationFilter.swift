import CoreImage
import UIKit

enum ColorBlindnessType: String, CaseIterable {
    case normal = "normal"
    case protanopia = "protanopia"
    case deuteranopia = "deuteranopia"
    case tritanopia = "tritanopia"
    
    var displayName: String {
        switch self {
        case .normal: return "Normal Vision"
        case .protanopia: return "Protanopia"
        case .deuteranopia: return "Deuteranopia"
        case .tritanopia: return "Tritanopia"
        }
    }
}

class DaltonizationFilter {
    static let shared = DaltonizationFilter()
    private let context = CIContext()
    
    func applyDaltonization(to image: CIImage, type: ColorBlindnessType) -> CIImage? {
        // Matrix values are based on research for color vision deficiency correction
        let matrix: [CGFloat]
        
        switch type {
        case .normal:
            return image
            
        case .protanopia:
            matrix = [
                0.567, 0.433, 0, 0,
                0.558, 0.442, 0, 0,
                0, 0.242, 0.758, 0,
                0, 0, 0, 1
            ]
            
        case .deuteranopia:
            matrix = [
                0.625, 0.375, 0, 0,
                0.7, 0.3, 0, 0,
                0, 0.3, 0.7, 0,
                0, 0, 0, 1
            ]
            
        case .tritanopia:
            matrix = [
                0.95, 0.05, 0, 0,
                0, 0.433, 0.567, 0,
                0, 0.475, 0.525, 0,
                0, 0, 0, 1
            ]
        }
        
        let filter = CIFilter(name: "CIColorMatrix")
        filter?.setValue(image, forKey: kCIInputImageKey)
        
        // CIColorMatrix expects separate 4-element vectors for each color channel
        // Each vector is [R, G, B, A] contribution to that output channel
        let rVector = CIVector(x: matrix[0], y: matrix[1], z: matrix[2], w: matrix[3])
        let gVector = CIVector(x: matrix[4], y: matrix[5], z: matrix[6], w: matrix[7])
        let bVector = CIVector(x: matrix[8], y: matrix[9], z: matrix[10], w: matrix[11])
        let aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        
        filter?.setValue(rVector, forKey: "inputRVector")
        filter?.setValue(gVector, forKey: "inputGVector")
        filter?.setValue(bVector, forKey: "inputBVector")
        filter?.setValue(aVector, forKey: "inputAVector")
        
        return filter?.outputImage
    }
    
    func processBuffer(_ buffer: CVPixelBuffer, type: ColorBlindnessType) -> CVPixelBuffer? {
        let ciImage = CIImage(cvPixelBuffer: buffer)
        guard let processedImage = applyDaltonization(to: ciImage, type: type) else { return nil }
        
        var outputBuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault,
                           CVPixelBufferGetWidth(buffer),
                           CVPixelBufferGetHeight(buffer),
                           CVPixelBufferGetPixelFormatType(buffer),
                           nil,
                           &outputBuffer)
        
        if let outputBuffer = outputBuffer {
            context.render(processedImage, to: outputBuffer)
            return outputBuffer
        }
        return nil
    }
}