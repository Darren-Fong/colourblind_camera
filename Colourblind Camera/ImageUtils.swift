import UIKit
import CoreImage

func preprocessImage(_ image: UIImage) -> CIImage? {
    guard let ciImage = CIImage(image: image) else { return nil }
    
    // Apply any custom preprocessing here (e.g., cropping, scaling)
    let context = CIContext()
    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
    return CIImage(cgImage: cgImage)
}
