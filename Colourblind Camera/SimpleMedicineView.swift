import SwiftUI

struct SimpleMedicineView: View {
    @StateObject private var medicineStorage = MedicineStorageService()
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var isRecognizing = false
    @State private var showingMedicineInfo = false
    @State private var recognizedText = ""
    @State private var medicineName = ""
    @State private var medicineDescription = ""
    
    private let medicineRecognitionService = MedicineRecognitionService()
    
    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle("Medicine Scanner")
                .sheet(isPresented: $showingCamera) {
                    CustomCameraView(capturedImage: $capturedImage)
                }
                .onChange(of: capturedImage) { oldImage, newImage in
                    handleCapturedImage(newImage)
                }
                .sheet(isPresented: $showingMedicineInfo) {
                    medicineInfoSheet
                }
                .overlay {
                    if isRecognizing {
                        loadingOverlay
                    }
                }
        }
    }
    
    private var mainContent: some View {
        VStack {
            if !medicineStorage.medicines.isEmpty {
                medicineList
            } else {
                emptyStateView
            }
            
            cameraButton
        }
    }
    
    private var medicineList: some View {
        List {
            ForEach(medicineStorage.medicines) { medicine in
                MedicineListItem(medicine: medicine)
                    .onTapGesture {
                        let text = "\(medicine.name). \(medicine.description)"
                        medicineRecognitionService.speakText(text)
                    }
            }
            .onDelete(perform: deleteMedicine)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.circle")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Take a Picture of Medicine")
                .font(.title2)
                .multilineTextAlignment(.center)
            
            Text("Tap the camera button to scan and save medicine information")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var cameraButton: some View {
        Button(action: {
            showingCamera = true
        }) {
            HStack {
                Image(systemName: "camera.fill")
                Text("Take Photo")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding()
    }
    
    private var medicineInfoSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Medicine Information")) {
                    TextField("Medicine Name", text: $medicineName)
                    TextEditor(text: $medicineDescription)
                        .frame(height: 100)
                }
                
                Section(header: Text("Recognized Text")) {
                    Text(recognizedText)
                        .foregroundColor(.secondary)
                }
                
                if let image = capturedImage {
                    Section(header: Text("Image")) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    }
                }
            }
            .navigationTitle("Save Medicine")
            .navigationBarItems(
                leading: Button("Cancel") {
                    showingMedicineInfo = false
                    capturedImage = nil
                    medicineName = ""
                    medicineDescription = ""
                    recognizedText = ""
                },
                trailing: Button("Save") {
                    saveMedicine()
                    showingMedicineInfo = false
                }
            )
        }
    }
    
    private var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay(
                LoadingView(message: "Analyzing Medicine...")
            )
    }
    
    private func handleCapturedImage(_ newImage: UIImage?) {
        if let image = newImage {
            isRecognizing = true
            medicineRecognitionService.recognizeText(in: image) { text in
                isRecognizing = false
                if let text = text {
                    recognizedText = text
                    medicineName = text
                    showingMedicineInfo = true
                }
            }
        }
    }
    
    private func deleteMedicine(at offsets: IndexSet) {
        offsets.forEach { index in
            medicineStorage.deleteMedicine(withId: medicineStorage.medicines[index].id)
        }
    }
    
    private func saveMedicine() {
        let id = UUID()
        if let image = capturedImage,
           let pillImagePath = medicineStorage.saveImage(image, forMedicineId: id, isBoxImage: false) {
            let medicine = Medicine(
                id: id,
                name: medicineName,
                description: medicineDescription,
                pillImagePath: pillImagePath,
                boxImagePath: "",
                dateAdded: Date()
            )
            medicineStorage.addMedicine(medicine)
            
            capturedImage = nil
            medicineName = ""
            medicineDescription = ""
            recognizedText = ""
        }
    }
}

struct MedicineListItem: View {
    let medicine: Medicine
    
    var body: some View {
        HStack(spacing: 12) {
            if let image = UIImage(contentsOfFile: medicine.pillImagePath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "pills.fill")
                    .font(.title)
                    .frame(width: 60, height: 60)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(medicine.name)
                    .font(.headline)
                Text(medicine.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "speaker.wave.2")
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}
