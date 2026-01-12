//
//  LiveCameraView.swift
//  Colourblind Camera
//
//  Main live camera view with color and object detection
//

import SwiftUI

struct LiveCameraView: View {
    @StateObject private var camera = CameraManager()
    @State private var showColorInfo = true
    @State private var showObjectDetection = false
    
    var body: some View {
        ZStack {
            // Camera preview
            if camera.isRunning {
                CameraPreview(cameraManager: camera)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Color.black.edgesIgnoringSafeArea(.all)
                ProgressView("Starting Camera...")
                    .foregroundColor(.white)
            }
            
            // UI Overlay
            VStack {
                // Top controls
                HStack {
                    Button(action: {
                        withAnimation {
                            showColorInfo.toggle()
                        }
                    }) {
                        Image(systemName: showColorInfo ? "eye.fill" : "eye.slash")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showObjectDetection.toggle()
                            camera.enableObjectDetection = showObjectDetection
                        }
                    }) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundColor(showObjectDetection ? .yellow : .white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                }
                .padding()
                
                Spacer()
                
                // Info display
                VStack(spacing: 16) {
                    if showColorInfo {
                        VStack(spacing: 8) {
                            Text("Color")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(camera.detectedColor)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.7))
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    if showObjectDetection && !camera.detectedObject.isEmpty {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                Text("Object")
                                    .font(.caption)
                            }
                            .foregroundColor(.white.opacity(0.8))
                            
                            Text(camera.detectedObject)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(confidenceColor)
                                    .frame(width: 6, height: 6)
                                Text("\(camera.objectConfidence)%")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.purple.opacity(0.7))
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.bottom, 50)
            }
            
            // Crosshair
            Image(systemName: "plus")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.5))
        }
        .onAppear {
            camera.startSession()
        }
        .onDisappear {
            camera.stopSession()
        }
    }
    
    private var confidenceColor: Color {
        if camera.objectConfidence > 70 { return .green }
        if camera.objectConfidence > 40 { return .orange }
        return .yellow
    }
}
