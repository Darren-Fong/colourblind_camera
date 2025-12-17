import SwiftUI
import AVFoundation

struct MedicineListView: View {
    @StateObject private var storageService = MedicineStorageService()
    @State private var showingAddMedicine = false
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(storageService.medicines) { medicine in
                    MedicineRowView(medicine: medicine, storageService: storageService, speechSynthesizer: speechSynthesizer)
                }
                .onDelete { indices in
                    indices.forEach { index in
                        let medicine = storageService.medicines[index]
                        storageService.deleteMedicine(withId: medicine.id)
                    }
                }
            }
            .navigationTitle("My Medicines")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddMedicine = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMedicine) {
                AddMedicineView(storageService: storageService)
            }
        }
    }
}

struct MedicineRowView: View {
    let medicine: Medicine
    let storageService: MedicineStorageService
    let speechSynthesizer: AVSpeechSynthesizer
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            HStack {
                if let pillImage = medicine.pillImage {
                    Image(uiImage: pillImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                VStack(alignment: .leading) {
                    Text(medicine.name)
                        .font(.headline)
                    Text(medicine.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .sheet(isPresented: $showingDetail) {
            MedicineDetailView(medicine: medicine)
        }
    }
}