import SwiftUI
import AVFoundation

struct MedicineDetailView: View {
    let medicine: Medicine
    @Environment(\.presentationMode) var presentationMode
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Images
                    HStack(spacing: 20) {
                        if let pillImage = medicine.pillImage {
                            VStack {
                                Image(uiImage: pillImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                Text("Pill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let boxImage = medicine.boxImage {
                            VStack {
                                Image(uiImage: boxImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                Text("Box")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    
                    // Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text(medicine.name)
                            .font(.title)
                            .bold()
                        
                        Text(medicine.description)
                            .font(.body)
                    }
                    .padding()
                    
                    // Text-to-Speech Button
                    Button(action: speakMedicineInfo) {
                        Label("Read Information", systemImage: "speaker.wave.2.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding()
                }
            }
            .navigationTitle("Medicine Details")
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
    
    private func speakMedicineInfo() {
        let textToSpeak = "This is \(medicine.name). \(medicine.description)"
        let utterance = AVSpeechUtterance(string: textToSpeak)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        speechSynthesizer.speak(utterance)
    }
}