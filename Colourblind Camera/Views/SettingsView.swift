//
//  SettingsView.swift
//  Colourblind Camera
//
//  App settings
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("4.0")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Features")) {
                    Label("Real-time color detection", systemImage: "eye.fill")
                    Label("AI object recognition", systemImage: "sparkles")
                    Label("Photo color analysis", systemImage: "photo")
                    Label("Optimized performance", systemImage: "bolt.fill")
                }
                
                Section(header: Text("Credits")) {
                    Text("Built with Swift and CoreML")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
