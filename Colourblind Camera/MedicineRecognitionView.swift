import SwiftUI

struct MedicineRecognitionView: View {
    @StateObject private var storageService = MedicineStorageService()
    @State private var showingCamera = false
    @State private var showingAddSheet = false
    @State private var isPillImage = true
    @State private var pillImage: UIImage?
    @State private var boxImage: UIImage?
    @State private var recognizedText: String = ""
    @State private var medicineName: String = ""
    @State private var medicineDescription: String = ""
    @State private var isScanning = false
    
    private let medicineRecognitionService = MedicineRecognitionService()
    
    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle("Medicine Recognition")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingAddSheet = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAddSheet) {
                    addMedicineSheet
                }
                .sheet(isPresented: $showingCamera) {
                    cameraView
                }
        }
    }
    
    private var mainContent: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                if !storageService.medicines.isEmpty {
                    medicineListView
                } else {
                    emptyStateView
                }
            }
        }
    }
    
    private var medicineListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(storageService.medicines) { medicine in
                    MedicineRow(medicine: medicine, storageService: storageService)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "pills.fill")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text("No medicines saved yet")
                .font(.title3)
                .foregroundColor(.gray)
            Text("Tap the + button to add your first medicine")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
    }
    
    private var addMedicineSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                imagePicker
                cameraButton
                textFields
                
                if isScanning {
                    ProgressView("Scanning...")
                }
                
                scanButton
                
                if !recognizedText.isEmpty {
                    recognizedTextView
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Medicine")
            .navigationBarItems(
                leading: cancelButton,
                trailing: saveButton
            )
        }
    }
    
    private var imagePicker: some View {
        VStack(spacing: 20) {
            Picker("Image Type", selection: $isPillImage) {
                Text("Pill Image").tag(true)
                Text("Box Image").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if isPillImage {
                if let image = pillImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(10)
                }
            } else {
                if let image = boxImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(10)
                }
            }
        }
    }
    
    private var cameraButton: some View {
        Button(action: {
            showingCamera = true
        }) {
            HStack {
                Image(systemName: "camera")
                Text("Take Photo")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    private var textFields: some View {
        VStack(spacing: 10) {
            TextField("Medicine Name", text: $medicineName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            TextField("Description", text: $medicineDescription)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
        }
    }
    
    private var scanButton: some View {
        Button(action: scanImage) {
            Text("Scan Image")
                .frame(maxWidth: .infinity)
                .padding()
                .background((isPillImage ? pillImage : boxImage) == nil ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .disabled((isPillImage ? pillImage : boxImage) == nil)
        .padding(.horizontal)
    }
    
    private var recognizedTextView: some View {
        ScrollView {
            Text(recognizedText)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
        }
        .frame(maxHeight: 100)
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            showingAddSheet = false
            pillImage = nil
            boxImage = nil
            recognizedText = ""
            medicineName = ""
            medicineDescription = ""
        }
    }
    
    private var saveButton: some View {
        Button("Save") {
            saveMedicine()
        }
        .disabled(medicineName.isEmpty && (pillImage == nil && boxImage == nil))
    }
    
    private var cameraView: some View {
        CustomCameraView(capturedImage: isPillImage ? $pillImage : $boxImage)
    }
    
    private func scanImage() {
        let imageToScan = isPillImage ? pillImage : boxImage
        guard let image = imageToScan else { return }
        
        isScanning = true
        medicineRecognitionService.recognizeText(in: image) { text in
            isScanning = false
            if let text = text {
                recognizedText = text
                medicineName = text.components(separatedBy: .newlines).first ?? ""
            }
        }
    }
    
    private func saveMedicine() {
        let id = UUID()
        let pillImg = pillImage
        let boxImg = boxImage
        
        if pillImg != nil || boxImg != nil {
            var pillPath = ""
            var boxPath = ""
            
            if let img = pillImg {
                pillPath = storageService.saveImage(img, forMedicineId: id, isBoxImage: false) ?? ""
            }
            if let img = boxImg {
                boxPath = storageService.saveImage(img, forMedicineId: id, isBoxImage: true) ?? ""
            }
            
            let medicine = Medicine(
                id: id,
                name: medicineName,
                description: medicineDescription,
                pillImagePath: pillPath,
                boxImagePath: boxPath,
                dateAdded: Date()
            )
            storageService.addMedicine(medicine)
            showingAddSheet = false
            pillImage = nil
            boxImage = nil
            recognizedText = ""
            medicineName = ""
            medicineDescription = ""
        }
    }
    
    func deleteMedicine(at offsets: IndexSet) {
        offsets.forEach { index in
            let medicine = storageService.medicines[index]
            storageService.deleteMedicine(withId: medicine.id)
        }
    }
}

struct MedicineRow: View {
    let medicine: Medicine
    let storageService: MedicineStorageService
    @State private var showingDetail = false
    @State private var isReadingText = false
    
    private let recognitionService = MedicineRecognitionService()
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            HStack(spacing: 16) {
                if let uiImage = medicine.pillImage ?? medicine.boxImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                } else {
                    Image(systemName: "pills.fill")
                        .font(.title)
                        .frame(width: 60, height: 60)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(medicine.name)
                        .font(.headline)
                    if !medicine.description.isEmpty {
                        Text(medicine.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    guard !isReadingText else { return }
                    isReadingText = true
                    
                    let imageToScan = medicine.boxImage ?? medicine.pillImage
                    
                    if let image = imageToScan {
                        recognitionService.recognizeText(in: image) { text in
                            if let text = text {
                                recognitionService.speakText(text)
                            }
                            isReadingText = false
                        }
                    } else {
                        isReadingText = false
                    }
                }) {
                    Image(systemName: isReadingText ? "stop.fill" : "play.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                .disabled(medicine.pillImage == nil && medicine.boxImage == nil)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            MedicineDetailView(medicine: medicine)
        }
    }
}