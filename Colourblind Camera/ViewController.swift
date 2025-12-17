import SwiftUI
import UIKit
import PhotosUI
import MobileCoreServices

class ColourblindCameraViewController: UIViewController, PHPickerViewControllerDelegate {

    var configuration: PHPickerConfiguration = {
        var config = PHPickerConfiguration()
        config.filter = .any(of: [.livePhotos, .videos]) // Set the filter type
        config.selection = .ordered // Respect selection order
        config.selectionLimit = 0 // Enable multiselection
        return config
    }()

    var selection = [String: PHPickerResult]()
    var selectedAssetIdentifiers = [String]()
    var selectedAssetIdentifierIterator: IndexingIterator<[String]>?





    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true, completion: nil)
        
        let existingSelection = selection
        var newSelection = [String: PHPickerResult]()
        
        for result in results {
            guard let identifier = result.assetIdentifier else { continue }
            newSelection[identifier] = existingSelection[identifier] ?? result
        }
        
        // Track the selection in case the user deselects it later
        selection = newSelection
        selectedAssetIdentifiers = results.compactMap { $0.assetIdentifier }
        selectedAssetIdentifierIterator = selectedAssetIdentifiers.makeIterator()
        
        if selection.isEmpty {
            displayEmptyImage()
        } else {
            displayNext()
        }
        
        if let assetIdentifier = selectedAssetIdentifierIterator?.next() {
            loadAsset(assetIdentifier: assetIdentifier)
        }
    }

    private func loadAsset(assetIdentifier: String) {
        guard let itemProvider = selection[assetIdentifier]?.itemProvider else { return }
        
        if itemProvider.canLoadObject(ofClass: PHLivePhoto.self) {
            itemProvider.loadObject(ofClass: PHLivePhoto.self) { [weak self] livePhoto, error in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.handleCompletion(assetIdentifier: assetIdentifier, object: livePhoto, error: error)
                }
            }
        } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] data, error in
                guard self != nil else { return }
                guard let data = data,
                      let cgImageSource = CGImageSourceCreateWithData(data as CFData, nil),
                      let properties = CGImageSourceCopyPropertiesAtIndex(cgImageSource, 0, nil) else { return }
                
                print(properties)
            }
        }
    }

    private func displayEmptyImage() {
        // Handle the case when no images are selected
        print("No images selected.")
    }

    private func displayNext() {
        // Logic to display the next asset
        print("Displaying next asset.")
    }

    private func handleCompletion(assetIdentifier: String, object: Any?, error: Error?) {
        if let error = error {
            print("Error loading asset: \(error.localizedDescription)")
            return
        }
        
        // Process the loaded asset (livePhoto or image)
        print("Successfully loaded asset with identifier: \(assetIdentifier)")
    }
}
