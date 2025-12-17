import SwiftUI
import AVFoundation
import UIKit
import CoreImage

// Idea 1: Color Context Interpreter - Real-Time Color Naming
struct ColorContextInterpreterView: View {
    @StateObject private var cameraManager = ColorCameraManager()
    @State private var selectedPoint: CGPoint?
    @State private var detectedColorName: String = "Tap on screen to detect color"
    @State private var detectedRGB: (r: Int, g: Int, b: Int)?
    @State private var isSpeaking = false
    
    var body: some View {
        ZStack {
            // Live camera feed
            CameraPreviewView(cameraManager: cameraManager)
                .edgesIgnoringSafeArea(.all)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            handleTap(at: value.location)
                        }
                )
            
            VStack {
                Spacer()
                
                // Color info panel
                VStack(spacing: 15) {
                    Text(detectedColorName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    if let rgb = detectedRGB {
                        HStack(spacing: 20) {
                            ColorValueLabel(label: "R", value: rgb.r, color: .red)
                            ColorValueLabel(label: "G", value: rgb.g, color: .green)
                            ColorValueLabel(label: "B", value: rgb.b, color: .blue)
                        }
                    }
                    
                    // Voice control button
                    Button(action: {
                        speakColorName()
                    }) {
                        HStack {
                            Image(systemName: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
                            Text(isSpeaking ? "Speaking..." : "Speak Color Name")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(12)
                    }
                    .disabled(detectedColorName == "Tap on screen to detect color")
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(20)
                .padding()
            }
            
            // Crosshair at tap location
            if let point = selectedPoint {
                Circle()
                    .stroke(Color.white, lineWidth: 3)
                    .frame(width: 60, height: 60)
                    .position(point)
                
                Circle()
                    .stroke(Color.black, lineWidth: 1)
                    .frame(width: 62, height: 62)
                    .position(point)
            }
        }
        .navigationTitle("Color Interpreter")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    private func handleTap(at location: CGPoint) {
        selectedPoint = location
        
        if let rgb = cameraManager.getPixelColor(at: location) {
            detectedRGB = rgb
            detectedColorName = ColorNameLookup.shared.getColorName(r: rgb.r, g: rgb.g, b: rgb.b)
            speakColorName()
        }
    }
    
    private func speakColorName() {
        guard detectedColorName != "Tap on screen to detect color" else { return }
        
        isSpeaking = true
        let utterance = AVSpeechUtterance(string: detectedColorName)
        utterance.rate = 0.5
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSpeaking = false
        }
    }
}

struct ColorValueLabel: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundColor(.white)
            Text("\(value)")
                .font(.headline)
                .foregroundColor(color)
                .padding(8)
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
        }
    }
}

// Camera Manager for live feed
class ColorCameraManager: NSObject, ObservableObject {
    @Published var frame: CGImage?
    private var captureSession: AVCaptureSession?
    private let videoOutput = AVCaptureVideoDataOutput()
    private var currentBuffer: CVPixelBuffer?
    
    func startSession() {
        setupCaptureSession()
        captureSession?.startRunning()
    }
    
    func stopSession() {
        captureSession?.stopRunning()
    }
    
    private func setupCaptureSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        captureSession = session
    }
    
    func getPixelColor(at point: CGPoint) -> (r: Int, g: Int, b: Int)? {
        guard let buffer = currentBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        
        let x = Int(point.x * CGFloat(width) / UIScreen.main.bounds.width)
        let y = Int(point.y * CGFloat(height) / UIScreen.main.bounds.height)
        
        guard x >= 0, x < width, y >= 0, y < height else { return nil }
        
        let baseAddress = CVPixelBufferGetBaseAddress(buffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let buffer32 = baseAddress!.assumingMemoryBound(to: UInt8.self)
        
        let offset = y * bytesPerRow + x * 4
        let b = Int(buffer32[offset])
        let g = Int(buffer32[offset + 1])
        let r = Int(buffer32[offset + 2])
        
        return (r, g, b)
    }
}

extension ColorCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        currentBuffer = pixelBuffer
        
        DispatchQueue.main.async {
            self.frame = self.imageFromSampleBuffer(sampleBuffer)
        }
    }
    
    private func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: ColorCameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let frame = cameraManager.frame {
            let layer = CALayer()
            layer.contents = frame
            layer.frame = uiView.bounds
            layer.contentsGravity = .resizeAspectFill
            uiView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            uiView.layer.addSublayer(layer)
        }
    }
}

// Color name lookup table
class ColorNameLookup {
    static let shared = ColorNameLookup()
    
    private let colorDatabase: [(name: String, r: Int, g: Int, b: Int)] = [
        ("Red", 255, 0, 0),
        ("Green", 0, 255, 0),
        ("Blue", 0, 0, 255),
        ("Yellow", 255, 255, 0),
        ("Cyan", 0, 255, 255),
        ("Magenta", 255, 0, 255),
        ("White", 255, 255, 255),
        ("Black", 0, 0, 0),
        ("Gray", 128, 128, 128),
        ("Orange", 255, 165, 0),
        ("Purple", 128, 0, 128),
        ("Pink", 255, 192, 203),
        ("Brown", 165, 42, 42),
        ("Lime", 0, 255, 0),
        ("Navy", 0, 0, 128),
        ("Teal", 0, 128, 128),
        ("Olive", 128, 128, 0),
        ("Maroon", 128, 0, 0),
        ("Aqua", 0, 255, 255),
        ("Silver", 192, 192, 192)
    ]
    
    func getColorName(r: Int, g: Int, b: Int) -> String {
        var closestColor = "Unknown"
        var minDistance = Double.infinity
        
        for color in colorDatabase {
            let distance = sqrt(
                pow(Double(r - color.r), 2) +
                pow(Double(g - color.g), 2) +
                pow(Double(b - color.b), 2)
            )
            
            if distance < minDistance {
                minDistance = distance
                closestColor = color.name
            }
        }
        
        return closestColor
    }
}
