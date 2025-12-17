import CoreML
import Vision
import SwiftUI

@available(iOS 17.0, *)
class ImagePredictor {
    // Load the FastViTMA36F16 Core ML model
    static let imageClassifier: VNCoreMLModel = {
        do {
            // Replace `FastViTMA36F16` with the actual name of your Core ML model
            let config = MLModelConfiguration()
            let model = try VNCoreMLModel(for: MobileNetV2(configuration: config).model)
            return model
        } catch {
            fatalError("Failed to load FastViTMA36F16 Core ML model: \(error)")
        }
    }()

    // Handle the Vision request and update the recognized object
    static func visionRequestHandler(request: VNRequest, error: Error?, recognizedObject: Binding<String>) {
        guard let results = request.results as? [VNClassificationObservation] else {
            recognizedObject.wrappedValue = "No results found."
            return
        }

        if let topResult = results.first {
            // Display the top result with its confidence percentage
            recognizedObject.wrappedValue = "\(topResult.identifier) (\(Int(topResult.confidence * 100))%)"
        } else {
            recognizedObject.wrappedValue = "No object recognized."
        }
    }
}
