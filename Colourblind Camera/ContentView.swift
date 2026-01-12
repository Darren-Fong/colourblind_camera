//
//  MainTabView.swift
//  Colourblind Camera
//
//  Clean, optimized main interface
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LiveCameraView()
                .tabItem {
                    Label("Live", systemImage: "camera.viewfinder")
                }
                .tag(0)
            
            AlbumView()
                .tabItem {
                    Label("Album", systemImage: "photo.stack")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .tint(.blue)
    }
}

struct MoreFeaturesView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Color Learning
                    FeatureCard(
                        title: "Color Learning",
                        description: "Interactive games to learn colors better",
                        icon: "graduationcap.fill",
                        color: .green,
                        destination: AnyView(ColorLearningView())
                    )
                    
                    // Pattern Converter (Idea 2)
                    FeatureCard(
                        title: "Pattern Converter",
                        description: "Convert images to pattern-coded versions",
                        icon: "square.grid.3x3.fill",
                        color: .indigo,
                        destination: AnyView(PatternCodingConverterView())
                    )
                    
                    // Color Blindness Detection
                    FeatureCard(
                        title: "Vision Test",
                        description: "Test and detect your color blindness type",
                        icon: "eye.fill",
                        color: .blue,
                        destination: AnyView(ColorBlindnessDetectionView())
                    )
                    
                    // Settings
                    NavigationLink(destination: SettingsView()) {
                        HStack {
                            Image(systemName: "gear")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            Text("Settings")
                                .font(.headline)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("More Features")
        }
    }
}

struct FeatureCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 15) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(radius: 2)
        }
    }
}

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // App Icon and Title
                VStack(spacing: 15) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Colourblind Camera")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version 4.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Description
                VStack(alignment: .leading, spacing: 15) {
                    Text("About")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Colourblind Camera is designed to help people with color vision deficiency identify and understand colors in their environment. Using advanced computer vision and AI, the app provides real-time color identification, learning tools, and accessibility features.")
                        .font(.body)
                        .multilineTextAlignment(.leading)
                }
                
                // Features
                VStack(alignment: .leading, spacing: 15) {
                    Text("Key Features")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Real-time color identification with voice announcements")
                        Text("• AR-powered color labeling in 3D space")
                        Text("• Interactive color learning games")
                        Text("• Voice assistant for hands-free operation")
                        Text("• Safety alerts for critical color situations")
                        Text("• Color-blind friendly design suggestions")
                        Text("• Personal color album with analysis")
                    }
                    .font(.subheadline)
                }
                
                // Credits
                VStack(alignment: .leading, spacing: 15) {
                    Text("Credits")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Developed with ❤️ for the color-blind community")
                        .font(.body)
                        .italic()
                }
                
                // Legal
                VStack(spacing: 10) {
                    Button("Privacy Policy") {
                        // Open privacy policy
                    }
                    .foregroundColor(.blue)
                    
                    Button("Terms of Service") {
                        // Open terms
                    }
                    .foregroundColor(.blue)
                    
                    Text("© 2024 Colourblind Camera. All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.large)
    }
}