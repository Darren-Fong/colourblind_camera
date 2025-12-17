//
//  ARColorRecognitionView.swift
//  Colourblind Camera
//
//  AR-powered real-time color identification and labeling
//

import SwiftUI
import ARKit
import RealityKit
import AVFoundation

struct ARColorRecognitionView: View {
    @StateObject private var arSession = ARColorSession()
    @State private var isARSupported = ARWorldTrackingConfiguration.isSupported
    @State private var showingSettings = false
    @State private var enableVoiceAnnouncements = true
    @State private var selectedColorBlindType: ColorBlindnessType = .normal
    
    var body: some View {
        ZStack {
            if isARSupported {
                // AR View
                ARViewContainer(
                    arSession: arSession,
                    colorBlindType: selectedColorBlindType
                )
                .edgesIgnoringSafeArea(.all)
                
                // Overlay UI
                VStack {
                    // Top controls
                    HStack {
                        // Settings button
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gear")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Color blind type indicator
                        Text(selectedColorBlindType.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(15)
                        
                        Spacer()
                        
                        // Voice toggle
                        Button(action: { 
                            enableVoiceAnnouncements.toggle()
                            arSession.setVoiceEnabled(enableVoiceAnnouncements)
                        }) {
                            Image(systemName: enableVoiceAnnouncements ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Bottom status bar
                    HStack {
                        // Active colors counter
                        HStack {
                            Image(systemName: "eye.fill")
                                .foregroundColor(.white)
                            Text("\(arSession.activeColorAnchors.count) colors detected")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        // AR tracking status
                        HStack {
                            Circle()
                                .fill(arSession.trackingState == .normal ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(arSession.trackingStatusText)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(20)
                    .padding()
                }
                
                // Crosshair for center targeting
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        CrosshairView()
                        Spacer()
                    }
                    Spacer()
                }
                
            } else {
                // AR not supported fallback
                ARNotSupportedView()
            }
        }
        .sheet(isPresented: $showingSettings) {
            ARSettingsView(
                colorBlindType: $selectedColorBlindType,
                voiceEnabled: $enableVoiceAnnouncements,
                arSession: arSession
            )
        }
        .onAppear {
            if isARSupported {
                arSession.start()
            }
        }
        .onDisappear {
            arSession.stop()
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    let arSession: ARColorSession
    let colorBlindType: ColorBlindnessType
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arSession.setupARView(arView)
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        arSession.updateColorBlindType(colorBlindType)
    }
}

struct CrosshairView: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 40, height: 40)
            
            Circle()
                .fill(Color.white)
                .frame(width: 4, height: 4)
        }
        .shadow(color: .black, radius: 2)
    }
}

struct ARNotSupportedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arkit")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("AR Not Supported")
                .font(.title)
                .fontWeight(.bold)
            
            Text("This device doesn't support ARKit. Please use a device with ARKit support for AR color recognition.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Use Standard Camera") {
                // Navigate back to regular camera
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
        }
        .padding()
    }
}

struct ARSettingsView: View {
    @Binding var colorBlindType: ColorBlindnessType
    @Binding var voiceEnabled: Bool
    let arSession: ARColorSession
    @Environment(\.presentationMode) var presentationMode
    
    @State private var detectionSensitivity: Float = 0.7
    @State private var labelDisplayDuration: Float = 5.0
    @State private var maxSimultaneousColors: Float = 10
    @State private var enableHapticFeedback = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Vision Settings")) {
                    Picker("Color Vision Type", selection: $colorBlindType) {
                        Text("Normal Vision").tag(ColorBlindnessType.normal)
                        Text("Protanopia (Red-blind)").tag(ColorBlindnessType.protanopia)
                        Text("Deuteranopia (Green-blind)").tag(ColorBlindnessType.deuteranopia)
                        Text("Tritanopia (Blue-blind)").tag(ColorBlindnessType.tritanopia)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Detection Settings")) {
                    VStack(alignment: .leading) {
                        Text("Detection Sensitivity")
                        Slider(value: $detectionSensitivity, in: 0.1...1.0, step: 0.1) {
                            Text("Sensitivity")
                        } minimumValueLabel: {
                            Text("Low")
                        } maximumValueLabel: {
                            Text("High")
                        }
                        .onChange(of: detectionSensitivity) { value in
                            arSession.setDetectionSensitivity(value)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Label Display Duration: \(Int(labelDisplayDuration))s")
                        Slider(value: $labelDisplayDuration, in: 1...15, step: 1)
                            .onChange(of: labelDisplayDuration) { value in
                                arSession.setLabelDuration(TimeInterval(value))
                            }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Max Colors: \(Int(maxSimultaneousColors))")
                        Slider(value: $maxSimultaneousColors, in: 5...20, step: 1)
                            .onChange(of: maxSimultaneousColors) { value in
                                arSession.setMaxColors(Int(value))
                            }
                    }
                }
                
                Section(header: Text("Feedback Settings")) {
                    Toggle("Voice Announcements", isOn: $voiceEnabled)
                        .onChange(of: voiceEnabled) { value in
                            arSession.setVoiceEnabled(value)
                        }
                    
                    Toggle("Haptic Feedback", isOn: $enableHapticFeedback)
                        .onChange(of: enableHapticFeedback) { value in
                            arSession.setHapticEnabled(value)
                        }
                }
                
                Section(header: Text("Performance")) {
                    Button("Reset AR Session") {
                        arSession.reset()
                    }
                    
                    Button("Clear All Labels") {
                        arSession.clearAllLabels()
                    }
                }
            }
            .navigationTitle("AR Settings")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// AR Session Management
class ARColorSession: NSObject, ObservableObject {
    @Published var activeColorAnchors: [ColorAnchor] = []
    @Published var trackingState: ARCamera.TrackingState = .notAvailable
    @Published var trackingStatusText: String = "Initializing..."
    
    private var arView: ARView?
    private var session: ARSession?
    private let speechSynthesizer = AVSpeechSynthesizer()
    private let colorDetector = RealTimeColorDetector()
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    // Settings
    private var currentColorBlindType: ColorBlindnessType = .normal
    private var voiceEnabled = true
    private var hapticEnabled = true
    private var detectionSensitivity: Float = 0.7
    private var labelDuration: TimeInterval = 5.0
    private var maxColors = 10
    
    private var lastAnnouncementTime: Date = Date.distantPast
    private let announcementCooldown: TimeInterval = 2.0
    
    func setupARView(_ arView: ARView) {
        self.arView = arView
        self.session = arView.session
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = [.personSegmentationWithDepth]
        configuration.planeDetection = [.horizontal, .vertical]
        
        arView.session.delegate = self
        arView.session.run(configuration)
        
        // Setup tap gesture for manual color detection
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        arView.addGestureRecognizer(tapGesture)
        
        // Start continuous color detection
        startContinuousDetection()
    }
    
    func start() {
        guard let arView = arView else { return }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = [.personSegmentationWithDepth]
        arView.session.run(configuration)
    }
    
    func stop() {
        session?.pause()
        clearAllLabels()
    }
    
    func reset() {
        guard let arView = arView else { return }
        
        let configuration = ARWorldTrackingConfiguration()
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        clearAllLabels()
    }
    
    func clearAllLabels() {
        activeColorAnchors.removeAll()
        arView?.scene.anchors.removeAll()
    }
    
    // Settings methods
    func updateColorBlindType(_ type: ColorBlindnessType) {
        currentColorBlindType = type
    }
    
    func setVoiceEnabled(_ enabled: Bool) {
        voiceEnabled = enabled
    }
    
    func setHapticEnabled(_ enabled: Bool) {
        hapticEnabled = enabled
    }
    
    func setDetectionSensitivity(_ sensitivity: Float) {
        detectionSensitivity = sensitivity
    }
    
    func setLabelDuration(_ duration: TimeInterval) {
        labelDuration = duration
    }
    
    func setMaxColors(_ max: Int) {
        maxColors = max
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = arView else { return }
        
        let location = gesture.location(in: arView)
        detectColorAt(screenPoint: location, isManual: true)
    }
    
    private func startContinuousDetection() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.performAutomaticDetection()
        }
    }
    
    private func performAutomaticDetection() {
        guard let arView = arView else { return }
        guard activeColorAnchors.count < maxColors else { return }
        
        // Detect color at center of screen
        let centerPoint = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        detectColorAt(screenPoint: centerPoint, isManual: false)
    }
    
    private func detectColorAt(screenPoint: CGPoint, isManual: Bool) {
        guard let arView = arView,
              let frame = arView.session.currentFrame else { return }
        
        // Convert screen point to normalized coordinates
        let normalizedPoint = CGPoint(
            x: screenPoint.x / arView.bounds.width,
            y: screenPoint.y / arView.bounds.height
        )
        
        // Sample color from camera image
        let pixelBuffer = frame.capturedImage
        guard let color = sampleColor(from: pixelBuffer, at: normalizedPoint) else { return }
        
        // Perform raycast to get world position
        guard let raycastQuery = arView.makeRaycastQuery(from: screenPoint, allowing: .estimatedPlane, alignment: .any),
              let raycastResult = arView.session.raycast(raycastQuery).first else { return }
        
        // Create color anchor
        let colorAnchor = ColorAnchor(
            color: color,
            position: raycastResult.worldTransform.translation,
            isManual: isManual,
            timestamp: Date()
        )
        
        // Check if this color is already detected nearby
        if !isDuplicateColor(colorAnchor) {
            addColorAnchor(colorAnchor)
        }
    }
    
    private func sampleColor(from pixelBuffer: CVPixelBuffer, at point: CGPoint) -> DetectedColor? {
        // Convert pixel buffer to UIImage and sample color
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        let uiImage = UIImage(cgImage: cgImage)
        
        // Sample pixel at the specified point
        let pixelX = Int(point.x * CGFloat(cgImage.width))
        let pixelY = Int(point.y * CGFloat(cgImage.height))
        
        guard let pixelColor = uiImage.getPixelColor(at: CGPoint(x: pixelX, y: pixelY)) else { return nil }
        
        // Apply color blind correction if needed
        let correctedColor = applyColorBlindCorrection(pixelColor)
        
        return DetectedColor(
            name: correctedColor.closestColorName(),
            uiColor: correctedColor,
            confidence: 0.8
        )
    }
    
    private func applyColorBlindCorrection(_ color: UIColor) -> UIColor {
        guard currentColorBlindType != .normal else { return color }
        
        // Apply daltonization correction
        let ciColor = CIColor(color: color)
        let ciImage = CIImage(color: ciColor).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        
        if let correctedImage = DaltonizationFilter.shared.applyDaltonization(to: ciImage, type: currentColorBlindType) {
            let context = CIContext()
            var pixel: [UInt8] = [0, 0, 0, 0]
            context.render(correctedImage, toBitmap: &pixel, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
            
            return UIColor(
                red: CGFloat(pixel[0]) / 255.0,
                green: CGFloat(pixel[1]) / 255.0,
                blue: CGFloat(pixel[2]) / 255.0,
                alpha: 1.0
            )
        }
        
        return color
    }
    
    private func isDuplicateColor(_ newAnchor: ColorAnchor) -> Bool {
        return activeColorAnchors.contains { existingAnchor in
            let distance = simd_distance(newAnchor.position, existingAnchor.position)
            let colorSimilarity = newAnchor.color.name.lowercased() == existingAnchor.color.name.lowercased()
            return distance < 0.5 && colorSimilarity // Within 50cm and same color
        }
    }
    
    private func addColorAnchor(_ colorAnchor: ColorAnchor) {
        activeColorAnchors.append(colorAnchor)
        
        // Create AR anchor and entity
        createAREntity(for: colorAnchor)
        
        // Provide feedback
        if colorAnchor.isManual {
            announceColor(colorAnchor.color.name)
            if hapticEnabled {
                hapticFeedback.impactOccurred()
            }
        }
        
        // Schedule removal after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + labelDuration) {
            self.removeColorAnchor(colorAnchor)
        }
    }
    
    private func createAREntity(for colorAnchor: ColorAnchor) {
        guard let arView = arView else { return }
        
        // Create text entity
        let textMesh = MeshResource.generateText(
            colorAnchor.color.name,
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: 0.1)
        )
        
        let textMaterial = SimpleMaterial(color: colorAnchor.color.uiColor, isMetallic: false)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
        
        // Create background panel
        let panelMesh = MeshResource.generatePlane(width: 0.3, height: 0.1, cornerRadius: 0.02)
        let panelMaterial = SimpleMaterial(color: .white.withAlphaComponent(0.9), isMetallic: false)
        let panelEntity = ModelEntity(mesh: panelMesh, materials: [panelMaterial])
        
        // Position text on panel
        textEntity.position = SIMD3<Float>(0, 0, 0.001)
        panelEntity.addChild(textEntity)
        
        // Create anchor
        let transform = simd_float4x4(translation: colorAnchor.position)
        let anchor = AnchorEntity(.world(transform: transform))
        anchor.addChild(panelEntity)
        
        // Make it always face the camera
        panelEntity.look(at: arView.cameraTransform.translation, from: colorAnchor.position, relativeTo: nil)
        
        arView.scene.addAnchor(anchor)
        
        // Store reference for cleanup
        colorAnchor.arAnchor = anchor
    }
    
    private func removeColorAnchor(_ colorAnchor: ColorAnchor) {
        if let index = activeColorAnchors.firstIndex(where: { $0.id == colorAnchor.id }) {
            activeColorAnchors.remove(at: index)
        }
        
        if let anchor = colorAnchor.arAnchor {
            arView?.scene.removeAnchor(anchor)
        }
    }
    
    private func announceColor(_ colorName: String) {
        guard voiceEnabled else { return }
        guard Date().timeIntervalSince(lastAnnouncementTime) > announcementCooldown else { return }
        
        let utterance = AVSpeechUtterance(string: colorName)
        utterance.rate = 0.5
        utterance.volume = 0.8
        speechSynthesizer.speak(utterance)
        
        lastAnnouncementTime = Date()
    }
}

// MARK: - ARSessionDelegate
extension ARColorSession: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        DispatchQueue.main.async {
            self.trackingState = frame.camera.trackingState
            self.updateTrackingStatusText()
        }
    }
    
    private func updateTrackingStatusText() {
        switch trackingState {
        case .normal:
            trackingStatusText = "Tracking"
        case .notAvailable:
            trackingStatusText = "Not Available"
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                trackingStatusText = "Move Slower"
            case .insufficientFeatures:
                trackingStatusText = "Point at Textured Surface"
            case .initializing:
                trackingStatusText = "Initializing"
            case .relocalizing:
                trackingStatusText = "Relocalizing"
            @unknown default:
                trackingStatusText = "Limited"
            }
        }
    }
}

// Supporting Models
struct DetectedColor {
    let name: String
    let uiColor: UIColor
    let confidence: Float
}

class ColorAnchor: ObservableObject {
    let id = UUID()
    let color: DetectedColor
    let position: SIMD3<Float>
    let isManual: Bool
    let timestamp: Date
    var arAnchor: AnchorEntity?
    
    init(color: DetectedColor, position: SIMD3<Float>, isManual: Bool, timestamp: Date) {
        self.color = color
        self.position = position
        self.isManual = isManual
        self.timestamp = timestamp
    }
}

class RealTimeColorDetector {
    func detectColors(in frame: ARFrame) -> [DetectedColor] {
        // Implementation for real-time color detection
        return []
    }
}

// Extensions
extension simd_float4x4 {
    init(translation: SIMD3<Float>) {
        self.init(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(translation.x, translation.y, translation.z, 1)
        )
    }
    
    var translation: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}

extension UIImage {
    func getPixelColor(at point: CGPoint) -> UIColor? {
        guard let cgImage = cgImage else { return nil }
        guard let data = cgImage.dataProvider?.data else { return nil }
        guard let bytes = CFDataGetBytePtr(data) else { return nil }
        
        let bytesPerPixel = 4
        let bytesPerRow = cgImage.bytesPerRow
        let pixelOffset = Int(point.y) * bytesPerRow + Int(point.x) * bytesPerPixel
        
        guard pixelOffset < CFDataGetLength(data) else { return nil }
        
        let r = CGFloat(bytes[pixelOffset]) / 255.0
        let g = CGFloat(bytes[pixelOffset + 1]) / 255.0
        let b = CGFloat(bytes[pixelOffset + 2]) / 255.0
        let a = CGFloat(bytes[pixelOffset + 3]) / 255.0
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}