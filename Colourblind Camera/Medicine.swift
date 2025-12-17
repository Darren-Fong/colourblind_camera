import SwiftUI

struct Medicine: Identifiable, Codable {
    var id = UUID()
    var name: String
    var description: String
    var pillImagePath: String
    var boxImagePath: String
    var dateAdded: Date
    
    var pillImage: UIImage? {
        if let data = try? Data(contentsOf: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(pillImagePath)) {
            return UIImage(data: data)
        }
        return nil
    }
    
    var boxImage: UIImage? {
        if let data = try? Data(contentsOf: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(boxImagePath)) {
            return UIImage(data: data)
        }
        return nil
    }
}