import SwiftUI

struct ColorIdentificationHelpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    helpSection(title: "Getting Started",
                              content: "Point your camera at any object to identify its color. The color will be detected at the center of the screen, marked by the crosshair.")
                    
                    helpSection(title: "Auto vs Manual Mode",
                              content: "Toggle between automatic and manual color announcement using the speaker button at the top of the screen.")
                    
                    helpSection(title: "Color Information",
                              content: "Show or hide detailed color information using the eye button at the bottom of the screen.")
                    
                    helpSection(title: "Manual Speak",
                              content: "In manual mode, tap the speak button to hear the current color.")
                }
                .padding()
            }
            .navigationTitle("How to Use")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func helpSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .foregroundColor(.secondary)
        }
    }
}