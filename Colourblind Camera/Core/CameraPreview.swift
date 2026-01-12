//
//  CameraPreview.swift
//  Colourblind Camera
//
//  SwiftUI camera preview
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        if let layer = cameraManager.getPreviewLayer() {
            view.setPreviewLayer(layer)
        }
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {}
    
    class PreviewView: UIView {
        private var previewLayer: AVCaptureVideoPreviewLayer?
        
        func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
            previewLayer = layer
            layer.frame = bounds
            self.layer.addSublayer(layer)
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer?.frame = bounds
        }
    }
}
