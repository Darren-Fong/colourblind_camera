//
//  CameraService.swift
//  Colourblind Camera
//
//  Created by Alex Au on 2/12/2024.
//
import SwiftUI
import Foundation
import AVFoundation
import CoreImage

extension UIImage {
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x,
                                  y: inputImage.extent.origin.y,
                                  z: inputImage.extent.size.width,
                                  w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage",
                                  parameters: [kCIInputImageKey: inputImage,
                                             kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage,
                      toBitmap: &bitmap,
                      rowBytes: 4,
                      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                      format: .RGBA8,
                      colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255,
                      green: CGFloat(bitmap[1]) / 255,
                      blue: CGFloat(bitmap[2]) / 255,
                      alpha: CGFloat(bitmap[3]) / 255)
    }
}

extension UIColor {
    func closestColorName() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        // Define basic colors and their names
        let colors: [(name: String, color: (r: CGFloat, g: CGFloat, b: CGFloat))] = [
            ("Red", (1, 0, 0)),
            ("Green", (0, 1, 0)),
            ("Blue", (0, 0, 1)),
            ("Yellow", (1, 1, 0)),
            ("Purple", (0.5, 0, 0.5)),
            ("Orange", (1, 0.5, 0)),
            ("Brown", (0.6, 0.3, 0)),
            ("Pink", (1, 0.7, 0.7)),
            ("Gray", (0.5, 0.5, 0.5)),
            ("Black", (0, 0, 0)),
            ("White", (1, 1, 1))
        ]
        
        // Find the closest color by calculating the distance in RGB space
        var minDistance = CGFloat.infinity
        var closestColor = "Unknown"
        
        for color in colors {
            let distance = sqrt(
                pow(r - color.color.r, 2) +
                pow(g - color.color.g, 2) +
                pow(b - color.color.b, 2)
            )
            
            if distance < minDistance {
                minDistance = distance
                closestColor = color.name
            }
        }
        
        return closestColor
    }
}

class CameraService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {
    @Published var session: AVCaptureSession?
    var delegate: AVCapturePhotoCaptureDelegate?
    
    let output = AVCapturePhotoOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()
    let videoOutput = AVCaptureVideoDataOutput()
    let processingQueue = DispatchQueue(label: "com.colourblind.processing")
    
    @Published var dominantColor: String = "Unknown"
    @Published var colorBlindnessType: ColorBlindnessType = .normal
    
    func checkPermissions() {
        checkPermission { error in
            if let error = error {
                print("Camera setup error: \(error)")
            }
        }
    }
    
    func start(delegate: AVCapturePhotoCaptureDelegate, completion: @escaping (Error?)->()) {
        self.delegate = delegate
        checkPermission(completion: completion)
    }
    
    private func checkPermission(completion: @escaping(Error?)->()) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    guard granted else { return }
                    DispatchQueue.main.async {
                        self?.setupCamera(completion: completion)
                    }
                }
            case .restricted:
                break
            case .denied:
                break
            case .authorized:
                setupCamera(completion: completion)
            @unknown default:
                break
        }
    }
    
    private func setupCamera(completion: @escaping(Error?)->()) {
        let session = AVCaptureSession()
        if let device = AVCaptureDevice.default(for: .video) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                
                if session.canAddOutput(output) {
                    session.addOutput(output)
                }
                
                videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
                if session.canAddOutput(videoOutput) {
                    session.addOutput(videoOutput)
                }
                
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session
                
                DispatchQueue.global(qos: .userInitiated).async {
                    session.startRunning()
                    DispatchQueue.main.async {
                        self.session = session
                        completion(nil)
                    }
                }
            } catch {
                completion(error)
            }
        }
    }
    
    func capturePhoto(with settings: AVCapturePhotoSettings = AVCapturePhotoSettings()) {
        output.capturePhoto(with: settings, delegate: delegate!)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        if let processedBuffer = DaltonizationFilter.shared.processBuffer(pixelBuffer, type: colorBlindnessType) {
            let ciImage = CIImage(cvPixelBuffer: processedBuffer)
            let context = CIContext()
            
            let centerRect = CGRect(x: ciImage.extent.width/2 - 50,
                                  y: ciImage.extent.height/2 - 50,
                                  width: 100,
                                  height: 100)
            
            guard let centerImage = context.createCGImage(ciImage, from: centerRect) else { return }
            
            let uiImage = UIImage(cgImage: centerImage)
            
            if let color = uiImage.averageColor {
                DispatchQueue.main.async {
                    self.dominantColor = color.closestColorName()
                }
            }
        }
    }
}