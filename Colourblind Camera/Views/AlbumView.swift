//
//  AlbumView.swift
//  Colourblind Camera
//
//  Photo album view for saved colors
//

import SwiftUI
import PhotosUI

struct AlbumView: View {
    @State private var selectedImage: UIImage?
    @State private var showingPicker = false
    @State private var detectedColor = "Select a photo"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .cornerRadius(16)
                        .shadow(radius: 10)
                    
                    Text(detectedColor)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                } else {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    
                    Text("No photo selected")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showingPicker = true
                }) {
                    Label("Choose Photo", systemImage: "photo.on.rectangle.angled")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding()
            }
            .padding()
            .navigationTitle("Photo Album")
            .sheet(isPresented: $showingPicker) {
                ImagePicker(selectedImage: $selectedImage, detectedColor: $detectedColor)
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var detectedColor: String
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                guard let self = self, let uiImage = image as? UIImage else { return }
                
                DispatchQueue.main.async {
                    self.parent.selectedImage = uiImage
                    self.parent.detectedColor = self.analyzeColor(uiImage)
                }
            }
        }
        
        private func analyzeColor(_ image: UIImage) -> String {
            guard let ciImage = CIImage(image: image),
                  let filter = CIFilter(name: "CIAreaAverage") else {
                return "Unable to analyze"
            }
            
            let extent = ciImage.extent
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            filter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)
            
            guard let outputImage = filter.outputImage else { return "Unable to analyze" }
            
            var bitmap = [UInt8](repeating: 0, count: 4)
            let context = CIContext()
            context.render(outputImage,
                          toBitmap: &bitmap,
                          rowBytes: 4,
                          bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                          format: .RGBA8,
                          colorSpace: nil)
            
            let r = Double(bitmap[0]) / 255.0
            let g = Double(bitmap[1]) / 255.0
            let b = Double(bitmap[2]) / 255.0
            
            return ColorRecognizer().recognize(r: r, g: g, b: b)
        }
    }
}
