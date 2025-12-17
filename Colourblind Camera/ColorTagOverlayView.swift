//
//  ColorTagOverlayView.swift
//  Colourblind Camera
//
//  Real-time color tag overlay system with TTS integration
//

import SwiftUI
import AVFoundation
import CoreImage
import Vision

struct ColorTagOverlayView: View {
    @StateObject private var colorDetector = ColorRegionDetector()
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var enableTTS = true
    @State private var showLabels = true
    @State private var detectionSensitivity: Float = 0.5
    
    let cameraService: CameraService
    
    var body: some View {
        ZStack {
            // Base camera view would go here
            GeometryReader { geometry in
                ForEach(colorDetector.colorRegions, id: \.id) { region in
                    ColorTagView(
                        region: region,
                        showLabel: showLabels,
                        onTap: { speakColor(region.colorName) }
                    )
                    .position(
                        x: region.center.x * geometry.size.width,
                        y: region.center.y * geometry.size.height
                    )
                }
            }
            
            // Controls overlay
            VStack {
                HStack {
                    // Toggle labels button
                    Button(action: { showLabels.toggle() }) {
                        Image(systemName: showLabels ? "tag.fill" : "tag")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    // Toggle TTS button
                    Button(action: { enableTTS.toggle() }) {
                        Image(systemName: enableTTS ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Sensitivity slider
                    VStack {
                        Text("Sensitivity")
                            .font(.caption)
                            .foregroundColor(.white)
                        Slider(value: Binding(
                            get: { detectionSensitivity },
                            set: { detectionSensitivity = $0; colorDetector.setSensitivity($0) }
                        ), in: 0.1...1.0)
                        .frame(width: 100)
                    }
                    .padding(10)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                }
                .padding()
                
                Spacer()
            }
        }
        .onAppear {
            colorDetector.startDetection(with: cameraService)
        }
        .onDisappear {
            colorDetector.stopDetection()
        }
    }
    
    private func speakColor(_ colorName: String) {
        guard enableTTS else { return }
        
        let utterance = AVSpeechUtterance(string: colorName)
        utterance.rate = 0.5
        utterance.volume = 0.8
        speechSynthesizer.speak(utterance)
    }
}

struct ColorTagView: View {
    let region: ColorRegion
    let showLabel: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                // Color swatch
                RoundedRectangle(cornerRadius: 4)
                    .fill(region.averageColor)
                    .frame(width: 20, height: 20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white, lineWidth: 1)
                    )
                
                // Color label
                if showLabel {
                    Text(region.colorName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showLabel)
    }
}

// Color region detection model
struct ColorRegion {
    let id = UUID()
    let center: CGPoint
    let boundingBox: CGRect
    let averageColor: Color
    let colorName: String
    let confidence: Float
}

class ColorRegionDetector: ObservableObject {
    @Published var colorRegions: [ColorRegion] = []
    private var cameraService: CameraService?
    private var detectionTimer: Timer?
    private var sensitivity: Float = 0.5
    
    func startDetection(with cameraService: CameraService) {
        self.cameraService = cameraService
        detectionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.detectColorRegions()
        }
    }
    
    func stopDetection() {
        detectionTimer?.invalidate()
        detectionTimer = nil
    }
    
    func setSensitivity(_ sensitivity: Float) {
        self.sensitivity = sensitivity
    }
    
    private func detectColorRegions() {
        // This would integrate with Vision framework to detect distinct color regions
        // For now, we'll simulate the detection
        DispatchQueue.main.async {
            self.colorRegions = self.generateMockColorRegions()
        }
    }
    
    private func generateMockColorRegions() -> [ColorRegion] {
        // Mock implementation - replace with actual Vision-based detection
        return [
            ColorRegion(
                center: CGPoint(x: 0.3, y: 0.4),
                boundingBox: CGRect(x: 0.25, y: 0.35, width: 0.1, height: 0.1),
                averageColor: .red,
                colorName: "Red",
                confidence: 0.9
            ),
            ColorRegion(
                center: CGPoint(x: 0.7, y: 0.6),
                boundingBox: CGRect(x: 0.65, y: 0.55, width: 0.1, height: 0.1),
                averageColor: .green,
                colorName: "Green",
                confidence: 0.8
            )
        ]
    }
}