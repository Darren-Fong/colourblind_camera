import SwiftUI
import AVFoundation
import CoreML
import Vision

struct CameraView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController
    
    let cameraService: CameraService
    let didFinishProcessingPhoto: (Result<AVCapturePhoto, Error>) -> ()
    
    func makeUIViewController(context: Context) -> UIViewController {
        cameraService.start(delegate: context.coordinator) { err in
            if let err = err {
                didFinishProcessingPhoto(.failure(err))
                return
            }
        }
        
        let viewController = UIViewController()
        viewController.view.backgroundColor = .black
        viewController.view.layer.addSublayer(cameraService.previewLayer)
        cameraService.previewLayer.frame = viewController.view.bounds
        return viewController
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, didFinishProcessingPhoto: didFinishProcessingPhoto)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
    
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        let parent: CameraView
        private var didFinishProcessingPhoto: (Result<AVCapturePhoto, Error>) -> ()
        
        init(parent: CameraView,
             didFinishProcessingPhoto: @escaping (Result<AVCapturePhoto, Error>) -> ()) {
            self.parent = parent
            self.didFinishProcessingPhoto = didFinishProcessingPhoto
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let error = error {
                didFinishProcessingPhoto(.failure(error))
                return
            }
            
            // Pass the captured photo to the completion handler
            didFinishProcessingPhoto(.success(photo))
            
            // Perform AI image recognition on the captured photo
            if let imageData = photo.fileDataRepresentation(), let uiImage = UIImage(data: imageData) {
                performImageRecognition(image: uiImage)
            }
        }
        
        private func performImageRecognition(image: UIImage) {
            guard let ciImage = CIImage(image: image) else {
                print("Unable to process image.")
                return
            }
            
            guard let model = try? VNCoreMLModel(for: MobileNetV2(configuration: MLModelConfiguration()).model) else {
                print("Failed to load Core ML model.")
                return
            }
            
            let request = VNCoreMLRequest(model: model) { request, error in
                DispatchQueue.main.async {
                    self.processVisionResults(request: request, error: error)
                }
            }
            
            let handler = VNImageRequestHandler(ciImage: ciImage)
            do {
                try handler.perform([request])
            } catch {
                print("Error performing image recognition: \(error.localizedDescription)")
            }
        }
        
        private func processVisionResults(request: VNRequest?, error: Error?) {
            guard let results = request?.results as? [VNClassificationObservation], !results.isEmpty else {
                print("No results found.")
                return
            }
            if let topResult = results.first {
                print("Recognized Object: \(topResult.identifier) (\(Int(topResult.confidence * 100))%)")
            } else {
                print("No object recognized.")
            }
        }
    }
}
