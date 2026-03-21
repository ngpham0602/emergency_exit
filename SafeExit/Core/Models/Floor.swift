import Foundation
import FirebaseFirestore

struct Floor: Codable, Identifiable {
    @DocumentID var id: String?
    var buildingId: String
    var floorNumber: Int          // negative = basement: -1, -2
    var floorLabel: String        // "Ground Floor" "Level 3" "Basement 1"
    var mapImageURL: String       // Firebase Storage URL of the map photo
    var mapImageWidth: Double     // original photo width in pixels
    var mapImageHeight: Double    // original photo height in pixels
    var analysisStatus: String    // "pending" | "analyzed" | "verified"
    var confidenceTier: String    // "unverified" | "community" | "official"
    var uploadCount: Int
}
