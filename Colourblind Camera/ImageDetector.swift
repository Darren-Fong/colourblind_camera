import SwiftUI
import CoreML
import Vision

struct ImageDetector: View {
    @State private var recognizedObject: String = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil

    var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                Text(recognizedObject)
                    .font(.headline)
                    .padding()
            } else {
                Button("Select Image") {
                    showImagePicker.toggle()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView2(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { oldValue, newValue in
            if let image = newValue {
                performImageRecognition(image: image)
            }
        }
    }

    func performImageRecognition(image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            recognizedObject = "Unable to process image."
            return
        }

        let handler = VNImageRequestHandler(ciImage: ciImage)

        do {
            if #available(iOS 17.0, *) {
                try handler.perform([VNCoreMLRequest(model: ImagePredictor.imageClassifier, completionHandler: { request, error in
                    DispatchQueue.main.async {
                        ImagePredictor.visionRequestHandler(request: request, error: error, recognizedObject: self.$recognizedObject)
                    }
                })])
            } else {
                // Fallback on earlier versions
            }
        } catch {
            recognizedObject = "Error performing image recognition: \(error.localizedDescription)"
        }
    }
}
