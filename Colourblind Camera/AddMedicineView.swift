import SwiftUI
import AVFoundation

struct AddMedicineView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var storageService: MedicineStorageService
    
    @State private var medicineName = ""
    @State private var medicineDescription = ""
    @State private var pillImage: UIImage?
    @State private var boxImage: UIImage?
    @State private var showingPillImagePicker = false
    @State private var showingBoxImagePicker = false
    @State private var isShowingCamera = false
    @State private var currentImageType: ImageType = .pill
    
    enum ImageType {
        case pill
        case box
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Medicine Information")) {
                    TextField("Medicine Name", text: $medicineName)
                    TextField("Description/Function", text: $medicineDescription)
                }
                
                Section(header: Text("Medicine Images")) {
                    HStack {
                        Text("Pill Photo")
                        Spacer()
                        if let image = pillImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        Button(action: {
                            currentImageType = .pill
                            isShowingCamera = true
                        }) {
                            Image(systemName: "camera")
                        }
                    }
                    
                    HStack {
                        Text("Box Photo")
                        Spacer()
                        if let image = boxImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        Button(action: {
                            currentImageType = .box
                            isShowingCamera = true
                        }) {
                            Image(systemName: "camera")
                        }
                    }
                }
            }
            .navigationTitle("Add Medicine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMedicine()
                    }
                    .disabled(medicineName.isEmpty || medicineDescription.isEmpty || pillImage == nil || boxImage == nil)
                }
            }
            .sheet(isPresented: $isShowingCamera) {
                CustomCameraView(capturedImage: Binding(
                    get: { currentImageType == .pill ? pillImage : boxImage },
                    set: { newImage in
                        if currentImageType == .pill {
                            pillImage = newImage
                        } else {
                            boxImage = newImage
                        }
                    }
                ))
            }
        }
    }
    
    private func saveMedicine() {
        let id = UUID()
        
        // Save images and get their paths
        guard let pillImagePath = storageService.saveImage(pillImage!, forMedicineId: id, isBoxImage: false),
              let boxImagePath = storageService.saveImage(boxImage!, forMedicineId: id, isBoxImage: true)
        else { return }
        
        let medicine = Medicine(
            id: id,
            name: medicineName,
            description: medicineDescription,
            pillImagePath: pillImagePath,
            boxImagePath: boxImagePath,
            dateAdded: Date()
        )
        
        storageService.addMedicine(medicine)
        presentationMode.wrappedValue.dismiss()
    }
}