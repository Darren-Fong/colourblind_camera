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
        filter?.setValue(CIVector(values: matrix, count: 16), forKey: "inputRVector")
        filter?.setValue(CIVector(values: matrix, count: 16), forKey: "inputGVector")
        filter?.setValue(CIVector(values: matrix, count: 16), forKey: "inputBVector")
        
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