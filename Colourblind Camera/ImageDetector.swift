import SwiftUI
import CoreML
import Vision
import AVFoundation

struct ImageDetector: View {
    @State private var recognizedObject: String = ""
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var isProcessing = false
    @State private var confidence: Int = 0
    private let speechSynthesizer = AVSpeechSynthesizer()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let image = selectedImage {
                    // Image Display
                    VStack(spacing: 16) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.2), radius: 10)
                        
                        // Recognition Result
                        if isProcessing {
                            HStack(spacing: 12) {
                                ProgressView()
                                Text("Analyzing image...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        } else if !recognizedObject.isEmpty {
                            VStack(spacing: 12) {
                                Text("Detected Object")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(recognizedObject)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                if confidence > 0 {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(confidence > 70 ? .green : .orange)
                                        Text("\(confidence)% confident")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // Speak button
                                Button(action: speakResult) {
                                    HStack {
                                        Image(systemName: "speaker.wave.2.fill")
                                        Text("Speak Result")
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                        }
                        
                        // Action Buttons
                        HStack(spacing: 16) {
                            Button(action: { showImagePicker.toggle() }) {
                                HStack {
                                    Image(systemName: "photo")
                                    Text("Choose Another")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            
                            Button(action: clearImage) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Clear")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                } else {
                    // Empty State
                    VStack(spacing: 24) {
                        Spacer()
                        
                        Image(systemName: "viewfinder.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.blue.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text("Object Recognition")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Select an image to identify objects using AI")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: { showImagePicker.toggle() }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("Select Image from Library")
                            }
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Spacer()
                        
                        // Info Section
                        VStack(alignment: .leading, spacing: 12) {
                            Label("AI-Powered Recognition", systemImage: "brain.head.profile")
                                .font(.subheadline)
                            Label("Works Offline", systemImage: "wifi.slash")
                                .font(.subheadline)
                            Label("Voice Announcements", systemImage: "speaker.wave.2")
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Object Recognition")
        .navigationBarTitleDisplayMode(.large)
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
        
        isProcessing = true
        recognizedObject = ""
        confidence = 0

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        do {
            if #available(iOS 17.0, *) {
                let request = VNCoreMLRequest(model: ImagePredictor.imageClassifier) { request, error in
                    DispatchQueue.main.async {
                        self.isProcessing = false
                        
                        if let error = error {
                            self.recognizedObject = "Error: \(error.localizedDescription)"
                            return
                        }
                        
                        guard let results = request.results as? [VNClassificationObservation],
                              let topResult = results.first else {
                            self.recognizedObject = "No objects detected"
                            return
                        }
                        
                        // Format the identifier to be more readable
                        let identifier = topResult.identifier
                            .replacingOccurrences(of: "_", with: " ")
                            .capitalized
                        
                        self.recognizedObject = identifier
                        self.confidence = Int(topResult.confidence * 100)
                        
                        // Auto-speak if confidence is high
                        if self.confidence > 50 {
                            self.speakResult()
                        }
                    }
                }
                
                // Configure request for better results
                request.imageCropAndScaleOption = .centerCrop
                
                try handler.perform([request])
            } else {
                // Fallback for iOS versions below 17.0
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.recognizedObject = "Object recognition requires iOS 17.0 or later"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isProcessing = false
                self.recognizedObject = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    private func speakResult() {
        guard !recognizedObject.isEmpty,
              !recognizedObject.contains("Error"),
              !recognizedObject.contains("requires") else { return }
        
        let textToSpeak = "I detected \(recognizedObject) with \(confidence) percent confidence"
        let utterance = AVSpeechUtterance(string: textToSpeak)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        speechSynthesizer.speak(utterance)
    }
    
    private func clearImage() {
        selectedImage = nil
        recognizedObject = ""
        confidence = 0
        isProcessing = false
    }
}
