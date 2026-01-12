//
//  CameraManager.swift
//  Colourblind Camera
//
//  Optimized camera service with minimal overhead
//

import AVFoundation
import Vision
import CoreML
import SwiftUI

@MainActor
class CameraManager: NSObject, ObservableObject {
    @Published var detectedColor = "Unknown"
    @Published var detectedObject = ""
    @Published var objectConfidence = 0
    @Published var isRunning = false
    
    nonisolated(unsafe) var enableObjectDetection = false
    nonisolated(unsafe) var useVisionForColor = false
    
    private var captureSession: AVCaptureSession?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session", qos: .userInitiated)
    private let processingQueue = DispatchQueue(label: "camera.processing", qos: .utility)
    
    nonisolated(unsafe) private var lastProcessTime = Date.distantPast
    nonisolated(unsafe) private let processingInterval: TimeInterval = 0.15
    nonisolated(unsafe) private var isProcessingFrame = false
    
    // Lazy load ML model
    nonisolated(unsafe) private lazy var mlModel: VNCoreMLModel? = {
        guard #available(iOS 17.0, *) else { return nil }
        let config = MLModelConfiguration()
        config.computeUnits = .cpuAndNeuralEngine
        return try? VNCoreMLModel(for: MobileNetV2(configuration: config).model)
    }()
    
    nonisolated(unsafe) private let colorRecognizer = ColorRecognizer()
    
    override init() {
        super.init()
    }
    
    nonisolated func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                await self.setupSession()
            }
        }
    }
    
    nonisolated func stopSession() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.internalStopSession()
        }
    }
    
    private func internalStopSession() async {
        captureSession?.stopRunning()
        captureSession = nil
        isRunning = false
    }
    
    private func setupSession() async {
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        
        session.addInput(input)
        
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        session.commitConfiguration()
        
        session.startRunning()
        captureSession = session
        isRunning = true
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }
}

// MARK: - Video Delegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = Date()
        guard now.timeIntervalSince(lastProcessTime) >= processingInterval,
              !isProcessingFrame else { return }
        
        isProcessingFrame = true
        lastProcessTime = now
        
        defer { isProcessingFrame = false }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Process color (fast)
        processColor(pixelBuffer)
        
        // Process object if enabled (slow)
        if enableObjectDetection {
            processObject(pixelBuffer)
        }
    }
    
    nonisolated private func processColor(_ pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        guard let buffer = CVPixelBufferGetBaseAddress(pixelBuffer)?.assumingMemoryBound(to: UInt8.self) else { return }
        
        // Sample center region
        let cx = width / 2
        let cy = height / 2
        
        var r: Double = 0, g: Double = 0, b: Double = 0
        var count = 0
        
        // Center point (weighted)
        for _ in 0..<3 {
            let offset = cy * bytesPerRow + cx * 4
            r += Double(buffer[offset + 2])
            g += Double(buffer[offset + 1])
            b += Double(buffer[offset])
            count += 1
        }
        
        // Cardinal points
        for (dx, dy) in [(0, 50), (0, -50), (50, 0), (-50, 0)] {
            let x = cx + dx, y = cy + dy
            guard x >= 0, x < width, y >= 0, y < height else { continue }
            let offset = y * bytesPerRow + x * 4
            r += Double(buffer[offset + 2])
            g += Double(buffer[offset + 1])
            b += Double(buffer[offset])
            count += 1
        }
        
        let avgR = r / Double(count) / 255.0
        let avgG = g / Double(count) / 255.0
        let avgB = b / Double(count) / 255.0
        
        let color = colorRecognizer.recognize(r: avgR, g: avgG, b: avgB)
        
        Task { @MainActor in
            self.detectedColor = color
        }
    }
    
    nonisolated private func processObject(_ pixelBuffer: CVPixelBuffer) {
        guard let model = mlModel else { return }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, _ in
            guard let results = request.results as? [VNClassificationObservation],
                  let top = results.first,
                  top.confidence > 0.2 else { return }
            
            let name = top.identifier
                .components(separatedBy: ",").first?
                .replacingOccurrences(of: "_", with: " ")
                .capitalized ?? "Unknown"
            
            let conf = Int(top.confidence * 100)
            
            Task { @MainActor in
                self?.detectedObject = name
                self?.objectConfidence = conf
            }
        }
        
        request.imageCropAndScaleOption = .centerCrop
        try? handler.perform([request])
    }
}
