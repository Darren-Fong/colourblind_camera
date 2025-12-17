import SwiftUI
import AVFoundation

struct LiveColorView: View {
    @StateObject private var cameraService = CameraService()
    @State private var selectedFilter = "Normal"
    @State private var showFilterSettings = false
    @State private var showColorText = true
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
                if let session = cameraService.session {
                    CameraPreview(session: session)
                        .edgesIgnoringSafeArea(.all)
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