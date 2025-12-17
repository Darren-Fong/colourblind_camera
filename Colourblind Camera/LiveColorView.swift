import SwiftUI
import AVFoundation

struct LiveColorView: View {
    @StateObject private var cameraService = CameraService()
    @State private var selectedFilter = "Normal"
    @State private var showFilterSettings = false
    @State private var showColorText = true
    @State private var cameraPermissionDenied = false
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    let filterOptions = [
        "Normal": (color: Color("Normal"), opacity: 0.0),
        "Deuteranopia": (color: Color("Deuteranopia"), opacity: 0.3),
        "Protanopia": (color: Color("Protanopia"), opacity: 0.3),
        "Trianopia": (color: Color("Trianopia"), opacity: 0.3)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera preview
                if cameraService.session != nil {
                    CameraPreview(session: cameraService.session!)
                        .edgesIgnoringSafeArea(.all)
                } else if cameraPermissionDenied {
                    // Show permission denied message
                    VStack(spacing: 20) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Camera Access Required")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Please enable camera access in Settings to use this feature.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Open Settings") {
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                } else {
                    // Loading state
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Starting Camera...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.top, 10)
                    }
                }
                
                // Color Filter Overlay
                if let filter = filterOptions[selectedFilter] {
                    GlobalColorFilter(color: filter.color, opacity: filter.opacity)
                }
                
                VStack {
                    // Top Controls
                    HStack {
                        // Filter Button
                        Button(action: {
                            showFilterSettings = true
                        }) {
                            HStack {
                                Image(systemName: "eye.fill")
                                Text(selectedFilter)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                        
                        Spacer()
                        
                        // Color Tag Overlay Button
                        NavigationLink(destination: ColorTagOverlayView(cameraService: cameraService)) {
                            Image(systemName: "tag.fill")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                        
                        // Toggle Color Text Button
                        Button(action: {
                            withAnimation {
                                showColorText.toggle()
                            }
                        }) {
                            Image(systemName: showColorText ? "text.bubble.fill" : "text.bubble")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Color Display
                    if showColorText {
                        VStack(spacing: 8) {
                            Text("Current Color")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(cameraService.dominantColor)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(15)
                        }
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom))
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showFilterSettings) {
                FilterSettingsView(selectedFilter: $selectedFilter)
            }
            .onAppear {
                startCamera()
            }
        }
    }
    
    private func startCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraService.checkPermissions()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        cameraService.checkPermissions()
                    } else {
                        cameraPermissionDenied = true
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                cameraPermissionDenied = true
            }
        @unknown default:
            break
        }
    }
}

struct FilterSettingsView: View {
    @Binding var selectedFilter: String
    @Environment(\.presentationMode) var presentationMode
    
    let filters = [
        (name: "Normal", description: "No color adjustment"),
        (name: "Deuteranopia", description: "For red-green color blindness (green weak)"),
        (name: "Protanopia", description: "For red-green color blindness (red weak)"),
        (name: "Trianopia", description: "For blue-yellow color blindness")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filters, id: \.name) { filter in
                    Button(action: {
                        selectedFilter = filter.name
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(filter.name)
                                    .font(.headline)
                                Text(filter.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedFilter == filter.name {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Color Filters")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}