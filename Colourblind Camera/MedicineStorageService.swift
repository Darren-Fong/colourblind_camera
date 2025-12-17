import SwiftUI

class MedicineStorageService: ObservableObject {
    @Published var medicines: [Medicine] = []
    private let saveKey = "SavedMedicines"
    
    init() {
        loadMedicines()
    }
    
    private func loadMedicines() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let medicines = try? JSONDecoder().decode([Medicine].self, from: data) {
            self.medicines = medicines
        }
    }
    
    private func saveMedicines() {
        if let encoded = try? JSONEncoder().encode(medicines) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    func addMedicine(_ medicine: Medicine) {
        medicines.append(medicine)
        saveMedicines()
    }
    
    func deleteMedicine(withId id: UUID) {
        if let index = medicines.firstIndex(where: { $0.id == id }) {
            // Delete associated images
            try? FileManager.default.removeItem(at: getDocumentsDirectory().appendingPathComponent(medicines[index].pillImagePath))
            try? FileManager.default.removeItem(at: getDocumentsDirectory().appendingPathComponent(medicines[index].boxImagePath))
            
            medicines.remove(at: index)
            saveMedicines()
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func saveImage(_ image: UIImage, forMedicineId id: UUID, isBoxImage: Bool) -> String? {
        let fileName = "\(id.uuidString)_\(isBoxImage ? "box" : "pill").jpg"
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
            return fileName
        }
        return nil
    }
    
    func findMedicine(byImage image: UIImage) -> Medicine? {
        // This is a simple comparison that you might want to enhance with more sophisticated image matching
        guard let searchImageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        return medicines.first { medicine in
            if let pillImage = medicine.pillImage,
               let pillImageData = pillImage.jpegData(compressionQuality: 0.8) {
                return pillImageData == searchImageData
            }
            return false
        }
    }
}