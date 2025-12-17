import Vision
import AVFoundation
import CoreML
import UIKit

class MedicineRecognitionService: NSObject {
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    // Function to recognize text from image
    func recognizeText(in image: UIImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        // Create request handler
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        
        // Create text recognition request
        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  error == nil else {
                completion(nil)
                return
            }
            
            // Process the recognized text
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            completion(recognizedText)
        }
        
        // Configure request for accurate text recognition
        request.recognitionLevel = .accurate
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Error performing text recognition: \(error)")
            completion(nil)
        }
    }
    
    // Function to speak text
    func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.volume = 1.0
        
        speechSynthesizer.speak(utterance)
    }
    
    // Function to stop speaking
    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
}